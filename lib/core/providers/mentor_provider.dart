import 'package:flutter/material.dart';
import '../models/mentor_listing.dart';
import '../services/mentor_service.dart';

enum MentorState { initial, loading, loaded, error }

class MentorProvider with ChangeNotifier {
  final MentorService _service;

  MentorProvider(this._service);

  List<MentorListing> _mentors = [];
  List<MentorListing> _myListings = [];
  MentorListing? _selectedMentor;
  MentorState _state = MentorState.initial;
  String _errorMessage = '';

  List<MentorListing> get mentors => _mentors;
  List<MentorListing> get myListings => _myListings;
  MentorListing? get selectedMentor => _selectedMentor;
  MentorState get state => _state;
  String get errorMessage => _errorMessage;

  Future<void> fetchMentors({String? category, String? search}) async {
    _state = MentorState.loading;
    notifyListeners();

    try {
      _mentors = await _service.listMentors(category: category, search: search);
      _state = MentorState.loaded;
    } catch (e) {
      _state = MentorState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> fetchMentorDetail(String id) async {
    try {
      _selectedMentor = await _service.getMentorDetail(id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching mentor detail: $e');
    }
  }

  Future<void> fetchMyListings() async {
    try {
      _myListings = await _service.getMyListings();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching my listings: $e');
    }
  }

  Future<void> createListing(Map<String, dynamic> data) async {
    try {
      final newListing = await _service.createListing(
        title: data['title'],
        category: data['category'],
        description: data['description'],
        coinPrice: data['coinPrice'],
        durationMinutes: data['durationMinutes'],
        isActive: data['isActive'] ?? true,
      );
      _myListings.insert(0, newListing);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateListing(String id, Map<String, dynamic> data) async {
    try {
      final updated = await _service.updateListing(id, data);
      final index = _myListings.indexWhere((l) => l.id == id);
      if (index != -1) {
        _myListings[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteListing(String id) async {
    try {
      await _service.deleteListing(id);
      _myListings.removeWhere((l) => l.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
