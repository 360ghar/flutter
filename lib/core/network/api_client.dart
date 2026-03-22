import 'dart:async';
import 'dart:convert';

import 'package:firebase_performance/firebase_performance.dart' as fp;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart' as getx;
import 'package:ghar360/core/network/api_paths.dart';
import 'package:ghar360/core/network/auth_header_provider.dart';
import 'package:ghar360/core/network/etag_cache.dart';
import 'package:ghar360/core/utils/app_exceptions.dart';
import 'package:ghar360/core/utils/debug_logger.dart';

class UnauthorizedEvent {
  final AuthenticationException error;
  final String method;
  final String endpoint;
  final int statusCode;
  final bool isSessionCritical;

  const UnauthorizedEvent({
    required this.error,
    required this.method,
    required this.endpoint,
    required this.statusCode,
    required this.isSessionCritical,
  });
}

typedef UnauthorizedHandler = Future<void> Function(UnauthorizedEvent event);
typedef RequestDispatcher =
    Future<getx.Response> Function(
      String method,
      String url, {
      Map<String, dynamic>? body,
      required Map<String, String> headers,
    });

/// Focused HTTP client for API communication.
/// Handles: auth headers, retries, instrumentation, caching (ETag).
class ApiClient {
  static UnauthorizedHandler? onUnauthorized;
  static DateTime? _lastUnauthorizedNotificationAt;
  static const Duration _unauthorizedNotificationCooldown = Duration(seconds: 6);

  final String _baseUrl;
  final AuthHeaderProvider _authProvider;
  final ETagCache _etagCache;
  final int _timeoutSeconds;
  final int _maxGetRetries;
  final bool _enablePerformanceMetrics;
  final RequestDispatcher? _requestDispatcher;
  getx.GetConnect? _client;

  /// In-flight GET requests keyed by full URL. Prevents duplicate network
  /// calls when multiple controllers request the same endpoint concurrently.
  final Map<String, Future<ApiResponse>> _inflightGets = {};

  ApiClient({
    String? baseUrl,
    AuthHeaderProvider? authProvider,
    ETagCache? etagCache,
    int timeoutSeconds = 15,
    int maxGetRetries = 2,
    bool enablePerformanceMetrics = !kDebugMode,
    RequestDispatcher? requestDispatcher,
    getx.GetConnect? client,
  }) : _baseUrl = _normalizeBaseUrl(
         baseUrl ?? dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000',
       ),
       _authProvider = authProvider ?? AuthHeaderProvider(),
       _etagCache = etagCache ?? ETagCache(),
       _timeoutSeconds = timeoutSeconds,
       _maxGetRetries = maxGetRetries,
       _enablePerformanceMetrics = enablePerformanceMetrics,
       _requestDispatcher = requestDispatcher,
       _client = client;

  String get baseUrl => _baseUrl;

  getx.GetConnect get _resolvedClient =>
      _client ??= (getx.GetConnect()..timeout = Duration(seconds: _timeoutSeconds));

