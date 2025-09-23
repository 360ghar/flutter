import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/controllers/auth_controller.dart';
import '../../../core/data/models/agent_model.dart';
import '../../../core/data/models/property_model.dart';
import '../../../core/data/models/visit_model.dart';
import '../../../core/data/providers/api_service.dart';
import '../../../core/utils/debug_logger.dart'; // Added missing import
import '../../dashboard/controllers/dashboard_controller.dart';

class VisitsController extends GetxController {
  late final ApiService _apiService;
  late final AuthController _authController;

  final RxList<VisitModel> visits = <VisitModel>[].obs;
  final RxList<VisitModel> upcomingVisitsList = <VisitModel>[].obs;
  final RxList<VisitModel> pastVisitsList = <VisitModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingAgent = false.obs;
  final RxBool isBookingVisit = false.obs;
  final RxString error = ''.obs;
  final Rxn<AgentModel> relationshipManager = Rxn<AgentModel>();
  bool _backgroundRefreshInFlight = false;
  final RxBool isBackgroundRefreshing = false.obs;

  // Track if data has been loaded to prevent infinite loops
  final RxBool hasLoadedVisits = false.obs;
  final RxBool hasLoadedAgent = false.obs;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _authController = Get.find<AuthController>();

    // Listen to authentication state changes
    ever(_authController.authStatus, (authStatus) {
      if (_authController.isAuthenticated) {
        // User is authenticated, safe to fetch data
        _initializeController();
      } else {
        // User logged out, clear all data
        _clearAllData();
      }
    });

    // If already authenticated, initialize immediately
    if (_authController.isAuthenticated) {
      _initializeController();
    }

