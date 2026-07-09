import 'package:flutter/material.dart';
import '../models/feed_item.dart';
import '../services/feed_service.dart';
import '../services/social_service.dart';

enum FeedState { initial, loading, loaded, error }

class FeedProvider with ChangeNotifier {
  final FeedService _feedService;
  final SocialService _socialService;

  FeedProvider(this._feedService, this._socialService);

  List<FeedItem> _items = [];
  String? _nextCursor;
  bool _hasMore = true;
  FeedState _state = FeedState.initial;
  String _errorMessage = '';

  List<FeedItem> get items => _items;
  FeedState get state => _state;
  String get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  Future<void> fetchFeed({bool refresh = false, String? folder, bool? singleVideoOnly}) async {
    if (refresh) {
      _nextCursor = null;
      _hasMore = true;
    }

    if (!_hasMore && !refresh) return;

    if (_state == FeedState.loading) return;

    _state = FeedState.loading;
    if (refresh) _items = [];
    notifyListeners();

    try {
      final response = await _feedService.getFeed(cursor: _nextCursor, folder: folder, singleVideoOnly: singleVideoOnly);
      _items.addAll(response.items);
      _nextCursor = response.nextCursor;
      _hasMore = response.hasMore;
      _state = FeedState.loaded;
    } catch (e) {
      _state = FeedState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> toggleLike(String itemId) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index == -1) return;

    final item = _items[index];
    final isLiked = item.viewerState.liked;

    // Optimistic update
    final newStats = FeedStats(
      views: item.stats.views,
      likes: isLiked ? item.stats.likes - 1 : item.stats.likes + 1,
      comments: item.stats.comments,
      shares: item.stats.shares,
    );
    final newState = ViewerState(
      liked: !isLiked,
      saved: item.viewerState.saved,
      followedAuthor: item.viewerState.followedAuthor,
      friendStatus: item.viewerState.friendStatus,
    );

    _items[index] = item.copyWith(stats: newStats, viewerState: newState);
    notifyListeners();

    try {
      if (isLiked) {
        await _socialService.unlikeVideo(itemId);
      } else {
        await _socialService.likeVideo(itemId);
      }
    } catch (e) {
      // Rollback on failure
      _items[index] = item;
      notifyListeners();
    }
  }

  void updateItemStats(String itemId, {int? comments}) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index == -1) return;

    final item = _items[index];
    if (comments != null) {
      _items[index] = item.copyWith(
        stats: FeedStats(
          views: item.stats.views,
          likes: item.stats.likes,
          comments: comments,
          shares: item.stats.shares,
        ),
      );
      notifyListeners();
    }
  }

  Future<void> recordView(String videoId, int seconds, bool completed) async {
    await _feedService.recordView(videoId, watchSeconds: seconds, completed: completed);
  }

  Future<void> toggleFollow(String userId) async {
    final indexes = _items.asMap().entries
        .where((e) => e.value.author.id == userId)
        .map((e) => e.key)
        .toList();

    if (indexes.isEmpty) return;

    final firstItem = _items[indexes.first];
    final isFollowed = firstItem.viewerState.followedAuthor;

    // Optimistic update for all items by this author
    for (final i in indexes) {
      final item = _items[i];
      _items[i] = item.copyWith(
        viewerState: ViewerState(
          liked: item.viewerState.liked,
          saved: item.viewerState.saved,
          followedAuthor: !isFollowed,
          friendStatus: item.viewerState.friendStatus,
        ),
      );
    }
    notifyListeners();

    try {
      if (isFollowed) {
        await _socialService.unfollowUser(userId);
      } else {
        await _socialService.followUser(userId);
      }
    } catch (e) {
      // Rollback
      for (final i in indexes) {
        final item = _items[i];
        _items[i] = item.copyWith(
          viewerState: ViewerState(
            liked: item.viewerState.liked,
            saved: item.viewerState.saved,
            followedAuthor: isFollowed,
            friendStatus: item.viewerState.friendStatus,
          ),
        );
      }
      notifyListeners();
    }
  }

  Future<void> sendFriendRequest(String userId) async {
    try {
      await _socialService.sendFriendRequest(userId);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<FeedItem>> getRelatedVideos(String videoId) async {
    return await _feedService.getRelatedVideos(videoId);
  }
}
