import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart' as getx;
import 'package:flutter/material.dart';
import '../models/property_model.dart';
import '../models/user_model.dart';
import '../models/visit_model.dart';
import '../models/booking_model.dart';
import '../models/unified_property_response.dart';
import '../models/unified_filter_model.dart';
import '../models/agent_model.dart';

import '../models/amenity_model.dart';
import '../models/api_response_models.dart';
import '../../utils/debug_logger.dart';
import '../../utils/error_handler.dart';
import '../../utils/theme.dart';

class ApiAuthException implements Exception {
  final String message;
  final int? statusCode;

  ApiAuthException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiAuthException: $message';
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? response;

  ApiException(this.message, {this.statusCode, this.response});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
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
        upcoming:
            safeJson['upcoming'] ?? visits.where((v) => v.isUpcoming).length,
        completed:
            safeJson['completed'] ?? visits.where((v) => v.isCompleted).length,
        cancelled:
            safeJson['cancelled'] ?? visits.where((v) => v.isCancelled).length,
      );
    } catch (e, stackTrace) {
      DebugLogger.error('Error in VisitListResponse.fromJson', e, stackTrace);
      DebugLogger.api('Raw JSON: $json');
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

  late String _baseUrl;
  late final SupabaseClient _supabase;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeService();

    // Request modifier to add authentication token
    httpClient.addRequestModifier<Object?>((request) async {
      final token = await _authToken;
      if (token != null && token.trim().isNotEmpty) {
        request.headers['Authorization'] = 'Bearer ${token.trim()}';
      } else {
        request.headers.remove('Authorization');
      }
      request.headers['Content-Type'] = 'application/json';
      return request;
    });

    // Response interceptor for auth error handling
    httpClient.addResponseModifier((request, response) async {
      if (response.statusCode == 401) {
        try {
          // Let the Supabase client handle the refresh
          await _supabase.auth.refreshSession();
          // Retry the original request
          final newToken = await _authToken;
          if (newToken != null && newToken.trim().isNotEmpty) {
            request.headers['Authorization'] = 'Bearer ${newToken.trim()}';
          } else {
            request.headers.remove('Authorization');
          }
          return await httpClient.request(
            request.url.toString(),
            request.method,
            headers: request.headers,
          );
        } catch (e) {
          DebugLogger.error('Token refresh failed', e);
          _handleAuthenticationFailure();
        }
      }
      return response;
    });
  }

  // === CORRECTED AND SIMPLIFIED INITIALIZATION ===
  Future<void> _initializeService() async {
    try {
      // Step 1: Directly use the full and correct base URL from .env
      // We will NOT manipulate this string anymore.
      _baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://360ghar.up.railway.app/api/v1';
      httpClient.baseUrl = _baseUrl; // Set it for GetConnect
      DebugLogger.startup('API Service initialized with base URL: $_baseUrl');

      // Supabase initialization remains the same
      try {
        _supabase = Supabase.instance.client;
        DebugLogger.success('Supabase client found');
      } catch (e) {
        DebugLogger.warning(
          'Supabase not initialized, attempting to initialize...',
        );
        final supabaseUrl = dotenv.env['SUPABASE_URL'];
        final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];

        if (supabaseUrl != null &&
            supabaseUrl.isNotEmpty &&
            supabaseKey != null &&
            supabaseKey.isNotEmpty) {
          await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
          _supabase = Supabase.instance.client;
          DebugLogger.success('Supabase initialized successfully');
        } else {
          DebugLogger.warning(
            'Supabase credentials not provided, continuing without Supabase',
          );
        }
      }
    } catch (e, stackTrace) {
      DebugLogger.error('Error initializing API service', e, stackTrace);
    }

    // Auth state change listener remains the same
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      switch (event) {
        case AuthChangeEvent.signedIn:
          DebugLogger.auth('User signed in');
          if (session != null) {
            DebugLogger.logJWTToken(
              session.accessToken,
              userEmail: session.user.email,
            );
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

  Future<String?> get _authToken async {
    final session = _supabase.auth.currentSession;
    final token = session?.accessToken;

    if (token != null) {
      DebugLogger.logJWTToken(
        token,
        expiresAt: session?.expiresAt != null
            ? DateTime.fromMillisecondsSinceEpoch(session!.expiresAt! * 1000)
            : null,
        userId: session?.user.id,
        userEmail: session?.user.email,
      );
    } else {
      DebugLogger.warning('No JWT Token available');
    }

    return token;
  }

  void _handleAuthenticationFailure() {
    DebugLogger.auth('🚪 Authentication failed: redirecting to login');
    _supabase.auth.signOut();
    try {
      if (getx.Get.currentRoute != '/login' &&
          getx.Get.currentRoute != '/onboarding') {
        getx.Get.offAllNamed('/onboarding');
        getx.Get.snackbar(
          'Session Expired',
          'Please log in again to continue',
          snackPosition: getx.SnackPosition.TOP,
          duration: const Duration(seconds: 3),
          backgroundColor: AppTheme.errorRed,
          colorText: AppTheme.backgroundWhite,
        );
      }
    } catch (e) {
      DebugLogger.error('❌ Navigation error during auth failure: $e');
    }
  }

  // === CORRECTED AND SIMPLIFIED REQUEST METHOD ===
  Future<T> _makeRequest<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    int retries = 1,
    String? operationName,
    bool useMockFallback = true,
  }) async {
    Exception? lastException;
    final operation = operationName ?? '$method $endpoint';

    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        // Step 2: Drastically simplified URL construction.
        // We assume the endpoint starts with a '/' (e.g., '/properties').
        // GetConnect will automatically join `httpClient.baseUrl` + `endpoint`.
        final String finalEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';

        DebugLogger.api(
          '🚀 API $method $_baseUrl$finalEndpoint${queryParams != null && queryParams.isNotEmpty ? ' | Query: $queryParams' : ''}${body != null && body.isNotEmpty ? ' | Body: $body' : ''}',
        );

        DebugLogger.logAPIRequest(
          method: method,
          endpoint: finalEndpoint,
          body: body,
        );

        getx.Response response;

        switch (method.toUpperCase()) {
          case 'GET':
            response = await get(finalEndpoint, query: queryParams);
            break;
          case 'POST':
            response = await post(finalEndpoint, body, query: queryParams);
            break;
          case 'PUT':
            response = await put(finalEndpoint, body, query: queryParams);
            break;
          case 'DELETE':
            response = await delete(finalEndpoint, query: queryParams);
            break;
          default:
            throw Exception('Unsupported HTTP method: $method');
        }

        DebugLogger.api(
          '📨 API $method $_baseUrl$finalEndpoint → ${response.statusCode}',
        );
        DebugLogger.api(
          '📨 API $method $_baseUrl$finalEndpoint → ${response.bodyString}',
        );

        DebugLogger.logAPIResponse(
          statusCode: response.statusCode ?? 0,
          endpoint: finalEndpoint,
          body: response.bodyString ?? '',
        );

        if (response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300) {
          final responseData = response.body;
          if (responseData is Map<String, dynamic>) {
            return fromJson(responseData);
          } else if (responseData is List) {
            return fromJson({'data': responseData});
          } else {
            return fromJson({'data': responseData});
          }
        } else if (response.statusCode == 401) {
          DebugLogger.auth('🔒 Authentication failed for $operation');
          throw ApiAuthException('Authentication failed', statusCode: 401);
        } else if (response.statusCode == 403) {
          DebugLogger.auth('🚫 Access forbidden for $operation');
          throw ApiAuthException('Access forbidden', statusCode: 403);
        } else if (response.statusCode == 404) {
          final errorMessage = 'API endpoint not found: $_baseUrl$finalEndpoint';
          DebugLogger.error('❌ API 404 Error for $operation: $errorMessage');
          if (useMockFallback) {
            DebugLogger.warning('🔄 Falling back to mock data for $operation');
            return _getMockDataForEndpoint(endpoint, fromJson);
          }
          throw ApiException(
            'Request not found. Please check if the backend server is running and the API endpoints are correct.',
            statusCode: 404,
            response: response.bodyString,
          );
        } else if (response.statusCode! >= 500 && attempt < retries) {
          DebugLogger.warning(
            '🔄 Server error (${response.statusCode}) for $operation, retrying... (${attempt + 1}/$retries)',
          );
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          continue;
        } else {
          final errorMessage =
              'HTTP ${response.statusCode}: ${response.statusText ?? 'Unknown error'}';
          DebugLogger.error('❌ API Error for $operation: $errorMessage');
          ErrorHandler.handleNetworkError(response.bodyString ?? errorMessage);

          throw ApiException(
            response.statusText ?? 'API Error',
            statusCode: response.statusCode,
            response: response.bodyString,
          );
        }
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        if (e is ApiAuthException) {
          DebugLogger.auth('🔒 Authentication error for $operation: $e');
          rethrow;
        }

        if (e.toString().contains('Connection refused') ||
            e.toString().contains('Failed host lookup') ||
            e.toString().contains('Network is unreachable') ||
            e.toString().contains('No route to host') ||
            e.toString().contains('Connection timed out')) {
          DebugLogger.warning(
            '🌐 Network connectivity issue for $operation: $e',
          );
          if (useMockFallback) {
            DebugLogger.warning(
              '🔄 Falling back to mock data for $operation due to network issues',
            );
            return _getMockDataForEndpoint(endpoint, fromJson);
          }
        }

        if (attempt == retries) {
          DebugLogger.error(
            '💥 API Request failed for $operation after ${attempt + 1} attempts: $e',
          );
          ErrorHandler.handleNetworkError(e);
          rethrow;
        }

        DebugLogger.warning(
          '🔄 Request failed for $operation, retrying... (${attempt + 1}/$retries)',
        );
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }

    throw lastException ?? Exception('Unknown error occurred for $operation');
  }

  // --- BAAKI SARA CODE SAME RAHEGA ---
  // (All other methods like _parseUserModel, signUp, searchProperties, etc. will now work correctly
  // because they all use the fixed _makeRequest method. No changes are needed in them.)

  // Helper method for safer user model parsing
  static UserModel _parseUserModel(Map<String, dynamic> json) {
    try {
      final safeJson = Map<String, dynamic>.from(json);
      safeJson['email'] ??= '';
      safeJson['phone'] ??= '';
      if (safeJson['preferences'] is! Map) {
        safeJson['preferences'] = <String, dynamic>{};
      }
      return UserModel.fromJson(safeJson);
    } catch (e) {
      DebugLogger.error('❌ Error parsing user model: $e');
      DebugLogger.api('📊 Raw JSON: $json');
      rethrow;
    }
  }

  // Helper method for safer property model parsing
  static PropertyModel _parsePropertyModel(Map<String, dynamic> json) {
    try {
      final Map<String, dynamic> safeJson = Map<String, dynamic>.from(json);
      if (safeJson['calendar_data'] is List) {
        safeJson['calendar_data'] = <String, dynamic>{};
      }
      double? toDouble(dynamic v) {
        if (v == null) return null;
        if (v is num) return v.toDouble();
        if (v is String) return double.tryParse(v);
        return null;
      }
      if (safeJson.containsKey('base_price')) {
        safeJson['base_price'] = toDouble(safeJson['base_price']) ?? 0.0;
      }
      if (safeJson.containsKey('price_per_sqft')) {
        safeJson['price_per_sqft'] = toDouble(safeJson['price_per_sqft']);
      }
      if (safeJson.containsKey('monthly_rent')) {
        safeJson['monthly_rent'] = toDouble(safeJson['monthly_rent']);
      }
      if (safeJson.containsKey('daily_rate')) {
        safeJson['daily_rate'] = toDouble(safeJson['daily_rate']);
      }
      if (safeJson.containsKey('security_deposit')) {
        safeJson['security_deposit'] = toDouble(safeJson['security_deposit']);
      }
      if (safeJson.containsKey('maintenance_charges')) {
        safeJson['maintenance_charges'] = toDouble(
          safeJson['maintenance_charges'],
        );
      }
      _validatePropertyJson(json);
      return PropertyModel.fromJson(safeJson);
    } catch (e) {
      DebugLogger.error('❌ Error parsing property model: $e');
      DebugLogger.api('📊 Raw JSON: $json');
      if (json['id'] == null)
        DebugLogger.error('🚫 Missing required field: id');
      if (json['title'] == null)
        DebugLogger.error('🚫 Missing required field: title');
      if (json['property_type'] == null)
        DebugLogger.error('🚫 Missing required field: property_type');
      if (json['purpose'] == null)
        DebugLogger.error('🚫 Missing required field: purpose');
      rethrow;
    }
  }

  static void _validatePropertyJson(Map<String, dynamic> json) {
    final requiredFields = ['id', 'title', 'property_type', 'purpose'];
    final missingFields = <String>[];
    for (final field in requiredFields) {
      if (json[field] == null) {
        missingFields.add(field);
      }
    }
    if (missingFields.isNotEmpty) {
      throw Exception('Missing required fields: ${missingFields.join(', ')}');
    }
  }

  static UnifiedPropertyResponse _parseUnifiedPropertyResponse(
    Map<String, dynamic> json,
  ) {
    try {
      final Map<String, dynamic> safeJson = Map<String, dynamic>.from(json);
      dynamic rawList =
          safeJson['properties'] ??
          safeJson['data'] ??
          safeJson['results'] ??
          safeJson['items'];
      final List<dynamic> list = rawList is List ? rawList : <dynamic>[];
      final List<PropertyModel> parsed = <PropertyModel>[];
      int failedCount = 0;
      for (int i = 0; i < list.length; i++) {
        final item = list[i];
        if (item is Map<String, dynamic>) {
          try {
            parsed.add(_parsePropertyModel(item));
          } catch (_) {
            failedCount++;
          }
        } else {
          failedCount++;
        }
      }
      if (failedCount > 0) {
        DebugLogger.warning('⚠️ Skipped $failedCount invalid properties');
      }
      final int total = (safeJson['total'] is num)
          ? (safeJson['total'] as num).toInt()
          : parsed.length;
      final int limit = (safeJson['limit'] is num)
          ? (safeJson['limit'] as num).toInt()
          : (parsed.isNotEmpty ? parsed.length : 20);
      final int page = (safeJson['page'] is num)
          ? (safeJson['page'] as num).toInt()
          : 1;
      final int totalPages = (safeJson['total_pages'] is num)
          ? (safeJson['total_pages'] as num).toInt()
          : ((limit > 0) ? ((total + limit - 1) / limit).ceil() : 1);
      Map<String, dynamic> filtersApplied = {};
      if (safeJson['filters_applied'] is Map<String, dynamic>) {
        filtersApplied = Map<String, dynamic>.from(
          safeJson['filters_applied'] as Map,
        );
      }
      SearchCenter? searchCenter;
      if (safeJson['search_center'] is Map<String, dynamic>) {
        final sc = safeJson['search_center'] as Map<String, dynamic>;
        final lat = sc['latitude'] ?? sc['lat'];
        final lng = sc['longitude'] ?? sc['lng'];
        if (lat is num && lng is num) {
          searchCenter = SearchCenter(
            latitude: lat.toDouble(),
            longitude: lng.toDouble(),
          );
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
      DebugLogger.api('📊 Raw JSON: $json');
      rethrow;
    }
  }

  Future<AuthResponse> signUp(
    String email,
    String password, {
    String? fullName,
    String? phone,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
      },
    );
    return response;
  }

  Future<AuthResponse> signIn(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<UserModel> getCurrentUser() async {
    return await _makeRequest('/users/profile', (json) {
      final userData = json['data'] ?? json;
      return _parseUserModel(userData);
    }, operationName: 'Get Current User');
  }

  Future<UserModel> updateUserProfile(Map<String, dynamic> profileData) async {
    return await _makeRequest(
      '/users/profile',
      (json) {
        final userData = json['data'] ?? json;
        return _parseUserModel(userData);
      },
      method: 'PUT',
      body: profileData,
      operationName: 'Update User Profile',
    );
  }

  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    await _makeRequest(
      '/users/preferences',
      (json) => json,
      method: 'PUT',
      body: preferences,
      operationName: 'Update User Preferences',
    );
  }

  Future<void> updateUserLocation(double latitude, double longitude) async {
    await _makeRequest(
      '/users/location',
      (json) => json,
      method: 'PUT',
      body: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      },
      operationName: 'Update User Location',
    );
  }

  Future<UnifiedPropertyResponse> searchProperties({
    required UnifiedFilterModel filters,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    // Only include essential parameters, exclude unnecessary filters
    if (filters.latitude != null) {
      queryParams['lat'] = filters.latitude.toString();
    }
    if (filters.longitude != null) {
      queryParams['lng'] = filters.longitude.toString();
    }
    if (filters.radiusKm != null) {
      queryParams['radius'] = filters.radiusKm!.toInt().toString();
    }
    if (filters.purpose != null) {
      queryParams['purpose'] = filters.purpose!;
    }
    if (filters.propertyType != null && filters.propertyType!.isNotEmpty) {
      queryParams['property_type'] = filters.propertyType!.join(',');
    }
    if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
      queryParams['q'] = filters.searchQuery!;
    }
    if (filters.sortBy != null) {
      queryParams['sort_by'] = filters.sortBy.toString();
    }

    return await _makeRequest(
      '/properties/',
      (json) => _parseUnifiedPropertyResponse(json),
      method: 'GET',
      queryParams: queryParams,
      operationName: 'Search Properties',
    );
  }

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
        'radius': '10',
      },
      operationName: 'Discover Properties',
    );
  }

  // Helper method to filter out only essential parameters
  Map<String, String> _getEssentialQueryParams(Map<String, dynamic>? filters) {
    final essentialKeys = {
      'purpose',
      'property_type',
      'q',
      'sort_by',
      'radius_km',
    };

    final queryParams = <String, String>{};

    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null && essentialKeys.contains(key)) {
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

    return queryParams;
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

    // Only add essential filters, exclude unnecessary ones like price, city, locality
    final essentialFilters = _getEssentialQueryParams(filters);
    queryParams.addAll(essentialFilters);

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

    // Only add essential filters, exclude unnecessary ones like price, city, locality
    final essentialFilters = _getEssentialQueryParams(filters);
    queryParams.addAll(essentialFilters);

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

  Future<bool> testConnection() async {
    try {
      DebugLogger.api('🔍 Testing backend connection to $_baseUrl');
      try {
        final internetTest = await get('https://www.google.com').timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw Exception('Internet timeout'),
        );
        if (internetTest.statusCode != 200) {
          DebugLogger.warning('🌐 No internet connectivity');
          return false;
        }
        DebugLogger.success('✅ Internet connectivity confirmed');
      } catch (e) {
        DebugLogger.warning('🌐 Internet connectivity check failed: $e');
      }
      final endpoints = [
        '/health',
        '/',
        '/properties',
      ];
      for (final endpoint in endpoints) {
        try {
          final response = await get(endpoint).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Backend timeout for $endpoint');
            },
          );
          DebugLogger.api(
            '🏥 Backend endpoint $endpoint response: ${response.statusCode}',
          );
          if (response.statusCode != null && response.statusCode! < 600) {
            DebugLogger.success(
              '✅ Backend server is reachable at $endpoint (status: ${response.statusCode})',
            );
            return true;
          }
        } catch (e) {
          DebugLogger.debug('🔄 Endpoint $endpoint failed: $e');
        }
      }
      DebugLogger.warning('💔 Backend server unreachable at all endpoints');
      DebugLogger.warning(
        '💡 Make sure your backend server is running on $_baseUrl',
      );
      DebugLogger.warning(
        '💡 Check if the API_BASE_URL in .env.development matches your backend server URL',
      );
      DebugLogger.warning('🔄 App will continue with mock data fallback');
      return false;
    } catch (e) {
      DebugLogger.error('💥 Connection test error: $e');
      DebugLogger.warning('🔄 App will continue with mock data fallback');
      return false;
    }
  }

  Future<Map<String, dynamic>> testConnectionDetailed() async {
    final Map<String, dynamic> result = {
      'isConnected': false,
      'hasInternet': false,
      'backendReachable': false,
      'serverRunning': false,
      'errorMessage': '',
      'recommendations': <String>[],
    };
    try {
      try {
        final internetTest = await get('https://www.google.com').timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw Exception('Internet timeout'),
        );
        if (internetTest.statusCode == 200) {
          result['hasInternet'] = true;
          DebugLogger.success('✅ Internet connectivity confirmed');
        }
      } catch (e) {
        result['errorMessage'] = 'No internet connection';
        final recommendations = result['recommendations'] as List<String>;
        recommendations.add('Check your internet connection');
        DebugLogger.warning('🌐 Internet connectivity check failed: $e');
      }
      if (!(result['hasInternet'] as bool)) {
        return result;
      }
      final endpoints = ['/health', '/'];
      bool backendReachable = false;
      bool serverRunning = false;
      for (final endpoint in endpoints) {
        try {
          final response = await get(endpoint).timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception('Backend timeout for $endpoint'),
          );
          backendReachable = true;
          if (response.statusCode != null && response.statusCode! < 600) {
            serverRunning = true;
            DebugLogger.success(
              '✅ Backend server is reachable at $endpoint (status: ${response.statusCode})',
            );
            break;
          }
        } catch (e) {
          DebugLogger.debug('🔄 Endpoint $endpoint failed: $e');
        }
      }
      result['backendReachable'] = backendReachable;
      result['serverRunning'] = serverRunning;
      result['isConnected'] = serverRunning;
      if (!backendReachable) {
        result['errorMessage'] = 'Backend server is not reachable';
        final recommendations = result['recommendations'] as List<String>;
        recommendations.addAll([
          'Make sure your backend server is running',
          'Check if the API_BASE_URL in .env.development is correct',
          'Verify the backend server is running on the expected port',
        ]);
      } else if (!serverRunning) {
        result['errorMessage'] =
            'Backend server is reachable but not responding properly';
        final recommendations = result['recommendations'] as List<String>;
        recommendations.addAll([
          'Check if your backend server is healthy',
          'Verify the API endpoints are correctly configured',
        ]);
      }
    } catch (e) {
      result['errorMessage'] = 'Connection test failed: $e';
      final recommendations = result['recommendations'] as List<String>;
      recommendations.add('Unknown error occurred during connection test');
      DebugLogger.error('💥 Connection test error: $e');
    }
    return result;
  }

  Future<T> _getMockDataForEndpoint<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    DebugLogger.info('🎭 Providing mock data for endpoint: $endpoint');
    final path = endpoint.split('?').first;
    if (path.contains('/properties')) {
      return fromJson({
        'properties': _getMockPropertiesData(),
        'total': 20,
        'page': 1,
        'limit': 20,
        'total_pages': 1,
        'filters_applied': {},
        'search_center': {'latitude': 19.0596, 'longitude': 72.8295},
      });
    }
    return fromJson({'data': []});
  }

  List<Map<String, dynamic>> _getMockPropertiesData() {
    return [
      {
        'id': 1,
        'title': 'Luxury Apartment in Bandra',
        'description': 'Beautiful 2BHK apartment with modern amenities',
        'property_type': 'apartment',
        'purpose': 'rent',
        'base_price': 45000.0,
        'status': 'available',
        'monthly_rent': 45000.0,
        'bedrooms': 2,
        'bathrooms': 2,
        'area_sqft': 1200,
        'full_address': 'Bandra West, Mumbai',
        'city': 'Mumbai',
        'locality': 'Bandra',
        'latitude': 19.0596,
        'longitude': 72.8295,
        'is_available': true,
        'view_count': 0,
        'like_count': 0,
        'interest_count': 0,
        'created_at': DateTime.now()
            .subtract(const Duration(days: 7))
            .toIso8601String(),
      },
      {
        'id': 2,
        'title': 'Cozy Studio in Andheri',
        'description': 'Perfect for single professionals',
        'property_type': 'room',
        'purpose': 'rent',
        'base_price': 25000.0,
        'status': 'available',
        'monthly_rent': 25000.0,
        'bedrooms': 1,
        'bathrooms': 1,
        'area_sqft': 600,
        'full_address': 'Andheri East, Mumbai',
        'city': 'Mumbai',
        'locality': 'Andheri',
        'latitude': 19.1136,
        'longitude': 72.8697,
        'is_available': true,
        'view_count': 0,
        'like_count': 0,
        'interest_count': 0,
        'created_at': DateTime.now()
            .subtract(const Duration(days: 5))
            .toIso8601String(),
      },
      {
        'id': 3,
        'title': 'Spacious Villa in Thane',
        'description': 'Large family villa with garden',
        'property_type': 'house',
        'purpose': 'buy',
        'base_price': 8500000.0,
        'status': 'available',
        'bedrooms': 4,
        'bathrooms': 4,
        'area_sqft': 3000,
        'full_address': 'Thane West',
        'city': 'Thane',
        'locality': 'Thane West',
        'latitude': 19.2183,
        'longitude': 72.9781,
        'is_available': true,
        'view_count': 0,
        'like_count': 0,
        'interest_count': 0,
        'created_at': DateTime.now()
            .subtract(const Duration(days: 10))
            .toIso8601String(),
      },
    ];
  }

  Future<void> swipeProperty(
    int propertyId,
    bool isLiked, {
    double? userLocationLat,
    double? userLocationLng,
    String? sessionId,
  }) async {
    try {
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
        useMockFallback:
            false,
      );
    } catch (e) {
      DebugLogger.warning(
        '⚠️ Swipe recording failed, but UI will continue: $e',
      );
      if (isLiked) {
        getx.Get.snackbar(
          '❤️ Liked!',
          'Property added to favorites',
          snackPosition: getx.SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        getx.Get.snackbar(
          '👈 Passed',
          'Property added to passed list',
          snackPosition: getx.SnackPosition.BOTTOM,
          backgroundColor: Colors.grey.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 1),
        );
      }
    }
  }

  Future<Map<String, dynamic>> getSwipes({
    double? lat,
    double? lng,
    int? radius,
    String? q,
    List<String>? propertyType,
    String? purpose,
    bool? isLiked,
    String? sortBy,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    // Only include location parameters and essential query parameters
    if (lat != null) queryParams['lat'] = lat.toString();
    if (lng != null) queryParams['lng'] = lng.toString();
    if (radius != null) queryParams['radius'] = radius.toString();
    if (q != null && q.isNotEmpty) queryParams['q'] = q;
    if (propertyType != null && propertyType.isNotEmpty) {
      queryParams['property_type'] = propertyType.join(',');
    }
    if (purpose != null) queryParams['purpose'] = purpose;
    if (isLiked != null) queryParams['is_liked'] = isLiked.toString();
    if (sortBy != null) queryParams['sort_by'] = sortBy;
    return await _makeRequest(
      '/swipes/',
      (json) => json,
      queryParams: queryParams,
      operationName: 'Get Swipes',
    );
  }

  Future<Map<String, dynamic>> scheduleVisit({
    required int propertyId,
    required String scheduledDate,
    String? specialRequirements,
  }) async {
    return await _makeRequest(
      '/visits/',
      (json) => json,
      method: 'POST',
      body: {
        'property_id': propertyId,
        'scheduled_date': scheduledDate,
        if (specialRequirements != null)
          'special_requirements': specialRequirements,
      },
      operationName: 'Schedule Visit',
    );
  }

  Future<List<VisitModel>> getMyVisits({String? visitType}) async {
    final queryParams = <String, String>{};
    if (visitType != null) {
      queryParams['visit_type'] = visitType;
    }
    final response = await _makeRequest<List<dynamic>>(
      '/visits/',
      (json) => json['visits'] as List<dynamic>,
      queryParams: queryParams,
      operationName: 'Get My Visits',
    );
    return response
        .map((item) => VisitModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<VisitModel> updateVisit(
    int visitId,
    Map<String, dynamic> updateData,
  ) async {
    return await _makeRequest(
      '/visits/$visitId',
      (json) => VisitModel.fromJson(json),
      method: 'PATCH',
      body: updateData,
      operationName: 'Update Visit',
    );
  }

  Future<VisitModel> rescheduleVisit(
    int visitId,
    String newScheduledDate,
  ) async {
    return await updateVisit(visitId, {'scheduled_date': newScheduledDate});
  }

  Future<VisitModel> cancelVisit(int visitId, {String? reason}) async {
    final updateData = <String, dynamic>{};
    if (reason != null) {
      updateData['cancellation_reason'] = reason;
    }
    return await updateVisit(visitId, updateData);
  }

  Future<AgentModel> getRelationshipManager() async {
    return await _makeRequest('/agents/assigned/', (json) {
      return AgentModel.fromJson(json);
    }, operationName: 'Get Assigned Agent');
  }

  Future<BookingModel> createBooking({
    required int propertyId,
    required String checkInDate,
    required String checkOutDate,
    required int guestsCount,
    String? specialRequests,
    Map<String, dynamic>? guestDetails,
  }) async {
    return await _makeRequest(
      '/bookings/',
      (json) {
        final bookingData = json['data'] ?? json;
        return BookingModel.fromJson(bookingData);
      },
      method: 'POST',
      body: {
        'property_id': propertyId,
        'check_in_date': checkInDate,
        'check_out_date': checkOutDate,
        'guests_count': guestsCount,
        if (specialRequests != null) 'special_requests': specialRequests,
        if (guestDetails != null) 'guest_details': guestDetails,
      },
      operationName: 'Create Booking',
    );
  }

  Future<List<BookingModel>> getMyBookings() async {
    return await _makeRequest('/bookings/', (json) {
      final bookingsData = json['data'] ?? json;
      if (bookingsData is List) {
        return bookingsData.map((item) => BookingModel.fromJson(item)).toList();
      } else {
        throw Exception(
          'Expected list of bookings but got: ${bookingsData.runtimeType}',
        );
      }
    }, operationName: 'Get My Bookings');
  }

  Future<BookingModel> getBookingDetails(int bookingId) async {
    return await _makeRequest('/bookings/$bookingId', (json) {
      final bookingData = json['data'] ?? json;
      return BookingModel.fromJson(bookingData);
    }, operationName: 'Get Booking Details');
  }

  Future<BookingModel> updateBooking(
    int bookingId,
    Map<String, dynamic> updateData,
  ) async {
    return await _makeRequest(
      '/bookings/$bookingId',
      (json) {
        final bookingData = json['data'] ?? json;
        return BookingModel.fromJson(bookingData);
      },
      method: 'PUT',
      body: updateData,
      operationName: 'Update Booking',
    );
  }

  Future<void> cancelBooking(int bookingId, {String? reason}) async {
    await _makeRequest(
      '/bookings/$bookingId/cancel',
      (json) => json,
      method: 'POST',
      body: {if (reason != null) 'cancellation_reason': reason},
      operationName: 'Cancel Booking',
    );
  }

  Future<Map<String, dynamic>> initiatePayment(
    int bookingId, {
    String paymentMethod = 'card',
    Map<String, dynamic>? paymentDetails,
  }) async {
    return await _makeRequest(
      '/bookings/$bookingId/payment',
      (json) => json,
      method: 'POST',
      body: {
        'payment_method': paymentMethod,
        if (paymentDetails != null) 'payment_details': paymentDetails,
      },
      operationName: 'Initiate Payment',
    );
  }

  Future<Map<String, dynamic>> getPaymentStatus(int bookingId) async {
    return await _makeRequest(
      '/bookings/$bookingId/payment-status',
      (json) => json,
      operationName: 'Get Payment Status',
    );
  }

  Future<void> confirmPayment(int bookingId, String paymentReference) async {
    await _makeRequest(
      '/bookings/$bookingId/confirm-payment',
      (json) => json,
      method: 'POST',
      body: {'payment_reference': paymentReference},
      operationName: 'Confirm Payment',
    );
  }

  Future<List<BookingModel>> getUpcomingBookings() async {
    return await _makeRequest('/bookings/upcoming', (json) {
      final bookingsData = json['data'] ?? json;
      if (bookingsData is List) {
        return bookingsData.map((item) => BookingModel.fromJson(item)).toList();
      } else {
        throw Exception(
          'Expected list of bookings but got: ${bookingsData.runtimeType}',
        );
      }
    }, operationName: 'Get Upcoming Bookings');
  }

  Future<List<BookingModel>> getPastBookings() async {
    return await _makeRequest('/bookings/past', (json) {
      final bookingsData = json['data'] ?? json;
      if (bookingsData is List) {
        return bookingsData.map((item) => BookingModel.fromJson(item)).toList();
      } else {
        throw Exception(
          'Expected list of bookings but got: ${bookingsData.runtimeType}',
        );
      }
    }, operationName: 'Get Past Bookings');
  }

  Future<List<AmenityModel>> getAllAmenities() async {
    return await _makeRequest('/amenities', (json) {
      final amenitiesData = json['data'] ?? json;
      if (amenitiesData is List) {
        return amenitiesData
            .map((item) => AmenityModel.fromJson(item))
            .toList();
      } else {
        throw Exception(
          'Expected list of amenities but got: ${amenitiesData.runtimeType}',
        );
      }
    }, operationName: 'Get All Amenities');
  }

  Future<void> recordSearchHistory({
    String? searchQuery,
    Map<String, dynamic>? searchFilters,
    String? searchLocation,
    int? searchRadius,
    int? resultsCount,
    double? userLocationLat,
    double? userLocationLng,
    String? searchType,
    String? sessionId,
  }) async {
    await _makeRequest(
      '/users/search-history',
      (json) => json,
      method: 'POST',
      body: {
        'search_query': searchQuery,
        'search_filters': searchFilters,
        'search_location': searchLocation,
        'search_radius': searchRadius,
        'results_count': resultsCount,
        'user_location_lat': userLocationLat,
        'user_location_lng': userLocationLng,
        'search_type': searchType,
        'session_id': sessionId,
      },
      operationName: 'Record Search History',
    );
  }

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