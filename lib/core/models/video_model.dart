class VideoModel {
  final String id; // Changed from int to String
  final String displayName;
  final String? description;
  final String? category;
  final String? tags;
  final String accessType;
  final int accessTypeId;
  final String thumbnailUrl;
  final String videoUrl;
  final String? fileSize;
  final DateTime createdAt;

  VideoModel({
    required this.id,
    required this.displayName,
    this.description,
    this.category,
    this.tags,
    required this.accessType,
    required this.accessTypeId,
    required this.thumbnailUrl,
    required this.videoUrl,
    this.fileSize,
    required this.createdAt,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id']?.toString() ?? '',
      displayName: json['displayName'] ?? json['title'] ?? 'No Name',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      tags: (json['tags'] is List) ? (json['tags'] as List).join(', ') : json['tags']?.toString() ?? '',
      accessType: json['accessType'] ?? json['label'] ?? 'FREE',
      accessTypeId: json['accessTypeId'] ?? (json['label'] == 'PREMIUM' ? 2 : 1),
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      fileSize: json['fileSize']?.toString() ?? json['fileSizeMb']?.toString() ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isFree => accessType.toUpperCase() == "FREE" || accessTypeId == 1;
  bool get isPremium => accessType.toUpperCase() == "PREMIUM" || accessTypeId == 2;
}
