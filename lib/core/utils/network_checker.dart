import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'debug_logger.dart';

class NetworkChecker {
  static final Dio _dio = Dio();
  
  /// Check if device has internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      // First check connectivity status
      final connectivityResult = await Connectivity().checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        DebugLogger.warning('📱 No network connection detected');
        return false;
      }
      
      // Test actual internet connectivity with a reliable endpoint
      try {
        final response = await _dio.get(
          'https://www.google.com',
          options: Options(
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
            headers: {'Cache-Control': 'no-cache'},
          ),
        );
        
        final isConnected = response.statusCode == 200;
        DebugLogger.success(isConnected 
          ? '✅ Internet connection verified' 
          : '❌ Internet connection failed');
        return isConnected;
      } catch (e) {
        DebugLogger.warning('🌐 Internet connectivity test failed: $e');
        return false;
      }
    } catch (e) {
      DebugLogger.error('💥 Network check failed: $e');
      return false;
    }
  }
  
  /// Check if backend API is reachable
  static Future<bool> isBackendReachable(String baseUrl) async {
    try {
      DebugLogger.info('🔍 Testing backend connectivity to: $baseUrl');
      
      // Test multiple endpoints to check server availability
      final endpoints = ['/health', '/api/v1/health', '/'];
      
      for (final endpoint in endpoints) {
        try {
          final response = await _dio.get(
            '$baseUrl$endpoint',
            options: Options(
              sendTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
              validateStatus: (status) => status != null && status < 600, // Accept any HTTP status
            ),
          );
          
          // Server is reachable if we get any HTTP response
          if (response.statusCode != null) {
            DebugLogger.success('✅ Backend server reachable at $baseUrl$endpoint (${response.statusCode})');
            return true;
          }
        } catch (e) {
          DebugLogger.debug('🔄 Endpoint $endpoint failed: $e');
          // Continue to next endpoint
        }
      }
      
      DebugLogger.warning('❌ Backend server unreachable at all endpoints');
      return false;
    } catch (e) {
      DebugLogger.error('💥 Backend connectivity test error: $e');
      return false;
    }
  }
  
  /// Comprehensive network status check
  static Future<NetworkStatus> checkNetworkStatus({String? backendUrl}) async {
    final hasInternet = await hasInternetConnection();
    
    if (!hasInternet) {
      return NetworkStatus(
        hasInternet: false,
        isBackendReachable: false,
        message: 'No internet connection. Please check your network settings.',
      );
    }
    
    bool backendReachable = true;
    if (backendUrl != null) {
      backendReachable = await isBackendReachable(backendUrl);
      if (!backendReachable) {
        return NetworkStatus(
          hasInternet: true,
          isBackendReachable: false,
          message: 'Internet connected, but backend server is not available.',
        );
      }
    }
    
    return NetworkStatus(
      hasInternet: true,
      isBackendReachable: backendReachable,
      message: 'All connections are working properly.',
    );
  }
}

class NetworkStatus {
  final bool hasInternet;
  final bool isBackendReachable;
  final String message;
  
  NetworkStatus({
    required this.hasInternet,
    required this.isBackendReachable,
    required this.message,
  });
  
  bool get isFullyConnected => hasInternet && isBackendReachable;
}