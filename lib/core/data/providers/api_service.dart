import 'dart:convert';
import 'dart:math';

import 'package:firebase_performance/firebase_performance.dart' as fp;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart' as getx;
import 'package:get_storage/get_storage.dart';
import 'package:ghar360/core/controllers/auth_controller.dart';
import 'package:ghar360/core/data/models/agent_model.dart';
import 'package:ghar360/core/data/models/amenity_model.dart';
import 'package:ghar360/core/data/models/api_response_models.dart';
import 'package:ghar360/core/data/models/app_update_models.dart';
import 'package:ghar360/core/data/models/bug_report_model.dart';
import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/data/models/static_page_model.dart';
import 'package:ghar360/core/data/models/unified_filter_model.dart';
import 'package:ghar360/core/data/models/unified_property_response.dart';
import 'package:ghar360/core/data/models/user_model.dart';
import 'package:ghar360/core/data/models/visit_model.dart';
import 'package:ghar360/core/firebase/remote_config_service.dart';
import 'package:ghar360/core/routes/app_routes.dart';
import 'package:ghar360/core/utils/app_exceptions.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/core/utils/error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const int _logKeyLimit = 8;
const Set<String> _sensitiveKeys = {
  'password',
  'token',
  'access_token',
  'refresh_token',
  'secret',
  'api_key',
  'apikey',
  'authorization',
  'auth',
  'credential',
  'otp',
  'pin',
};

String _summarizeForLog(Object? value) {
  if (value == null) return 'null';
  if (value is Map) {
    // Filter out sensitive keys from logs
    final keys =
        value.keys
            .map((k) => k.toString())
            .where((k) => !_sensitiveKeys.contains(k.toLowerCase()))
            .toList()
          ..sort();
    final hiddenCount = value.keys.length - keys.length;
    final hiddenNote = hiddenCount > 0 ? ' +$hiddenCount hidden' : '';
    final shown = keys.take(_logKeyLimit).join(', ');
    final extra = keys.length > _logKeyLimit ? ' +${keys.length - _logKeyLimit} more' : '';
    return 'map(keys=[$shown$extra]$hiddenNote)';
  }
  if (value is Iterable) {
    return 'list(length=${value.length})';
  }
  if (value is String) {
    return 'string(length=${value.length})';
  }
  return 'type=${value.runtimeType}';
}

class ApiAuthException implements Exception {
  final String message;
  final int? statusCode;

  ApiAuthException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiAuthException: $message';
}

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? errorCode;
  final Map<String, dynamic>? details;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errorCode,
    this.details,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T? data) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: data,
      errorCode: json['error_code'],
      details: json['details'],
    );
  }
}

class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginatedResponse.fromJson(Map<String, dynamic> json, List<T> items) {
    return PaginatedResponse<T>(
      items: items,
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      totalPages: json['total_pages'] ?? 1,
      hasNext: json['has_next'] ?? false,
      hasPrev: json['has_prev'] ?? false,
    );
  }
}

// Response wrapper for visits API
class VisitListResponse {
  final List<VisitModel> visits;
  final int total;
  final int upcoming;
  final int completed;
  final int cancelled;

  VisitListResponse({
    required this.visits,
    required this.total,
    required this.upcoming,
    required this.completed,
    required this.cancelled,
  });

  factory VisitListResponse.fromJson(Map<String, dynamic> json) {
    try {
      final safeJson = Map<String, dynamic>.from(json);

      // Parse visits array
      List<VisitModel> visits = [];
      if (safeJson['visits'] is List) {
        final visitsData = safeJson['visits'] as List;
        visits = visitsData.map((item) => VisitModel.fromJson(item)).toList();
      }

      return VisitListResponse(
        visits: visits,
        total: safeJson['total'] ?? visits.length,
        upcoming: safeJson['upcoming'] ?? visits.where((v) => v.isUpcoming).length,
        completed: safeJson['completed'] ?? visits.where((v) => v.isCompleted).length,
        cancelled: safeJson['cancelled'] ?? visits.where((v) => v.isCancelled).length,
      );
    } catch (e, stackTrace) {
      DebugLogger.error('Error in VisitListResponse.fromJson', e, stackTrace);
      DebugLogger.api('Raw JSON summary: ${_summarizeForLog(json)}');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
    'visits': visits.map((v) => v.toJson()).toList(),
    'total': total,
    'upcoming': upcoming,
    'completed': completed,
    'cancelled': cancelled,
  };
}

class ApiService extends getx.GetConnect {
  static ApiService get instance => getx.Get.find<ApiService>();

  late final String _baseUrl;
  late final SupabaseClient _supabase;
  final GetStorage _cacheStorage = GetStorage();
  static const String _cacheKeyPrefix = 'HTTP_CACHE|';
  static const Duration _cacheTtl = Duration(minutes: 15);
  static const int _maxCacheEntries = 200;
  // Track in-flight profile fetch to avoid duplicate concurrent calls
  Future<UserModel>? _getCurrentUserInFlight;
  // Removed token cache - trust Supabase session management

  @override
  void onInit() {
    super.onInit();
    // Initialize synchronously to avoid race conditions on early requests
    _initializeService();
    httpClient.baseUrl = _baseUrl;
    // Configure a sensible default timeout, overridable via env
    final timeoutSeconds = int.tryParse(dotenv.env['API_TIMEOUT_SECONDS'] ?? '') ?? 15;
    httpClient.timeout = Duration(seconds: timeoutSeconds);
    DebugLogger.startup('HTTP client timeout set to ${httpClient.timeout.inSeconds}s');

    // Request modifier to add authentication token
    httpClient.addRequestModifier<Object?>((request) async {
      final token = await _ensureValidSessionToken();
      if (token != null && token.trim().isNotEmpty) {
        request.headers['Authorization'] = 'Bearer ${token.trim()}';
        DebugLogger.auth('➡️ Attaching Authorization header to ${request.url}');
      } else {
        request.headers.remove('Authorization');
        DebugLogger.auth('➡️ No Authorization header for ${request.url}');
      }
      request.headers['Content-Type'] = 'application/json';
      return request;
    });

    // Response interceptor: be tolerant on the first 401 to avoid premature sign-out
    httpClient.addResponseModifier((request, response) async {
      if (response.statusCode == 401) {
        // Let the caller handle the first 401 gracefully; only force sign-out on repeated failures
        _recordAuthFailure();
        if (_authFailureCount >= 2) {
          DebugLogger.warning('🔐 Repeated 401 responses detected. Signing out.');
          _handleAuthenticationFailure();
        } else {
          DebugLogger.warning(
            '🔐 401 received. Propagating without forced sign-out (grace attempt).',
          );
        }
        throw ApiAuthException('Authentication failed', statusCode: 401);
      }
      return response;
    });
  }

