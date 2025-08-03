// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingModel _$BookingModelFromJson(Map<String, dynamic> json) => BookingModel(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      propertyId: (json['property_id'] as num).toInt(),
      checkInDate: DateTime.parse(json['check_in_date'] as String),
      checkOutDate: DateTime.parse(json['check_out_date'] as String),
      guests: (json['guests'] as num).toInt(),
      primaryGuestName:
          json['primary_guest_name'] as String? ?? 'Unknown Guest',
      primaryGuestPhone: json['primary_guest_phone'] as String? ?? '',
      primaryGuestEmail: json['primary_guest_email'] as String? ?? '',
      specialRequests: json['special_requests'] as String?,
      bookingReference: json['booking_reference'] as String,
      nights: (json['nights'] as num).toInt(),
      baseAmount: (json['base_amount'] as num).toDouble(),
      taxesAmount: (json['taxes_amount'] as num).toDouble(),
      serviceCharges: (json['service_charges'] as num).toDouble(),
      discountAmount: (json['discount_amount'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      bookingStatus:
          $enumDecode(_$BookingStatusEnumMap, json['booking_status']),
      paymentStatus:
          $enumDecode(_$PaymentStatusEnumMap, json['payment_status']),
      guestDetails: json['guest_details'] as Map<String, dynamic>?,
      internalNotes: json['internal_notes'] as String?,
      actualCheckIn: json['actual_check_in'] == null
          ? null
          : DateTime.parse(json['actual_check_in'] as String),
      actualCheckOut: json['actual_check_out'] == null
          ? null
          : DateTime.parse(json['actual_check_out'] as String),
      earlyCheckIn: json['early_check_in'] as bool? ?? false,
      lateCheckOut: json['late_check_out'] as bool? ?? false,
      cancellationDate: json['cancellation_date'] == null
          ? null
          : DateTime.parse(json['cancellation_date'] as String),
      cancellationReason: json['cancellation_reason'] as String?,
      refundAmount: (json['refund_amount'] as num?)?.toDouble(),
      paymentMethod: json['payment_method'] as String?,
      transactionId: json['transaction_id'] as String?,
      paymentDate: json['payment_date'] == null
          ? null
          : DateTime.parse(json['payment_date'] as String),
      guestRating: (json['guest_rating'] as num?)?.toInt(),
      guestReview: json['guest_review'] as String?,
      hostRating: (json['host_rating'] as num?)?.toInt(),
      hostReview: json['host_review'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$BookingModelToJson(BookingModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'property_id': instance.propertyId,
      'check_in_date': instance.checkInDate.toIso8601String(),
      'check_out_date': instance.checkOutDate.toIso8601String(),
      'guests': instance.guests,
      'primary_guest_name': instance.primaryGuestName,
      'primary_guest_phone': instance.primaryGuestPhone,
      'primary_guest_email': instance.primaryGuestEmail,
      'special_requests': instance.specialRequests,
      'booking_reference': instance.bookingReference,
      'nights': instance.nights,
      'base_amount': instance.baseAmount,
      'taxes_amount': instance.taxesAmount,
      'service_charges': instance.serviceCharges,
      'discount_amount': instance.discountAmount,
      'total_amount': instance.totalAmount,
      'booking_status': _$BookingStatusEnumMap[instance.bookingStatus]!,
      'payment_status': _$PaymentStatusEnumMap[instance.paymentStatus]!,
      'guest_details': instance.guestDetails,
      'internal_notes': instance.internalNotes,
      'actual_check_in': instance.actualCheckIn?.toIso8601String(),
      'actual_check_out': instance.actualCheckOut?.toIso8601String(),
      'early_check_in': instance.earlyCheckIn,
      'late_check_out': instance.lateCheckOut,
      'cancellation_date': instance.cancellationDate?.toIso8601String(),
      'cancellation_reason': instance.cancellationReason,
      'refund_amount': instance.refundAmount,
      'payment_method': instance.paymentMethod,
      'transaction_id': instance.transactionId,
      'payment_date': instance.paymentDate?.toIso8601String(),
      'guest_rating': instance.guestRating,
      'guest_review': instance.guestReview,
      'host_rating': instance.hostRating,
      'host_review': instance.hostReview,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$BookingStatusEnumMap = {
  BookingStatus.pending: 'pending',
  BookingStatus.confirmed: 'confirmed',
  BookingStatus.checkedIn: 'checked_in',
  BookingStatus.checkedOut: 'checked_out',
  BookingStatus.cancelled: 'cancelled',
  BookingStatus.completed: 'completed',
};

const _$PaymentStatusEnumMap = {
  PaymentStatus.pending: 'pending',
  PaymentStatus.partial: 'partial',
  PaymentStatus.paid: 'paid',
  PaymentStatus.refunded: 'refunded',
  PaymentStatus.failed: 'failed',
};

BookingListResponse _$BookingListResponseFromJson(Map<String, dynamic> json) =>
    BookingListResponse(
      bookings: (json['bookings'] as List<dynamic>)
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      upcoming: (json['upcoming'] as num).toInt(),
      completed: (json['completed'] as num).toInt(),
      cancelled: (json['cancelled'] as num).toInt(),
    );

Map<String, dynamic> _$BookingListResponseToJson(
        BookingListResponse instance) =>
    <String, dynamic>{
      'bookings': instance.bookings,
      'total': instance.total,
      'upcoming': instance.upcoming,
      'completed': instance.completed,
      'cancelled': instance.cancelled,
    };
