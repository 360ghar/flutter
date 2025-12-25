import 'dart:async';
import 'dart:convert';

import 'package:firebase_performance/firebase_performance.dart' as fp;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart' as getx;
import 'package:ghar360/core/network/auth_header_provider.dart';
import 'package:ghar360/core/network/etag_cache.dart';
import 'package:ghar360/core/utils/app_exceptions.dart';
import 'package:ghar360/core/utils/debug_logger.dart';

/// Focused HTTP client for API communication.
/// Handles: auth headers, retries, instrumentation, caching (ETag).
class ApiClient {
  final String _baseUrl;
  final AuthHeaderProvider _authProvider;
  final ETagCache _etagCache;
  final int _timeoutSeconds;

  ApiClient({
    String? baseUrl,
    AuthHeaderProvider? authProvider,
    ETagCache? etagCache,
    int timeoutSeconds = 15,
  }) : _baseUrl = baseUrl ?? dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000',
       _authProvider = authProvider ?? AuthHeaderProvider(),
       _etagCache = etagCache ?? ETagCache(),
       _timeoutSeconds = timeoutSeconds;

  String get baseUrl => _baseUrl;

  /// Makes a GET request.
  Future<ApiResponse> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool useCache = true,
  }) async {
    return _makeRequest('GET', endpoint, queryParams: queryParams, useCache: useCache);
  }

  /// Makes a POST request.
  Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
  }) async {
    return _makeRequest('POST', endpoint, body: body, queryParams: queryParams);
  }

  /// Makes a PUT request.
  Future<ApiResponse> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
  }) async {
    return _makeRequest('PUT', endpoint, body: body, queryParams: queryParams);
  }

  /// Makes a DELETE request.
  Future<ApiResponse> delete(String endpoint, {Map<String, dynamic>? queryParams}) async {
    return _makeRequest('DELETE', endpoint, queryParams: queryParams);
  }

  /// Makes a PATCH request.
  Future<ApiResponse> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
  }) async {
    return _makeRequest('PATCH', endpoint, body: body, queryParams: queryParams);
  }

  Future<ApiResponse> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    bool useCache = false,
  }) async {
    final fullEndpoint = _buildUrl(endpoint, queryParams);
    final headers = await _buildHeaders();
    final cacheKey = useCache ? _buildCacheKey(method, fullEndpoint) : null;

    // Add ETag header if cached
    if (useCache && cacheKey != null) {
      final cachedEtag = _etagCache.getETag(cacheKey);
      if (cachedEtag != null) {
        headers['If-None-Match'] = cachedEtag;
        DebugLogger.debug('🧠 Added If-None-Match for $fullEndpoint');
      }
    }

    // Performance instrumentation
    fp.HttpMetric? httpMetric;
    if (!kDebugMode) {
      try {
        httpMetric = fp.FirebasePerformance.instance.newHttpMetric(
          fullEndpoint,
          _methodToHttpMethod(method),
        );
        await httpMetric.start();
      } catch (_) {}
    }

    DebugLogger.api('🚀 API $method $fullEndpoint');

    try {
      final getxClient = getx.GetConnect();
      getxClient.timeout = Duration(seconds: _timeoutSeconds);

      getx.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await getxClient.get(fullEndpoint, headers: headers);
          break;
        case 'POST':
          response = await getxClient.post(fullEndpoint, body, headers: headers);
          break;
        case 'PUT':
          response = await getxClient.put(fullEndpoint, body, headers: headers);
          break;
        case 'DELETE':
          response = await getxClient.delete(fullEndpoint, headers: headers);
          break;
        case 'PATCH':
          response = await getxClient.patch(fullEndpoint, body, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      DebugLogger.api('📨 API $method $fullEndpoint → ${response.statusCode}');

      // Stop instrumentation
      if (httpMetric != null) {
        httpMetric.httpResponseCode = response.statusCode ?? 0;
        final bodyLen = response.bodyString?.length;
        if (bodyLen != null) httpMetric.responsePayloadSize = bodyLen;
        await httpMetric.stop();
      }

      // Handle 304 Not Modified
      if (response.statusCode == 304 && cacheKey != null) {
        final cachedBody = _etagCache.getCachedBody(cacheKey);
        if (cachedBody != null) {
          DebugLogger.debug('🔁 304 for $fullEndpoint → serving cached response');
          return ApiResponse(
            statusCode: 200,
            body: jsonDecode(cachedBody),
            headers: response.headers ?? {},
          );
        }
      }

      // Handle errors
      if (response.statusCode == null || response.statusCode! >= 400) {
        throw _mapHttpError(response);
      }

      // Cache successful GET responses
      if (method.toUpperCase() == 'GET' && useCache && cacheKey != null) {
        _etagCache.cacheResponse(cacheKey, response);
      }

      return ApiResponse(
        statusCode: response.statusCode!,
        body: response.body,
        headers: response.headers ?? {},
      );
    } on TimeoutException {
      throw NetworkException('Request timed out after $_timeoutSeconds seconds');
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  String _buildUrl(String endpoint, Map<String, dynamic>? queryParams) {
    final rawUrl = endpoint.startsWith('http') ? endpoint : '$_baseUrl$endpoint';
    final uri = Uri.parse(rawUrl);
    if (queryParams == null || queryParams.isEmpty) {
      return uri.toString();
    }

    final merged = Map<String, String>.from(uri.queryParameters);
    for (final entry in queryParams.entries) {
      if (entry.value == null) continue;
      merged[entry.key] = entry.value.toString();
    }

    return uri.replace(queryParameters: merged).toString();
  }

  Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add auth header if available
    final authHeader = await _authProvider.getAuthHeader();
    if (authHeader != null) {
      headers.addAll(authHeader);
    }

    return headers;
  }

  String? _buildCacheKey(String method, String url) {
    return method.toUpperCase() == 'GET' ? url : null;
  }

  fp.HttpMethod _methodToHttpMethod(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return fp.HttpMethod.Get;
      case 'POST':
        return fp.HttpMethod.Post;
      case 'PUT':
        return fp.HttpMethod.Put;
      case 'DELETE':
        return fp.HttpMethod.Delete;
      case 'PATCH':
        return fp.HttpMethod.Patch;
      default:
        return fp.HttpMethod.Get;
    }
  }

  AppException _mapHttpError(getx.Response response) {
    final statusCode = response.statusCode ?? 0;
    final bodyString = response.bodyString ?? '';

    if (statusCode == 401 || statusCode == 403) {
      return AuthenticationException('Authentication failed');
    }

    if (statusCode >= 500) {
      return ServerException('Server error: $statusCode');
    }

    if (statusCode >= 400) {
      return ApiException('API error: $bodyString', statusCode: statusCode);
    }

    return NetworkException('Unknown error: $statusCode');
  }

  /// Clears the ETag cache.
  void clearCache() => _etagCache.clear();
}

/// Response wrapper for API calls.
class ApiResponse {
  final int statusCode;
  final dynamic body;
  final Map<String, String> headers;

  ApiResponse({required this.statusCode, required this.body, required this.headers});

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}
