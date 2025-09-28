import 'dart:async';

import 'package:get/get.dart';

import 'package:ghar360/core/utils/debug_logger.dart';

/// A utility class to monitor GetX reactive state changes for debugging
class ReactiveStateMonitor {
  static final Map<String, dynamic> _lastValues = <String, dynamic>{};
  static final List<StreamSubscription> _subs = <StreamSubscription>[];

  /// Monitor an RxList and log changes
  static void monitorRxList<T>(RxList<T> rxList, String name) {
    final sub = rxList.listen((List<T> newList) {
      final currentLength = newList.length;
      final lastLength = _lastValues[name] as int? ?? -1;

      if (currentLength != lastLength) {
        DebugLogger.info('📊 [$name] List changed: $lastLength → $currentLength items');
        _lastValues[name] = currentLength;

        // Log sample items if available
        if (newList.isNotEmpty && newList.length <= 3) {
          DebugLogger.info('📝 [$name] Sample items');
          for (int i = 0; i < newList.length; i++) {
            DebugLogger.info('  item[$i]=${_getItemDescription(newList[i])}');
          }
        } else if (newList.isNotEmpty) {
          DebugLogger.info('📝 [$name] First item: ${_getItemDescription(newList.first)}');
          DebugLogger.info('📝 [$name] Last item: ${_getItemDescription(newList.last)}');
        }
      }
    });
    _subs.add(sub);
  }

  /// Monitor an RxBool and log changes
  static void monitorRxBool(RxBool rxBool, String name) {
    final sub = rxBool.listen((bool newValue) {
      final lastValue = _lastValues[name] as bool?;

      if (newValue != lastValue) {
        DebugLogger.info('🔄 [$name] Bool changed: $lastValue → $newValue');
        _lastValues[name] = newValue;
      }
    });
    _subs.add(sub);
  }

  /// Monitor an RxString and log changes
  static void monitorRxString(RxString rxString, String name) {
    final sub = rxString.listen((String newValue) {
      final lastValue = _lastValues[name] as String?;

      if (newValue != lastValue) {
        final displayValue = newValue.isEmpty ? '(empty)' : newValue;
        final displayLastValue = lastValue?.isEmpty == true ? '(empty)' : lastValue ?? '(null)';
        DebugLogger.info('📝 [$name] String changed: $displayLastValue → $displayValue');
        _lastValues[name] = newValue;
      }
    });
    _subs.add(sub);
  }

  /// Get a brief description of an item for logging
  static String _getItemDescription(dynamic item) {
    if (item == null) return 'null';

    try {
      // Try to get useful information from common property models
      if (item.toString().contains('PropertyCardModel')) {
        final dynamic property = item;
        final String titleStr = property.title.toString();
        final int end = titleStr.length < 30 ? titleStr.length : 30;
        return 'Property(id: ${property.id}, title: "${titleStr.substring(0, end)}...")';
      }

      if (item.toString().contains('PropertyModel')) {
        final dynamic property = item;
        final String titleStr = property.title.toString();
        final int end = titleStr.length < 30 ? titleStr.length : 30;
        return 'Property(id: ${property.id}, title: "${titleStr.substring(0, end)}...")';
      }

      final String str = item.toString();
      final int end = str.length < 50 ? str.length : 50;
      return str.substring(0, end);
    } catch (e) {
      return item.runtimeType.toString();
    }
  }

  /// Create a monitor for a PropertyController
  static void monitorPropertyController(dynamic controller, String controllerName) {
    DebugLogger.info('🔍 Setting up reactive state monitoring for $controllerName');

    try {
      // Monitor key lists
      if (controller.properties != null) {
        monitorRxList(controller.properties, '$controllerName.properties');
      }
      if (controller.discoverProperties != null) {
        monitorRxList(controller.discoverProperties, '$controllerName.discoverProperties');
      }
      if (controller.favouriteProperties != null) {
        monitorRxList(controller.favouriteProperties, '$controllerName.favouriteProperties');
      }
      if (controller.nearbyProperties != null) {
        monitorRxList(controller.nearbyProperties, '$controllerName.nearbyProperties');
      }

      // Monitor loading states
      if (controller.isLoading != null) {
        monitorRxBool(controller.isLoading, '$controllerName.isLoading');
      }
      if (controller.isLoadingDiscover != null) {
        monitorRxBool(controller.isLoadingDiscover, '$controllerName.isLoadingDiscover');
      }

      // Monitor error state
      if (controller.error != null) {
        monitorRxString(controller.error, '$controllerName.error');
      }

      DebugLogger.success('✅ Monitoring setup complete for $controllerName');
    } catch (e) {
      DebugLogger.error('❌ Failed to setup monitoring for $controllerName: $e');
    }
  }

  /// Clear all monitored values (useful for testing)
  static Future<void> clear() async {
    // Cancel all stored subscriptions
    final cancelFutures = _subs.map((sub) => sub.cancel());
    await Future.wait(cancelFutures);

    // Clear collections
    _subs.clear();
    _lastValues.clear();

    // Log cleared state
    DebugLogger.info('🧹 Cleared reactive state monitor history (subscriptions canceled)');
  }
}
