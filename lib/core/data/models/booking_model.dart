import 'package:json_annotation/json_annotation.dart';

part 'booking_model.g.dart';

enum BookingStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('confirmed')
  confirmed,
  @JsonValue('checked_in')
  checkedIn,
  @JsonValue('checked_out')
  checkedOut,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('completed')
  completed,
}

enum PaymentStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('partial')
  partial,
  @JsonValue('paid')
  paid,
  @JsonValue('refunded')
  refunded,
  @JsonValue('failed')
  failed,
}

@JsonSerializable()
class BookingModel {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'property_id')
  final int propertyId;
  @JsonKey(name: 'check_in_date')
  final DateTime checkInDate;
  @JsonKey(name: 'check_out_date')
  final DateTime checkOutDate;
  final int guests;
  @JsonKey(name: 'primary_guest_name', defaultValue: 'Unknown Guest')
  final String primaryGuestName;
  @JsonKey(name: 'primary_guest_phone', defaultValue: '')
  final String primaryGuestPhone;
  @JsonKey(name: 'primary_guest_email', defaultValue: '')
  final String primaryGuestEmail;
  @JsonKey(name: 'special_requests')
  final String? specialRequests;
  @JsonKey(name: 'booking_reference')
  final String bookingReference;
  final int nights;
  @JsonKey(name: 'base_amount')
  final double baseAmount;
  @JsonKey(name: 'taxes_amount')
  final double taxesAmount;
  @JsonKey(name: 'service_charges')
  final double serviceCharges;
  @JsonKey(name: 'discount_amount')
  final double discountAmount;
  @JsonKey(name: 'total_amount')
  final double totalAmount;
  @JsonKey(name: 'booking_status')
  final BookingStatus bookingStatus;
  @JsonKey(name: 'payment_status')
  final PaymentStatus paymentStatus;
  @JsonKey(name: 'guest_details')
  final Map<String, dynamic>? guestDetails;
  @JsonKey(name: 'internal_notes')
  final String? internalNotes;
  @JsonKey(name: 'actual_check_in')
  final DateTime? actualCheckIn;
  @JsonKey(name: 'actual_check_out')
  final DateTime? actualCheckOut;
  @JsonKey(name: 'early_check_in', defaultValue: false)
  final bool earlyCheckIn;
  @JsonKey(name: 'late_check_out', defaultValue: false)
  final bool lateCheckOut;
  @JsonKey(name: 'cancellation_date')
  final DateTime? cancellationDate;
  @JsonKey(name: 'cancellation_reason')
  final String? cancellationReason;
  @JsonKey(name: 'refund_amount')
  final double? refundAmount;
  @JsonKey(name: 'payment_method')
  final String? paymentMethod;
  @JsonKey(name: 'transaction_id')
  final String? transactionId;
  @JsonKey(name: 'payment_date')
  final DateTime? paymentDate;
  @JsonKey(name: 'guest_rating')
  final int? guestRating;
  @JsonKey(name: 'guest_review')
  final String? guestReview;
  @JsonKey(name: 'host_rating')
  final int? hostRating;
  @JsonKey(name: 'host_review')
  final String? hostReview;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  BookingModel({
    required this.id,
    required this.userId,
    required this.propertyId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guests,
    required this.primaryGuestName,
    required this.primaryGuestPhone,
    required this.primaryGuestEmail,
    this.specialRequests,
    required this.bookingReference,
    required this.nights,
    required this.baseAmount,
    required this.taxesAmount,
    required this.serviceCharges,
    required this.discountAmount,
    required this.totalAmount,
    required this.bookingStatus,
    required this.paymentStatus,
    this.guestDetails,
    this.internalNotes,
    this.actualCheckIn,
    this.actualCheckOut,
    required this.earlyCheckIn,
    required this.lateCheckOut,
    this.cancellationDate,
    this.cancellationReason,
    this.refundAmount,
    this.paymentMethod,
    this.transactionId,
    this.paymentDate,
    this.guestRating,
    this.guestReview,
    this.hostRating,
    this.hostReview,
    required this.createdAt,
    this.updatedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) => _$BookingModelFromJson(json);

  Map<String, dynamic> toJson() => _$BookingModelToJson(this);

  // Convenience getters
  Duration get duration => checkOutDate.difference(checkInDate);
  bool get isActive => bookingStatus == BookingStatus.confirmed || bookingStatus == BookingStatus.checkedIn;
  bool get isCompleted => bookingStatus == BookingStatus.completed || bookingStatus == BookingStatus.checkedOut;
  bool get isCancelled => bookingStatus == BookingStatus.cancelled;
  bool get isPaid => paymentStatus == PaymentStatus.paid;
  bool get isRefunded => paymentStatus == PaymentStatus.refunded;
  bool get isPending => bookingStatus == BookingStatus.pending;
  
  String get formattedTotal => '₹${totalAmount.toStringAsFixed(2)}';
  String get formattedBaseAmount => '₹${baseAmount.toStringAsFixed(2)}';
  String get formattedTaxes => '₹${taxesAmount.toStringAsFixed(2)}';
  String get formattedServiceCharges => '₹${serviceCharges.toStringAsFixed(2)}';
  String get formattedDiscount => '₹${discountAmount.toStringAsFixed(2)}';
  
  String get bookingStatusString {
    switch (bookingStatus) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.checkedIn:
        return 'Checked In';
      case BookingStatus.checkedOut:
        return 'Checked Out';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
    }
  }
  
  String get paymentStatusString {
    switch (paymentStatus) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.partial:
        return 'Partial';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.failed:
        return 'Failed';
    }
  }
  
  bool get canCancel => bookingStatus == BookingStatus.pending || bookingStatus == BookingStatus.confirmed;
  bool get canCheckIn => bookingStatus == BookingStatus.confirmed && DateTime.now().isAfter(checkInDate.subtract(const Duration(hours: 2)));
  bool get canCheckOut => bookingStatus == BookingStatus.checkedIn;
  bool get canRate => bookingStatus == BookingStatus.completed && guestRating == null;
}

@JsonSerializable()
class BookingListResponse {
  final List<BookingModel> bookings;
  final int total;
  final int upcoming;
  final int completed;
  final int cancelled;

  BookingListResponse({
    required this.bookings,
    required this.total,
    required this.upcoming,
    required this.completed,
    required this.cancelled,
  });

  factory BookingListResponse.fromJson(Map<String, dynamic> json) => _$BookingListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$BookingListResponseToJson(this);
}