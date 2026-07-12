import 'package:flutter/material.dart';
import '../models/mobile_user.dart';
import '../models/feed_item.dart';
import '../services/user_service.dart';

enum UserState { initial, loading, loaded, error }

class UserProvider with ChangeNotifier {
  final UserService _userService;

  UserProvider(this._userService);

  List<FeedItem> _myUploads = [];
  String? _uploadsCursor;
  bool _uploadsHasMore = true;
  UserState _uploadsState = UserState.initial;

  List<FeedItem> _mySaved = [];
  String? _savedCursor;
  bool _savedHasMore = true;
  UserState _savedState = UserState.initial;

  List<MobileUser> _searchResults = [];
  UserState _searchState = UserState.initial;

  List<FeedItem> get myUploads => _myUploads;
  bool get uploadsHasMore => _uploadsHasMore;
  UserState get uploadsState => _uploadsState;

  List<FeedItem> get mySaved => _mySaved;
  bool get savedHasMore => _savedHasMore;
  UserState get savedState => _savedState;

  List<MobileUser> get searchResults => _searchResults;
  UserState get searchState => _searchState;

  Future<void> fetchMyUploads({bool refresh = false}) async {
    if (refresh) {
      _uploadsCursor = null;
      _uploadsHasMore = true;
    }
    if (!_uploadsHasMore && !refresh) return;
    if (_uploadsState == UserState.loading) return;

    _uploadsState = UserState.loading;
    if (refresh) _myUploads = [];
    notifyListeners();

    try {
      final response = await _userService.getMyUploads(cursor: _uploadsCursor);
      _myUploads.addAll(response.items);
      _uploadsCursor = response.nextCursor;
      _uploadsHasMore = response.hasMore;
      _uploadsState = UserState.loaded;
    } catch (e) {
      _uploadsState = UserState.error;
    }
    notifyListeners();
  }

  Future<void> fetchMySaved({bool refresh = false}) async {
    if (refresh) {
      _savedCursor = null;
      _savedHasMore = true;
    }
    if (!_savedHasMore && !refresh) return;
    if (_savedState == UserState.loading) return;

    _savedState = UserState.loading;
    if (refresh) _mySaved = [];
    notifyListeners();

    try {
      final response = await _userService.getMySaved(cursor: _savedCursor);
      _mySaved.addAll(response.items);
      _savedCursor = response.nextCursor;
      _savedHasMore = response.hasMore;
      _savedState = UserState.loaded;
    } catch (e) {
      _savedState = UserState.error;
    }
    notifyListeners();
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      _searchState = UserState.initial;
      notifyListeners();
      return;
    }

    _searchState = UserState.loading;
    notifyListeners();

    try {
      _searchResults = await _userService.searchUsers(query);
      _searchState = UserState.loaded;
    } catch (e) {
      _searchState = UserState.error;
    }
    notifyListeners();
  }

  void removeSavedItem(String itemId) {
    _mySaved.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }
}
