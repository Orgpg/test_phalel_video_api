import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/video_model.dart';
import '../../../widgets/video_card.dart';

class VideoList extends StatelessWidget {
  final List<VideoModel> videos;
  final Future<void> Function() onRefresh;

  const VideoList({
    super.key,
    required this.videos,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No Videos Found', style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRefresh, child: const Text('Refresh')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final video = videos[index];
          return VideoCard(
            video: video,
            onTap: () => context.push('/player', extra: video),
          );
        },
      ),
    );
  }
}
