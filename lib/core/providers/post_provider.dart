import 'package:flutter/material.dart';
import '../models/feed_item.dart';
import '../models/comment.dart';
import '../services/post_service.dart';

enum PostState { initial, loading, loaded, error }

class PostProvider with ChangeNotifier {
  final PostService _postService;

  PostProvider(this._postService);

  List<FeedItem> _posts = [];
  String? _nextCursor;
  bool _hasMore = true;
  PostState _state = PostState.initial;

  List<FeedItem> get posts => _posts;
  bool get hasMore => _hasMore;
  PostState get state => _state;

  Future<void> fetchPosts({bool refresh = false, String? authorId}) async {
    if (refresh) {
      _nextCursor = null;
      _hasMore = true;
    }
    if (!_hasMore && !refresh) return;
    if (_state == PostState.loading) return;

    _state = PostState.loading;
    if (refresh) _posts = [];
    notifyListeners();

    try {
      final response = await _postService.listPosts(cursor: _nextCursor, authorId: authorId);
      _posts.addAll(response.items);
      _nextCursor = response.nextCursor;
      _hasMore = response.hasMore;
      _state = PostState.loaded;
    } catch (e) {
      _state = PostState.error;
    }
    notifyListeners();
  }

  Future<void> toggleLike(String postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];
    final isLiked = post.viewerState.liked;

    // Optimistic update
    _posts[index] = post.copyWith(
      stats: FeedStats(
        likes: isLiked ? post.stats.likes - 1 : post.stats.likes + 1,
        comments: post.stats.comments,
        views: post.stats.views,
        shares: post.stats.shares,
      ),
      viewerState: ViewerState(
        liked: !isLiked,
        saved: post.viewerState.saved,
        followedAuthor: post.viewerState.followedAuthor,
        friendStatus: post.viewerState.friendStatus,
      ),
    );
    notifyListeners();

    try {
      if (isLiked) {
        final res = await _postService.unlikePost(postId);
        _posts[index] = _posts[index].copyWith(
          stats: FeedStats(
            likes: res['likes'] ?? _posts[index].stats.likes,
            comments: _posts[index].stats.comments,
            views: _posts[index].stats.views,
            shares: _posts[index].stats.shares,
          ),
          viewerState: ViewerState(
            liked: res['liked'] ?? false,
            saved: _posts[index].viewerState.saved,
            followedAuthor: _posts[index].viewerState.followedAuthor,
            friendStatus: _posts[index].viewerState.friendStatus,
          ),
        );
      } else {
        final res = await _postService.likePost(postId);
        _posts[index] = _posts[index].copyWith(
          stats: FeedStats(
            likes: res['likes'] ?? _posts[index].stats.likes,
            comments: _posts[index].stats.comments,
            views: _posts[index].stats.views,
            shares: _posts[index].stats.shares,
          ),
          viewerState: ViewerState(
            liked: res['liked'] ?? true,
            saved: _posts[index].viewerState.saved,
            followedAuthor: _posts[index].viewerState.followedAuthor,
            friendStatus: _posts[index].viewerState.friendStatus,
          ),
        );
      }
      notifyListeners();
    } catch (e) {
      _posts[index] = post;
      notifyListeners();
    }
  }

  Future<void> toggleSave(String postId, {Function(String)? onUnsave}) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];
    final isSaved = post.viewerState.saved;

    _posts[index] = post.copyWith(
      viewerState: ViewerState(
        liked: post.viewerState.liked,
        saved: !isSaved,
        followedAuthor: post.viewerState.followedAuthor,
        friendStatus: post.viewerState.friendStatus,
      ),
    );
    notifyListeners();

    try {
      if (isSaved) {
        final res = await _postService.unsavePost(postId);
        _posts[index] = _posts[index].copyWith(
          viewerState: ViewerState(
            liked: _posts[index].viewerState.liked,
            saved: res['saved'] ?? false,
            followedAuthor: _posts[index].viewerState.followedAuthor,
            friendStatus: _posts[index].viewerState.friendStatus,
          ),
        );
        if (onUnsave != null) onUnsave(postId);
      } else {
        final res = await _postService.savePost(postId);
        _posts[index] = _posts[index].copyWith(
          viewerState: ViewerState(
            liked: _posts[index].viewerState.liked,
            saved: res['saved'] ?? true,
            followedAuthor: _posts[index].viewerState.followedAuthor,
            friendStatus: _posts[index].viewerState.friendStatus,
          ),
        );
      }
      notifyListeners();
    } catch (e) {
      _posts[index] = post;
      notifyListeners();
    }
  }
}
