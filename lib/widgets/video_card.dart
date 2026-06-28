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
    if (url.isEmpty) return null;
    
    // Fix localhost for Android Emulator if needed (though this is for Desktop)
    // But let's keep it consistent with what the user might be using in .env
    
    try {
      final token = dotenv.get('API_TOKEN', fallback: '');
      
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));

      final response = await dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'image/*',
          },
          validateStatus: (status) => status == 200,
        ),
      );

      final contentType = response.headers.value('content-type');
      if (contentType != null && !contentType.startsWith('image/')) {
        debugPrint('Thumbnail fetch failed: Response is not an image ($contentType). URL: $url');
        return null;
      }

      return Uint8List.fromList(response.data);
    } catch (e) {
      debugPrint('Error fetching thumbnail for ${video.displayName}: $e. URL: $url');
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
                      color: Colors.grey[200],
                      child: const Center(
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                    return Container(
                      color: Colors.grey[300],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                          const SizedBox(height: 4),
                          Text(
                            'No Thumbnail',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }

                  try {
                    return Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(child: Icon(Icons.broken_image, size: 40)),
                        );
                      },
                    );
                  } catch (e) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(child: Icon(Icons.error, size: 40)),
                    );
                  }
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.displayName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (video.author != null && video.author!.isNotEmpty)
                              Text(
                                'by ${video.author}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.play_circle_outline, size: 30, color: Colors.deepPurple),
                    ],
                  ),
                  if (video.description != null && video.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      video.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (video.category != null && video.category!.isNotEmpty)
                        _buildBadge(context, video.category!, Colors.blue),
                      _buildBadge(context, video.normalizedFolder, Colors.orange),
                      _buildBadge(
                        context, 
                        video.accessType, 
                        video.isPremium ? Colors.amber : Colors.green,
                        isPremium: video.isPremium,
                      ),
                      Chip(
                        label: Text(_formatFileSize(video.fileSize)),
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

  Widget _buildBadge(BuildContext context, String text, Color color, {bool isPremium = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPremium) ...[
            const Icon(Icons.star, size: 12, color: Colors.amber),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color.darker(),
            ),
          ),
        ],
      ),
    );
  }
}

extension ColorExtension on Color {
  Color darker() {
    return Color.fromARGB(
      alpha,
      (red * 0.7).round(),
      (green * 0.7).round(),
      (blue * 0.7).round(),
    );
  }
}

String _formatFileSize(int bytes) {
  if (bytes <= 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB"];
  var i = (math.log(bytes.toDouble()) / math.log(1024)).floor();
  return "${(bytes / math.pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}";
}