    // Observe dashboard tab switches to load data when Visits tab is selected for the first time
    if (Get.isRegistered<DashboardController>()) {
      final dash = Get.find<DashboardController>();

      ever<int>(dash.currentIndex, (idx) async {
        if (idx == 4) {
          // Visits tab index
          DebugLogger.info('🔄 Visits tab selected');
          await onTabSelected();
        }
      });

      // If app starts on Visits tab, load data immediately
      if (dash.currentIndex.value == 4) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await onTabSelected();
        });
      }
    }
  }

  Future<void> _initializeController() async {
    // Don't eagerly load data - let views request it when needed
    // await loadVisits();
    // await loadRelationshipManager();
  }

  void _clearAllData() {
    visits.clear();
    upcomingVisitsList.clear();
    relationshipManager.value = null;
    error.value = '';
    hasLoadedVisits.value = false;
    hasLoadedAgent.value = false;
  }

  // Lazy loading methods - only fetch when actually needed
  Future<void> loadVisitsLazy() async {
    if (hasLoadedVisits.value || isLoading.value) {
      return; // Prevent infinite loop
    }
    hasLoadedVisits.value = true;
    await loadVisits();
  }

  Future<void> loadRelationshipManagerLazy() async {
    if (hasLoadedAgent.value || isLoadingAgent.value) {
      return; // Prevent infinite loop
    }
    hasLoadedAgent.value = true;
    await loadRelationshipManager();
  }

  // This method is called when the "Visits" tab becomes visible
  Future<void> onTabSelected() async {
    if (hasLoadedVisits.value || isLoading.value) {
      return; // Don't fetch if already loaded or loading
    }

    isLoading.value = true;
    try {
      await loadVisits();
      hasLoadedVisits.value = true; // Mark as loaded
    } catch (e) {
      // Handle error
      DebugLogger.error('Error loading visits on tab select: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadVisits({bool isRefresh = false, bool silent = false}) async {
    if (!_authController.isAuthenticated) {
      error.value = 'User not authenticated';
      return;
    }

    try {
      if (isRefresh && !silent) {
        // For pull-to-refresh, clear existing data
        visits.clear();
        upcomingVisitsList.clear();
        pastVisitsList.clear();
      }
      if (silent) {
        if (_backgroundRefreshInFlight) {
          DebugLogger.info('🔁 Background refresh already running, skipping');
          return;
        }
        _backgroundRefreshInFlight = true;
        isBackgroundRefreshing.value = true;
      } else {
        isLoading.value = true;
      }
      error.value = '';

      // Get all visits and compute groups to match product requirements
      DebugLogger.info('🔄 Fetching visits summary...');
      final summary = await _apiService.getVisitsSummary();
      var allVisits = summary.visits;
      DebugLogger.info(
        '📥 Visits fetched: total=${allVisits.length} | example=${allVisits.isNotEmpty ? '{id: ${allVisits.first.id}, status: ${allVisits.first.status}, date: ${allVisits.first.scheduledDate.toIso8601String()}}' : 'none'}',
      );

      // Fallback: some backends may return counts without visits payload on summary
      if (allVisits.isEmpty && summary.total > 0) {
        DebugLogger.warning(
          '⚠️ Summary returned no visits list but total=${summary.total}. Falling back to upcoming + past endpoints',
        );
        final results = await Future.wait([
          _apiService.getUpcomingVisits(),
          _apiService.getPastVisits(),
        ]);
        allVisits = [...results[0].visits, ...results[1].visits];
        DebugLogger.info('📥 Fallback combined visits: ${allVisits.length}');
      }

      final now = DateTime.now();
      final upcomingVisits = allVisits
          .where((v) => now.isBefore(v.scheduledDate) && v.status != VisitStatus.completed)
          .toList();
      final pastVisits = allVisits.where((v) => !now.isBefore(v.scheduledDate)).toList();

      // Sort per spec
      upcomingVisits.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
      pastVisits.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

      // Update reactive variables
      upcomingVisitsList.assignAll(upcomingVisits);
      pastVisitsList.assignAll(pastVisits);
      visits.assignAll([...upcomingVisits, ...pastVisits]);

      // Detailed per-item logs for diagnostics
      if (upcomingVisits.isEmpty) {
        DebugLogger.warning('🟡 No upcoming visits after compute');
      } else {
        DebugLogger.info('🟢 Upcoming visits (${upcomingVisits.length}):');
        for (final v in upcomingVisits) {
          DebugLogger.info(
            '  • id=${v.id} status=${v.status} date=${v.scheduledDate.toIso8601String()}',
          );
        }
      }
      if (pastVisits.isEmpty) {
        DebugLogger.warning('🟠 No past visits after compute');
      } else {
        DebugLogger.info('🔵 Past visits (${pastVisits.length}):');
        for (final v in pastVisits) {
          DebugLogger.info(
            '  • id=${v.id} status=${v.status} date=${v.scheduledDate.toIso8601String()}',
          );
        }
      }

      // Sort visits by date
      _sortVisits();

      DebugLogger.success(
        '✅ Visits loaded successfully: ${allVisits.length} total, ${upcomingVisits.length} upcoming, ${pastVisits.length} past',
      );
    } catch (e) {
      error.value = 'Failed to load visits: ${e.toString()}';
      DebugLogger.error('❌ Error loading visits: $e');
    } finally {
      if (silent) {
        _backgroundRefreshInFlight = false;
        isBackgroundRefreshing.value = false;
      } else {
        isLoading.value = false;
      }
    }
  }

  // Pull-to-refresh method
  Future<void> refreshVisits() async {
    await loadVisits(isRefresh: true);
  }

  Future<void> loadRelationshipManager() async {
    if (!_authController.isAuthenticated) return;

    try {
      isLoadingAgent.value = true;
      final agentData = await _apiService.getRelationshipManager();

      // Use updated AgentModel with simplified fields
      relationshipManager.value = AgentModel(
        id: agentData.id,
        name: agentData.name,
        description: agentData.description,
        avatarUrl: agentData.avatarUrl,
        languages: agentData.languages,
        agentType: agentData.agentType,
        experienceLevel: agentData.experienceLevel,
        isActive: agentData.isActive,
        isAvailable: agentData.isAvailable,
        workingHours: agentData.workingHours,
        totalUsersAssigned: agentData.totalUsersAssigned,
        userSatisfactionRating: agentData.userSatisfactionRating,
        createdAt: agentData.createdAt,
        updatedAt: agentData.updatedAt,
      );

      DebugLogger.success('✅ Agent loaded successfully: ${agentData.name}');
    } catch (e) {
      DebugLogger.error('❌ Error loading agent: $e');
      error.value = 'Failed to load agent';
    } finally {
      isLoadingAgent.value = false;
    }
  }

  Future<bool> bookVisit(
    dynamic property, // Can be PropertyModel or PropertyCardModel
    DateTime visitDateTime, {
    String visitType = 'physical',
    String? notes,
    String contactPreference = 'phone',
    int guestsCount = 1,
  }) async {
    if (!_authController.isAuthenticated) {
      Get.snackbar(
        'Authentication Required',
        'Please login to book property visits',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }

    try {
      isBookingVisit.value = true;
      error.value = '';

      // Extract property ID based on type
      final int propertyId = property is PropertyModel
          ? int.tryParse(property.id.toString()) ?? 0
          : property.id as int;
      final String propertyTitle = property is PropertyModel
          ? property.title
          : property.title as String;

      final visitModel = await _apiService.scheduleVisit(
        propertyId: propertyId,
        scheduledDate: visitDateTime.toUtc().toIso8601String(),
        specialRequirements: notes ?? 'Property visit scheduled through 360ghar app',
      );

      DebugLogger.success('✅ Visit scheduled successfully: ${visitModel.id}');

      // The API returns the complete visit model, no need to reconstruct
      // Just reload visits to get the updated list
      await loadVisits(isRefresh: true, silent: true);

      Get.snackbar(
        'Visit Scheduled',
        'Your visit to $propertyTitle has been scheduled for ${formatVisitDate(visitDateTime)} at ${formatVisitTime(visitDateTime)}',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
      );

      return true;
    } catch (e) {
      error.value = e.toString();
      DebugLogger.error('Error booking visit: $e');

      Get.snackbar(
        'Booking Failed',
        'Failed to schedule visit: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );

      return false;
    } finally {
      isBookingVisit.value = false;
    }
  }

  // Fallback method for non-authenticated users
  void bookVisitLocal(dynamic property, DateTime visitDateTime) {
    final int propertyId = property is PropertyModel
        ? int.tryParse(property.id.toString()) ?? 0
        : property.id as int;
    final String propertyTitle = property is PropertyModel
        ? property.title
        : property.title as String;

    final visit = VisitModel(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: 1, // Default user ID
      propertyId: propertyId,
      scheduledDate: visitDateTime,
      status: VisitStatus.scheduled,
      visitNotes: 'Property visit scheduled through 360ghar app',
      createdAt: DateTime.now(),
    );

    visits.insert(0, visit);
    upcomingVisitsList.insert(0, visit);
    _sortVisits();

    Get.snackbar(
      'Visit Scheduled',
      'Your visit to $propertyTitle has been scheduled for ${formatVisitDate(visitDateTime)} at ${formatVisitTime(visitDateTime)}',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );
  }

  Future<bool> cancelVisit(dynamic visitId, {required String reason}) async {
    final visitIdInt = visitId is int ? visitId : int.tryParse(visitId.toString()) ?? 0;
    final visitIndex = visits.indexWhere((visit) => visit.id == visitIdInt);
    if (visitIndex == -1) return false;

    final visit = visits[visitIndex];
    if (!visit.isUpcoming) return false;

    if (reason.trim().isEmpty) {
      Get.snackbar(
        'Reason required',
        'Please provide a reason to cancel this visit.',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }

    try {
      if (_authController.isAuthenticated) {
        final ok = await _apiService.cancelVisit(visitIdInt, reason: reason);
        if (!ok) {
          throw Exception('Failed to cancel visit');
        }
      }

      // Reload visits to get updated state from server
      await loadVisits(isRefresh: true, silent: true);

      Get.snackbar(
        'Visit Cancelled',
        'Your visit has been cancelled',
        snackPosition: SnackPosition.TOP,
      );

      return true;
    } catch (e) {
      DebugLogger.error('Error cancelling visit: $e');
      Get.snackbar(
        'Cancellation Failed',
        'Failed to cancel visit: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }

  Future<bool> rescheduleVisit(dynamic visitId, DateTime newDateTime, {String? reason}) async {
    final visitIdInt = visitId is int ? visitId : int.tryParse(visitId.toString()) ?? 0;
    final visitIndex = visits.indexWhere((visit) => visit.id == visitIdInt);
    if (visitIndex == -1) return false;

    final visit = visits[visitIndex];
    if (!visit.isUpcoming) return false;

    try {
      if (_authController.isAuthenticated) {
        final ok = await _apiService.rescheduleVisit(
          visitIdInt,
          newDate: newDateTime.toUtc().toIso8601String(),
          reason: reason,
        );
        if (!ok) {
          throw Exception('Failed to reschedule visit');
        }
      }

      // Reload visits to get updated state from server
      await loadVisits(isRefresh: true, silent: true);

      Get.snackbar(
        'Visit Rescheduled',
        'Your visit has been rescheduled to ${formatVisitDate(newDateTime)} at ${formatVisitTime(newDateTime)}',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
      );

      return true;
    } catch (e) {
      DebugLogger.error('Error rescheduling visit: $e');
      Get.snackbar(
        'Reschedule Failed',
        'Failed to reschedule visit: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }

  void markVisitCompleted(dynamic visitId) {
    final visitIdInt = visitId is int ? visitId : int.tryParse(visitId.toString()) ?? 0;
    final visitIndex = visits.indexWhere((visit) => visit.id == visitIdInt);
    if (visitIndex != -1) {
      visits[visitIndex] = visits[visitIndex].copyWith(status: VisitStatus.completed);
    }
  }

  void _sortVisits() {
    final upcoming = visits.where((v) => v.isUpcoming).toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate)); // ascending
    final past = visits.where((v) => !v.isUpcoming).toList()
      ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate)); // descending
    visits.assignAll([...upcoming, ...past]);
  }

  List<VisitModel> get upcomingVisits {
    DebugLogger.info(
      '📊 Getter upcomingVisits called | rxLen=${upcomingVisitsList.length} loaded=${hasLoadedVisits.value} isLoading=${isLoading.value}',
    );
    if (upcomingVisitsList.isNotEmpty || hasLoadedVisits.value) {
      return upcomingVisitsList;
    }
    // Fallback compute
    final now = DateTime.now();
    final list =
        visits
            .where((v) => now.isBefore(v.scheduledDate) && v.status != VisitStatus.completed)
            .toList()
          ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    DebugLogger.info('📊 Getter upcomingVisits fallback computed=${list.length}');
    return list;
  }

  List<VisitModel> get pastVisits {
    DebugLogger.info(
      '📊 Getter pastVisits called | rxLen=${pastVisitsList.length} loaded=${hasLoadedVisits.value} isLoading=${isLoading.value}',
    );
    if (pastVisitsList.isNotEmpty || hasLoadedVisits.value) {
      return pastVisitsList;
    }
    // Fallback compute: all dates in the past, any status
    final now = DateTime.now();
    final list = visits.where((v) => !now.isBefore(v.scheduledDate)).toList()
      ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
    DebugLogger.info('📊 Getter pastVisits fallback computed=${list.length}');
    return list;
  }

  String formatVisitDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference > 1) {
      return 'In $difference days';
    } else {
      return '${difference.abs()} days ago';
    }
  }

  String formatVisitTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');

    return '$displayHour:$displayMinute $period';
  }
}
