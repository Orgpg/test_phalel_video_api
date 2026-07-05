import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';

enum BookingState { initial, loading, loaded, error }

class BookingProvider with ChangeNotifier {
  final BookingService _service;

  BookingProvider(this._service);

  List<Booking> _learnerBookings = [];
  List<Booking> _teacherBookings = [];
  Booking? _selectedBooking;
  BookingState _state = BookingState.initial;
  String _errorMessage = '';

  List<Booking> get learnerBookings => _learnerBookings;
  List<Booking> get teacherBookings => _teacherBookings;
  Booking? get selectedBooking => _selectedBooking;
  BookingState get state => _state;
  String get errorMessage => _errorMessage;

  Future<void> fetchLearnerBookings({String? status}) async {
    _state = BookingState.loading;
    notifyListeners();
    try {
      _learnerBookings = await _service.listBookings(role: 'learner', status: status);
      _state = BookingState.loaded;
    } catch (e) {
      _state = BookingState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> fetchTeacherBookings({String? status}) async {
    _state = BookingState.loading;
    notifyListeners();
    try {
      _teacherBookings = await _service.listBookings(role: 'teacher', status: status);
      _state = BookingState.loaded;
    } catch (e) {
      _state = BookingState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> fetchBookingDetail(String id) async {
    try {
      _selectedBooking = await _service.getBookingDetail(id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching booking detail: $e');
    }
  }

  Future<BookingResponse> createBooking(String mentorListingId, DateTime scheduledFor) async {
    try {
      final res = await _service.createBooking(
        mentorListingId: mentorListingId,
        scheduledFor: scheduledFor,
      );
      _learnerBookings.insert(0, res.booking);
      notifyListeners();
      return res;
    } catch (e) {
      rethrow;
    }
  }

  Future<BookingResponse> cancelBooking(String id) async {
    try {
      final res = await _service.cancelBooking(id);
      _updateBookingInLists(res.booking);
      return res;
    } catch (e) {
      rethrow;
    }
  }

  Future<BookingResponse> completeBooking(String id) async {
    try {
      final res = await _service.completeBooking(id);
      _updateBookingInLists(res.booking);
      return res;
    } catch (e) {
      rethrow;
    }
  }

  void _updateBookingInLists(Booking updated) {
    final lIndex = _learnerBookings.indexWhere((b) => b.id == updated.id);
    if (lIndex != -1) _learnerBookings[lIndex] = updated;

    final tIndex = _teacherBookings.indexWhere((b) => b.id == updated.id);
    if (tIndex != -1) _teacherBookings[tIndex] = updated;

    if (_selectedBooking?.id == updated.id) _selectedBooking = updated;
    notifyListeners();
  }
}
