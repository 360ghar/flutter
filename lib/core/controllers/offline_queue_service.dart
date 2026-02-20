import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:ghar360/core/utils/app_exceptions.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/features/swipes/data/datasources/swipes_remote_datasource.dart';
import 'package:ghar360/features/visits/data/datasources/visits_remote_datasource.dart';

/// Maximum number of actions the queue will hold. Oldest actions are
/// dropped when the limit is exceeded during enqueue.
const _maxQueueSize = 100;

/// Maximum number of retry attempts per action before it is dropped.
const _maxRetries = 5;

/// Actions older than this duration are considered stale and dropped.
const _maxAge = Duration(hours: 24);

/// OfflineQueueService
///
/// A lightweight queue for deferring network actions when offline.
/// Stores queued actions in GetStorage and retries when connectivity returns.
class OfflineQueueService extends GetxService {
  static const _storageKey = 'offline_action_queue';

  static const _connectedResults = {
    ConnectivityResult.mobile,
    ConnectivityResult.wifi,
    ConnectivityResult.ethernet,
    ConnectivityResult.vpn,
  };

  final GetStorage _storage = GetStorage();
  final SwipesRemoteDatasource _swipesRemoteDatasource = Get.find<SwipesRemoteDatasource>();
  final VisitsRemoteDatasource _visitsRemoteDatasource = Get.find<VisitsRemoteDatasource>();

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
      'retries': 0,
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
      'retries': 0,
    });
    DebugLogger.info('🕓 Queued visit booking for property $propertyId');
  }

  Future<void> processQueue() async {
    if (_processing) return;
    _processing = true;
    try {
      final queue = _getQueue();
      if (queue.isEmpty) return;

      // Purge stale actions before processing
      final now = DateTime.now();
      queue.removeWhere((action) {
        final ts = DateTime.tryParse(action['ts']?.toString() ?? '');
        if (ts != null && now.difference(ts) > _maxAge) {
          DebugLogger.warning(
            '🗑️ Dropping stale offline action '
            '(type=${action['type']}, age=${now.difference(ts).inHours}h)',
          );
          return true;
        }
        return false;
      });

      DebugLogger.info('🔁 Processing ${queue.length} offline actions...');
      final remaining = <Map<String, dynamic>>[];

      for (final action in queue) {
        final type = action['type'] as String?;
        final retries = (action['retries'] as num?)?.toInt() ?? 0;

        // Drop actions that have exceeded max retries
        if (retries >= _maxRetries) {
          DebugLogger.warning(
            '🗑️ Dropping offline action after $_maxRetries retries '
            '(type=$type, propertyId=${action['propertyId']})',
          );
          continue;
        }

        try {
          if (type == 'swipe') {
            await _processSwipe(action);
          } else if (type == 'visit') {
            await _processVisit(action);
          } else {
            DebugLogger.warning('Unknown offline action type: $type — dropping');
          }
        } on NetworkException catch (e, st) {
          // Network error — keep in queue with incremented retry count,
          // then stop processing to avoid hammering.
          DebugLogger.warning(
            '🌐 Network error while replaying "$type" — '
            'keeping in queue (retry ${retries + 1}/$_maxRetries)',
            e,
            st,
          );
          action['retries'] = retries + 1;
          remaining.add(action);
          // Add remaining unprocessed actions back as-is
          remaining.addAll(queue.sublist(queue.indexOf(action) + 1));
          break;
        } on AppException catch (e, st) {
          // Non-network app errors (validation, auth, etc.) — drop action
          DebugLogger.error(
            '❌ Non-network error on queued "$type" — '
            'dropping action: ${e.message}',
            e,
            st,
          );
        } catch (e, st) {
          // Unexpected error — increment retry and continue to next item
          // (don't break the loop so other actions can still process)
          DebugLogger.error(
            '❌ Unexpected error processing offline "$type" '
            '(retry ${retries + 1}/$_maxRetries): $e',
            e,
            st,
          );
          action['retries'] = retries + 1;
          remaining.add(action);
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

  // Action processors

  Future<void> _processSwipe(Map<String, dynamic> action) async {
    final propertyId = _parsePropertyId(action);
    if (propertyId == null) {
      DebugLogger.error(
        '❌ Invalid propertyId in queued swipe — dropping: '
        '${action['propertyId']}',
      );
      return; // Drop the action
    }
    final isLiked = action['isLiked'] == true || action['isLiked'].toString() == 'true';
    await _swipesRemoteDatasource.swipeProperty(propertyId: propertyId, isLiked: isLiked);
    DebugLogger.success('✅ Replayed swipe for property $propertyId');
  }

  Future<void> _processVisit(Map<String, dynamic> action) async {
    final propertyId = _parsePropertyId(action);
    if (propertyId == null) {
      DebugLogger.error(
        '❌ Invalid propertyId in queued visit — dropping: '
        '${action['propertyId']}',
      );
      return;
    }
    final scheduledDate = action['scheduledDate']?.toString();
    if (scheduledDate == null) {
      DebugLogger.error('❌ Missing scheduledDate in queued visit — dropping');
      return;
    }
    final specialRequirements = action['specialRequirements']?.toString();
    await _visitsRemoteDatasource.scheduleVisit(
      propertyId: propertyId,
      scheduledDate: scheduledDate,
      specialRequirements: specialRequirements,
    );
    DebugLogger.success('✅ Replayed visit booking for $propertyId');
  }

  /// Parses propertyId from the queued action map.
  /// Returns null instead of falling back to 0.
  static int? _parsePropertyId(Map<String, dynamic> action) {
    final raw = action['propertyId'];
    if (raw is int) return raw;
    if (raw != null) return int.tryParse(raw.toString());
    return null;
  }

  // Internals

  Future<void> _enqueue(Map<String, dynamic> action) async {
    final list = _getQueue();
    list.add(action);

    // Enforce queue size limit — drop oldest actions
    while (list.length > _maxQueueSize) {
      final dropped = list.removeAt(0);
      DebugLogger.warning(
        '🗑️ Queue full ($_maxQueueSize) — dropping oldest action '
        '(type=${dropped['type']})',
      );
    }

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
    final results = event is List<ConnectivityResult>
        ? event
        : (event is ConnectivityResult ? [event] : <ConnectivityResult>[]);
    final hasConnection = results.any(_connectedResults.contains);
    if (hasConnection) {
      DebugLogger.info('📶 Connectivity restored — attempting to flush queue');
      await processQueue();
    }
  }
}
