import 'package:dio/dio.dart';
import '../models/booking.dart';
import '../models/wallet.dart';
import '../network/dio_client.dart';

class BookingResponse {
  final Booking booking;
  final Wallet wallet;

  BookingResponse({required this.booking, required this.wallet});
}

class BookingService {
  final DioClient _dioClient;

  BookingService(this._dioClient);

  Future<BookingResponse> createBooking({
    required String mentorListingId,
    required DateTime scheduledFor,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/mobile/bookings',
        data: {
          'mentorListingId': mentorListingId,
          'scheduledFor': scheduledFor.toIso8601String(),
        },
      );
      return BookingResponse(
        booking: Booking.fromJson(response.data['booking']),
        wallet: Wallet.fromJson(response.data['wallet']),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Booking>> listBookings({String? role, String? status}) async {
    try {
      final response = await _dioClient.dio.get(
        '/api/mobile/bookings',
        queryParameters: {
          if (role != null) 'role': role,
          if (status != null) 'status': status,
        },
      );
      if (response.data['bookings'] != null) {
        return (response.data['bookings'] as List)
            .map((e) => Booking.fromJson(e))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Booking> getBookingDetail(String id) async {
    try {
      final response = await _dioClient.dio.get('/api/mobile/bookings/$id');
      return Booking.fromJson(response.data['booking']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<BookingResponse> cancelBooking(String id) async {
    try {
      final response = await _dioClient.dio.patch('/api/mobile/bookings/$id/cancel');
      return BookingResponse(
        booking: Booking.fromJson(response.data['booking']),
        wallet: Wallet.fromJson(response.data['wallet']),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<BookingResponse> completeBooking(String id) async {
    try {
      final response = await _dioClient.dio.patch('/api/mobile/bookings/$id/complete');
      return BookingResponse(
        booking: Booking.fromJson(response.data['booking']),
        wallet: Wallet.fromJson(response.data['wallet']),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response?.data != null && e.response?.data['error'] != null) {
      return e.response?.data['error'];
    }
    return e.message ?? 'Booking service error';
  }
}
