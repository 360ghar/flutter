import 'package:get/get.dart';
import '../../../core/data/models/property_model.dart';
import '../../../core/data/models/booking_model.dart';
import '../../../core/data/providers/api_service.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/utils/debug_logger.dart';

class BookingController extends GetxController {
  late final ApiService _apiService;
  late final AuthController _authController;
  
  final RxList<BookingModel> bookings = <BookingModel>[].obs;
  final RxList<BookingModel> upcomingBookings = <BookingModel>[].obs;
  final RxList<BookingModel> pastBookings = <BookingModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isCreatingBooking = false.obs;
  final RxString error = ''.obs;
  
  // Payment related observables
  final RxBool isProcessingPayment = false.obs;
  final RxString paymentStatus = ''.obs;
  final Rxn<Map<String, dynamic>> currentPaymentSession = Rxn<Map<String, dynamic>>();

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
    if (_authController.isAuthenticated) {
      await loadBookings();
    }
  }
  
  void _clearAllData() {
    bookings.clear();
    upcomingBookings.clear();
    pastBookings.clear();
    currentPaymentSession.value = null;
    paymentStatus.value = '';
    error.value = '';
  }

  Future<void> loadBookings() async {
    if (!_authController.isAuthenticated) {
      error.value = 'User not authenticated';
      return;
    }

    try {
      isLoading.value = true;
      error.value = '';
      
      DebugLogger.info('🔍 Loading user bookings...');
      
      final allBookings = await _apiService.getMyBookings();
      bookings.assignAll(allBookings);
      
      // Categorize bookings
      final upcoming = <BookingModel>[];
      final past = <BookingModel>[];
      
      final now = DateTime.now();
      
      for (final booking in allBookings) {
        if (booking.checkOutDate.isAfter(now) && 
            (booking.bookingStatus == BookingStatus.confirmed || booking.bookingStatus == BookingStatus.pending)) {
          upcoming.add(booking);
        } else {
          past.add(booking);
        }
      }
      
      upcomingBookings.assignAll(upcoming);
      pastBookings.assignAll(past);
      
      // Sort bookings
      _sortBookings();
      
      DebugLogger.success('✅ Bookings loaded: ${allBookings.length} total, ${upcoming.length} upcoming, ${past.length} past');
      
      // Track analytics
      await _apiService.trackEvent('bookings_loaded', {
        'total_count': allBookings.length,
        'upcoming_count': upcoming.length,
        'past_count': past.length,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      error.value = 'Failed to load bookings: ${e.toString()}';
      DebugLogger.error('❌ Error loading bookings: $e');
      
      Get.snackbar(
        'Error',
        'Failed to load bookings',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createBooking({
    required dynamic property, // PropertyModel or PropertyCardModel
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int guestsCount,
    String? specialRequests,
    Map<String, dynamic>? guestDetails,
  }) async {
    if (!_authController.isAuthenticated) {
      Get.snackbar(
        'Authentication Required',
        'Please login to make bookings',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }

    try {
      isCreatingBooking.value = true;
      error.value = '';
      
      // Extract property details based on type
      final int propertyId = property is PropertyModel 
          ? int.tryParse(property.id.toString()) ?? 0
          : property.id as int;
      final String propertyTitle = property is PropertyModel 
          ? property.title 
          : property.title as String;
      
      DebugLogger.info('🏠 Creating booking for property: $propertyTitle');
      
      final booking = await _apiService.createBooking(
        propertyId: propertyId,
        checkInDate: checkInDate.toIso8601String().split('T')[0],
        checkOutDate: checkOutDate.toIso8601String().split('T')[0],
        guestsCount: guestsCount,
        specialRequests: specialRequests,
        guestDetails: guestDetails,
      );
      
      // Add to local state
      bookings.insert(0, booking);
      if (booking.checkOutDate.isAfter(DateTime.now())) {
        upcomingBookings.insert(0, booking);
      }
      _sortBookings();
      
      DebugLogger.success('✅ Booking created successfully: ${booking.id}');
      
      // Track analytics
      await _apiService.trackBookingAction(
        action: 'created',
        bookingId: booking.id,
        propertyId: propertyId,
        additionalData: {
          'check_in_date': checkInDate.toIso8601String().split('T')[0],
          'check_out_date': checkOutDate.toIso8601String().split('T')[0],
          'guests_count': guestsCount,
          'has_special_requests': specialRequests != null,
        },
      );
      
      Get.snackbar(
        'Booking Created',
        'Your booking for $propertyTitle has been created successfully',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
      );
      
      return true;
    } catch (e) {
      error.value = e.toString();
      DebugLogger.error('❌ Error creating booking: $e');
      
      Get.snackbar(
        'Booking Failed',
        'Failed to create booking: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );
      
      return false;
    } finally {
      isCreatingBooking.value = false;
    }
  }

  Future<BookingModel?> getBookingDetails(int bookingId) async {
    try {
      DebugLogger.info('🔍 Fetching booking details for ID: $bookingId');
      
      final booking = await _apiService.getBookingDetails(bookingId);
      
      DebugLogger.success('✅ Booking details loaded: ${booking.id}');
      
      // Update local booking if it exists
      final index = bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        bookings[index] = booking;
      }
      
      return booking;
    } catch (e) {
      DebugLogger.error('❌ Error fetching booking details: $e');
      Get.snackbar(
        'Error',
        'Failed to load booking details',
        snackPosition: SnackPosition.TOP,
      );
      return null;
    }
  }

  Future<bool> updateBooking(int bookingId, Map<String, dynamic> updateData) async {
    try {
      DebugLogger.info('✏️ Updating booking: $bookingId');
      
      final updatedBooking = await _apiService.updateBooking(bookingId, updateData);
      
      // Update local state
      final index = bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        bookings[index] = updatedBooking;
        
        // Update categorized lists
        _updateCategorizedLists();
      }
      
      DebugLogger.success('✅ Booking updated successfully');
      
      // Track analytics
      await _apiService.trackBookingAction(
        action: 'updated',
        bookingId: bookingId,
        additionalData: updateData,
      );
      
      Get.snackbar(
        'Booking Updated',
        'Your booking has been updated successfully',
        snackPosition: SnackPosition.TOP,
      );
      
      return true;
    } catch (e) {
      DebugLogger.error('❌ Error updating booking: $e');
      Get.snackbar(
        'Update Failed',
        'Failed to update booking: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }

  Future<bool> cancelBooking(int bookingId, {String? reason}) async {
    try {
      DebugLogger.info('❌ Cancelling booking: $bookingId');
      
      await _apiService.cancelBooking(bookingId, reason: reason);
      
      // Update local state
      final index = bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        // Reload bookings to get updated state from server
        await loadBookings();
        _updateCategorizedLists();
      }
      
      DebugLogger.success('✅ Booking cancelled successfully');
      
      // Track analytics
      await _apiService.trackBookingAction(
        action: 'cancelled',
        bookingId: bookingId,
        additionalData: {
          if (reason != null) 'cancellation_reason': reason,
        },
      );
      
      Get.snackbar(
        'Booking Cancelled',
        'Your booking has been cancelled',
        snackPosition: SnackPosition.TOP,
      );
      
      return true;
    } catch (e) {
      DebugLogger.error('❌ Error cancelling booking: $e');
      Get.snackbar(
        'Cancellation Failed',
        'Failed to cancel booking: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }

  Future<bool> initiatePayment(int bookingId, {
    String paymentMethod = 'card',
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      isProcessingPayment.value = true;
      paymentStatus.value = 'initiating';
      
      DebugLogger.info('💳 Initiating payment for booking: $bookingId');
      
      final paymentSession = await _apiService.initiatePayment(
        bookingId,
        paymentMethod: paymentMethod,
        paymentDetails: paymentDetails,
      );
      
      currentPaymentSession.value = paymentSession;
      paymentStatus.value = 'pending';
      
      DebugLogger.success('✅ Payment session created');
      
      // Track analytics
      await _apiService.trackBookingAction(
        action: 'payment_initiated',
        bookingId: bookingId,
        additionalData: {
          'payment_method': paymentMethod,
          'payment_session_id': paymentSession['session_id'],
        },
      );
      
      return true;
    } catch (e) {
      paymentStatus.value = 'failed';
      DebugLogger.error('❌ Error initiating payment: $e');
      Get.snackbar(
        'Payment Failed',
        'Failed to initiate payment: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } finally {
      isProcessingPayment.value = false;
    }
  }

  Future<bool> confirmPayment(int bookingId, String paymentReference) async {
    try {
      DebugLogger.info('✅ Confirming payment for booking: $bookingId');
      
      await _apiService.confirmPayment(bookingId, paymentReference);
      
      // Update booking status
      final index = bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        // Reload bookings to get updated state from server
        await loadBookings();
        _updateCategorizedLists();
      }
      
      paymentStatus.value = 'completed';
      currentPaymentSession.value = null;
      
      DebugLogger.success('✅ Payment confirmed successfully');
      
      // Track analytics
      await _apiService.trackBookingAction(
        action: 'payment_completed',
        bookingId: bookingId,
        additionalData: {
          'payment_reference': paymentReference,
        },
      );
      
      Get.snackbar(
        'Payment Successful',
        'Your payment has been processed successfully',
        snackPosition: SnackPosition.TOP,
      );
      
      return true;
    } catch (e) {
      paymentStatus.value = 'failed';
      DebugLogger.error('❌ Error confirming payment: $e');
      Get.snackbar(
        'Payment Confirmation Failed',
        'Failed to confirm payment: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }

  Future<Map<String, dynamic>?> getPaymentStatus(int bookingId) async {
    try {
      final status = await _apiService.getPaymentStatus(bookingId);
      paymentStatus.value = status['status'] ?? 'unknown';
      return status;
    } catch (e) {
      DebugLogger.error('❌ Error getting payment status: $e');
      return null;
    }
  }

  void _updateCategorizedLists() {
    final upcoming = <BookingModel>[];
    final past = <BookingModel>[];
    final now = DateTime.now();
    
    for (final booking in bookings) {
      if (booking.checkOutDate.isAfter(now) && 
          (booking.bookingStatus == BookingStatus.confirmed || booking.bookingStatus == BookingStatus.pending)) {
        upcoming.add(booking);
      } else {
        past.add(booking);
      }
    }
    
    upcomingBookings.assignAll(upcoming);
    pastBookings.assignAll(past);
  }

  void _sortBookings() {
    bookings.sort((a, b) {
      // Upcoming bookings first, then by check-in date
      if (a.checkOutDate.isAfter(DateTime.now()) && !b.checkOutDate.isAfter(DateTime.now())) {
        return -1;
      } else if (!a.checkOutDate.isAfter(DateTime.now()) && b.checkOutDate.isAfter(DateTime.now())) {
        return 1;
      } else {
        return b.checkInDate.compareTo(a.checkInDate);
      }
    });
    
    upcomingBookings.sort((a, b) => a.checkInDate.compareTo(b.checkInDate));
    pastBookings.sort((a, b) => b.checkInDate.compareTo(a.checkInDate));
  }

  // Utility methods
  bool hasActiveBookings() {
    return upcomingBookings.any((booking) => 
      booking.bookingStatus == BookingStatus.confirmed || 
      booking.bookingStatus == BookingStatus.pending
    );
  }

  int get totalBookingsCount => bookings.length;
  int get upcomingBookingsCount => upcomingBookings.length;
  int get pastBookingsCount => pastBookings.length;

  String formatBookingDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
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

  String formatBookingDuration(BookingModel booking) {
    final duration = booking.checkOutDate.difference(booking.checkInDate).inDays;
    return '$duration ${duration == 1 ? 'night' : 'nights'}';
  }

  double calculateTotalAmount(BookingModel booking) {
    // This would typically include base price, taxes, fees, etc.
    return booking.totalAmount;
  }

  bool canCancelBooking(BookingModel booking) {
    // Allow cancellation only for upcoming bookings that are not checked in
    return booking.checkInDate.isAfter(DateTime.now()) && 
           (booking.bookingStatus == BookingStatus.confirmed || booking.bookingStatus == BookingStatus.pending);
  }

  bool canModifyBooking(BookingModel booking) {
    // Allow modification only for future bookings
    return booking.checkInDate.isAfter(DateTime.now().add(const Duration(days: 1))) &&
           booking.bookingStatus == BookingStatus.confirmed;
  }
}