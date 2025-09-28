import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:ghar360/core/data/providers/api_service.dart';
import 'package:ghar360/core/utils/app_exceptions.dart';
import 'package:ghar360/core/utils/debug_logger.dart';

/// OfflineQueueService
///
/// A lightweight queue for deferring network actions when offline.
/// Stores queued actions in GetStorage and retries when connectivity returns.
class OfflineQueueService extends GetxService {
  static const _storageKey = 'offline_action_queue';

  final GetStorage _storage = GetStorage();
  final ApiService _apiService = Get.find<ApiService>();

  StreamSubscription? _connectivitySub;
  bool _processing = false;

  Future<OfflineQueueService> init() async {
    // Set up connectivity listener
    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      (event) async {
        await _handleConnectivityEvent(event);
      },
      onError: (e, st) {
        DebugLogger.warning('OfflineQueue connectivity stream error: $e');
      },
    );

    // Attempt initial flush on startup (non-blocking)
    unawaited(processQueue());
    return this;
  }

  @override
  void onClose() {
    _connectivitySub?.cancel();
    super.onClose();
  }

  // Public API

  Future<void> enqueueSwipe({required int propertyId, required bool isLiked}) async {
    await _enqueue({
      'type': 'swipe',
      'propertyId': propertyId,
      'isLiked': isLiked,
      'ts': DateTime.now().toIso8601String(),
    });
    DebugLogger.info('🕓 Queued swipe action for property $propertyId');
  }

  Future<void> enqueueVisit({
    required int propertyId,
    required String scheduledDate,
    String? specialRequirements,
  }) async {
    await _enqueue({
      'type': 'visit',
      'propertyId': propertyId,
      'scheduledDate': scheduledDate,
      if (specialRequirements != null) 'specialRequirements': specialRequirements,
      'ts': DateTime.now().toIso8601String(),
    });
    DebugLogger.info('🕓 Queued visit booking for property $propertyId');
  }

  Future<void> processQueue() async {
    if (_processing) return;
    _processing = true;
    try {
      final queue = _getQueue();
      if (queue.isEmpty) return;

      // Ensure backend is reachable before attempting
      final ok = await _apiService.testConnection();
      if (!ok) {
        DebugLogger.warning('🌐 Backend not reachable yet, deferring queue');
        return;
      }

      DebugLogger.info('🔁 Processing ${queue.length} offline actions...');
      final remaining = <Map<String, dynamic>>[];

      for (final action in queue) {
        final type = action['type'] as String?;
        try {
          if (type == 'swipe') {
            final propertyId =
                action['propertyId'] as int? ?? int.tryParse(action['propertyId'].toString()) ?? 0;
            final isLiked = action['isLiked'] as bool? ?? (action['isLiked'].toString() == 'true');
            await _apiService.swipeProperty(propertyId, isLiked);
            DebugLogger.success('✅ Replayed swipe for property $propertyId');
          } else if (type == 'visit') {
            final propertyId =
                action['propertyId'] as int? ?? int.tryParse(action['propertyId'].toString()) ?? 0;
            final scheduledDate = action['scheduledDate']?.toString();
            final specialRequirements = action['specialRequirements']?.toString();
            if (scheduledDate == null) {
              throw ValidationException('Missing scheduledDate');
            }
            await _apiService.scheduleVisit(
              propertyId: propertyId,
              scheduledDate: scheduledDate,
              specialRequirements: specialRequirements,
            );
            DebugLogger.success('✅ Replayed visit booking for $propertyId');
          } else {
            DebugLogger.warning('Unknown offline action type: $type');
          }
        } on AppException catch (e, st) {
          // Keep network-related failures in queue; drop invalid actions
          if (e is NetworkException) {
            DebugLogger.warning(
              '🌐 Network error while replaying "$type" — keeping in queue',
              e,
              st,
            );
            remaining.add(action);
            // Stop early to avoid hammering
            break;
          } else {
            DebugLogger.error(
              '❌ Non-network error on queued "$type" — dropping action: ${e.message}',
              e,
              st,
            );
          }
        } catch (e, st) {
          DebugLogger.error('❌ Error processing offline action: $e', e, st);
          // Keep action to retry later
          remaining.add(action);
          break;
        }
      }

      _saveQueue(remaining);
      final processed = queue.length - remaining.length;
      if (processed > 0) {
        DebugLogger.success('📤 Flushed $processed queued action(s)');
      }
    } finally {
      _processing = false;
    }
  }

  // Internals

  Future<void> _enqueue(Map<String, dynamic> action) async {
    final list = _getQueue();
    list.add(action);
    _saveQueue(list);
  }

  List<Map<String, dynamic>> _getQueue() {
    final raw = _storage.read<List<dynamic>>(_storageKey) ?? <dynamic>[];
    return raw
        .map(
          (e) => Map<String, dynamic>.from(
            e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{},
          ),
        )
        .toList();
  }

  void _saveQueue(List<Map<String, dynamic>> queue) {
    _storage.write(_storageKey, queue);
  }

  Future<void> _handleConnectivityEvent(dynamic event) async {
    bool hasConnection = false;
    if (event is ConnectivityResult) {
      hasConnection =
          event == ConnectivityResult.mobile ||
          event == ConnectivityResult.wifi ||
          event == ConnectivityResult.ethernet ||
          event == ConnectivityResult.vpn;
    } else if (event is List<ConnectivityResult>) {
      hasConnection = event.any(
        (r) =>
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.ethernet ||
            r == ConnectivityResult.vpn,
      );
    }
    if (hasConnection) {
      DebugLogger.info('📶 Connectivity restored — attempting to flush queue');
      await processQueue();
    }
  }
}
