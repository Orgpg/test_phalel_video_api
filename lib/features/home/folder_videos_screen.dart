import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'video_provider.dart';
import 'widgets/video_list.dart';

class FolderVideosScreen extends StatelessWidget {
  final String folderName;

  const FolderVideosScreen({super.key, required this.folderName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(folderName),
      ),
      body: Consumer<VideoProvider>(
        builder: (context, provider, child) {
          final videos = provider.videosByFolder(folderName);
          return VideoList(
            videos: videos,
            onRefresh: provider.loadVideos,
          );
        },
      ),
    );
  }
}
