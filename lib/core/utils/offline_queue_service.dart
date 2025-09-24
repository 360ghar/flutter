import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../data/providers/api_service.dart';
import '../utils/debug_logger.dart';

/// A lightweight offline queue service to persist user actions when network calls fail
/// and retry them automatically when connectivity is restored.
class OfflineQueueService extends GetxService {
  static OfflineQueueService get instance => Get.find<OfflineQueueService>();

  final GetStorage _storage = GetStorage();

  // Storage keys
  static const String _swipeQueueKey = 'offline_queue_swipes';
  static const String _visitQueueKey = 'offline_queue_visits';

  // In-memory queues (mirrored to storage)
  final RxList<Map<String, dynamic>> _swipeQueue = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _visitQueue = <Map<String, dynamic>>[].obs;

  StreamSubscription<ConnectivityResult>? _connectivitySub;
  Timer? _periodicRetryTimer;

  @override
  void onInit() {
    super.onInit();
    _loadQueues();
  }

  @override
  void onClose() {
    _connectivitySub?.cancel();
    _periodicRetryTimer?.cancel();
    super.onClose();
  }

  /// Call from InitialBinding to start listeners and periodic processing
  void start() {
    // Listen to connectivity changes
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      DebugLogger.network('Connectivity changed: $result');
      if (_isOnline(result)) {
        processQueues();
      }
    });

    // Periodic background retry (every 60 seconds)
    _periodicRetryTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _checkConnectivityAndProcess();
    });
  }

  // Public queue operations

  Future<void> enqueueSwipe({required int propertyId, required bool isLiked}) async {
    final item = {
      'type': 'swipe',
      'property_id': propertyId,
      'is_liked': isLiked,
      'retry_count': 0,
      'next_attempt_at': DateTime.now().toIso8601String(),
      'queued_at': DateTime.now().toIso8601String(),
    };
    _swipeQueue.add(item);
    _persistQueues();
    DebugLogger.info('🗃️ Enqueued swipe action (property=$propertyId, liked=$isLiked)');
  }

  Future<void> enqueueVisitAction({
    required String action, // 'schedule' | 'cancel' | 'reschedule'
    required Map<String, dynamic> payload,
  }) async {
    final item = {
      'type': 'visit',
      'action': action,
      'payload': payload,
      'retry_count': 0,
      'next_attempt_at': DateTime.now().toIso8601String(),
      'queued_at': DateTime.now().toIso8601String(),
    };
    _visitQueue.add(item);
    _persistQueues();
    DebugLogger.info('🗃️ Enqueued visit action ($action)');
  }

  /// Attempt processing all queues (respecting next_attempt_at)
  Future<void> processQueues() async {
    if (!Get.isRegistered<ApiService>()) return;
    final api = Get.find<ApiService>();

    await _processSwipeQueue(api);
    await _processVisitQueue(api);

    _persistQueues();
  }

  // Internal helpers

  void _loadQueues() {
    try {
      final swipes = _storage.read(_swipeQueueKey);
      final visits = _storage.read(_visitQueueKey);
      if (swipes is List) {
        _swipeQueue.assignAll(swipes.cast<Map<String, dynamic>>());
      }
      if (visits is List) {
        _visitQueue.assignAll(visits.cast<Map<String, dynamic>>());
      }
      DebugLogger.success('✅ Offline queues loaded '
          '(swipes=${_swipeQueue.length}, visits=${_visitQueue.length})');
    } catch (e) {
      DebugLogger.error('Failed to load offline queues: $e');
    }
  }

  void _persistQueues() {
    try {
      _storage.write(_swipeQueueKey, _swipeQueue.toList());
      _storage.write(_visitQueueKey, _visitQueue.toList());
    } catch (e) {
      DebugLogger.error('Failed to persist offline queues: $e');
    }
  }

  Future<void> _processSwipeQueue(ApiService api) async {
    if (_swipeQueue.isEmpty) return;

    final now = DateTime.now();
    final items = List<Map<String, dynamic>>.from(_swipeQueue);
    for (final item in items) {
      final nextAt = DateTime.tryParse(item['next_attempt_at'] ?? '') ?? now;
      if (nextAt.isAfter(now)) continue;

      try {
        final propertyId = item['property_id'] as int;
        final isLiked = item['is_liked'] as bool;
        await api.swipeProperty(propertyId, isLiked);
        _swipeQueue.remove(item);
        DebugLogger.success('✅ Processed queued swipe (property=$propertyId, liked=$isLiked)');
      } catch (e) {
        // Backoff scheduling
        final retry = (item['retry_count'] as int?) ?? 0;
        final delaySeconds = _computeBackoffSeconds(retry);
        item['retry_count'] = retry + 1;
        item['next_attempt_at'] = DateTime.now()
            .add(Duration(seconds: delaySeconds))
            .toIso8601String();
        // Keep item in queue with updated schedule
        final idx = _swipeQueue.indexOf(item);
        if (idx >= 0) {
          _swipeQueue[idx] = item;
        }
        DebugLogger.warning('⚠️ Failed to process queued swipe, will retry in ${delaySeconds}s: $e');
      }
    }
  }

  Future<void> _processVisitQueue(ApiService api) async {
    if (_visitQueue.isEmpty) return;

    final now = DateTime.now();
    final items = List<Map<String, dynamic>>.from(_visitQueue);
    for (final item in items) {
      final nextAt = DateTime.tryParse(item['next_attempt_at'] ?? '') ?? now;
      if (nextAt.isAfter(now)) continue;

      try {
        final action = item['action'] as String;
        final payload = Map<String, dynamic>.from(item['payload'] as Map);
        switch (action) {
          case 'schedule':
            await api.scheduleVisit(
              propertyId: payload['property_id'] as int,
              scheduledDate: payload['scheduled_date'] as String,
              specialRequirements: payload['special_requirements'] as String?,
            );
            break;
          case 'cancel':
            await api.cancelVisit(
              payload['visit_id'] as int,
              reason: payload['reason'] as String,
            );
            break;
          case 'reschedule':
            await api.rescheduleVisit(
              payload['visit_id'] as int,
              newDate: payload['new_date'] as String,
              reason: payload['reason'] as String?,
            );
            break;
          default:
            DebugLogger.warning('Unknown visit action: $action');
            continue;
        }
        _visitQueue.remove(item);
        DebugLogger.success('✅ Processed queued visit action ($action)');
      } catch (e) {
        final retry = (item['retry_count'] as int?) ?? 0;
        final delaySeconds = _computeBackoffSeconds(retry);
        item['retry_count'] = retry + 1;
        item['next_attempt_at'] = DateTime.now()
            .add(Duration(seconds: delaySeconds))
            .toIso8601String();
        final idx = _visitQueue.indexOf(item);
        if (idx >= 0) {
          _visitQueue[idx] = item;
        }
        DebugLogger.warning('⚠️ Failed to process queued visit action, retry in ${delaySeconds}s: $e');
      }
    }
  }

  Future<void> _checkConnectivityAndProcess() async {
    final result = await Connectivity().checkConnectivity();
    if (_isOnline(result)) {
      await processQueues();
    }
  }

  bool _isOnline(ConnectivityResult result) {
    return result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet;
  }

  int _computeBackoffSeconds(int retry) {
    // 0,1,2,3 → 30, 60, 120, 240 seconds
    final base = 30 * (1 << retry);
    // cap at 15 minutes
    return base > 900 ? 900 : base;
  }
}