import 'package:get/get.dart';
import '../../../core/data/providers/api_service.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/utils/debug_logger.dart';

class DashboardController extends GetxController {
  late final ApiService _apiService;
  late final AuthController _authController;

  final RxMap<String, dynamic> dashboardData = <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> searchHistory = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> recentActivity = <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> userStats = <String, dynamic>{}.obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxString error = ''.obs;
  
  // Bottom navigation state
  final RxInt currentIndex = 2.obs; // Default to Discover tab (index 2)

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _authController = Get.find<AuthController>();
    
    // Listen to authentication state changes
    ever(_authController.isLoggedIn, (bool isLoggedIn) {
      if (isLoggedIn) {
        // User is logged in, safe to fetch data
        loadDashboardData();
      } else {
        // User logged out, clear all data
        _clearAllData();
      }
    });
    
    // If already logged in, load dashboard data
    if (_authController.isLoggedIn.value) {
      loadDashboardData();
    }
  }

  Future<void> loadDashboardData() async {
    if (!_authController.isAuthenticated) return;

    try {
      isLoading.value = true;
      error.value = '';
      
      // Load dashboard data (analytics removed)
      final results = await Future.wait([
        _loadUserStats(),
        _loadRecentActivity(),
      ]);
      
      userStats.value = results[0] as Map<String, dynamic>;
      recentActivity.value = results[1] as List<Map<String, dynamic>>;
      
      // Clear analytics data that's no longer available
      dashboardData.value = {};
      searchHistory.value = [];
      
    } catch (e, stackTrace) {
      error.value = 'Failed to load dashboard data';
      DebugLogger.error('Error loading dashboard data', e, stackTrace);
      
      Get.snackbar(
        'Dashboard Error',
        'Failed to load dashboard data. Please try again.',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshDashboard() async {
    if (!_authController.isAuthenticated || isRefreshing.value) return;

    try {
      isRefreshing.value = true;
      await loadDashboardData();
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<Map<String, dynamic>> _loadUserStats() async {
    try {
      // Analytics removed - return basic stats or empty data
      return {
        'properties_viewed': 0,
        'properties_liked': 0,
        'visits_scheduled': 0,
        'searches_made': 0,
        'time_spent_minutes': 0,
        'favorite_location': 'N/A',
      };
    } catch (e, stackTrace) {
      DebugLogger.error('Error loading user stats', e, stackTrace);
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _loadRecentActivity() async {
    try {
      // This would typically be a separate API call
      // For now, we'll simulate recent activity based on available data
      return [
        {
          'type': 'property_view',
          'title': 'Viewed luxury apartment',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          'icon': 'visibility',
        },
        {
          'type': 'search',
          'title': 'Searched for 2BHK apartments',
          'timestamp': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
          'icon': 'search',
        },
        {
          'type': 'like',
          'title': 'Liked villa in Bandra',
          'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'icon': 'favorite',
        },
      ];
    } catch (e, stackTrace) {
      DebugLogger.error('Error loading recent activity', e, stackTrace);
      return [];
    }
  }

  void _clearAllData() {
    dashboardData.clear();
    searchHistory.clear();
    recentActivity.clear();
    userStats.clear();
    error.value = '';
  }

  // Analytics dashboard getters
  int get totalViews => dashboardData['total_views'] ?? 0;
  int get totalLikes => dashboardData['total_likes'] ?? 0;
  int get totalVisitsScheduled => dashboardData['total_visits_scheduled'] ?? 0;
  double get conversionRate => dashboardData['conversion_rate']?.toDouble() ?? 0.0;
  
  List<String> get preferredLocations {
    final locations = dashboardData['preferred_locations'];
    if (locations is List) {
      return List<String>.from(locations);
    }
    return [];
  }

  Map<String, dynamic> get activitySummary => dashboardData['activity_summary'] ?? {};

  // User stats getters
  int get propertiesViewed => userStats['properties_viewed'] ?? 0;
  int get propertiesLiked => userStats['properties_liked'] ?? 0;
  int get visitsScheduled => userStats['visits_scheduled'] ?? 0;
  int get searchesMade => userStats['searches_made'] ?? 0;
  int get timeSpentMinutes => userStats['time_spent_minutes'] ?? 0;
  String get favoriteLocation => userStats['favorite_location'] ?? 'N/A';

  // Search history methods (analytics removed)
  Future<void> refreshSearchHistory() async {
    searchHistory.clear();
  }

  void clearSearchHistory() {
    searchHistory.clear();
    // Also clear from backend if needed  
    // Note: clearSearchHistory method needs to be implemented in ApiService
  }

  // Dashboard insights
  String get topPerformingSearchTerm {
    if (searchHistory.isEmpty) return 'No searches yet';
    
    // Find most frequent search term
    final searchTerms = <String, int>{};
    for (final search in searchHistory) {
      final term = search['query'] as String? ?? '';
      searchTerms[term] = (searchTerms[term] ?? 0) + 1;
    }
    
    if (searchTerms.isEmpty) return 'No searches yet';
    
    final topTerm = searchTerms.entries.reduce((a, b) => a.value > b.value ? a : b);
    return topTerm.key;
  }

  double get averagePropertyPrice {
    final summary = activitySummary;
    return summary['average_property_price']?.toDouble() ?? 0.0;
  }

  String get mostViewedPropertyType {
    final summary = activitySummary;
    return summary['most_viewed_property_type'] ?? 'Apartment';
  }

  List<Map<String, dynamic>> get topLocations {
    final locations = dashboardData['top_locations'];
    if (locations is List) {
      return List<Map<String, dynamic>>.from(locations);
    }
    return [];
  }

  // Engagement metrics
  double get engagementScore {
    if (propertiesViewed == 0) return 0.0;
    return (propertiesLiked / propertiesViewed * 100).clamp(0.0, 100.0);
  }

  String get userEngagementLevel {
    final score = engagementScore;
    if (score >= 80) return 'High';
    if (score >= 50) return 'Medium';
    if (score >= 20) return 'Low';
    return 'Very Low';
  }

  // Time-based insights
  String get timeSpentFormatted {
    final minutes = timeSpentMinutes;
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }

  bool get isActiveUser => propertiesViewed >= 10 || timeSpentMinutes >= 60;

  // Data export functionality
  Map<String, dynamic> exportDashboardData() {
    return {
      'dashboard_data': dashboardData,
      'search_history': searchHistory,
      'user_stats': userStats,
      'recent_activity': recentActivity,
      'export_timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Dashboard summary for quick overview
  Map<String, dynamic> get quickSummary => {
    'properties_viewed': propertiesViewed,
    'properties_liked': propertiesLiked,
    'visits_scheduled': visitsScheduled,
    'engagement_level': userEngagementLevel,
    'time_spent': timeSpentFormatted,
    'top_search_term': topPerformingSearchTerm,
    'favorite_location': favoriteLocation,
  };
  
  // Navigation methods
  void changeTab(int index) {
    currentIndex.value = index;
  }
}