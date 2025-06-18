import 'package:get/get.dart';
import '../data/models/property_model.dart';
import '../data/models/visit_model.dart';
import '../data/models/agent_model.dart';

class VisitsController extends GetxController {
  final RxList<VisitModel> visits = <VisitModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  
  // Relationship Manager (Agent) info
  final Rx<AgentModel> relationshipManager = AgentModel(
    id: 'rm_001',
    name: 'Priya Sharma',
    phone: '+91 98765 43210',
    email: 'priya.sharma@360ghar.com',
    image: 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face',
    rating: 4.8,
    experience: '5+ years',
    specialization: 'Residential Properties',
  ).obs;

  @override
  void onInit() {
    super.onInit();
    _loadMockVisits();
  }

  void _loadMockVisits() {
    // Add some mock visits for demonstration
    visits.addAll([
      VisitModel(
        id: 'visit_001',
        propertyId: 'prop_001',
        propertyTitle: 'Luxury Villa in Gurgaon',
        propertyImage: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=300&h=200&fit=crop',
        visitDateTime: DateTime.now().add(const Duration(days: 2)),
        status: VisitStatus.upcoming,
        agentName: 'Priya Sharma',
        agentPhone: '+91 98765 43210',
        notes: 'First visit to check the property layout and amenities',
      ),
      VisitModel(
        id: 'visit_002',
        propertyId: 'prop_002',
        propertyTitle: 'Modern Apartment in Mumbai',
        propertyImage: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=300&h=200&fit=crop',
        visitDateTime: DateTime.now().subtract(const Duration(days: 5)),
        status: VisitStatus.completed,
        agentName: 'Priya Sharma',
        agentPhone: '+91 98765 43210',
        notes: 'Great property, considering for purchase',
      ),
    ]);
  }

  void bookVisit(PropertyModel property, DateTime visitDateTime) {
    final visit = VisitModel(
      id: 'visit_${DateTime.now().millisecondsSinceEpoch}',
      propertyId: property.id,
      propertyTitle: property.title,
      propertyImage: property.images.isNotEmpty ? property.images.first : '',
      visitDateTime: visitDateTime,
      status: VisitStatus.upcoming,
      agentName: relationshipManager.value.name,
      agentPhone: relationshipManager.value.phone,
      notes: 'Property visit scheduled through 360ghar app',
    );
    
    visits.insert(0, visit);
    _sortVisits();
  }

  void cancelVisit(String visitId) {
    final visitIndex = visits.indexWhere((visit) => visit.id == visitId);
    if (visitIndex != -1) {
      final visit = visits[visitIndex];
      if (visit.status == VisitStatus.upcoming) {
        visits[visitIndex] = visit.copyWith(status: VisitStatus.cancelled);
        Get.snackbar(
          'Visit Cancelled',
          'Your visit to ${visit.propertyTitle} has been cancelled',
          snackPosition: SnackPosition.TOP,
        );
      }
    }
  }

  void rescheduleVisit(String visitId, DateTime newDateTime) {
    final visitIndex = visits.indexWhere((visit) => visit.id == visitId);
    if (visitIndex != -1) {
      final visit = visits[visitIndex];
      if (visit.status == VisitStatus.upcoming) {
        visits[visitIndex] = visit.copyWith(
          visitDateTime: newDateTime,
          status: VisitStatus.upcoming,
        );
        _sortVisits();
        Get.snackbar(
          'Visit Rescheduled',
          'Your visit to ${visit.propertyTitle} has been rescheduled',
          snackPosition: SnackPosition.TOP,
        );
      }
    }
  }

  void markVisitCompleted(String visitId) {
    final visitIndex = visits.indexWhere((visit) => visit.id == visitId);
    if (visitIndex != -1) {
      visits[visitIndex] = visits[visitIndex].copyWith(status: VisitStatus.completed);
    }
  }

  void _sortVisits() {
    visits.sort((a, b) {
      // Upcoming visits first, then by date
      if (a.status == VisitStatus.upcoming && b.status != VisitStatus.upcoming) {
        return -1;
      } else if (a.status != VisitStatus.upcoming && b.status == VisitStatus.upcoming) {
        return 1;
      } else {
        return b.visitDateTime.compareTo(a.visitDateTime);
      }
    });
  }

  List<VisitModel> get upcomingVisits {
    return visits.where((visit) => visit.status == VisitStatus.upcoming).toList();
  }

  List<VisitModel> get pastVisits {
    return visits.where((visit) => 
      visit.status == VisitStatus.completed || 
      visit.status == VisitStatus.cancelled
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