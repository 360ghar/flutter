import 'package:get/get.dart';
import 'package:flutter/widgets.dart';
import '../../../core/data/models/property_model.dart';
import '../../../core/data/models/visit_model.dart';
import '../../../core/data/models/agent_model.dart';
import '../../../core/data/providers/api_service.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/utils/debug_logger.dart'; // Added missing import
import '../../dashboard/controllers/dashboard_controller.dart';

class VisitsController extends GetxController {
  late final ApiService _apiService;
  late final AuthController _authController;
  
  final RxList<VisitModel> visits = <VisitModel>[].obs;
  final RxList<VisitModel> upcomingVisitsList = <VisitModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingAgent = false.obs;
  final RxBool isBookingVisit = false.obs;
  final RxString error = ''.obs;
  final Rxn<AgentModel> relationshipManager = Rxn<AgentModel>();
  
  // Track if data has been loaded to prevent infinite loops
  final RxBool hasLoadedVisits = false.obs;
  final RxBool hasLoadedAgent = false.obs;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _authController = Get.find<AuthController>();
    
    // Listen to authentication state changes
    ever(_authController.isLoggedIn, (bool isLoggedIn) {
      if (isLoggedIn) {
        // User is logged in, safe to fetch data
        _initializeController();
      } else {
        // User logged out, clear all data
        _clearAllData();
      }
    });
    
    // If already logged in, initialize immediately
    if (_authController.isLoggedIn.value) {
      _initializeController();
    }

    // Observe dashboard tab switches to refresh when Visits tab is active
    if (Get.isRegistered<DashboardController>()) {
      final dash = Get.find<DashboardController>();
      DateTime? _lastRefresh;
      const cooldown = Duration(seconds: 30);

      ever<int>(dash.currentIndex, (idx) async {
        if (idx == 4) {
          final now = DateTime.now();
          // Throttle to avoid spamming refresh
          if (_lastRefresh == null || now.difference(_lastRefresh!) > cooldown) {
            DebugLogger.info('🔄 Visits tab activated — refreshing visits');
            await loadVisits(isRefresh: true);
            _lastRefresh = now;
          } else {
            DebugLogger.info('⏳ Skipping visits refresh due to cooldown');
          }
        }
      });

      // If app starts on Visits tab, ensure data loads quickly
      if (dash.currentIndex.value == 4) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!hasLoadedVisits.value && !isLoading.value) {
            loadVisitsLazy();
          }
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
    if (hasLoadedVisits.value || isLoading.value) return; // Prevent infinite loop
    hasLoadedVisits.value = true;
    await loadVisits();
  }

  Future<void> loadRelationshipManagerLazy() async {
    if (hasLoadedAgent.value || isLoadingAgent.value) return; // Prevent infinite loop
    hasLoadedAgent.value = true;
    await loadRelationshipManager();
  }

  Future<void> loadVisits({bool isRefresh = false}) async {
    if (!_authController.isAuthenticated) {
      error.value = 'User not authenticated';
      return;
    }

    try {
      if (isRefresh) {
        // For pull-to-refresh, clear existing data
        visits.clear();
        upcomingVisitsList.clear();
      }
      
      isLoading.value = true;
      error.value = '';
      
      // Load all visits using single endpoint
      final allVisits = await _apiService.getMyVisits();
      
      // Separate upcoming and past visits locally
      final upcomingVisits = allVisits.where((visit) => visit.isUpcoming).toList();
      final pastVisits = allVisits.where((visit) => visit.isCompleted || visit.isCancelled).toList();
      
      // Update reactive variables
      visits.assignAll(allVisits);
      upcomingVisitsList.assignAll(upcomingVisits);
      
      // Sort visits by date
      _sortVisits();
      
      DebugLogger.success('✅ Visits loaded successfully: ${allVisits.length} total, ${upcomingVisits.length} upcoming, ${pastVisits.length} past');
    } catch (e) {
      error.value = 'Failed to load visits: ${e.toString()}';
      DebugLogger.error('❌ Error loading visits: $e');
    } finally {
      isLoading.value = false;
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
      
      final visitResponse = await _apiService.scheduleVisit(
        propertyId: propertyId,
        scheduledDate: visitDateTime.toIso8601String(),
        specialRequirements: notes ?? 'Property visit scheduled through 360ghar app',
      );
      
      DebugLogger.success('✅ Visit scheduled successfully: ${visitResponse['id']}');
      
      // The API returns the complete visit model, no need to reconstruct
      // Just reload visits to get the updated list
      await loadVisits();
      
      
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

  Future<bool> cancelVisit(dynamic visitId, {String? reason}) async {
    final visitIdInt = visitId is int ? visitId : int.tryParse(visitId.toString()) ?? 0;
    final visitIndex = visits.indexWhere((visit) => visit.id == visitIdInt);
    if (visitIndex == -1) return false;
    
    final visit = visits[visitIndex];
    if (!visit.isUpcoming) return false;

    try {
      if (_authController.isAuthenticated) {
        await _apiService.cancelVisit(visitIdInt, reason: reason);
        
      }
      
      // Reload visits to get updated state from server
      await loadVisits();
      
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
        await _apiService.rescheduleVisit(
          visitIdInt,
          newDateTime.toIso8601String(),
        );
        
      }
      
      // Reload visits to get updated state from server
      await loadVisits();
      
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
    visits.sort((a, b) {
      // Upcoming visits first, then by date
      if (a.isUpcoming && !b.isUpcoming) {
        return -1;
      } else if (!a.isUpcoming && b.isUpcoming) {
        return 1;
      } else {
        return b.scheduledDate.compareTo(a.scheduledDate);
      }
    });
  }

  List<VisitModel> get upcomingVisits {
    return visits.where((visit) => visit.isUpcoming).toList();
  }

  List<VisitModel> get pastVisits {
    return visits.where((visit) => 
      visit.isCompleted || 
      visit.isCancelled
    ).toList();
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
