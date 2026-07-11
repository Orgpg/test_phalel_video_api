enum FeedItemType { VIDEO, POST }

enum ThumbnailSource { UPLOADED, VIDEO_FRAME }

enum FriendStatus { NONE, SELF, FRIENDS }

class FeedItem {
  final FeedItemType type;
  final String id;
  final String? title;
  final String? description;
  final String? body;
  final String? videoUrl;
  final String? imageUrl;
  final String? objectKey;
  final FeedThumbnail? thumbnail;
  final FeedAuthor author;
  final FeedStats stats;
  final ViewerState viewerState;
  final DateTime? createdAt;

  FeedItem({
    required this.type,
    required this.id,
    this.title,
    this.description,
    this.body,
    this.videoUrl,
    this.imageUrl,
    this.objectKey,
    this.thumbnail,
    required this.author,
    required this.stats,
    required this.viewerState,
    this.createdAt,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      type: json['type'] == 'VIDEO' ? FeedItemType.VIDEO : FeedItemType.POST,
      id: json['id'] ?? '',
      title: json['title'],
      description: json['description'],
      body: json['body'],
      videoUrl: json['videoUrl'],
      imageUrl: json['imageUrl'],
      objectKey: json['objectKey'] ?? json['object_key'],
      thumbnail: json['thumbnail'] != null ? FeedThumbnail.fromJson(json['thumbnail']) : null,
      author: FeedAuthor.fromJson(json['author'] ?? {}),
      stats: FeedStats.fromJson(json['stats'] ?? {}),
      viewerState: ViewerState.fromJson(json['viewerState'] ?? {}),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  FeedItem copyWith({
    FeedStats? stats,
    ViewerState? viewerState,
  }) {
    return FeedItem(
      type: type,
      id: id,
      title: title,
      description: description,
      body: body,
      videoUrl: videoUrl,
      imageUrl: imageUrl,
      thumbnail: thumbnail,
      author: author,
      stats: stats ?? this.stats,
      viewerState: viewerState ?? this.viewerState,
      createdAt: createdAt,
    );
  }
}

class FeedThumbnail {
  final ThumbnailSource source;
  final String? url;
  final int frameSecond;
  final String? fallbackVideoUrl;

  FeedThumbnail({
    required this.source,
    this.url,
    required this.frameSecond,
    this.fallbackVideoUrl,
  });

  factory FeedThumbnail.fromJson(Map<String, dynamic> json) {
    return FeedThumbnail(
      source: json['source'] == 'UPLOADED' ? ThumbnailSource.UPLOADED : ThumbnailSource.VIDEO_FRAME,
      url: json['url'],
      frameSecond: json['frameSecond'] ?? 1,
      fallbackVideoUrl: json['fallbackVideoUrl'],
    );
  }
}

class FeedAuthor {
  final String id;
  final String name;
  final String? username;
  final String? avatarUrl;

  FeedAuthor({
    required this.id,
    required this.name,
    this.username,
    this.avatarUrl,
  });

  factory FeedAuthor.fromJson(Map<String, dynamic> json) {
    // Handle both direct fields and nested user object
    final userData = json['user'] ?? json;
    return FeedAuthor(
      id: userData['id'] ?? '',
      name: userData['name'] ?? 'Unknown',
      username: userData['username'],
      avatarUrl: userData['avatarUrl'],
    );
  }

  String get displayName => username ?? name;
}

class FeedStats {
  final int views;
  final int likes;
  final int comments;
  final int shares;

  FeedStats({
    this.views = 0,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
  });

  factory FeedStats.fromJson(Map<String, dynamic> json) {
    return FeedStats(
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      shares: json['shares'] ?? 0,
    );
  }
}

class ViewerState {
  final bool liked;
  final bool saved;
  final bool followedAuthor;
  final FriendStatus friendStatus;

  ViewerState({
    this.liked = false,
    this.saved = false,
    this.followedAuthor = false,
    this.friendStatus = FriendStatus.NONE,
  });

  factory ViewerState.fromJson(Map<String, dynamic> json) {
    return ViewerState(
      liked: json['liked'] ?? false,
      saved: json['saved'] ?? false,
      followedAuthor: json['followedAuthor'] ?? false,
      friendStatus: _parseFriendStatus(json['friendStatus']),
    );
  }

  static FriendStatus _parseFriendStatus(String? status) {
    switch (status) {
      case 'SELF': return FriendStatus.SELF;
      case 'FRIENDS': return FriendStatus.FRIENDS;
      default: return FriendStatus.NONE;
    }
  }
}
