import 'package:flutter_dotenv/flutter_dotenv.dart';

class VideoModel {
  final String id;
  final String fileName;
  final String displayName;
  final String? author;
  final String? description;
  final String? folder;
  final String? category;
  final List<String> tags;
  final String accessType;
  final int fileSize;
  final String fileType;
  final String r2ObjectKey;
  final String? thumbnailObjectKey;
  final DateTime createdAt;
  final String? videoUrlOverride;
  final String? thumbnailUrlOverride;

  VideoModel({
    required this.id,
    required this.fileName,
    required this.displayName,
    this.author,
    this.description,
    this.folder,
    this.category,
    required this.tags,
    required this.accessType,
    required this.fileSize,
    required this.fileType,
    required this.r2ObjectKey,
    this.thumbnailObjectKey,
    required this.createdAt,
    this.videoUrlOverride,
    this.thumbnailUrlOverride,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id']?.toString() ?? '',
      fileName: json['fileName'] ?? json['file_name'] ?? '',
      displayName: json['displayName'] ?? json['display_name'] ?? json['fileName'] ?? json['file_name'] ?? 'No Name',
      author: json['author'],
      description: json['description'],
      folder: (json['folder'] == null || json['folder'].toString().trim().isEmpty) 
          ? 'General' 
          : json['folder'].toString().trim(),
      category: json['category'],
      tags: (json['tags'] is List) 
          ? List<String>.from(json['tags']) 
          : (json['tags']?.toString().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ?? []),
      accessType: json['accessType']?.toString().toUpperCase() ?? json['access_type']?.toString().toUpperCase() ?? 'FREE',
      fileSize: json['fileSize'] is int ? json['fileSize'] : (json['file_size'] is int ? json['file_size'] : int.tryParse(json['fileSize']?.toString() ?? json['file_size']?.toString() ?? '0') ?? 0),
      fileType: json['fileType'] ?? json['file_type'] ?? '',
      r2ObjectKey: json['r2ObjectKey'] ?? json['r2_object_key'] ?? '',
      thumbnailObjectKey: json['thumbnailObjectKey'] ?? json['thumbnail_object_key'],
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now()),
      videoUrlOverride: json['videoUrl'] ?? json['url'] ?? json['video_url'],
      thumbnailUrlOverride: json['thumbnailUrl'] ?? json['thumbnail_url'] ?? json['thumbnail'],
    );
  }

  bool get isFree => accessType == "FREE";
  bool get isPremium => accessType == "PREMIUM";

  String get normalizedFolder => (folder == null || folder!.trim().isEmpty) ? 'General' : folder!.trim();

  String get videoUrl {
    if (videoUrlOverride != null && videoUrlOverride!.isNotEmpty) return videoUrlOverride!;
    final baseUrl = dotenv.get('BASE_URL', fallback: '').replaceAll(RegExp(r'/$'), '');
    if (r2ObjectKey.isEmpty) return '';
    final encodedKey = Uri.encodeComponent(r2ObjectKey);
    return "$baseUrl/api/mobile/uploads/proxy?key=$encodedKey";
  }

  String get thumbnailUrl {
    if (thumbnailUrlOverride != null && thumbnailUrlOverride!.isNotEmpty) return thumbnailUrlOverride!;
    if (thumbnailObjectKey == null || thumbnailObjectKey!.isEmpty) return '';
    final baseUrl = dotenv.get('BASE_URL', fallback: '').replaceAll(RegExp(r'/$'), '');
    final encodedKey = Uri.encodeComponent(thumbnailObjectKey!);
    return "$baseUrl/api/mobile/uploads/proxy?key=$encodedKey";
  }
}
