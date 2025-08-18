import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart' as getx;
import '../models/property_model.dart';
import '../models/user_model.dart';
import '../models/visit_model.dart';
import '../models/booking_model.dart';
import '../models/unified_property_response.dart';
import '../models/unified_filter_model.dart';
import '../models/agent_model.dart';
import '../models/swipe_history_model.dart';
import '../models/amenity_model.dart';
import '../models/api_response_models.dart';
import '../../utils/debug_logger.dart';
import '../../utils/error_handler.dart';

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
        upcoming: safeJson['upcoming'] ?? visits.where((v) => v.isUpcoming).length,
        completed: safeJson['completed'] ?? visits.where((v) => v.isCompleted).length,
        cancelled: safeJson['cancelled'] ?? visits.where((v) => v.isCancelled).length,
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
  
  late final String _baseUrl;
  late final SupabaseClient _supabase;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeService();
    httpClient.baseUrl = _baseUrl;
    
    // Request modifier to add authentication token
    httpClient.addRequestModifier<Object?>((request) async {
      final token = await _authToken;
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
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
          if (newToken != null) {
            request.headers['Authorization'] = 'Bearer $newToken';
            // Retry the request
            return await httpClient.request(
              request.url.toString(),
              request.method,
              headers: request.headers,
              body: request.files,
            );
          }
        } catch (e) {
          DebugLogger.error('Token refresh failed', e);
          _handleAuthenticationFailure();
        }
      }
      return response;
    });
  }

  Future<void> _initializeService() async {
    try {
      // Initialize environment variables - use root URL for GetConnect
      final fullApiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      // Extract base URL without /api/v1 for GetConnect
      _baseUrl = fullApiUrl.replaceAll('/api/v1', '');
      DebugLogger.startup('API Service initialized with base URL: $_baseUrl');
      
      // Check if Supabase is already initialized
      try {
        _supabase = Supabase.instance.client;
        DebugLogger.success('Supabase client found');
      } catch (e) {
        DebugLogger.warning('Supabase not initialized, attempting to initialize...');
        // Initialize Supabase if not already initialized
        await Supabase.initialize(
          url: dotenv.env['SUPABASE_URL'] ?? '',
          anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
        );
        _supabase = Supabase.instance.client;
        DebugLogger.success('Supabase initialized successfully');
      }
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
    
    // Log JWT Token for debugging
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


  /// Handles authentication failure by redirecting to login
  void _handleAuthenticationFailure() {
    DebugLogger.auth('🚪 Authentication failed: redirecting to login');
    
    // Clear the current session
    _supabase.auth.signOut();
    
    // Navigate to login screen
    // Use GetX navigation to redirect to login
    try {
      if (getx.Get.currentRoute != '/login' && getx.Get.currentRoute != '/onboarding') {
        getx.Get.offAllNamed('/onboarding');
        
        // Show user-friendly message
        getx.Get.snackbar(
          'Session Expired',
          'Please log in again to continue',
          snackPosition: getx.SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      DebugLogger.error('❌ Navigation error during auth failure: $e');
    }
  }

  Future<T> _makeRequest<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    int retries = 1,
    String? operationName,
  }) async {
    Exception? lastException;
    final operation = operationName ?? '$method $endpoint';
    
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        // Prepend /api/v1 to all endpoints
        final fullEndpoint = '/api/v1$endpoint';
        
        DebugLogger.logAPIRequest(
          method: method,
          endpoint: fullEndpoint,
          body: body,
        );

        getx.Response response;

        switch (method.toUpperCase()) {
          case 'GET':
            response = await get(fullEndpoint, query: queryParams);
            break;
          case 'POST':
            response = await post(fullEndpoint, body, query: queryParams);
            break;
          case 'PUT':
            response = await put(fullEndpoint, body, query: queryParams);
            break;
          case 'DELETE':
            response = await delete(fullEndpoint, query: queryParams);
            break;
          default:
            throw Exception('Unsupported HTTP method: $method');
        }

        // Log response
        DebugLogger.logAPIResponse(
          statusCode: response.statusCode ?? 0,
          endpoint: fullEndpoint,
          body: response.bodyString ?? '',
        );

        if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
          final responseData = response.body;
          if (responseData is Map<String, dynamic>) {
            return fromJson(responseData);
          } else if (responseData is List) {
            // Normalize bare list payloads to a map shape
            return fromJson({'data': responseData});
          } else {
            return fromJson({'data': responseData});
          }
        } else if (response.statusCode == 401) {
          // Token expired - the response interceptor will handle this
          DebugLogger.auth('🔒 Authentication failed for $operation');
          throw ApiAuthException('Authentication failed', statusCode: 401);
        } else if (response.statusCode == 403) {
          DebugLogger.auth('🚫 Access forbidden for $operation');
          throw ApiAuthException('Access forbidden', statusCode: 403);
        } else if (response.statusCode! >= 500 && attempt < retries) {
          // Server error - retry
          DebugLogger.warning('🔄 Server error (${response.statusCode}) for $operation, retrying... (${attempt + 1}/$retries)');
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          continue;
        } else {
          // Use ErrorHandler for comprehensive error handling
          final errorMessage = 'HTTP ${response.statusCode}: ${response.statusText ?? 'Unknown error'}';
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
        
        // If it's an auth exception, don't retry
        if (e is ApiAuthException) {
          DebugLogger.auth('🔒 Authentication error for $operation: $e');
          rethrow;
        }
        
        // If this is the last attempt, handle with ErrorHandler
        if (attempt == retries) {
          DebugLogger.error('💥 API Request failed for $operation after ${attempt + 1} attempts: $e');
          
          // Use ErrorHandler for comprehensive error categorization
          ErrorHandler.handleNetworkError(e);
          rethrow;
        }
        
        // Wait before retry
        DebugLogger.warning('🔄 Request failed for $operation, retrying... (${attempt + 1}/$retries)');
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }
    
    throw lastException ?? Exception('Unknown error occurred for $operation');
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
      DebugLogger.api('📊 Raw JSON: $json');
      rethrow;
    }
  }

  // Helper method for safer property model parsing
  static PropertyModel _parsePropertyModel(Map<String, dynamic> json) {
    try {
      // Normalize fields that may vary in type from different backends
      final Map<String, dynamic> safeJson = Map<String, dynamic>.from(json);

      // Features should remain as List, no conversion needed
      if (safeJson['calendar_data'] is List) {
        safeJson['calendar_data'] = <String, dynamic>{};
      }

      // Ensure numeric fields are parsed as double when provided as int/strings
      double? _toDouble(dynamic v) {
        if (v == null) return null;
        if (v is num) return v.toDouble();
        if (v is String) return double.tryParse(v);
        return null;
      }
      if (safeJson.containsKey('base_price')) {
        safeJson['base_price'] = _toDouble(safeJson['base_price']) ?? 0.0;
      }
      if (safeJson.containsKey('price_per_sqft')) {
        safeJson['price_per_sqft'] = _toDouble(safeJson['price_per_sqft']);
      }
      if (safeJson.containsKey('monthly_rent')) {
        safeJson['monthly_rent'] = _toDouble(safeJson['monthly_rent']);
      }
      if (safeJson.containsKey('daily_rate')) {
        safeJson['daily_rate'] = _toDouble(safeJson['daily_rate']);
      }
      if (safeJson.containsKey('security_deposit')) {
        safeJson['security_deposit'] = _toDouble(safeJson['security_deposit']);
      }
      if (safeJson.containsKey('maintenance_charges')) {
        safeJson['maintenance_charges'] = _toDouble(safeJson['maintenance_charges']);
      }

      // Validate critical fields before parsing
      _validatePropertyJson(json);
      return PropertyModel.fromJson(safeJson);
    } catch (e) {
      DebugLogger.error('❌ Error parsing property model: $e');
      DebugLogger.api('📊 Raw JSON: $json');
      
      // Log specific field issues
      if (json['id'] == null) DebugLogger.error('🚫 Missing required field: id');
      if (json['title'] == null) DebugLogger.error('🚫 Missing required field: title');
      if (json['property_type'] == null) DebugLogger.error('🚫 Missing required field: property_type');
      if (json['purpose'] == null) DebugLogger.error('🚫 Missing required field: purpose');
      
      rethrow;
    }
  }
  
  // Validate property JSON before parsing
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

  // Helper method for parsing unified property response
  static UnifiedPropertyResponse _parseUnifiedPropertyResponse(Map<String, dynamic> json) {
    try {
      final Map<String, dynamic> safeJson = Map<String, dynamic>.from(json);

      // Accept multiple shapes: { properties: [...] }, { data: [...] }, or nested common keys
      dynamic rawList = safeJson['properties'] ?? safeJson['data'] ?? safeJson['results'] ?? safeJson['items'];
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

      // Metadata with safe fallbacks
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
      DebugLogger.api('📊 Raw JSON: $json');
      rethrow;
    }
  }
  

  // Authentication Methods
  Future<AuthResponse> signUp(String email, String password, {
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
      // Handle both direct user object and wrapped response
      final userData = json['data'] ?? json;
      return _parseUserModel(userData);
    }, operationName: 'Get Current User');
  }


  // User Management
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


  // Unified property search method that supports all filters
  Future<UnifiedPropertyResponse> searchProperties({
    required UnifiedFilterModel filters,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    // Convert filters to query parameters
    final filterMap = filters.toJson();
    filterMap.forEach((key, value) {
      if (value != null) {
        if (value is List) {
          // Handle list parameters (like amenities, property_type)
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
      operationName: 'Search Properties',
    );
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
        'sort_by': 'distance',
      },
      operationName: 'Discover Properties',
    );
  }

  Future<UnifiedPropertyResponse> exploreProperties({
    required double latitude,
    required double longitude,
    double radiusKm = 5,
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
      'sort_by': 'distance',
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
      if (value != null && key != 'radius_km') { // Skip radius_km as we already added it as 'radius'
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
    return await _makeRequest(
      '/properties/$propertyId',
      (json) {
        final propertyData = json['data'] ?? json;
        return _parsePropertyModel(propertyData);
      },
      operationName: 'Get Property Details',
    );
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
      final isReachable = response.statusCode == 200 || 
                         response.statusCode == 404 || 
                         response.statusCode == 405;
      
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
        final isReachable = response.statusCode == 200 || 
                           response.statusCode == 404 || 
                           response.statusCode == 405;
                           
        if (isReachable) {
          DebugLogger.success('✅ Backend server is reachable via alternative test (status: ${response.statusCode})');
        }
        
        return isReachable;
      } catch (e2) {
        DebugLogger.warning('💔 Backend server unreachable: $e2');
        return false;
      }
    }
  }

  // Swipe System
  Future<SwipeHistoryItem> swipeProperty(int propertyId, bool isLiked, {
    double? userLocationLat,
    double? userLocationLng,
    String? sessionId,
  }) async {
    return await _makeRequest(
      '/swipes/',
      (json) => SwipeHistoryItem.fromJson(json['data'] ?? json),
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

  // Get swipes with pagination and property details
  Future<SwipeHistory> getSwipes({
    bool? isLiked,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    if (isLiked != null) {
      queryParams['is_liked'] = isLiked.toString();
    }

    return await _makeRequest(
      '/swipes/',
      (json) => SwipeHistory.fromJson(json),
      queryParams: queryParams,
      operationName: 'Get Swipes',
    );
  }


  Future<Map<String, dynamic>> getSwipeStats() async {
    return await _makeRequest('/swipes/stats', (json) => json, operationName: 'Get Swipe Stats');
  }

  Future<Map<String, dynamic>> toggleSwipeStatus(int swipeId) async {
    return await _makeRequest(
      '/swipes/$swipeId/toggle',
      (json) => json,
      method: 'PUT',
      operationName: 'Toggle Swipe Status',
    );
  }

  // Location Services


  // Visit Scheduling
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
        if (specialRequirements != null) 'special_requirements': specialRequirements,
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

    // Convert the list to VisitModel objects
    return response.map((item) => VisitModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  

  // Generic method to update visit (reschedule or cancel)
  Future<VisitModel> updateVisit(int visitId, Map<String, dynamic> updateData) async {
    return await _makeRequest(
      '/visits/$visitId',
      (json) => VisitModel.fromJson(json),
      method: 'PATCH',
      body: updateData,
      operationName: 'Update Visit',
    );
  }

  // Convenience method for rescheduling
  Future<VisitModel> rescheduleVisit(int visitId, String newScheduledDate) async {
    return await updateVisit(visitId, {'scheduled_date': newScheduledDate});
  }

  // Convenience method for cancelling  
  Future<VisitModel> cancelVisit(int visitId, {String? reason}) async {
    final updateData = <String, dynamic>{};
    if (reason != null) {
      updateData['cancellation_reason'] = reason;
    }
    return await updateVisit(visitId, updateData);
  }

  Future<AgentModel> getRelationshipManager() async {
    return await _makeRequest(
      '/agents/assigned/',
      (json) {
        // The API returns the agent object directly, not wrapped in 'data'
        return AgentModel.fromJson(json);
      },
      operationName: 'Get Assigned Agent',
    );
  }


  // Booking System APIs
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
    return await _makeRequest(
      '/bookings/',
      (json) {
        final bookingsData = json['data'] ?? json;
        
        if (bookingsData is List) {
          return bookingsData.map((item) => BookingModel.fromJson(item)).toList();
        } else {
          throw Exception('Expected list of bookings but got: ${bookingsData.runtimeType}');
        }
      },
      operationName: 'Get My Bookings',
    );
  }

  Future<BookingModel> getBookingDetails(int bookingId) async {
    return await _makeRequest(
      '/bookings/$bookingId',
      (json) {
        final bookingData = json['data'] ?? json;
        return BookingModel.fromJson(bookingData);
      },
      operationName: 'Get Booking Details',
    );
  }

  Future<BookingModel> updateBooking(int bookingId, Map<String, dynamic> updateData) async {
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
      body: {
        if (reason != null) 'cancellation_reason': reason,
      },
      operationName: 'Cancel Booking',
    );
  }

  Future<Map<String, dynamic>> initiatePayment(int bookingId, {
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
      body: {
        'payment_reference': paymentReference,
      },
      operationName: 'Confirm Payment',
    );
  }

  Future<List<BookingModel>> getUpcomingBookings() async {
    return await _makeRequest(
      '/bookings/upcoming',
      (json) {
        final bookingsData = json['data'] ?? json;
        
        if (bookingsData is List) {
          return bookingsData.map((item) => BookingModel.fromJson(item)).toList();
        } else {
          throw Exception('Expected list of bookings but got: ${bookingsData.runtimeType}');
        }
      },
      operationName: 'Get Upcoming Bookings',
    );
  }

  Future<List<BookingModel>> getPastBookings() async {
    return await _makeRequest(
      '/bookings/past',
      (json) {
        final bookingsData = json['data'] ?? json;
        
        if (bookingsData is List) {
          return bookingsData.map((item) => BookingModel.fromJson(item)).toList();
        } else {
          throw Exception('Expected list of bookings but got: ${bookingsData.runtimeType}');
        }
      },
      operationName: 'Get Past Bookings',
    );
  }

  // Amenities Management
  Future<List<AmenityModel>> getAllAmenities() async {
    return await _makeRequest(
      '/amenities',
      (json) {
        final amenitiesData = json['data'] ?? json;
        
        if (amenitiesData is List) {
          return amenitiesData.map((item) => AmenityModel.fromJson(item)).toList();
        } else {
          throw Exception('Expected list of amenities but got: ${amenitiesData.runtimeType}');
        }
      },
      operationName: 'Get All Amenities',
    );
  }
  // User Search History
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
    return await _makeRequest(
      '/users/notification-settings',
      (json) {
        final settingsData = json['data'] ?? json;
        return NotificationSettings.fromJson(settingsData);
      },
      operationName: 'Get Notification Settings',
    );
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
    return await _makeRequest(
      '/users/privacy-settings',
      (json) {
        final settingsData = json['data'] ?? json;
        return PrivacySettings.fromJson(settingsData);
      },
      operationName: 'Get Privacy Settings',
    );
  }


}