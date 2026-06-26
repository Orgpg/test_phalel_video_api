import 'dart:math' as math;
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import '../core/models/video_model.dart';

class VideoCard extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onTap;

  const VideoCard({
    super.key,
    required this.video,
    required this.onTap,
  });

  Future<Uint8List?> _fetchThumbnail(String url) async {
    try {
      final token = dotenv.get('API_TOKEN');
      final response = await Dio().get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return Uint8List.fromList(response.data);
    } catch (e) {
      debugPrint('Error fetching thumbnail: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: FutureBuilder<Uint8List?>(
                future: _fetchThumbnail(video.thumbnailUrl),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasData && snapshot.data != null) {
                    return Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    );
                  }
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 50),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          video.displayName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.play_circle_outline, size: 30, color: Colors.deepPurple),
                    ],
                  ),
                  if (video.description != null && video.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      video.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (video.category != null && video.category!.isNotEmpty)
                        Chip(
                          label: Text(video.category!),
                          visualDensity: VisualDensity.compact,
                        ),
                      if (video.fileSize != null && video.fileSize!.isNotEmpty)
                        Chip(
                          label: Text(_formatFileSize(video.fileSize!)),
                          visualDensity: VisualDensity.compact,
                          avatar: const Icon(Icons.sd_storage, size: 16),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('MMM dd, yyyy').format(video.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(String size) {
    try {
      final bytes = int.tryParse(size);
      if (bytes == null || bytes <= 0) return size;
      const suffixes = ["B", "KB", "MB", "GB", "TB"];
      var i = (math.log(bytes.toDouble()) / math.log(1024)).floor();
      return "${(bytes / math.pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}";
    } catch (e) {
      return size;
    }
  }
}
