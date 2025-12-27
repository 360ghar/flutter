import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/data/models/unified_filter_model.dart';
import 'package:ghar360/core/utils/app_exceptions.dart';
import 'package:json_annotation/json_annotation.dart';

part 'page_state_model.g.dart';

enum PageType { explore, discover, likes }

/// Lightweight data structure for persisting only essential state to storage.
/// Does NOT include properties list to avoid large disk writes and storage bloat.
@JsonSerializable()
class PageStateSnapshot {
  final String pageType;
  final LocationData? selectedLocation;
  final String? locationSource;
  final UnifiedFilterModel filters;
  final String? searchQuery;
  final Map<String, dynamic>? additionalData;
  final DateTime? lastFetched;

  const PageStateSnapshot({
    required this.pageType,
    this.selectedLocation,
    this.locationSource,
    required this.filters,
    this.searchQuery,
    this.additionalData,
    this.lastFetched,
  });

  factory PageStateSnapshot.fromJson(Map<String, dynamic> json) =>
      _$PageStateSnapshotFromJson(json);

  Map<String, dynamic> toJson() => _$PageStateSnapshotToJson(this);
}

@JsonSerializable()
class PageStateModel {
  // Page identification
  final PageType pageType;

  // Location state
  final LocationData? selectedLocation;
  final String? locationSource; // 'gps', 'ip', 'manual'

  // Filter state
  final UnifiedFilterModel filters;

  // Search state (null for discover page)
  final String? searchQuery;

  // Properties data
  final List<PropertyModel> properties;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isRefreshing;
  @JsonKey(includeFromJson: false, includeToJson: false) // We won't serialize the error object
  final AppException? error;
  final DateTime? lastFetched;

  // Additional state for specific pages
  final Map<String, dynamic>? additionalData;

  const PageStateModel({
    required this.pageType,
    this.selectedLocation,
    this.locationSource,
    required this.filters,
    this.searchQuery,
    required this.properties,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.error,
    this.lastFetched,
    this.additionalData,
  });

  factory PageStateModel.initial(PageType pageType) {
    return PageStateModel(
      pageType: pageType,
      filters: UnifiedFilterModel.initial(),
      properties: [],
      additionalData: pageType == PageType.likes ? {'currentSegment': 'liked'} : null,
    );
  }

  factory PageStateModel.fromJson(Map<String, dynamic> json) => _$PageStateModelFromJson(json);

  Map<String, dynamic> toJson() => _$PageStateModelToJson(this);

  PageStateModel copyWith({
    PageType? pageType,
    LocationData? selectedLocation,
    String? locationSource,
    UnifiedFilterModel? filters,
    String? searchQuery,
    List<PropertyModel>? properties,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isRefreshing,
    AppException? error,
    DateTime? lastFetched,
    Map<String, dynamic>? additionalData,
  }) {
    return PageStateModel(
      pageType: pageType ?? this.pageType,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      locationSource: locationSource ?? this.locationSource,
      filters: filters ?? this.filters,
      searchQuery: searchQuery ?? this.searchQuery,
      properties: properties ?? this.properties,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error ?? this.error,
      lastFetched: lastFetched ?? this.lastFetched,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  // Getters for common operations
  bool get hasLocation => selectedLocation != null;

  bool get hasActiveFilters => filters.activeFilterCount > 0 || (searchQuery?.isNotEmpty ?? false);

  int get activeFiltersCount =>
      filters.activeFilterCount + (searchQuery?.isNotEmpty ?? false ? 1 : 0);

  String get locationDisplayText {
    if (hasLocation) {
      return selectedLocation!.name.isNotEmpty ? selectedLocation!.name : 'Current Location';
    }
    return 'Select Location';
  }

  bool get isDataStale {
    if (lastFetched == null) return true;
    final now = DateTime.now();
    final staleThreshold = const Duration(minutes: 5);
    return now.difference(lastFetched!) > staleThreshold;
  }

  // Helper methods for specific page data
  T? getAdditionalData<T>(String key) {
    return additionalData?[key] as T?;
  }

  /// Creates a lightweight snapshot for persistence.
  /// Excludes properties list to avoid large disk writes.
  PageStateSnapshot toSnapshot() {
    return PageStateSnapshot(
      pageType: pageType.name,
      selectedLocation: selectedLocation,
      locationSource: locationSource,
      filters: filters,
      searchQuery: searchQuery,
      additionalData: additionalData,
      lastFetched: lastFetched,
    );
  }

  /// Creates a PageStateModel from a persisted snapshot.
  /// Properties list is initialized as empty (will be fetched on demand).
  static PageStateModel fromSnapshot(PageStateSnapshot snapshot) {
    final pageType = PageType.values.firstWhere(
      (e) => e.name == snapshot.pageType,
      orElse: () => PageType.discover,
    );
    return PageStateModel(
      pageType: pageType,
      selectedLocation: snapshot.selectedLocation,
      locationSource: snapshot.locationSource,
      filters: snapshot.filters,
      searchQuery: snapshot.searchQuery,
      additionalData: snapshot.additionalData,
      lastFetched: snapshot.lastFetched,
      properties: [], // Never persisted; fetched on demand
    );
  }

  PageStateModel updateAdditionalData(String key, dynamic value) {
    final newData = Map<String, dynamic>.from(additionalData ?? {});
    newData[key] = value;
    return copyWith(additionalData: newData);
  }

  // Reset methods
  PageStateModel resetData() {
    return copyWith(
      properties: [],
      currentPage: 1,
      totalPages: 1,
      hasMore: true,
      isLoading: false,
      isLoadingMore: false,
      isRefreshing: false,
      error: null,
    );
  }

  PageStateModel resetFilters() {
    return copyWith(
      filters: UnifiedFilterModel.initial(),
      searchQuery: pageType == PageType.discover ? null : '',
    ).resetData();
  }
}
