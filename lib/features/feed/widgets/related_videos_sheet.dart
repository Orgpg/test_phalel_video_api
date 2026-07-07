import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/feed_item.dart';
import '../../../core/providers/feed_provider.dart';

class RelatedVideosSheet extends StatelessWidget {
  final String videoId;
  const RelatedVideosSheet({super.key, required this.videoId});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
            padding: EdgeInsets.all(16.0),
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
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                }
                final videos = snapshot.data ?? [];
                if (videos.isEmpty) {
                  return const Center(child: Text('No related videos found', style: TextStyle(color: Colors.white)));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 9 / 16,
                  ),
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    return GestureDetector(
                      onTap: () {
                        // In a real app, we might want to push this to the feed or play it
                        Navigator.pop(context);
                        // For now just show a snackbar
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Playing ${video.title}')),
                        );
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: video.thumbnail?.url != null
                                ? Image.network(video.thumbnail!.url!, fit: BoxFit.cover)
                                : Container(color: Colors.grey[800], child: const Icon(Icons.play_arrow, color: Colors.white)),
                          ),
                          Positioned(
                            bottom: 4,
                            left: 4,
                            right: 4,
                            child: Text(
                              video.title ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
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
}
