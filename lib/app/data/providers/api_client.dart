import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart' as getx;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/debug_logger.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? response;
  final String? errorCode;

  ApiException(
    this.message, {
    this.statusCode,
    this.response,
    this.errorCode,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class ApiClient extends getx.GetxService {
  late final Dio _dio;
  late final String _baseUrl;
  final SupabaseClient _supabase = Supabase.instance.client;

  // Cache for responses with TTL
  final Map<String, CacheEntry> _cache = {};
  static const int _cacheTTLSeconds = 60;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeDio();
  }

  Future<void> _initializeDio() async {
    // Get base URL from environment
    final fullApiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    _baseUrl = '$fullApiUrl/api/v1';

    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      listFormat: ListFormat.multi, // For array parameters like property_type[]
    ));

    _setupInterceptors();
    DebugLogger.startup('API Client initialized with base URL: $_baseUrl');
  }

  void _setupInterceptors() {
    // Request interceptor - Add auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = _supabase.auth.currentSession?.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        DebugLogger.logAPIRequest(
          method: options.method,
          endpoint: '${options.baseUrl}${options.path}',
          body: options.data,
        );

        handler.next(options);
      },
      onResponse: (response, handler) {
        DebugLogger.logAPIResponse(
          statusCode: response.statusCode ?? 0,
          endpoint: '${response.requestOptions.baseUrl}${response.requestOptions.path}',
          body: response.data?.toString() ?? '',
        );
        handler.next(response);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Try to refresh token
          try {
            await _supabase.auth.refreshSession();
            final newToken = _supabase.auth.currentSession?.accessToken;
            
            if (newToken != null) {
              // Retry original request with new token
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newToken';
              
              final cloneReq = await _dio.fetch(opts);
              handler.resolve(cloneReq);
              return;
            }
          } catch (e, stackTrace) {
            DebugLogger.error('Token refresh failed', e, stackTrace);
          }
          
          // If refresh fails, redirect to login
          _handleAuthFailure();
        }
        
        handler.next(error);
      },
    ));

    // Retry interceptor for network errors
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) async {
        final int currentRetry = (error.requestOptions.extra['retryCount'] is int)
            ? (error.requestOptions.extra['retryCount'] as int)
            : 0;
        if (_shouldRetry(error) && currentRetry < 2) {
          final int retryCount = currentRetry + 1;
          error.requestOptions.extra['retryCount'] = retryCount;

          // Exponential backoff
          await Future.delayed(Duration(milliseconds: 500 * retryCount));

          try {
            final response = await _dio.fetch(error.requestOptions);
            handler.resolve(response);
            return;
          } catch (e, stackTrace) {
            DebugLogger.warning('Retry $retryCount failed', e);
          }
        }

        handler.next(error);
      },
    ));
  }

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.receiveTimeout ||
           error.type == DioExceptionType.connectionError ||
           (error.response?.statusCode != null && error.response!.statusCode! >= 500);
  }

  void _handleAuthFailure() {
    DebugLogger.auth('Authentication failed - redirecting to login');
    _supabase.auth.signOut();
    
    if (getx.Get.currentRoute != '/login' && getx.Get.currentRoute != '/onboarding') {
      getx.Get.offAllNamed('/onboarding');
      getx.Get.snackbar(
        'Session Expired',
        'Please log in again to continue',
        snackPosition: getx.SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Generic request method with caching
  Future<T> request<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    String method = 'GET',
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    bool useCache = false,
    String? operationName,
  }) async {
    final cacheKey = _getCacheKey(endpoint, method, queryParameters, data);
    
    // Check cache first
    if (useCache && method == 'GET') {
      final cached = _getFromCache(cacheKey);
      if (cached != null) {
        DebugLogger.api('Cache hit for $endpoint');
        return fromJson(cached);
      }
    }

    try {
      final Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _dio.get(endpoint, queryParameters: queryParameters);
          break;
        case 'POST':
          response = await _dio.post(endpoint, data: data, queryParameters: queryParameters);
          break;
        case 'PUT':
          response = await _dio.put(endpoint, data: data, queryParameters: queryParameters);
          break;
        case 'DELETE':
          response = await _dio.delete(endpoint, queryParameters: queryParameters);
          break;
        default:
          throw ApiException('Unsupported HTTP method: $method');
      }

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        final responseData = response.data as Map<String, dynamic>;
        
        // Cache successful GET responses
        if (useCache && method == 'GET') {
          _addToCache(cacheKey, responseData);
        }
        
        return fromJson(responseData);
      } else {
        throw ApiException(
          'HTTP ${response.statusCode}: ${response.statusMessage ?? 'Unknown error'}',
          statusCode: response.statusCode,
          response: response.data?.toString(),
        );
      }
    } on DioException catch (e) {
      DebugLogger.error('API Error for ${operationName ?? endpoint}: ${e.message}', e);
      
      if (e.response?.statusCode == 401) {
        throw ApiException('Authentication failed', statusCode: 401);
      } else if (e.response?.statusCode == 404) {
        throw ApiException('Resource not found', statusCode: 404);
      } else if (e.response?.statusCode == 422) {
        final errorMessage = _extractValidationError(e.response?.data);
        throw ApiException(errorMessage, statusCode: 422);
      } else {
        throw ApiException(
          e.message ?? 'Network error',
          statusCode: e.response?.statusCode,
          response: e.response?.data?.toString(),
        );
      }
    } catch (e, stackTrace) {
      DebugLogger.error('Unexpected error for ${operationName ?? endpoint}', e, stackTrace);
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  String _extractValidationError(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData['message'] is String) {
        return responseData['message'];
      }
      if (responseData['errors'] is Map) {
        final errors = responseData['errors'] as Map;
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
      }
    }
    return 'Invalid request data';
  }

  String _getCacheKey(String endpoint, String method, Map<String, dynamic>? queryParams, Map<String, dynamic>? data) {
    final buffer = StringBuffer('$method:$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      buffer.write('?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}');
    }
    if (data != null && data.isNotEmpty) {
      buffer.write('#${data.hashCode}');
    }
    return buffer.toString();
  }

  void _addToCache(String key, Map<String, dynamic> data) {
    _cache[key] = CacheEntry(data, DateTime.now());
    // Clean old cache entries
    _cleanCache();
  }

  Map<String, dynamic>? _getFromCache(String key) {
    final entry = _cache[key];
    if (entry != null) {
      final age = DateTime.now().difference(entry.timestamp).inSeconds;
      if (age < _cacheTTLSeconds) {
        return entry.data;
      } else {
        _cache.remove(key);
      }
    }
    return null;
  }

  void _cleanCache() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) {
      return now.difference(entry.timestamp).inSeconds > _cacheTTLSeconds;
    });
  }

  void clearCache() {
    _cache.clear();
    DebugLogger.api('Cache cleared');
  }
}

class CacheEntry {
  final Map<String, dynamic> data;
  final DateTime timestamp;

  CacheEntry(this.data, this.timestamp);
}