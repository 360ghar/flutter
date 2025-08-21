import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/network_checker.dart';
import '../utils/debug_logger.dart';
import '../data/providers/api_service.dart';
import '../utils/theme.dart';

class ConnectionStatusWidget extends StatefulWidget {
  const ConnectionStatusWidget({super.key});

  @override
  State<ConnectionStatusWidget> createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget> {
  NetworkStatus? _networkStatus;
  bool _isChecking = false;
  String _backendUrl = 'http://localhost:8000';

  @override
  void initState() {
    super.initState();
    _checkNetworkStatus();
  }

  Future<void> _checkNetworkStatus() async {
    if (_isChecking) return;
    
    setState(() {
      _isChecking = true;
      _networkStatus = null;
    });

    try {
      // Get backend URL from API service
      if (Get.isRegistered<ApiService>()) {
        // Access the base URL if possible, otherwise use default
        _backendUrl = 'http://localhost:8000'; // From your .env.development
      }

      final status = await NetworkChecker.checkNetworkStatus(
        backendUrl: _backendUrl,
      );

      setState(() {
        _networkStatus = status;
        _isChecking = false;
      });

      DebugLogger.info('🔍 Network Status Check Complete');
      DebugLogger.info('📱 Internet: ${status.hasInternet}');
      DebugLogger.info('🖥️ Backend: ${status.isBackendReachable}');
      DebugLogger.info('💬 Message: ${status.message}');
      
    } catch (e) {
      DebugLogger.error('💥 Network status check failed: $e');
      setState(() {
        _networkStatus = NetworkStatus(
          hasInternet: false,
          isBackendReachable: false,
          message: 'Network check failed: $e',
        );
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text(
                'Checking network connectivity...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_networkStatus == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      color: _networkStatus!.isFullyConnected 
        ? Colors.green.shade50 
        : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _networkStatus!.isFullyConnected
                    ? Icons.check_circle
                    : Icons.error,
                  color: _networkStatus!.isFullyConnected
                    ? Colors.green
                    : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Network Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _networkStatus!.isFullyConnected
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Internet Status
            _buildStatusRow(
              'Internet Connection',
              _networkStatus!.hasInternet,
            ),
            
            // Backend Status  
            _buildStatusRow(
              'Backend Server',
              _networkStatus!.isBackendReachable,
            ),
            
            const SizedBox(height: 16),
            Text(
              _networkStatus!.message,
              style: TextStyle(
                fontSize: 14,
                color: _networkStatus!.isFullyConnected
                  ? Colors.green.shade700
                  : Colors.red.shade700,
              ),
            ),
            
            const SizedBox(height: 16),
            Text(
              'Backend URL: $_backendUrl',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontFamily: 'monospace',
              ),
            ),
            
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _checkNetworkStatus,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Recheck'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    foregroundColor: Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                if (!_networkStatus!.isBackendReachable)
                  ElevatedButton.icon(
                    onPressed: _showTroubleshooting,
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Help'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isConnected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.check : Icons.close,
            color: isConnected ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          const Spacer(),
          Text(
            isConnected ? 'Connected' : 'Disconnected',
            style: TextStyle(
              fontSize: 12,
              color: isConnected ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showTroubleshooting() {
    Get.dialog(
      AlertDialog(
        title: const Text('Connection Troubleshooting'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Backend server is not running. To fix this:'),
              const SizedBox(height: 16),
              const Text('1. Make sure your backend server is running'),
              const SizedBox(height: 8),
              const Text('2. Check that it\'s running on http://localhost:8000'),
              const SizedBox(height: 8),
              const Text('3. Verify your .env.development file has the correct API_BASE_URL'),
              const SizedBox(height: 8),
              const Text('4. Try running your backend server and refresh this screen'),
              const SizedBox(height: 16),
              Text(
                'Current backend URL: $_backendUrl',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  backgroundColor: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _checkNetworkStatus();
            },
            child: const Text('Recheck'),
          ),
        ],
      ),
    );
  }
}