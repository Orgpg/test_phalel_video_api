import 'feed_item.dart';

class Comment {
  final String id;
  final String body;
  final String userId;
  final FeedAuthor author;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.body,
    required this.userId,
    required this.author,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final author = FeedAuthor.fromJson(json);
    return Comment(
      id: json['id'] ?? '',
      body: json['body'] ?? '',
      userId: json['userId'] ?? author.id,
      author: author,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
