import 'package:flutter_dotenv/flutter_dotenv.dart';

class VideoModel {
  final String id;
  final String fileName;
  final String displayName;
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

  VideoModel({
    required this.id,
    required this.fileName,
    required this.displayName,
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
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id']?.toString() ?? '',
      fileName: json['fileName'] ?? '',
      displayName: json['displayName'] ?? 'No Name',
      description: json['description'],
      folder: (json['folder'] == null || json['folder'].toString().trim().isEmpty) 
          ? 'General' 
          : json['folder'].toString().trim(),
      category: json['category'],
      tags: (json['tags'] is List) 
          ? List<String>.from(json['tags']) 
          : (json['tags']?.toString().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ?? []),
      accessType: json['accessType']?.toString().toUpperCase() ?? 'FREE',
      fileSize: json['fileSize'] is int ? json['fileSize'] : int.tryParse(json['fileSize']?.toString() ?? '0') ?? 0,
      fileType: json['fileType'] ?? '',
      r2ObjectKey: json['r2ObjectKey'] ?? '',
      thumbnailObjectKey: json['thumbnailObjectKey'],
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isFree => accessType == "FREE";
  bool get isPremium => accessType == "PREMIUM";

  String get normalizedFolder => (folder == null || folder!.trim().isEmpty) ? 'General' : folder!.trim();

  String get videoUrl {
    final baseUrl = dotenv.get('BASE_URL', fallback: '');
    return "$baseUrl/api/mobile/uploads/proxy?key=$r2ObjectKey";
  }

  String get thumbnailUrl {
    if (thumbnailObjectKey == null || thumbnailObjectKey!.isEmpty) return '';
    final baseUrl = dotenv.get('BASE_URL', fallback: '');
    return "$baseUrl/api/mobile/uploads/proxy?key=$thumbnailObjectKey";
  }
}
