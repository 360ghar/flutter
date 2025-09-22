import 'package:json_annotation/json_annotation.dart';
import 'unified_filter_model.dart';
import 'property_model.dart';
import '../../utils/app_exceptions.dart';

part 'page_state_model.g.dart';

enum PageType { explore, discover, likes }

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
  @JsonKey(ignore: true) // We won't serialize the error object
  final AppError? error;
  final DateTime? lastFetched;

  // Additional state for specific pages
  final Map<String, dynamic>? additionalData;

  PageStateModel({
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
    AppError? error,
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
    final staleThreshold = Duration(minutes: 5);
    return now.difference(lastFetched!) > staleThreshold;
  }

  // Helper methods for specific page data
  T? getAdditionalData<T>(String key) {
    return additionalData?[key] as T?;
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
