import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/feed_item.dart';
import '../../../core/providers/feed_provider.dart';
import 'video_feed_item.dart'; // သို့မဟုတ် video_feed_tile

class RelatedVideosSheet extends StatelessWidget {
  final String videoId;
  const RelatedVideosSheet({super.key, required this.videoId});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Related Videos',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<FeedItem>>(
              future: context.read<FeedProvider>().getRelatedVideos(videoId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white70)));
                }
                final videos = snapshot.data ?? [];
                if (videos.isEmpty) {
                  return const Center(child: Text('No related videos found', style: TextStyle(color: Colors.white54)));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 9 / 14,
                  ),
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context); // Sheet ကို ပိတ်မယ်
                        // ရွေးချယ်လိုက်တဲ့ video ကို play ဖို့အတွက် logic
                        _playRelatedVideo(context, video);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  _buildThumbnail(video),
                                  const Center(child: Icon(Icons.play_circle_outline, color: Colors.white70, size: 30)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            video.title ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(FeedItem video) {
    final thumb = video.thumbnail;
    if (thumb?.url != null) {
      return Image.network(thumb!.url!, fit: BoxFit.cover);
    }
    return Container(
      color: Colors.grey[900],
      child: const Icon(Icons.movie_filter_outlined, color: Colors.white24),
    );
  }

  void _playRelatedVideo(BuildContext context, FeedItem video) {
    // Related video ကို screen အသစ်မှာ vertical feed အဖြစ် ထပ်ပြပေးမယ်
    // သို့မဟုတ် လက်ရှိ feed မှာ jump to လုပ်လို့ရအောင် provider မှာ logic ထည့်နိုင်ပါတယ်
    // လက်ရှိမှာတော့ full player အနေနဲ့ပြပေးလိုက်ပါမယ်
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white),
        body: VideoFeedItem(item: video), // Re-using video feed item component
      ),
    );
  }
}
