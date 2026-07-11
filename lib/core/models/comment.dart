import 'feed_item.dart';

class Comment {
  final String id;
  final String body;
  final FeedAuthor author;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.body,
    required this.author,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? '',
      body: json['body'] ?? '',
      author: FeedAuthor.fromJson(json), // Pass entire json to let FeedAuthor find 'user' or 'author'
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
