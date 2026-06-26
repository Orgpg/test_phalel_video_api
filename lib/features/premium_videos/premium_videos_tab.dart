import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../home/video_provider.dart';
import '../home/widgets/video_list.dart';

class PremiumVideosTab extends StatelessWidget {
  const PremiumVideosTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoProvider>(
      builder: (context, provider, child) {
        return VideoList(
          videos: provider.premiumVideos,
          onRefresh: provider.loadVideos,
        );
      },
    );
  }
}
