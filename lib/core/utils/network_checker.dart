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

      // Use a more reliable endpoint that's less likely to be blocked
      final testUrls = [
        'https://httpbin.org/status/200',  // Simple status endpoint
        'https://www.cloudflare.com',      // CDN that's usually accessible
      ];

      for (final url in testUrls) {
        try {
          final response = await _dio.get(
            url,
            options: Options(
              sendTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
              headers: {'Cache-Control': 'no-cache'},
            ),
          );

          if (response.statusCode == 200) {
            DebugLogger.success('✅ Internet connection verified');
            return true;
          }
        } catch (e) {
          DebugLogger.debug('🔄 Test URL $url failed: $e');
          // Continue to next URL
        }
      }

      DebugLogger.warning('🌐 Internet connectivity test failed - all test URLs unreachable');
      return false;
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