  /// Makes a GET request.
  /// Set [dedupe] to false to bypass in-flight request deduplication.
  Future<ApiResponse> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool useCache = true,
    bool dedupe = true,
    bool requireAuth = true,
    bool notifyUnauthorized = true,
  }) async {
    if (!dedupe) {
      return _makeRequest(
        'GET',
        endpoint,
        queryParams: queryParams,
        useCache: useCache,
        requireAuth: requireAuth,
        notifyUnauthorized: notifyUnauthorized,
      );
    }

    final dedupeKey = _buildUrl(endpoint, queryParams);
    final inflight = _inflightGets[dedupeKey];
    if (inflight != null) {
      DebugLogger.debug('🔗 Deduplicating GET $dedupeKey');
      return inflight;
    }

    final future =
        _makeRequest(
          'GET',
          endpoint,
          queryParams: queryParams,
          useCache: useCache,
          requireAuth: requireAuth,
          notifyUnauthorized: notifyUnauthorized,
        ).whenComplete(() {
          _inflightGets.remove(dedupeKey);
        });

    _inflightGets[dedupeKey] = future;
    return future;
  }

  /// Makes a POST request.
  /// Set [idempotent] to true to allow one retry on transient errors.
  Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    bool idempotent = false,
    bool requireAuth = true,
    bool notifyUnauthorized = true,
  }) async {
    return _makeRequest(
      'POST',
      endpoint,
      body: body,
      queryParams: queryParams,
      idempotent: idempotent,
      requireAuth: requireAuth,
      notifyUnauthorized: notifyUnauthorized,
    );
  }

  /// Makes a PUT request.
  /// Set [idempotent] to true to allow one retry on transient errors.
  Future<ApiResponse> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    bool idempotent = false,
    bool requireAuth = true,
    bool notifyUnauthorized = true,
  }) async {
    return _makeRequest(
      'PUT',
      endpoint,
      body: body,
      queryParams: queryParams,
      idempotent: idempotent,
      requireAuth: requireAuth,
      notifyUnauthorized: notifyUnauthorized,
    );
  }

  /// Makes a DELETE request.
  Future<ApiResponse> delete(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool requireAuth = true,
    bool notifyUnauthorized = true,
  }) async {
    return _makeRequest(
      'DELETE',
      endpoint,
      queryParams: queryParams,
      requireAuth: requireAuth,
      notifyUnauthorized: notifyUnauthorized,
    );
  }

  /// Makes a PATCH request.
  Future<ApiResponse> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    bool requireAuth = true,
    bool notifyUnauthorized = true,
  }) async {
    return _makeRequest(
      'PATCH',
      endpoint,
      body: body,
      queryParams: queryParams,
      requireAuth: requireAuth,
      notifyUnauthorized: notifyUnauthorized,
    );
  }

  Future<ApiResponse> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    bool useCache = false,
    bool idempotent = false,
    bool requireAuth = true,
    bool notifyUnauthorized = true,
  }) async {
    final fullEndpoint = _buildUrl(endpoint, queryParams);
    var headers = await _buildHeaders(requireAuth: requireAuth, forceRefresh: false);
    final cacheKey = useCache ? _buildCacheKey(method, fullEndpoint) : null;
    final sessionCritical = isSessionCriticalEndpoint(fullEndpoint);
    var authRefreshRetryPerformed = false;

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
    int? responseCodeForMetric;
    int? responseSizeForMetric;
    if (_enablePerformanceMetrics) {
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
      var attempt = 0;
      while (true) {
        try {
          final response = await _dispatchRequest(
            method,
            fullEndpoint,
            body: body,
            headers: headers,
          );
          responseCodeForMetric = response.statusCode;
          responseSizeForMetric = response.bodyString?.length;
          DebugLogger.api('📨 API $method $fullEndpoint → ${response.statusCode}');

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
            if (response.statusCode == 401 && requireAuth && !authRefreshRetryPerformed) {
              authRefreshRetryPerformed = true;
              try {
                headers = await _buildHeaders(requireAuth: true, forceRefresh: true);
                DebugLogger.warning(
                  '🔐 401 received for $fullEndpoint. '
                  'Forced token refresh succeeded; retrying once.',
                );
                continue;
              } catch (refreshError, refreshStackTrace) {
                DebugLogger.warning(
                  '🔐 401 received for $fullEndpoint but forced refresh failed.',
                  refreshError,
                  refreshStackTrace,
                );
              }
            }

            final mappedError = _mapHttpError(response);
            if (mappedError is AuthenticationException &&
                mappedError.code == 'UNAUTHORIZED' &&
                requireAuth &&
                notifyUnauthorized &&
                sessionCritical) {
              await _notifyUnauthorized(
                UnauthorizedEvent(
                  error: mappedError,
                  method: method.toUpperCase(),
                  endpoint: fullEndpoint,
                  statusCode: response.statusCode ?? 401,
                  isSessionCritical: sessionCritical,
                ),
              );
            }
            if (_shouldRetry(
              method: method,
              error: mappedError,
              attempt: attempt,
              idempotent: idempotent,
            )) {
              attempt++;
              await _retryBackoffDelay(attempt);
              continue;
            }
            throw mappedError;
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
        } on TimeoutException catch (_) {
          if (_shouldRetry(
            method: method,
            error: NetworkException('timeout'),
            attempt: attempt,
            idempotent: idempotent,
          )) {
            attempt++;
            await _retryBackoffDelay(attempt);
            continue;
          }
          throw NetworkException('Request timed out after $_timeoutSeconds seconds');
        } catch (e) {
          if (_shouldRetry(method: method, error: e, attempt: attempt, idempotent: idempotent)) {
            attempt++;
            await _retryBackoffDelay(attempt);
            continue;
          }

          if (e is AppException) rethrow;
          throw NetworkException('Network error: ${e.toString()}');
        }
      }
    } on AppException {
      rethrow;
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    } finally {
      if (httpMetric != null) {
        try {
          httpMetric.httpResponseCode = responseCodeForMetric ?? 0;
          if (responseSizeForMetric != null) {
            final payloadSize = responseSizeForMetric;
            httpMetric.responsePayloadSize = payloadSize;
          }
          await httpMetric.stop();
        } catch (_) {}
      }
    }
  }

  String _buildUrl(String endpoint, Map<String, dynamic>? queryParams) {
    final normalizedEndpoint = ApiPaths.normalize(endpoint);
    final rawUrl = normalizedEndpoint.startsWith('http')
        ? normalizedEndpoint
        : '$_baseUrl$normalizedEndpoint';
    final uri = Uri.parse(rawUrl);
    if (queryParams == null || queryParams.isEmpty) {
      return uri.toString();
    }

    final merged = <String, List<String>>{};
    uri.queryParametersAll.forEach((key, value) {
      merged[key] = List<String>.from(value);
    });

    for (final entry in queryParams.entries) {
      if (entry.value == null) continue;

      final value = entry.value;
      if (value is Iterable && value is! String) {
        final values = value
            .where((item) => item != null)
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList();
        if (values.isNotEmpty) {
          merged[entry.key] = values;
        }
        continue;
      }

      final scalar = value.toString().trim();
      if (scalar.isNotEmpty) {
        merged[entry.key] = [scalar];
      }
    }

    final queryString = merged.entries
        .expand((entry) {
          final encodedKey = Uri.encodeQueryComponent(entry.key);
          final values = entry.value.isEmpty ? const <String>[''] : entry.value;
          return values.map((value) => '$encodedKey=${Uri.encodeQueryComponent(value)}');
        })
        .join('&');

    return uri.replace(query: queryString).toString();
  }

  @visibleForTesting
  String buildUrlForTesting(String endpoint, {Map<String, dynamic>? queryParams}) {
    return _buildUrl(endpoint, queryParams);
  }

  Future<Map<String, String>> _buildHeaders({
    required bool requireAuth,
    bool forceRefresh = false,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (!requireAuth) {
      return headers;
    }

    // Add auth header if available
    final authHeader = await _authProvider.getAuthHeader(forceRefresh: forceRefresh);
    if (authHeader != null) {
      headers.addAll(authHeader);
      final authValue = authHeader['Authorization'] ?? '';
      final hasBearer = authValue.startsWith('Bearer ');
      final tokenPreview = hasBearer && authValue.length > 20
          ? '${authValue.substring(7, 15)}...${authValue.substring(authValue.length - 8)}'
          : 'invalid format';
      DebugLogger.api('🔐 Auth header added (token: $tokenPreview, length: ${authValue.length})');
    } else {
      // CRITICAL: Block request if auth is required but header is not available
      DebugLogger.error('🔐 CRITICAL: No auth header available for authenticated request');
      throw AuthenticationException(
        'Authentication required but no auth header available',
        code: 'MISSING_AUTH_HEADER',
      );
    }

    return headers;
  }

  String? _buildCacheKey(String method, String url) {
    return method.toUpperCase() == 'GET' ? url : null;
  }

  Future<getx.Response> _dispatchRequest(
    String method,
    String url, {
    Map<String, dynamic>? body,
    required Map<String, String> headers,
  }) async {
    final requestDispatcher = _requestDispatcher;
    if (requestDispatcher != null) {
      return requestDispatcher(method.toUpperCase(), url, body: body, headers: headers);
    }

    switch (method.toUpperCase()) {
      case 'GET':
        return _resolvedClient.get(url, headers: headers);
      case 'POST':
        return _resolvedClient.post(url, body, headers: headers);
      case 'PUT':
        return _resolvedClient.put(url, body, headers: headers);
      case 'DELETE':
        return _resolvedClient.delete(url, headers: headers);
      case 'PATCH':
        return _resolvedClient.patch(url, body, headers: headers);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }

  bool _shouldRetry({
    required String method,
    required Object error,
    required int attempt,
    bool idempotent = false,
  }) {
    final isGet = method.toUpperCase() == 'GET';
    // GETs: up to _maxGetRetries. Idempotent mutations: up to 1 retry.
    final maxRetries = isGet ? _maxGetRetries : (idempotent ? 1 : 0);
    if (attempt >= maxRetries) return false;
    return error is NetworkException || error is ServerException;
  }

  Future<void> _retryBackoffDelay(int attempt) async {
    final milliseconds = 250 * (1 << (attempt - 1));
    await Future.delayed(Duration(milliseconds: milliseconds));
  }

  static String _normalizeBaseUrl(String baseUrl) {
    var normalized = baseUrl.trim();
    if (normalized.isEmpty) {
      return 'http://localhost:8000';
    }

    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    if (normalized.endsWith(ApiPaths.apiVersionPrefix)) {
      normalized = normalized.substring(0, normalized.length - ApiPaths.apiVersionPrefix.length);
    }

    return normalized;
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

    if (statusCode == 401) {
      DebugLogger.error('🔐 Authentication failed: $statusCode');
      return AuthenticationException(
        'Your session has expired. Please sign in again.',
        code: 'UNAUTHORIZED',
        details: bodyString,
      );
    }

    if (statusCode == 403) {
      DebugLogger.error('🔐 Authorization denied: $statusCode');
      return AuthenticationException(
        'You do not have permission to access this resource.',
        code: 'FORBIDDEN',
        details: bodyString,
      );
    }

    if (statusCode >= 500) {
      return ServerException('Server error: $statusCode');
    }

    if (statusCode >= 400) {
      return ApiException('API error: $bodyString', statusCode: statusCode);
    }

    return NetworkException('Unknown error: $statusCode');
  }

  Future<void> _notifyUnauthorized(UnauthorizedEvent event) async {
    final callback = onUnauthorized;
    if (callback == null) return;

    final now = DateTime.now();
    final lastNotificationAt = _lastUnauthorizedNotificationAt;
    if (lastNotificationAt != null &&
        now.difference(lastNotificationAt) < _unauthorizedNotificationCooldown) {
      return;
    }

    _lastUnauthorizedNotificationAt = now;
    try {
      await callback(event);
    } catch (e, st) {
      DebugLogger.warning('🔐 Unauthorized handler failed', e, st);
    }
  }

  /// Returns true only for endpoints that represent auth/session validity.
  static bool isSessionCriticalEndpoint(String endpointOrUrl) {
    final uri = Uri.tryParse(endpointOrUrl);
    var path = (uri?.hasScheme == true ? uri!.path : ApiPaths.normalize(endpointOrUrl)).trim();
    if (path.isEmpty) return false;
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    const criticalPaths = <String>{'/api/v1/users/profile'};

    for (final critical in criticalPaths) {
      if (path == critical || path.startsWith('$critical/')) {
        return true;
      }
    }
    return false;
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
