import 'package:get/get.dart';
import '../../../core/data/models/property_model.dart';
import '../../../core/data/models/visit_model.dart';
import '../../../core/data/models/agent_model.dart';
import '../../../core/data/providers/api_service.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/utils/debug_logger.dart'; // Added missing import

class VisitsController extends GetxController {
  late final ApiService _apiService;
  late final AuthController _authController;
  
  final RxList<VisitModel> visits = <VisitModel>[].obs;
  final RxList<VisitModel> upcomingVisitsList = <VisitModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingAgent = false.obs;
  final RxBool isBookingVisit = false.obs;
  final RxString error = ''.obs;
  final Rxn<RelationshipManagerModel> relationshipManagerData = Rxn<RelationshipManagerModel>();
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
  }

  Future<void> _initializeController() async {
    // Don't eagerly load data - let views request it when needed
    // await loadVisits();
    // await loadRelationshipManager();
  }
  
  void _clearAllData() {
    visits.clear();
    upcomingVisitsList.clear();
    relationshipManagerData.value = null;
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

  Future<void> loadVisits() async {
    if (!_authController.isAuthenticated) {
      error.value = 'User not authenticated';
      return;
    }

    try {
      isLoading.value = true;
      error.value = '';
      
      final visitResponse = await _apiService.getMyVisits();
      final List<VisitModel> visitsData = visitResponse.visits;
      
      // Categorize visits based on status and date
      final List<VisitModel> upcomingVisits = [];
      
      for (final visit in visitsData) {
        // Categorize visits based on status and date
        if (visit.isUpcoming && visit.scheduledDate.isAfter(DateTime.now())) {
          upcomingVisits.add(visit);
        }
      }
      
      // Update reactive variables
      visits.assignAll(visitsData);
      upcomingVisitsList.assignAll(upcomingVisits);
      
      // Sort visits by date
      _sortVisits();
      
      DebugLogger.success('✅ Visits loaded successfully: ${visitsData.length} total, ${upcomingVisits.length} upcoming');
    } catch (e) {
      error.value = 'Failed to load visits: ${e.toString()}';
      DebugLogger.error('❌ Error loading visits: $e');
    } finally {
      isLoading.value = false;
    }
  }




  Future<void> loadRelationshipManager() async {
    if (!_authController.isAuthenticated) return;

    try {
      isLoadingAgent.value = true;
      final rmData = await _apiService.getRelationshipManager();
      relationshipManagerData.value = rmData;
      
      // Update the AgentModel for backward compatibility
      relationshipManager.value = AgentModel(
        id: rmData.id.toString(),
        name: rmData.name,
        phone: rmData.phone,
        email: rmData.email,
        image: rmData.profileImageUrl ?? 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face',
        rating: rmData.customerRating != null ? double.tryParse(rmData.customerRating!) ?? 4.5 : 4.5,
        experience: '${rmData.experienceYears ?? 3}+ years',
        specialization: rmData.department,
      );
      
      DebugLogger.success('✅ Relationship manager loaded successfully: ${rmData.name}');
    } catch (e) {
      DebugLogger.error('❌ Error loading relationship manager: $e');
      error.value = 'Failed to load relationship manager';
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
        visitDate: visitDateTime.toIso8601String().split('T')[0],
        visitTime: '${visitDateTime.hour.toString().padLeft(2, '0')}:${visitDateTime.minute.toString().padLeft(2, '0')}:00',
        visitType: visitType,
        notes: notes ?? 'Property visit scheduled through 360ghar app',
        contactPreference: contactPreference,
        guestsCount: guestsCount,
      );
      
      DebugLogger.success('✅ Visit scheduled successfully: ${visitResponse['id']}');
      
      // The API returns the complete visit model, no need to reconstruct
      // Just reload visits to get the updated list
      await loadVisits();
      
      // Track analytics
      await _apiService.trackVisitScheduling(
        propertyId: propertyId,
        visitType: visitType,
        visitDate: visitDateTime.toIso8601String().split('T')[0],
        additionalData: {
          'guests_count': guestsCount,
          'contact_preference': contactPreference,
        },
      );
      
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
      visitorName: 'Current User',
      visitorPhone: '',
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
        
        // Track analytics
        await _apiService.trackEvent('visit_cancelled', {
          'visit_id': visitIdInt,
          'property_id': visit.propertyId,
          'reason': reason ?? 'user_cancelled',
        });
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
          reason: reason,
        );
        
        // Track analytics
        await _apiService.trackEvent('visit_rescheduled', {
          'visit_id': visitIdInt,
          'property_id': visit.propertyId,
          'new_date': newDateTime.toIso8601String(),
          'reason': reason ?? 'user_rescheduled',
        });
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