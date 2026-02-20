import 'package:flutter/material.dart';

import 'package:get_storage/get_storage.dart';

import 'package:ghar360/core/controllers/page_data_loader.dart';
import 'package:ghar360/core/controllers/page_state_service.dart';
import 'package:ghar360/core/data/models/page_state_model.dart';
import 'package:ghar360/core/data/models/unified_filter_model.dart';
import 'package:ghar360/core/firebase/analytics_service.dart';
import 'package:ghar360/core/utils/debug_logger.dart';

/// Handles filter updates, search, global filter propagation, and
/// persistence for [PageStateService].
class PageFilterManager {
  final PageStateService _pageState;
  final PageDataLoader _dataLoader;
  final GetStorage _storage;

  // Search controllers (persistent per page type)
  final _controllers = <PageType, TextEditingController>{};

  PageFilterManager(this._pageState, this._dataLoader, this._storage);

  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  void updatePageFilters(PageType pageType, UnifiedFilterModel filters) {
    final previous = _pageState.getStateForPage(pageType).filters;
    final purposeChanged = (filters.purpose ?? '') != (previous.purpose ?? '');
    final List<String> prevTypes = previous.propertyType ?? const [];
    final List<String> nextTypes = filters.propertyType ?? const [];
    final typeChanged = prevTypes.join(',') != nextTypes.join(',');

    final state = _pageState.getStateForPage(pageType);
    _pageState.updatePageState(pageType, state.copyWith(filters: filters));
    if (!(purposeChanged || typeChanged)) {
      _dataLoader.debounceRefresh(pageType);
    }
    DebugLogger.info('🔍 Updated ${pageType.name} filters');
    try {
      AnalyticsService.filterApplied(
        activeCount: filters.activeFilterCount,
        pageType: pageType.name,
      );
    } catch (e, st) {
      DebugLogger.warning('Analytics filterApplied failed', e, st);
    }

    // Persist and propagate global fields when they change
    if (purposeChanged) {
      final newPurpose = filters.purpose?.trim();
      if (newPurpose != null && newPurpose.isNotEmpty) {
        _storage.write('global_purpose', newPurpose);
        setPurposeForAllPages(newPurpose);
        DebugLogger.info('🌐 Propagated purpose="$newPurpose" to all pages');
      }
    }

    if (typeChanged) {
      _storage.write('global_property_types', nextTypes);
      setPropertyTypeForAllPages(nextTypes);
      DebugLogger.info('🌐 Propagated property_type=${nextTypes.join(', ')} to all pages');
    }

    if (purposeChanged || typeChanged) {
      _dataLoader.refreshAllPagesData();
    }
  }

  // Search management (only for explore and likes)
  void updatePageSearch(PageType pageType, String query) {
    if (pageType == PageType.discover) return; // Discover doesn't have search

    final state = _pageState.getStateForPage(pageType);
    _pageState.updatePageState(pageType, state.copyWith(searchQuery: query));
    _dataLoader.debounceRefresh(pageType);
    DebugLogger.info('🔍 Updated ${pageType.name} search: "$query"');
  }

  void clearPageSearch(PageType pageType) {
    updatePageSearch(pageType, '');
  }

  // Search controller management (prevents leaks and cursor jumps)
  TextEditingController getOrCreateSearchController(PageType pageType, {String? seedText}) {
    return _controllers.putIfAbsent(pageType, () {
      final controller = TextEditingController(text: seedText ?? '');
      controller.addListener(() => updatePageSearch(pageType, controller.text));
      return controller;
    });
  }

  // Reset methods
  void resetPageFilters(PageType pageType) {
    final state = _pageState.getStateForPage(pageType);
    _pageState.updatePageState(pageType, state.resetFilters());
    _dataLoader.loadPageData(pageType, forceRefresh: true);
    DebugLogger.info('🔄 Reset ${pageType.name} filters');
  }

  void resetAllFilters() {
    for (final page in PageType.values) {
      final state = _pageState.getStateForPage(page);
      _pageState.updatePageState(page, state.resetFilters());
    }
    _dataLoader.refreshAllPagesData();
    DebugLogger.info('🔄 Reset all page filters');
  }

  // Set default purpose across all pages; optionally only if unset
  void setPurposeForAllPages(String purpose, {bool onlyIfUnset = false}) {
    for (final page in PageType.values) {
      final state = _pageState.getStateForPage(page);
      if (onlyIfUnset && state.filters.purpose != null) continue;
      final updatedFilters = state.filters.copyWith(purpose: purpose);
      _pageState.updatePageState(page, state.copyWith(filters: updatedFilters).resetData());
    }
    DebugLogger.info(
      '🎯 Set default purpose="$purpose" for all pages '
      '(onlyIfUnset=$onlyIfUnset)',
    );
  }

  // Set property type across all pages; optionally only if unset/empty
  void setPropertyTypeForAllPages(List<String>? propertyTypes, {bool onlyIfUnset = false}) {
    for (final page in PageType.values) {
      final state = _pageState.getStateForPage(page);
      final current = state.filters.propertyType ?? const [];
      if (onlyIfUnset && current.isNotEmpty) continue;
      final updatedFilters = state.filters.copyWith(propertyType: propertyTypes ?? const []);
      _pageState.updatePageState(page, state.copyWith(filters: updatedFilters).resetData());
    }
    DebugLogger.info(
      '🏷️ Set property types='
      '"${(propertyTypes ?? const []).join(', ')}" for all pages '
      '(onlyIfUnset=$onlyIfUnset)',
    );
  }

  // Load globally stored purpose/property_type and apply across pages
  void applySavedGlobalFilters() {
    try {
      final String? globalPurpose = _storage.read('global_purpose');
      if (globalPurpose != null && globalPurpose.trim().isNotEmpty) {
        setPurposeForAllPages(globalPurpose.trim());
        DebugLogger.success('🎯 Applied saved global purpose: $globalPurpose');
      }

      final List<dynamic>? storedTypes = _storage.read('global_property_types');
      if (storedTypes != null) {
        final types = storedTypes.whereType<String>().toList();
        setPropertyTypeForAllPages(types);
        DebugLogger.success('🏷️ Applied saved global property types: ${types.join(', ')}');
      }
    } catch (e) {
      DebugLogger.warning('Failed to apply saved global filters: $e');
    }
  }
}