  void _initializeService() {
    try {
      // Initialize environment variables - use root URL for GetConnect
      final fullApiUrl = dotenv.env['API_BASE_URL'] ?? 'https://api.360ghar.com';
      // Extract base URL without /api/v1 for GetConnect
      _baseUrl = fullApiUrl.replaceAll('/api/v1', '');
      DebugLogger.startup('API Service initialized with base URL: $_baseUrl');

      // Get existing Supabase client (initialized in main.dart)
      _supabase = Supabase.instance.client;
      DebugLogger.success('Supabase client acquired');
    } catch (e, stackTrace) {
      DebugLogger.error('Error initializing API service', e, stackTrace);
      // Create a mock client or handle the error appropriately
    }

    // Listen to auth state changes with proper cleanup
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      switch (event) {
        case AuthChangeEvent.signedIn:
          DebugLogger.auth('User signed in');
          if (session != null) {
            DebugLogger.logJWTToken(session.accessToken);
          }
          break;
        case AuthChangeEvent.signedOut:
          DebugLogger.auth('User signed out');
          break;
        case AuthChangeEvent.tokenRefreshed:
          DebugLogger.auth('Token refreshed');
          if (session != null) {
            DebugLogger.logJWTToken(session.accessToken);
          }
          break;
        default:
          break;
      }
    });
  }

  // Track recent auth failures to avoid immediate sign-out on the first occurrence
  int _authFailureCount = 0;
  DateTime? _lastAuthFailureAt;
  void _recordAuthFailure() {
    final now = DateTime.now();
    if (_lastAuthFailureAt == null || now.difference(_lastAuthFailureAt!).inSeconds > 15) {
      // Reset window after 15s of no failures
      _authFailureCount = 0;
    }
    _lastAuthFailureAt = now;
    _authFailureCount++;
  }

  /// Retrieves the current valid JWT access token from the Supabase session.
  /// Supabase client handles secure storage and automatic token refreshing.
  Future<String?> get _authToken async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      DebugLogger.auth('No active Supabase session found.');
      return null;
    }
    // The accessToken is automatically refreshed by the Supabase client library.
    DebugLogger.auth('Retrieved access token from Supabase session.');
    return session.accessToken;
  }

  /// Ensures a valid session token is available before making a request.
  /// Attempts a refresh when missing and waits briefly.
  Future<String?> _ensureValidSessionToken() async {
    String? token = await _authToken;
    if (token != null && token.isNotEmpty) return token;

    try {
      await _supabase.auth.refreshSession();
    } catch (_) {}

    // brief wait for session to be set by SDK
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      final s = _supabase.auth.currentSession;
      if (s?.accessToken.isNotEmpty == true) {
        return s!.accessToken;
      }
    }
    return null;
  }

  /// Handles authentication failure by signing the user out and redirecting to login.
  void _handleAuthenticationFailure() {
    DebugLogger.auth('Authentication failed. Signing out and redirecting to login.');

    // Use AuthController to sign out, which will trigger a global state change.
    // This is safer than directly navigating.
    if (getx.Get.isRegistered<AuthController>()) {
      getx.Get.find<AuthController>().signOut();
    } else {
      // Fallback if AuthController isn't available for some reason
      _supabase.auth.signOut();
      getx.Get.offAllNamed(AppRoutes.phoneEntry);
    }
  }

  Future<T> _makeRequest<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    int retries = 2,
    String? operationName,
    Map<String, String>? headers,
    bool allowNotModified = false,
    void Function(Map<String, String?> headers)? onHeaders,
  }) async {
    AppException? lastAppException;
    final operation = operationName ?? '$method $endpoint';
    final int maxAttempts = retries + 1; // attempts = initial + retries

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      fp.HttpMetric? httpMetric;
      try {
        // Prepend /api/v1 to all endpoints
        final fullEndpoint = '/api/v1$endpoint';
        final absoluteUrl = '$_baseUrl$fullEndpoint';

        // Optional Firebase Performance HTTP auto-instrumentation
        try {
          if (RemoteConfigService.performanceEnabled && _shouldSampleHttpMetric()) {
            final httpMethod = _toHttpMethod(method);
            httpMetric = fp.FirebasePerformance.instance.newHttpMetric(absoluteUrl, httpMethod);
            await httpMetric.start();
          }
        } catch (_) {}

        // Prepare headers (and inject If-None-Match for GET when cached)
        final effectiveHeaders = <String, String>{...?(headers)};

        // Build a canonical cache key for GET requests
        String? cacheKey;
        String? cachedEtag;
        if (method.toUpperCase() == 'GET') {
          cacheKey = _buildCacheKey(
            method,
            // Include base to avoid collisions across envs
            '$_baseUrl$fullEndpoint',
            queryParams,
            userScope: _supabase.auth.currentUser?.id,
          );
          // Attempt to read an existing cache entry
          final cachedEntry = _readCacheEntry(cacheKey);
          cachedEtag = cachedEntry?['etag'] as String?;
          if (cachedEtag != null &&
              !effectiveHeaders.keys.any((k) => k.toLowerCase() == 'if-none-match')) {
            effectiveHeaders['If-None-Match'] = cachedEtag;
            DebugLogger.api('🧠 Added If-None-Match for $fullEndpoint (etag=$cachedEtag)');
          }
        }

        // Single-line API request log for debugging
        final querySummary = queryParams != null && queryParams.isNotEmpty
            ? _summarizeForLog(queryParams)
            : '';
        final bodySummary = body != null && body.isNotEmpty ? _summarizeForLog(body) : '';
        DebugLogger.api(
          '🚀 API $method $fullEndpoint${querySummary.isNotEmpty ? ' | Query: $querySummary' : ''}${bodySummary.isNotEmpty ? ' | Body: $bodySummary' : ''}',
        );

        final requestBodyForLog = bodySummary.isNotEmpty ? bodySummary : null;
        DebugLogger.logAPIRequest(method: method, endpoint: fullEndpoint, body: requestBodyForLog);

        getx.Response response;

        switch (method.toUpperCase()) {
          case 'GET':
            response = await get(fullEndpoint, query: queryParams, headers: effectiveHeaders);
            break;
          case 'POST':
            response = await post(
              fullEndpoint,
              body,
              query: queryParams,
              headers: effectiveHeaders,
            );
            break;
          case 'PUT':
            response = await put(fullEndpoint, body, query: queryParams, headers: effectiveHeaders);
            break;
          case 'DELETE':
            response = await delete(fullEndpoint, query: queryParams, headers: effectiveHeaders);
            break;
          default:
            throw Exception('Unsupported HTTP method: $method');
        }

        // Single-line API response log for debugging
        DebugLogger.api('📨 API $method $fullEndpoint → ${response.statusCode}');

        // Stop metric after response
        try {
          if (httpMetric != null) {
            httpMetric.httpResponseCode = response.statusCode ?? 0;
            final bodyLen = response.bodyString?.length;
            if (bodyLen != null) {
              httpMetric.responsePayloadSize = bodyLen;
            }
            await httpMetric.stop();
          }
        } catch (_) {}

        // Log response
        DebugLogger.logAPIResponse(
          statusCode: response.statusCode ?? 0,
          endpoint: fullEndpoint,
          body: response.bodyString ?? '',
        );

        // Handle 304 Not Modified: return cached data when available
        if (response.statusCode == 304) {
          // Preserve legacy behavior for explicit allowNotModified callers
          if (allowNotModified) {
            throw NotModifiedException('Not Modified', code: 'NOT_MODIFIED');
          }

          if (method.toUpperCase() == 'GET' && cacheKey != null) {
            final cachedEntry = _readCacheEntry(cacheKey);
            final cachedBody = cachedEntry?['body'] as String?;
            if (cachedBody != null) {
              DebugLogger.api('🔁 304 for $fullEndpoint → serving cached response');
              // Provide headers (e.g., ETag) to caller if requested
              if (onHeaders != null) {
                try {
                  onHeaders(response.headers ?? const {});
                } catch (_) {}
              }

              final cachedData = jsonDecode(cachedBody);
              try {
                if (cachedData is Map<String, dynamic>) {
                  final result = fromJson(cachedData);
                  return result;
                } else if (cachedData is List) {
                  final normalizedData = {'data': cachedData};
                  final result = fromJson(normalizedData);
                  return result;
                } else {
                  final normalizedData = {'data': cachedData};
                  final result = fromJson(normalizedData);
                  return result;
                }
              } catch (e) {
                DebugLogger.error('🚨 Error parsing cached data for $operation: $e');
                rethrow;
              }
            }
          }
          // No cache available; escalate as cache error
          DebugLogger.warning('⚠️ 304 received but no cache found for $operation');
          throw CacheException('No cached data available for 304 Not Modified');
        }

        if (response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300) {
          // Provide headers (e.g., ETag) to caller if requested
          if (onHeaders != null) {
            try {
              onHeaders(response.headers ?? const {});
            } catch (_) {}
          }
          final responseData = response.body;
          DebugLogger.api('📊 [_makeRequest] Response type: ${responseData?.runtimeType}');

          try {
            if (responseData is Map<String, dynamic>) {
              final result = fromJson(responseData);
              // Cache successful GET responses with ETag
              if (method.toUpperCase() == 'GET' && cacheKey != null) {
                _maybeCacheResponse(cacheKey, response);
              }
              return result;
            } else if (responseData is List) {
              final normalizedData = {'data': responseData};
              final result = fromJson(normalizedData);
              if (method.toUpperCase() == 'GET' && cacheKey != null) {
                _maybeCacheResponse(cacheKey, response);
              }
              return result;
            } else {
              final normalizedData = {'data': responseData};
              final result = fromJson(normalizedData);
              if (method.toUpperCase() == 'GET' && cacheKey != null) {
                _maybeCacheResponse(cacheKey, response);
              }
              DebugLogger.api('📊 [_makeRequest] fromJson completed successfully for $operation');
              return result;
            }
          } catch (e) {
            DebugLogger.error('🚨 [_makeRequest] ERROR in fromJson callback for $operation: $e');
            DebugLogger.error(
              '🚨 [_makeRequest] Response summary: ${_summarizeForLog(responseData)}',
            );
            rethrow;
          }
        } else if (response.statusCode == 401) {
          // Token expired - the response interceptor will handle this
          DebugLogger.auth('🔒 Authentication failed for $operation');
          throw ApiAuthException('Authentication failed for $operation', statusCode: 401);
        } else if (response.statusCode == 403) {
          DebugLogger.auth('🚫 Access forbidden for $operation');
          throw ApiAuthException('Access forbidden for $operation', statusCode: 403);
        } else if (((response.statusCode) ?? 0) >= 500 && attempt < retries) {
          // Server error - retry with exponential backoff + jitter
          final delayMs = _computeBackoffDelayMs(attempt);
          DebugLogger.warning(
            '🔄 Server error (${response.statusCode}) for $operation, retrying in ${delayMs}ms... (${attempt + 1}/$retries)',
          );
          await Future.delayed(Duration(milliseconds: delayMs));
          continue;
        } else {
          // Enhanced error logging for 422 errors
          if (response.statusCode == 422) {
            DebugLogger.error('🚫 422 Unprocessable Entity for $operation');
            DebugLogger.error('🚫 Endpoint: $fullEndpoint');
            DebugLogger.error('🚫 Method: $method');
            DebugLogger.error(
              '🚫 Query Params: ${queryParams != null ? _summarizeForLog(queryParams) : 'none'}',
            );
            DebugLogger.error('🚫 Request Body: ${body != null ? _summarizeForLog(body) : 'none'}');
            DebugLogger.error('🚫 Response Body: ${_summarizeForLog(response.bodyString)}');
            DebugLogger.error(
              '🚫 Response Headers: ${response.headers != null ? _summarizeForLog(response.headers) : 'none'}',
            );
          }

          // Enhanced error logging for 409 Conflict errors
          if (response.statusCode == 409) {
            DebugLogger.error('⚡ 409 Conflict detected for $operation');
            DebugLogger.error('⚡ This indicates a concurrent update conflict');
            DebugLogger.error('⚡ Endpoint: $fullEndpoint');
            DebugLogger.error('⚡ Response Body: ${_summarizeForLog(response.bodyString)}');
          }

          // Create an ApiException to be mapped to AppException below
          final errorMessage =
              'HTTP ${response.statusCode}: ${response.statusText ?? 'Unknown error'}';
          DebugLogger.error('❌ API Error for $operation: $errorMessage');
          final apiEx = ApiException(
            response.statusText ?? 'API Error',
            statusCode: response.statusCode,
            response: response.bodyString,
          );

          // Map to AppException for consistent handling
          final appEx = ErrorMapper.mapApiError(apiEx);
          if (attempt < retries && ErrorMapper.isRetryable(appEx)) {
            final delayMs = _computeBackoffDelayMs(attempt);
            DebugLogger.warning(
              '🔄 Retryable API error for $operation, retrying in ${delayMs}ms... (${attempt + 1}/$retries)',
            );
            await Future.delayed(Duration(milliseconds: delayMs));
            continue;
          }
          throw appEx;
        }
      } catch (e, st) {
        // Ensure any in-flight metric is stopped on error
        try {
          if (httpMetric != null) {
            await httpMetric.stop();
          }
        } catch (_) {}
        // Convert to AppException immediately
        final appEx = ErrorMapper.mapApiError(e, st);

        // Auth errors should bubble immediately
        if (appEx is AuthenticationException) {
          DebugLogger.auth('🔒 Authentication error for $operation: ${appEx.message}');
          throw appEx;
        }

        // If retryable and we have attempts remaining, retry with backoff
        if (attempt < retries && ErrorMapper.isRetryable(appEx)) {
          final delayMs = _computeBackoffDelayMs(attempt);
          DebugLogger.warning(
            '🔄 Request failed for $operation (${appEx.code ?? appEx.runtimeType}), retrying in ${delayMs}ms... (${attempt + 1}/$retries)',
          );
          await Future.delayed(Duration(milliseconds: delayMs));
          continue;
        }

        // No retries left or non-retryable → record and rethrow
        lastAppException = appEx;

        DebugLogger.reportError(
          context: 'API Request Failed',
          error: appEx,
          stackTrace: st,
          metadata: {
            'operation': operation,
            'attempts': attempt + 1,
            'endpoint': endpoint,
            'method': method,
            'hasBody': body != null,
            'hasQuery': queryParams?.isNotEmpty ?? false,
          },
        );

        throw appEx;
      }
    }
    throw lastAppException ?? NetworkException('Unknown error occurred for $operation');
  }

  // Exponential backoff with jitter (ms)
  int _computeBackoffDelayMs(int attempt) {
    // attempt: 0,1,2 → 300, 600, 1200 (+ jitter)
    final base = 300 * (1 << attempt);
    final jitter = (DateTime.now().microsecondsSinceEpoch % 200);
    final delay = base + jitter;
    // Cap delay to reasonable upper bound
    return delay > 4000 ? 4000 : delay;
  }

  // ===== Firebase Performance helpers =====
  fp.HttpMethod _toHttpMethod(String method) {
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
      case 'HEAD':
        return fp.HttpMethod.Head;
      default:
        return fp.HttpMethod.Get;
    }
  }

  bool _shouldSampleHttpMetric() {
    try {
      final ratio = RemoteConfigService.perfHttpSampling;
      if (ratio <= 0) return false;
      if (ratio >= 1) return true;
      final r = Random().nextDouble();
      return r < ratio;
    } catch (_) {
      return false;
    }
  }

  // ===== HTTP ETag cache helpers =====
  String _buildCacheKey(
    String method,
    String url,
    Map<String, String>? queryParams, {
    String? userScope,
  }) {
    final qp = Map<String, String>.from(queryParams ?? const {});
    final keys = qp.keys.toList()..sort();
    final qpString = keys.map((k) => '$k=${qp[k]}').join('&');
    final scope = (userScope != null && userScope.isNotEmpty) ? '|uid=$userScope' : '|uid=anon';
    return '$_cacheKeyPrefix${method.toUpperCase()}|$url|$qpString$scope';
  }

  Map<String, dynamic>? _readCacheEntry(String key) {
    try {
      final v = _cacheStorage.read(key);
      if (v is Map) {
        final entry = Map<String, dynamic>.from(v);
        if (_isCacheEntryExpired(entry)) {
          _cacheStorage.remove(key);
          return null;
        }
        return entry;
      }
    } catch (e) {
      DebugLogger.warning('Failed to read cache entry', e);
    }
    return null;
  }

  bool _isCacheEntryExpired(Map<String, dynamic> entry, {int? nowMs}) {
    final ts = entry['timestamp'];
    if (ts is! int) return true;
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    return now - ts > _cacheTtl.inMilliseconds;
  }

  void _maybeCacheResponse(String cacheKey, getx.Response response) {
    try {
      final etag = _getHeaderValue(response.headers, 'etag');
      if (etag == null || etag.isEmpty) {
        DebugLogger.api('🗂️ No ETag present; skipping cache for $cacheKey');
        return;
      }
      final bodyStr = response.bodyString ?? jsonEncode(response.body);
      if (bodyStr.isEmpty || bodyStr.trim() == 'null') {
        DebugLogger.api('🗂️ Empty body; skipping cache for $cacheKey');
        return;
      }
      _cacheStorage.write(cacheKey, {
        'etag': etag,
        'body': bodyStr,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      DebugLogger.api('✅ Cached response (etag=$etag) for $cacheKey');
      _evictCacheEntriesIfNeeded();
    } catch (e) {
      DebugLogger.warning('Failed to cache response for $cacheKey', e);
    }
  }

  void _evictCacheEntriesIfNeeded() {
    try {
      final keys = _cacheStorage.getKeys().where((k) => k.startsWith(_cacheKeyPrefix)).toList();

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final entries = <_CacheEntry>[];
      final expiredKeys = <String>[];

      // Collect valid entries and identify expired ones
      for (final key in keys) {
        final entry = _readCacheEntry(key);
        if (entry == null) {
          // Entry was already removed by _readCacheEntry or is invalid
          continue;
        }
        final ts = entry['timestamp'];
        if (ts is int && !_isCacheEntryExpired(entry, nowMs: nowMs)) {
          entries.add(_CacheEntry(key, ts));
        } else {
          // Entry is expired, mark for removal
          expiredKeys.add(key);
        }
      }

      // Remove expired entries
      for (final key in expiredKeys) {
        _cacheStorage.remove(key);
      }

      // Evict oldest entries if still over limit
      if (entries.length <= _maxCacheEntries) return;
      entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final removeCount = entries.length - _maxCacheEntries;
      for (int i = 0; i < removeCount; i++) {
        _cacheStorage.remove(entries[i].key);
      }
    } catch (e) {
      DebugLogger.warning('Failed to evict cache entries', e);
    }
  }

  String? _getHeaderValue(Map<String, String?>? headers, String name) {
    if (headers == null) return null;
    final target = name.toLowerCase();
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == target) return entry.value;
    }
    return null;
  }

  // Fetch static page content from core pages endpoint (no auth required)
  Future<StaticPageModel> fetchStaticPage(String uniqueName) async {
    return _makeRequest<StaticPageModel>(
      '/pages/$uniqueName/public',
      (json) => StaticPageModel.fromDynamic(json, fallbackTitle: uniqueName),
      method: 'GET',
      operationName: 'GET /pages/$uniqueName/public',
    );
  }

  Future<BugReportResponse> submitBugReport(BugReportRequest request) async {
    return _makeRequest<BugReportResponse>(
      '/bugs/',
      (json) => BugReportResponse.fromJson(json),
      method: 'POST',
      body: request.toJson(),
      operationName: 'POST /bugs/',
    );
  }

  Future<AppVersionCheckResponse> checkAppVersion({required AppVersionCheckRequest request}) async {
    return _makeRequest<AppVersionCheckResponse>(
      '/versions/check',
      (json) => AppVersionCheckResponse.fromJson(json),
      method: 'POST',
      body: request.toJson(),
      operationName: 'POST /versions/check',
    );
  }

  // Helper method for safer user model parsing
  static UserModel _parseUserModel(Map<String, dynamic> json) {
    try {
      final safeJson = Map<String, dynamic>.from(json);

      // Ensure required fields have defaults
      safeJson['email'] ??= '';
      safeJson['phone'] ??= '';

      // Handle preferences
      if (safeJson['preferences'] is! Map) {
        safeJson['preferences'] = <String, dynamic>{};
      }

      return UserModel.fromJson(safeJson);
    } catch (e) {
      DebugLogger.error('❌ Error parsing user model: $e');
      DebugLogger.api('📊 Raw JSON summary: ${_summarizeForLog(json)}');
      rethrow;
    }
  }

  // Helper method for safer property model parsing
  static PropertyModel _parsePropertyModel(Map<String, dynamic> json) {
    try {
      // Normalize fields that may vary in type from different backends
      final Map<String, dynamic> safeJson = Map<String, dynamic>.from(json);

      // Convert List calendar_data to Map if needed
      if (safeJson['calendar_data'] is List) {
        safeJson['calendar_data'] = <String, dynamic>{};
      }

      // Ensure numeric fields are parsed as double when provided as int/strings
      double? toDouble(dynamic v) {
        if (v == null) return null;
        if (v is num) return v.toDouble();
        if (v is String) return double.tryParse(v);
        return null;
      }

      // Convert numeric price fields
      final priceFields = [
        'base_price',
        'price_per_sqft',
        'monthly_rent',
        'daily_rate',
        'security_deposit',
        'maintenance_charges',
      ];
      for (final field in priceFields) {
        if (safeJson.containsKey(field)) {
          safeJson[field] = toDouble(safeJson[field]) ?? (field == 'base_price' ? 0.0 : null);
        }
      }

      List<String>? toStringList(dynamic value) {
        if (value == null) return null;
        if (value is List) {
          final cleaned = value
              .map((e) => e?.toString().trim())
              .whereType<String>()
              .where((e) => e.isNotEmpty)
              .toList();
          return cleaned.isEmpty ? null : cleaned;
        }
        if (value is String) {
          final parts = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          return parts.isEmpty ? null : parts;
        }
        return null;
      }

      safeJson['video_urls'] = toStringList(safeJson['video_urls']);
      // Normalize single video/floor-plan fields
      final videoTour = safeJson['video_tour_url'];
      if (videoTour is String && videoTour.trim().isNotEmpty) {
        safeJson['video_tour_url'] = videoTour.trim();
      } else {
        safeJson['video_tour_url'] = null;
      }

      final floorPlan = safeJson['floor_plan_url'];
      if (floorPlan is String && floorPlan.trim().isNotEmpty) {
        safeJson['floor_plan_url'] = floorPlan.trim();
      }
      final streetView = safeJson['google_street_view_url'];
      if (streetView is String) {
        final trimmed = streetView.trim();
        safeJson['google_street_view_url'] = trimmed.isEmpty ? null : trimmed;
      }

      // Normalize images into structured objects with media metadata
      if (safeJson['images'] is List) {
        final rawImages = safeJson['images'] as List;
        final normalizedImages = <Map<String, dynamic>>[];
        int tempId = -1;

        for (final img in rawImages) {
          if (img is Map<String, dynamic>) {
            final normalized = Map<String, dynamic>.from(img);
            normalized['id'] ??= tempId--;
            normalized['property_id'] ??= safeJson['id'] ?? tempId;
            normalized['is_main'] ??= normalized['is_main_image'] ?? false;
            normalized['category'] ??= 'gallery';
            normalizedImages.add(normalized);
          } else if (img is String && img.trim().isNotEmpty) {
            normalizedImages.add({
              'id': tempId--,
              'property_id': safeJson['id'] ?? tempId,
              'image_url': img.trim(),
              'display_order': 0,
              'is_main_image': false,
              'is_main': false,
              'category': 'gallery',
            });
          }
        }

        if (normalizedImages.isNotEmpty) {
          final flaggedMain = normalizedImages.firstWhere(
            (e) => e['is_main'] == true || e['is_main_image'] == true,
            orElse: () => normalizedImages.first,
          );
          if ((safeJson['main_image_url'] == null || '${safeJson['main_image_url']}'.isEmpty) &&
              flaggedMain['image_url'] != null) {
            safeJson['main_image_url'] = flaggedMain['image_url'];
          }
          safeJson['images'] = normalizedImages;
        }
      }

      return PropertyModel.fromJson(safeJson);
    } catch (e) {
      DebugLogger.error('❌ Error parsing property model: $e');
      DebugLogger.api('📊 Raw JSON summary: ${_summarizeForLog(json)}');
      rethrow;
    }
  }

  // Helper method for parsing unified property response
  static UnifiedPropertyResponse _parseUnifiedPropertyResponse(Map<String, dynamic> json) {
    try {
      final Map<String, dynamic> safeJson = Map<String, dynamic>.from(json);

      // Accept multiple shapes: { properties: [...] }, { data: [...] }, or nested common keys
      dynamic rawList =
          safeJson['properties'] ?? safeJson['data'] ?? safeJson['results'] ?? safeJson['items'];
      final List<dynamic> list = rawList is List ? rawList : <dynamic>[];

      DebugLogger.api('📦 [UNIFIED_PARSER] Found ${list.length} properties to parse');

      final List<PropertyModel> parsed = <PropertyModel>[];
      int failedCount = 0;
      for (int i = 0; i < list.length; i++) {
        final item = list[i];

        if (item is Map<String, dynamic>) {
          try {
            final property = _parsePropertyModel(item);
            parsed.add(property);
          } catch (e, stackTrace) {
            DebugLogger.error('❌ [UNIFIED_PARSER] Failed to parse property $i: $e');
            DebugLogger.debug('❌ [UNIFIED_PARSER] Stack trace: $stackTrace');

            if (e.toString().contains('Null check operator used on a null value')) {
              DebugLogger.error(
                '🚨 [UNIFIED_PARSER] NULL CHECK OPERATOR ERROR at property index $i!',
              );
              DebugLogger.error(
                '🚨 [UNIFIED_PARSER] This should provide more details from _parsePropertyModel',
              );
            }

            failedCount++;
          }
        } else {
          DebugLogger.warning(
            '⚠️ [UNIFIED_PARSER] Invalid property at index $i: $item (${item?.runtimeType})',
          );
          failedCount++;
        }
      }

      if (failedCount > 0) {
        DebugLogger.warning(
          '⚠️ [UNIFIED_PARSER] Skipped $failedCount invalid properties out of ${list.length}',
        );
      }

      // Metadata with safe fallbacks
      final int total = (safeJson['total'] is num)
          ? (safeJson['total'] as num).toInt()
          : parsed.length;
      final int limit = (safeJson['limit'] is num)
          ? (safeJson['limit'] as num).toInt()
          : (parsed.isNotEmpty ? parsed.length : 20);
      final int page = (safeJson['page'] is num) ? (safeJson['page'] as num).toInt() : 1;
      final int totalPages = (safeJson['total_pages'] is num)
          ? (safeJson['total_pages'] as num).toInt()
          : ((limit > 0) ? ((total + limit - 1) / limit).ceil() : 1);

      Map<String, dynamic> filtersApplied = {};
      if (safeJson['filters_applied'] is Map<String, dynamic>) {
        filtersApplied = Map<String, dynamic>.from(safeJson['filters_applied'] as Map);
      }

      SearchCenter? searchCenter;
      if (safeJson['search_center'] is Map<String, dynamic>) {
        final sc = safeJson['search_center'] as Map<String, dynamic>;
        final lat = sc['latitude'] ?? sc['lat'];
        final lng = sc['longitude'] ?? sc['lng'];
        if (lat is num && lng is num) {
          searchCenter = SearchCenter(latitude: lat.toDouble(), longitude: lng.toDouble());
        } else if (lat is String && lng is String) {
          final dLat = double.tryParse(lat);
          final dLng = double.tryParse(lng);
          if (dLat != null && dLng != null) {
            searchCenter = SearchCenter(latitude: dLat, longitude: dLng);
          }
        }
      }

      return UnifiedPropertyResponse(
        properties: parsed,
        total: total,
        page: page,
        limit: limit,
        totalPages: totalPages,
        filtersApplied: filtersApplied,
        searchCenter: searchCenter,
      );
    } catch (e) {
      DebugLogger.error('❌ Error parsing unified property response: $e');
      DebugLogger.api('📊 Raw JSON summary: ${_summarizeForLog(json)}');
      rethrow;
    }
  }

  // Authentication Methods

  // Phone + password sign-in (Supabase supports phone in signInWithPassword)
  Future<AuthResponse> signInWithPhonePassword(String phone, String password) async {
    final response = await _supabase.auth.signInWithPassword(phone: phone, password: password);
    return response;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Send OTP to a phone number
  // shouldCreateUser=false is safer for verification/resend/login flows
  Future<void> sendPhoneOtp(String phone, {bool shouldCreateUser = false}) async {
    await _supabase.auth.signInWithOtp(phone: phone, shouldCreateUser: shouldCreateUser);
  }

  // Verify an SMS OTP for a phone number
  Future<AuthResponse> verifyPhoneOtp({required String phone, required String token}) async {
    final response = await _supabase.auth.verifyOTP(phone: phone, token: token, type: OtpType.sms);
    return response;
  }

  // Sign up using phone and password, triggers SMS OTP verification
  Future<AuthResponse> signUpWithPhonePassword(
    String phone,
    String password, {
    Map<String, dynamic>? data,
  }) async {
    final response = await _supabase.auth.signUp(phone: phone, password: password, data: data);
    return response;
  }

  Future<UserModel> getCurrentUser() async {
    // Ensure we have a token (post sign-in race guard)
    await _waitForAuthToken(maxWaitMs: 1500);
    // De-dupe concurrent calls to avoid unnecessary load and race conditions
    if (_getCurrentUserInFlight != null) {
      return await _getCurrentUserInFlight!;
    }

    _getCurrentUserInFlight = _makeRequest(
      '/users/profile/',
      (json) {
        // Handle both direct user object and wrapped response
        final userData = json['data'] ?? json;
        return _parseUserModel(userData);
      },
      operationName: 'Get Current User',
      retries: 2,
    ); // small extra retry for robustness

    try {
      return await _getCurrentUserInFlight!;
    } finally {
      _getCurrentUserInFlight = null;
    }
  }

  /// Wait briefly for an auth token to become available (guards sign-in races)
  Future<String?> _waitForAuthToken({int maxWaitMs = 1500}) async {
    final deadline = DateTime.now().add(Duration(milliseconds: maxWaitMs));
    String? token = await _authToken;
    while ((token == null || token.isEmpty) && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 50));
      token = await _authToken;
    }
    return token;
  }

  // User Management
  Future<UserModel> updateUserProfile(Map<String, dynamic> profileData) async {
    // Ensure token is attached when updating profile right after sign-in
    await _waitForAuthToken(maxWaitMs: 1500);
    // Create a copy to avoid modifying the original
    final filteredData = Map<String, dynamic>.from(profileData);

    // Separate preference fields from profile fields
    final preferenceFields = <String, dynamic>{};
    final preferenceKeys = [
      'property_purpose',
      'budget_min',
      'budget_max',
      'preferred_locations',
      'property_types',
    ];

    for (final key in preferenceKeys) {
      if (filteredData.containsKey(key)) {
        preferenceFields[key] = filteredData.remove(key);
      }
    }

    // Handle date_of_birth format conversion
    if (filteredData['date_of_birth'] != null) {
      final dobString = filteredData['date_of_birth'].toString();
      try {
        // Convert various date formats to ISO format
        DateTime? parsedDate;

        // Try parsing common formats like "4/9/2007", "04/09/2007", "2007-04-09"
        if (dobString.contains('/')) {
          final parts = dobString.split('/');
          if (parts.length == 3) {
            int month, day, year;
            if (parts[2].length == 4) {
              // Format: M/d/yyyy or MM/dd/yyyy
              month = int.parse(parts[0]);
              day = int.parse(parts[1]);
              year = int.parse(parts[2]);
            } else {
              // Format: yyyy/M/d or yyyy/MM/dd (less common)
              year = int.parse(parts[0]);
              month = int.parse(parts[1]);
              day = int.parse(parts[2]);
            }
            parsedDate = DateTime(year, month, day);
          }
        } else if (dobString.contains('-')) {
          // Try ISO format parsing
          parsedDate = DateTime.parse(dobString);
        }

        if (parsedDate != null) {
          // Format as ISO date string (YYYY-MM-DD)
          filteredData['date_of_birth'] =
              "${parsedDate.year.toString().padLeft(4, '0')}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}";
          DebugLogger.info(
            '📅 Converted date_of_birth from "$dobString" to "${filteredData['date_of_birth']}"',
          );
        }
      } catch (e) {
        DebugLogger.warning('⚠️ Failed to parse date_of_birth "$dobString": $e');
        // Remove invalid date to prevent API error
        filteredData.remove('date_of_birth');
      }
    }

    // Log what we're sending (without sensitive data)
    DebugLogger.info('📝 Profile update fields: ${filteredData.keys.toList()}');
    if (preferenceFields.isNotEmpty) {
      DebugLogger.info(
        '⚙️ Preference fields (will be sent separately): ${preferenceFields.keys.toList()}',
      );
    }

    // Update preferences first if there are any
    if (preferenceFields.isNotEmpty) {
      try {
        await updateUserPreferences(preferenceFields);
        DebugLogger.success('✅ User preferences updated successfully');
      } catch (e) {
        DebugLogger.warning('⚠️ Failed to update preferences, continuing with profile update: $e');
      }
    }

    // Update profile (only if there are profile fields left)
    if (filteredData.isNotEmpty) {
      return await _makeRequest(
        '/users/profile/',
        (json) {
          final userData = json['data'] ?? json;
          return _parseUserModel(userData);
        },
        method: 'PUT',
        body: filteredData,
        operationName: 'Update User Profile',
      );
    } else {
      // If no profile fields, just return current user
      return await getCurrentUser();
    }
  }

  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    await _waitForAuthToken(maxWaitMs: 1500);
    await _makeRequest(
      '/users/preferences/',
      (json) => json,
      method: 'PUT',
      body: preferences,
      operationName: 'Update User Preferences',
    );
  }

  Future<void> updateUserLocation(double latitude, double longitude) async {
    await _waitForAuthToken(maxWaitMs: 1500);
    await _makeRequest(
      '/users/location/',
      (json) => json,
      method: 'PUT',
      body: {'latitude': latitude, 'longitude': longitude},
      operationName: 'Update User Location',
    );
  }

  // Unified property search method that supports all filters
  Future<UnifiedPropertyResponse> searchProperties({
    required UnifiedFilterModel filters,
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    int page = 1,
    int limit = 20,
    bool excludeSwiped = false,
    bool useCache = true,
  }) async {
    // Validate parameters to prevent 422 errors
    if (latitude < -90 || latitude > 90) {
      DebugLogger.error('🚫 Invalid latitude: $latitude (must be between -90 and 90)');
      throw ArgumentError('Invalid latitude: $latitude');
    }
    if (longitude < -180 || longitude > 180) {
      DebugLogger.error('🚫 Invalid longitude: $longitude (must be between -180 and 180)');
      throw ArgumentError('Invalid longitude: $longitude');
    }
    if (radiusKm <= 0 || radiusKm > 1000) {
      DebugLogger.error('🚫 Invalid radius: $radiusKm (must be between 0 and 1000 km)');
      throw ArgumentError('Invalid radius: $radiusKm');
    }
    if (page <= 0) {
      DebugLogger.error('🚫 Invalid page: $page (must be >= 1)');
      throw ArgumentError('Invalid page: $page');
    }
    if (limit <= 0 || limit > 100) {
      DebugLogger.error('🚫 Invalid limit: $limit (must be between 1 and 100)');
      throw ArgumentError('Invalid limit: $limit');
    }

    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'lat': latitude.toStringAsFixed(6), // Limit precision to avoid float precision issues
      'lng': longitude.toStringAsFixed(6),
      'radius': radiusKm.toInt().toString(),
    };

    // Simple cache-busting when fresh data is required
    if (!useCache) {
      queryParams['_'] = DateTime.now().millisecondsSinceEpoch.toString();
    }

    DebugLogger.api('🔍 Search parameters set (radius: $radiusKm km)');

    // Convert filters to query parameters with validation
    final filterMap = filters.toJson();
    filterMap.forEach((key, value) {
      if (value != null) {
        if (key == 'search_query') {
          // Map internal search_query to backend 'q'
          final q = value.toString().trim();
          if (q.isNotEmpty) {
            queryParams['q'] = q;
          }
          return; // Skip adding search_query as-is
        }

        if (value is List) {
          // Handle list parameters (like amenities, property_type)
          if (value.isNotEmpty) {
            // Validate list items are not empty strings
            final cleanList = value
                .where((item) => item != null && item.toString().trim().isNotEmpty)
                .toList();
            if (cleanList.isNotEmpty) {
              queryParams[key] = cleanList.join(',');
            }
          }
        } else if (value.toString().trim().isNotEmpty) {
          // Only add non-empty string values
          queryParams[key] = value.toString().trim();
        }
      }
    });

    // Internal flag: exclude properties already swiped by the user
    if (excludeSwiped) {
      queryParams['exclude_swiped'] = 'true';
    }

    DebugLogger.api('🔍 Final query params: ${_summarizeForLog(queryParams)}');

    return await _makeRequest(
      '/properties/',
      (json) => _parseUnifiedPropertyResponse(json),
      method: 'GET',
      queryParams: queryParams,
      operationName: 'Search Properties',
    );
  }

  // Same as searchProperties but supports If-None-Match and returns ETag
  Future<ApiWithEtag<UnifiedPropertyResponse>> searchPropertiesWithCacheValidation({
    required UnifiedFilterModel filters,
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    int page = 1,
    int limit = 20,
    bool excludeSwiped = false,
    bool useCache = true,
    String? ifNoneMatch,
  }) async {
    // Build query params same as searchProperties
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'lat': latitude.toStringAsFixed(6),
      'lng': longitude.toStringAsFixed(6),
      'radius': radiusKm.toInt().toString(),
    };

    if (!useCache) {
      queryParams['_'] = DateTime.now().millisecondsSinceEpoch.toString();
    }

    final filterMap = filters.toJson();
    filterMap.forEach((key, value) {
      if (value != null) {
        if (key == 'search_query') {
          final q = value.toString().trim();
          if (q.isNotEmpty) queryParams['q'] = q;
          return;
        }
        if (value is List) {
          final cleanList = value
              .where((item) => item != null && item.toString().trim().isNotEmpty)
              .toList();
          if (cleanList.isNotEmpty) queryParams[key] = cleanList.join(',');
        } else if (value.toString().trim().isNotEmpty) {
          queryParams[key] = value.toString().trim();
        }
      }
    });
    if (excludeSwiped) {
      queryParams['exclude_swiped'] = 'true';
    }

    String? responseEtag;
    try {
      final data = await _makeRequest<UnifiedPropertyResponse>(
        '/properties/',
        (json) => _parseUnifiedPropertyResponse(json),
        method: 'GET',
        queryParams: queryParams,
        operationName: 'Search Properties (ETag)',
        headers: ifNoneMatch != null ? {'If-None-Match': ifNoneMatch} : null,
        allowNotModified: true,
        onHeaders: (headers) {
          responseEtag = headers['etag'] ?? headers['ETag'];
        },
      );
      return ApiWithEtag(data: data, etag: responseEtag, notModified: false, statusCode: 200);
    } on NotModifiedException {
      return ApiWithEtag(data: null, etag: ifNoneMatch, notModified: true, statusCode: 304);
    }
  }

  // Property Discovery using unified search
  Future<UnifiedPropertyResponse> discoverProperties({
    required double latitude,
    required double longitude,
    int limit = 10,
    int page = 1,
  }) async {
    return await _makeRequest(
      '/properties/',
      (json) => _parseUnifiedPropertyResponse(json),
      method: 'GET',
      queryParams: {
        'page': page.toString(),
        'limit': limit.toString(),
        'lat': latitude.toString(),
        'lng': longitude.toString(),
        'radius': '10', // Large radius for discovery
      },
      operationName: 'Discover Properties',
    );
  }

  Future<UnifiedPropertyResponse> exploreProperties({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'lat': latitude.toString(),
      'lng': longitude.toString(),
      'radius': radiusKm.toInt().toString(),
    };

    // Add additional filters as query parameters
    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null) {
          if (value is List) {
            if (value.isNotEmpty) {
              queryParams[key] = value.join(',');
            }
          } else {
            queryParams[key] = value.toString();
          }
        }
      });
    }

    // Add sort_by only if explicitly provided in filters
    if (filters != null && filters.containsKey('sort_by')) {
      queryParams['sort_by'] = filters['sort_by'].toString();
    }

    return await _makeRequest(
      '/properties/',
      (json) => _parseUnifiedPropertyResponse(json),
      method: 'GET',
      queryParams: queryParams,
      operationName: 'Explore Properties',
    );
  }

  Future<UnifiedPropertyResponse> filterProperties({
    required double latitude,
    required double longitude,
    required Map<String, dynamic> filters,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'lat': latitude.toString(),
      'lng': longitude.toString(),
      'radius': (filters['radius_km'] ?? 10).toString(),
    };

    // Add all filters as query parameters
    filters.forEach((key, value) {
      if (value != null && key != 'radius_km') {
        // Skip radius_km as we already added it as 'radius'
        if (value is List) {
          if (value.isNotEmpty) {
            queryParams[key] = value.join(',');
          }
        } else {
          queryParams[key] = value.toString();
        }
      }
    });

    return await _makeRequest(
      '/properties/',
      (json) => _parseUnifiedPropertyResponse(json),
      method: 'GET',
      queryParams: queryParams,
      operationName: 'Filter Properties',
    );
  }

  Future<PropertyModel> getPropertyDetails(int propertyId) async {
    return await _makeRequest('/properties/$propertyId', (json) {
      final propertyData = json['data'] ?? json;
      return _parsePropertyModel(propertyData);
    }, operationName: 'Get Property Details');
  }

  Map<String, dynamic> _cleanPropertyPayload(Map<String, dynamic> payload) {
    final cleaned = <String, dynamic>{};
    payload.forEach((key, value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      if (value is List && value.isEmpty) return;
      if (value is Map && value.isEmpty) return;
      cleaned[key] = value;
    });
    return cleaned;
  }

  Future<PropertyModel> createProperty(Map<String, dynamic> payload) async {
    await _waitForAuthToken(maxWaitMs: 1500);
    final cleaned = _cleanPropertyPayload(payload);
    return await _makeRequest(
      '/properties/',
      (json) {
        final propertyData = json['data'] ?? json;
        return _parsePropertyModel(propertyData);
      },
      method: 'POST',
      body: cleaned,
      operationName: 'Create Property',
    );
  }

  Future<PropertyModel> updateProperty(int propertyId, Map<String, dynamic> payload) async {
    await _waitForAuthToken(maxWaitMs: 1500);
    final cleaned = _cleanPropertyPayload(payload);
    return await _makeRequest(
      '/properties/$propertyId',
      (json) {
        final propertyData = json['data'] ?? json;
        return _parsePropertyModel(propertyData);
      },
      method: 'PUT',
      body: cleaned,
      operationName: 'Update Property',
    );
  }

  Future<PropertyModel> updatePropertyMedia(
    int propertyId,
    Map<String, dynamic> mediaPayload,
  ) async {
    final merged = _cleanPropertyPayload(mediaPayload);
    return updateProperty(propertyId, merged);
  }

  // Connection Testing
  Future<bool> testConnection() async {
    try {
      DebugLogger.api('🔍 Testing backend connection to $_baseUrl');
      final response = await get('/health').timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      DebugLogger.api('🏥 Health check response: ${response.statusCode}');

      // Consider 200, 404, and 405 as "server is reachable"
      final isReachable =
          response.statusCode == 200 || response.statusCode == 404 || response.statusCode == 405;

      if (isReachable) {
        DebugLogger.success('✅ Backend server is reachable (status: ${response.statusCode})');
      }

      return isReachable;
    } catch (e) {
      DebugLogger.warning('🔍 Primary health check failed: $e');
      // Try alternative endpoint for testing
      try {
        final response = await get('/').timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw Exception('Connection timeout');
          },
        );
        DebugLogger.api('🔄 Alternative endpoint test: ${response.statusCode}');

        // Server is reachable if we get any HTTP response (including 405, 404)
        final isReachable =
            response.statusCode == 200 || response.statusCode == 404 || response.statusCode == 405;

        if (isReachable) {
          DebugLogger.success(
            '✅ Backend server is reachable via alternative test (status: ${response.statusCode})',
          );
        }

        return isReachable;
      } catch (e2) {
        DebugLogger.warning('💔 Backend server unreachable: $e2');
        return false;
      }
    }
  }

  // Swipe System
  Future<void> swipeProperty(
    int propertyId,
    bool isLiked, {
    double? userLocationLat,
    double? userLocationLng,
    String? sessionId,
  }) async {
    await _makeRequest(
      '/swipes/',
      (json) => json,
      method: 'POST',
      body: {
        'property_id': propertyId,
        'is_liked': isLiked,
        'user_location_lat': userLocationLat,
        'user_location_lng': userLocationLng,
        'session_id': sessionId,
      },
      operationName: 'Swipe Property',
    );
  }

  // Get swipes with comprehensive filtering and pagination
  Future<Map<String, dynamic>> getSwipes({
    // Location & Search
    double? lat,
    double? lng,
    int? radius,
    String? q,

    // Property Filters
    List<String>? propertyType,
    String? purpose,
    double? priceMin,
    double? priceMax,
    int? bedroomsMin,
    int? bedroomsMax,
    int? bathroomsMin,
    int? bathroomsMax,
    double? areaMin,
    double? areaMax,

    // Additional Filters
    List<String>? amenities,
    int? parkingSpacesMin,
    int? floorNumberMin,
    int? floorNumberMax,
    int? ageMax,

    // Short Stay Filters
    String? checkIn,
    String? checkOut,
    int? guests,

    // Swipe Filters
    bool? isLiked,

    // Sorting & Pagination
    String? sortBy,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{'page': page.toString(), 'limit': limit.toString()};

    // Location & Search
    if (lat != null) queryParams['lat'] = lat.toString();
    if (lng != null) queryParams['lng'] = lng.toString();
    if (radius != null) queryParams['radius'] = radius.toString();
    if (q != null && q.isNotEmpty) queryParams['q'] = q;

    // Property Filters
    if (propertyType != null && propertyType.isNotEmpty) {
      queryParams['property_type'] = propertyType.join(',');
    }
    if (purpose != null) queryParams['purpose'] = purpose;
    if (priceMin != null) queryParams['price_min'] = priceMin.toString();
    if (priceMax != null) queryParams['price_max'] = priceMax.toString();
    if (bedroomsMin != null) {
      queryParams['bedrooms_min'] = bedroomsMin.toString();
    }
    if (bedroomsMax != null) {
      queryParams['bedrooms_max'] = bedroomsMax.toString();
    }
    if (bathroomsMin != null) {
      queryParams['bathrooms_min'] = bathroomsMin.toString();
    }
    if (bathroomsMax != null) {
      queryParams['bathrooms_max'] = bathroomsMax.toString();
    }
    if (areaMin != null) queryParams['area_min'] = areaMin.toString();
    if (areaMax != null) queryParams['area_max'] = areaMax.toString();

    // Additional Filters
    if (amenities != null && amenities.isNotEmpty) {
      queryParams['amenities'] = amenities.join(',');
    }
    if (parkingSpacesMin != null) {
      queryParams['parking_spaces_min'] = parkingSpacesMin.toString();
    }
    if (floorNumberMin != null) {
      queryParams['floor_number_min'] = floorNumberMin.toString();
    }
    if (floorNumberMax != null) {
      queryParams['floor_number_max'] = floorNumberMax.toString();
    }
    if (ageMax != null) queryParams['age_max'] = ageMax.toString();

    // Short Stay Filters
    if (checkIn != null) queryParams['check_in'] = checkIn;
    if (checkOut != null) queryParams['check_out'] = checkOut;
    if (guests != null) queryParams['guests'] = guests.toString();

    // Swipe Filters
    if (isLiked != null) queryParams['is_liked'] = isLiked.toString();

    // Sorting
    if (sortBy != null) queryParams['sort_by'] = sortBy;

    return await _makeRequest(
      '/swipes/',
      (json) => json,
      queryParams: queryParams,
      operationName: 'Get Swipes',
    );
  }

  // Same as getSwipes but supports If-None-Match and returns ETag
  Future<ApiWithEtag<Map<String, dynamic>>> getSwipesWithCacheValidation({
    // Location & Search
    double? lat,
    double? lng,
    int? radius,
    String? q,

    // Property Filters
    List<String>? propertyType,
    String? purpose,
    double? priceMin,
    double? priceMax,
    int? bedroomsMin,
    int? bedroomsMax,
    int? bathroomsMin,
    int? bathroomsMax,
    double? areaMin,
    double? areaMax,

    // Additional Filters
    List<String>? amenities,
    int? parkingSpacesMin,
    int? floorNumberMin,
    int? floorNumberMax,
    int? ageMax,

    // Short Stay Filters
    String? checkIn,
    String? checkOut,
    int? guests,

    // Swipe Filters
    bool? isLiked,

    // Sorting & Pagination
    String? sortBy,
    int page = 1,
    int limit = 20,
    String? ifNoneMatch,
  }) async {
    final queryParams = <String, String>{'page': page.toString(), 'limit': limit.toString()};

    if (lat != null) queryParams['lat'] = lat.toString();
    if (lng != null) queryParams['lng'] = lng.toString();
    if (radius != null) queryParams['radius'] = radius.toString();
    if (q != null && q.isNotEmpty) queryParams['q'] = q;

    if (propertyType != null && propertyType.isNotEmpty) {
      queryParams['property_type'] = propertyType.join(',');
    }
    if (purpose != null) queryParams['purpose'] = purpose;
    if (priceMin != null) queryParams['price_min'] = priceMin.toString();
    if (priceMax != null) queryParams['price_max'] = priceMax.toString();
    if (bedroomsMin != null) queryParams['bedrooms_min'] = bedroomsMin.toString();
    if (bedroomsMax != null) queryParams['bedrooms_max'] = bedroomsMax.toString();
    if (bathroomsMin != null) queryParams['bathrooms_min'] = bathroomsMin.toString();
    if (bathroomsMax != null) queryParams['bathrooms_max'] = bathroomsMax.toString();
    if (areaMin != null) queryParams['area_min'] = areaMin.toString();
    if (areaMax != null) queryParams['area_max'] = areaMax.toString();
    if (amenities != null && amenities.isNotEmpty) {
      queryParams['amenities'] = amenities.join(',');
    }
    if (parkingSpacesMin != null) queryParams['parking_spaces_min'] = parkingSpacesMin.toString();
    if (floorNumberMin != null) queryParams['floor_number_min'] = floorNumberMin.toString();
    if (floorNumberMax != null) queryParams['floor_number_max'] = floorNumberMax.toString();
    if (ageMax != null) queryParams['age_max'] = ageMax.toString();
    if (checkIn != null) queryParams['check_in'] = checkIn;
    if (checkOut != null) queryParams['check_out'] = checkOut;
    if (guests != null) queryParams['guests'] = guests.toString();
    if (isLiked != null) queryParams['is_liked'] = isLiked.toString();
    if (sortBy != null) queryParams['sort_by'] = sortBy;

    String? responseEtag;
    try {
      final data = await _makeRequest<Map<String, dynamic>>(
        '/swipes/',
        (json) => json,
        queryParams: queryParams,
        operationName: 'Get Swipes (ETag)',
        headers: ifNoneMatch != null ? {'If-None-Match': ifNoneMatch} : null,
        allowNotModified: true,
        onHeaders: (headers) {
          responseEtag = headers['etag'] ?? headers['ETag'];
        },
      );
      return ApiWithEtag(data: data, etag: responseEtag, notModified: false, statusCode: 200);
    } on NotModifiedException {
      return ApiWithEtag(data: null, etag: ifNoneMatch, notModified: true, statusCode: 304);
    }
  }

  // Get swipe statistics
  Future<Map<String, dynamic>> getSwipeStats() async {
    return await _makeRequest(
      '/swipes/stats/',
      (json) => json,
      operationName: 'Get Swipe Statistics',
    );
  }

  // Toggle like/dislike status for properties
  Future<Map<String, dynamic>> toggleSwipeStatus({
    required int propertyId,
    required bool isLiked,
  }) async {
    return await _makeRequest(
      '/swipes/toggle/',
      (json) => json,
      method: 'POST',
      body: {'property_id': propertyId, 'is_liked': isLiked},
      operationName: 'Toggle Swipe Status',
    );
  }

  // Location Services

  // Visit Scheduling
  Future<VisitModel> scheduleVisit({
    required int propertyId,
    required String scheduledDate,
    String? specialRequirements,
  }) async {
    return await _makeRequest(
      '/visits/',
      (json) => VisitModel.fromJson(json),
      method: 'POST',
      body: {
        'property_id': propertyId,
        'scheduled_date': scheduledDate,
        if (specialRequirements != null) 'special_requirements': specialRequirements,
      },
      operationName: 'Schedule Visit',
    );
  }

  // Visits listing (aligned with API docs)
  Future<VisitListResponse> getUpcomingVisits() async {
    return await _makeRequest(
      '/visits/upcoming/',
      (json) => VisitListResponse.fromJson(json),
      method: 'GET',
      operationName: 'Get Upcoming Visits',
    );
  }

  Future<VisitListResponse> getPastVisits() async {
    return await _makeRequest(
      '/visits/past/',
      (json) => VisitListResponse.fromJson(json),
      method: 'GET',
      operationName: 'Get Past Visits',
    );
  }

  Future<VisitListResponse> getVisitsSummary() async {
    return await _makeRequest(
      '/visits/',
      (json) => VisitListResponse.fromJson(json),
      method: 'GET',
      operationName: 'Get All Visits Summary',
    );
  }

  // Generic method to update visit (reserved for admin/agent)
  Future<VisitModel> updateVisit(int visitId, Map<String, dynamic> updateData) async {
    return await _makeRequest(
      '/visits/$visitId',
      (json) => VisitModel.fromJson(json),
      method: 'PUT',
      body: updateData,
      operationName: 'Update Visit',
    );
  }

  // Reschedule a visit (API returns message + success)
  Future<bool> rescheduleVisit(int visitId, {required String newDate, String? reason}) async {
    final resp = await _makeRequest<Map<String, dynamic>>(
      '/visits/$visitId/reschedule',
      (json) => json,
      method: 'POST',
      body: {'new_date': newDate, if (reason != null) 'reason': reason},
      operationName: 'Reschedule Visit',
    );
    final success = (resp['success'] == true);
    return success;
  }

  // Cancel a visit (API returns message + success)
  Future<bool> cancelVisit(int visitId, {required String reason}) async {
    final resp = await _makeRequest<Map<String, dynamic>>(
      '/visits/$visitId/cancel',
      (json) => json,
      method: 'POST',
      body: {'reason': reason},
      operationName: 'Cancel Visit',
    );
    final success = (resp['success'] == true);
    return success;
  }

  Future<AgentModel> getRelationshipManager() async {
    return await _makeRequest('/agents/assigned/', (json) {
      // The API returns the agent object directly, not wrapped in 'data'
      return AgentModel.fromJson(json);
    }, operationName: 'Get Assigned Agent');
  }

  // Amenities Management
  Future<List<AmenityModel>> getAllAmenities() async {
    return await _makeRequest('/amenities/', (json) {
      final amenitiesData = json['data'] ?? json;

      if (amenitiesData is List) {
        return amenitiesData.map((item) => AmenityModel.fromJson(item)).toList();
      } else {
        throw Exception('Expected list of amenities but got: ${amenitiesData.runtimeType}');
      }
    }, operationName: 'Get All Amenities');
  }

  // Enhanced user settings
  Future<void> updateNotificationSettings(NotificationSettings settings) async {
    await _makeRequest(
      '/users/notification-settings',
      (json) => json,
      method: 'PUT',
      body: settings.toJson(),
      operationName: 'Update Notification Settings',
    );
  }

  Future<NotificationSettings> getNotificationSettings() async {
    return await _makeRequest('/users/notification-settings', (json) {
      final settingsData = json['data'] ?? json;
      return NotificationSettings.fromJson(settingsData);
    }, operationName: 'Get Notification Settings');
  }

  Future<void> updatePrivacySettings(PrivacySettings settings) async {
    await _makeRequest(
      '/users/privacy-settings',
      (json) => json,
      method: 'PUT',
      body: settings.toJson(),
      operationName: 'Update Privacy Settings',
    );
  }

  Future<PrivacySettings> getPrivacySettings() async {
    return await _makeRequest('/users/privacy-settings', (json) {
      final settingsData = json['data'] ?? json;
      return PrivacySettings.fromJson(settingsData);
    }, operationName: 'Get Privacy Settings');
  }
}

// Lightweight wrapper to return parsed data with caching metadata
class ApiWithEtag<T> {
  final T? data;
  final String? etag;
  final bool notModified;
  final int? statusCode;

  ApiWithEtag({this.data, this.etag, this.notModified = false, this.statusCode});
}

class _CacheEntry {
  final String key;
  final int timestamp;

  _CacheEntry(this.key, this.timestamp);
}
