import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart' as getx;
import '../models/property_model.dart';
import '../models/user_model.dart';
import '../models/visit_model.dart';
import '../models/booking_model.dart';
import '../models/unified_property_response.dart';
import '../models/unified_filter_model.dart';
import '../models/analytics_models.dart';
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
        } catch (e, stackTrace) {
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
      } catch (e, stackTrace) {
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
            _syncUserProfile();
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
    DebugLogger.auth('🚪 Authentication failed - redirecting to login');
    
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
    } catch (e, stackTrace) {
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
      } catch (e, stackTrace) {
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

  // Helper method for safer type conversion
  static Map<String, dynamic> _safeConvertToMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is Map) {
      return Map<String, dynamic>.from(data);
    } else {
      return {'data': data};
    }
  }

  // Helper method for safer user model parsing
  static UserModel _parseUserModel(Map<String, dynamic> json) {
    try {
      final safeJson = Map<String, dynamic>.from(json);
      
      // Handle ID conversion
      if (safeJson['id'] is int) {
        safeJson['id'] = safeJson['id'].toString();
      }
      
      // Ensure required fields have defaults
      safeJson['name'] ??= '';
      safeJson['email'] ??= '';
      safeJson['phone'] ??= '';
      safeJson['profile_image'] ??= '';
      
      // Handle preferences
      if (safeJson['preferences'] is! Map) {
        safeJson['preferences'] = <String, dynamic>{};
      }
      
      return UserModel.fromJson(safeJson);
    } catch (e, stackTrace) {
      DebugLogger.error('❌ Error parsing user model: $e');
      DebugLogger.api('📊 Raw JSON: $json');
      rethrow;
    }
  }

  // Helper method for safer property model parsing
  static PropertyModel _parsePropertyModel(Map<String, dynamic> json) {
    try {
      // Validate critical fields before parsing
      _validatePropertyJson(json);
      return PropertyModel.fromJson(json);
    } catch (e, stackTrace) {
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
      // Enhanced error handling for property list parsing
      if (json['properties'] is List) {
        final propertiesList = json['properties'] as List;
        final validProperties = <Map<String, dynamic>>[];
        int failedCount = 0;
        
        for (int i = 0; i < propertiesList.length; i++) {
          final propertyData = propertiesList[i];
          if (propertyData is Map<String, dynamic>) {
            try {
              // Test parsing each property individually
              _validatePropertyJson(propertyData);
              validProperties.add(propertyData);
            } catch (e, stackTrace) {
              failedCount++;
              DebugLogger.warning('⚠️ Skipping property at index $i due to parsing error: $e');
              continue;
            }
          } else {
            failedCount++;
            DebugLogger.warning('⚠️ Skipping invalid property data at index $i');
          }
        }
        
        if (failedCount > 0) {
          DebugLogger.warning('⚠️ Failed to parse $failedCount out of ${propertiesList.length} properties');
        }
        
        // Replace with validated properties
        json['properties'] = validProperties;
      }
      
      return UnifiedPropertyResponse.fromJson(json);
    } catch (e, stackTrace) {
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

    if (response.user != null) {
      await _syncUserProfile();
    }

    return response;
  }

  Future<AuthResponse> signIn(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user != null) {
      await _syncUserProfile();
    }

    return response;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<Map<String, dynamic>> checkSession() async {
    return await _makeRequest('/auth/session', (json) => json, operationName: 'Check Session');
  }

  Future<UserModel> getCurrentUser() async {
    return await _makeRequest('/auth/me', (json) {
      // Handle both direct user object and wrapped response
      final userData = json['data'] ?? json;
      return _parseUserModel(userData);
    }, operationName: 'Get Current User');
  }

  Future<void> _syncUserProfile() async {
    try {
      DebugLogger.api('🔄 Syncing user profile with backend...');
      await _makeRequest('/auth/sync', (json) => json, method: 'POST', operationName: 'Sync User Profile');
      DebugLogger.success('✅ User profile synced successfully');
    } catch (e, stackTrace) {
      DebugLogger.error('❌ Failed to sync user profile: $e');
    }
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

  Future<List<PropertyModel>> getLikedProperties() async {
    return await _makeRequest(
      '/users/liked-properties',
      (json) {
        final propertiesData = json['data'] ?? json;
        
        if (propertiesData is List) {
          return propertiesData.map((item) => _parsePropertyModel(item)).toList();
        } else {
          throw Exception('Expected list of properties but got: ${propertiesData.runtimeType}');
        }
      },
      operationName: 'Get Liked Properties',
    );
  }
  
  Future<List<PropertyModel>> getDislikedProperties() async {
    return await _makeRequest(
      '/users/disliked-properties',
      (json) {
        final propertiesData = json['data'] ?? json;
        
        if (propertiesData is List) {
          return propertiesData.map((item) => _parsePropertyModel(item)).toList();
        } else {
          throw Exception('Expected list of properties but got: ${propertiesData.runtimeType}');
        }
      },
      operationName: 'Get Disliked Properties',
    );
  }

  // Unified property search method that supports all filters
  Future<UnifiedPropertyResponse> searchProperties({
    required UnifiedFilterModel filters,
    int page = 1,
    int limit = 20,
  }) async {
    return await _makeRequest(
      '/properties/search',
      (json) => _parseUnifiedPropertyResponse(json),
      method: 'POST',
      queryParams: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
      body: filters.toJson(),
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
      '/properties/search',
      (json) => _parseUnifiedPropertyResponse(json),
      method: 'POST',
      queryParams: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
      body: {
        'latitude': latitude,
        'longitude': longitude,
        'radius_km': 10, // Large radius for discovery
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
    final body = {
      'latitude': latitude,
      'longitude': longitude,
      'radius_km': radiusKm.toInt(),
      'sort_by': 'distance',
      ...?filters,
    };

    return await _makeRequest(
      '/properties/search',
      (json) => _parseUnifiedPropertyResponse(json),
      method: 'POST',
      queryParams: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
      body: body,
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
    final body = {
      'latitude': latitude,
      'longitude': longitude,
      'radius_km': filters['radius_km'] ?? 10,
      ...filters,
    };

    return await _makeRequest(
      '/properties/search',
      (json) => _parseUnifiedPropertyResponse(json),
      method: 'POST',
      queryParams: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
      body: body,
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

  Future<List<PropertyModel>> getPropertyRecommendations({int limit = 10}) async {
    return await _makeRequest(
      '/properties/recommendations',
      (json) {
        final propertiesData = json['data'] ?? json;
        
        if (propertiesData is List) {
          return propertiesData.map((item) => _parsePropertyModel(item)).toList();
        } else {
          throw Exception('Expected list of properties but got: ${propertiesData.runtimeType}');
        }
      },
      queryParams: {'limit': limit.toString()},
      operationName: 'Get Property Recommendations',
    );
  }

  Future<void> showPropertyInterest(int propertyId, {
    required String interestType,
    String? message,
    String? preferredTime,
  }) async {
    await _makeRequest(
      '/properties/interest',
      (json) => json,
      method: 'POST',
      body: {
        'property_id': propertyId,
        'interest_type': interestType,
        if (message != null) 'message': message,
        if (preferredTime != null) 'preferred_time': preferredTime,
      },
      operationName: 'Show Property Interest',
    );
  }

  Future<Map<String, dynamic>> checkPropertyAvailability(
    int propertyId, {
    String? checkInDate,
    String? checkOutDate,
    int? guests,
  }) async {
    return await _makeRequest(
      '/properties/$propertyId/availability',
      (json) => json,
      queryParams: {
        if (checkInDate != null) 'check_in_date': checkInDate,
        if (checkOutDate != null) 'check_out_date': checkOutDate,
        if (guests != null) 'guests': guests.toString(),
      },
      operationName: 'Check Property Availability',
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
      DebugLogger.api('🏥 Health check body: ${response.bodyString}');
      
      return response.statusCode == 200;
    } catch (e, stackTrace) {
      DebugLogger.error('💔 Backend connection test failed: $e');
      // Try alternative endpoint for testing
      try {
        final response = await get('/').timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw Exception('Connection timeout');
          },
        );
        DebugLogger.api('🔄 Alternative endpoint test: ${response.statusCode}');
        return response.statusCode == 200 || response.statusCode == 404; // 404 is ok, means server is running
      } catch (e2) {
        DebugLogger.error('💔 Alternative endpoint test also failed: $e2');
        return false;
      }
    }
  }

  // Swipe System
  Future<void> swipeProperty(int propertyId, bool isLiked, {
    String? swipeDirection,
    int? interactionTimeSeconds,
  }) async {
    await _makeRequest(
      '/swipes/',
      (json) => json,
      method: 'POST',
      body: {
        'property_id': propertyId,
        'is_liked': isLiked,
        'swipe_direction': swipeDirection ?? (isLiked ? 'right' : 'left'),
        if (interactionTimeSeconds != null) 'interaction_time_seconds': interactionTimeSeconds,
      },
      operationName: 'Swipe Property',
    );
  }

  Future<List<Map<String, dynamic>>> getSwipeHistory({int limit = 100}) async {
    return await _makeRequest(
      '/swipes/history',
      (json) => (json as List).cast<Map<String, dynamic>>(),
      queryParams: {'limit': limit.toString()},
      operationName: 'Get Swipe History',
    );
  }

  Future<Map<String, dynamic>> getSwipeStats() async {
    return await _makeRequest('/swipes/stats', (json) => json, operationName: 'Get Swipe Stats');
  }

  Future<void> undoLastSwipe() async {
    await _makeRequest('/swipes/undo', (json) => json, method: 'POST', operationName: 'Undo Last Swipe');
  }

  // Location Services
  Future<List<Map<String, dynamic>>> searchLocations(String query, {int limit = 10}) async {
    return await _makeRequest(
      '/locations/search',
      (json) => (json as List).cast<Map<String, dynamic>>(),
      queryParams: {
        'query': query,
        'limit': limit.toString(),
      },
      operationName: 'Search Locations',
    );
  }


  // Visit Scheduling
  Future<Map<String, dynamic>> scheduleVisit({
    required int propertyId,
    required String visitDate,
    required String visitTime,
    String visitType = 'physical',
    String? notes,
    String contactPreference = 'phone',
    int guestsCount = 1,
  }) async {
    return await _makeRequest(
      '/visits/',
      (json) => json,
      method: 'POST',
      body: {
        'property_id': propertyId,
        'visit_date': visitDate,
        'visit_time': visitTime,
        'visit_type': visitType,
        if (notes != null) 'notes': notes,
        'contact_preference': contactPreference,
        'guests_count': guestsCount,
      },
      operationName: 'Schedule Visit',
    );
  }

  Future<VisitListResponse> getMyVisits() async {
    return await _makeRequest(
      '/visits/',
      (json) => VisitListResponse.fromJson(json),
      operationName: 'Get My Visits',
    );
  }

  Future<List<VisitModel>> getUpcomingVisits() async {
    return await _makeRequest(
      '/visits/upcoming',
      (json) {
        final visitsData = json['data'] ?? json;
        
        if (visitsData is List) {
          return visitsData.map((item) => VisitModel.fromJson(item)).toList();
        } else {
          throw Exception('Expected list of visits but got: ${visitsData.runtimeType}');
        }
      },
      operationName: 'Get Upcoming Visits',
    );
  }
  
  Future<List<VisitModel>> getPastVisits() async {
    return await _makeRequest(
      '/visits/past',
      (json) {
        final visitsData = json['data'] ?? json;
        
        if (visitsData is List) {
          return visitsData.map((item) => VisitModel.fromJson(item)).toList();
        } else {
          throw Exception('Expected list of visits but got: ${visitsData.runtimeType}');
        }
      },
      operationName: 'Get Past Visits',
    );
  }

  Future<void> rescheduleVisit(int visitId, String newDate, {String? reason}) async {
    await _makeRequest(
      '/visits/reschedule',
      (json) => json,
      method: 'POST',
      body: {
        'visit_id': visitId,
        'new_date': newDate,
        if (reason != null) 'reason': reason,
      },
      operationName: 'Reschedule Visit',
    );
  }

  Future<void> cancelVisit(int visitId, {String? reason}) async {
    await _makeRequest(
      '/visits/cancel',
      (json) => json,
      method: 'POST',
      body: {
        'visit_id': visitId,
        if (reason != null) 'reason': reason,
      },
      operationName: 'Cancel Visit',
    );
  }

  Future<RelationshipManagerModel> getRelationshipManager() async {
    return await _makeRequest(
      '/visits/relationship-manager',
      (json) {
        final rmData = json['data'] ?? json;
        return RelationshipManagerModel.fromJson(rmData);
      },
      operationName: 'Get Relationship Manager',
    );
  }

  // Analytics
  Future<void> trackEvent(String eventType, Map<String, dynamic> eventData, {
    String? sessionId,
    String? userAgent,
    String? ipAddress,
  }) async {
    // Get current user ID
    final currentUser = _supabase.auth.currentUser;
    final userId = currentUser?.id;
    
    await _makeRequest(
      '/analytics/event',
      (json) => json,
      method: 'POST',
      body: {
        'user_id': userId != null ? int.tryParse(userId) ?? 0 : 0,
        'event_type': eventType,
        'event_data': eventData,
        'timestamp': DateTime.now().toIso8601String(),
        'session_id': sessionId ?? 'unknown',
        'user_agent': userAgent ?? 'unknown',
        'ip_address': ipAddress ?? 'unknown',
      },
      operationName: 'Track Event',
    );
  }

  Future<Map<String, dynamic>> getAnalyticsDashboard() async {
    return await _makeRequest('/analytics/dashboard', (json) => json, operationName: 'Get Analytics Dashboard');
  }

  Future<List<Map<String, dynamic>>> getSearchHistory() async {
    return await _makeRequest(
      '/analytics/search-history',
      (json) {
        // Handle both List and Map responses from backend
        if (json is List) {
          return (json as List).cast<Map<String, dynamic>>();
        } else {
          // If response is a Map, extract the array or return empty list
          final resultsData = json['data'] ?? json['history'] ?? json['results'];
          if (resultsData is List) {
            return resultsData.cast<Map<String, dynamic>>();
          }
        }
      
        // Return empty list if parsing fails
        return <Map<String, dynamic>>[];
      },
      operationName: 'Get Search History',
    );
  }

  Future<SwipeStatsModel> getSwipeAnalytics() async {
    return await _makeRequest(
      '/analytics/swipe-stats',
      (json) {
        final statsData = json['data'] ?? json;
        return SwipeStatsModel.fromJson(statsData);
      },
      operationName: 'Get Swipe Analytics',
    );
  }

  Future<SearchAnalyticsModel> getSearchAnalytics() async {
    return await _makeRequest(
      '/analytics/search-stats',
      (json) {
        final statsData = json['data'] ?? json;
        return SearchAnalyticsModel.fromJson(statsData);
      },
      operationName: 'Get Search Analytics',
    );
  }

  Future<PropertyViewAnalyticsModel> getPropertyViewAnalytics() async {
    return await _makeRequest(
      '/analytics/property-view-stats',
      (json) {
        final statsData = json['data'] ?? json;
        return PropertyViewAnalyticsModel.fromJson(statsData);
      },
      operationName: 'Get Property View Analytics',
    );
  }

  Future<UserPreferencesInsightsModel> getUserInsights() async {
    return await _makeRequest(
      '/analytics/user-insights',
      (json) {
        final insightsData = json['data'] ?? json;
        return UserPreferencesInsightsModel.fromJson(insightsData);
      },
      operationName: 'Get User Insights',
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

  // Enhanced Analytics Tracking
  Future<void> trackPropertyView(int propertyId, {
    int? viewDurationSeconds,
    String? source,
    Map<String, dynamic>? additionalData,
  }) async {
    await trackEvent('property_view', {
      'property_id': propertyId,
      if (viewDurationSeconds != null) 'view_duration_seconds': viewDurationSeconds,
      if (source != null) 'source': source,
      ...?additionalData,
    });
  }

  Future<void> trackPropertySearch({
    required Map<String, dynamic> searchFilters,
    required int resultCount,
    String? searchLocation,
    Map<String, dynamic>? additionalData,
  }) async {
    await trackEvent('property_search', {
      'search_filters': searchFilters,
      'result_count': resultCount,
      if (searchLocation != null) 'search_location': searchLocation,
      ...?additionalData,
    });
  }

  Future<void> trackSwipeAction({
    required int propertyId,
    required bool isLiked,
    String? swipeDirection,
    int? interactionTimeSeconds,
    Map<String, dynamic>? additionalData,
  }) async {
    await trackEvent('property_swipe', {
      'property_id': propertyId,
      'is_liked': isLiked,
      'swipe_direction': swipeDirection ?? (isLiked ? 'right' : 'left'),
      if (interactionTimeSeconds != null) 'interaction_time_seconds': interactionTimeSeconds,
      ...?additionalData,
    });
  }

  Future<void> trackVisitScheduling({
    required int propertyId,
    required String visitType,
    required String visitDate,
    Map<String, dynamic>? additionalData,
  }) async {
    await trackEvent('visit_scheduled', {
      'property_id': propertyId,
      'visit_type': visitType,
      'visit_date': visitDate,
      ...?additionalData,
    });
  }

  Future<void> trackBookingAction({
    required String action, // 'created', 'cancelled', 'payment_initiated', etc.
    required int bookingId,
    int? propertyId,
    Map<String, dynamic>? additionalData,
  }) async {
    await trackEvent('booking_$action', {
      'booking_id': bookingId,
      if (propertyId != null) 'property_id': propertyId,
      ...?additionalData,
    });
  }

}