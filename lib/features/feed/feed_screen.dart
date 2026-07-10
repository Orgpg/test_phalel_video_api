import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/feed_provider.dart';
import '../../core/models/feed_item.dart';
import 'widgets/post_feed_item.dart';
import 'widgets/video_feed_tile.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PageController _pageController = PageController();
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedProvider>().fetchFeed(refresh: true);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Phalel Feed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/upload');
        },
        tooltip: 'Upload Video',
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.videocam),
      ),
      body: Consumer<FeedProvider>(
        builder: (context, provider, child) {
          if (provider.state == FeedState.loading && provider.items.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          if (provider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No items in feed', style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchFeed(refresh: true),
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.fetchFeed(refresh: true);
              setState(() {
                _activeIndex = 0;
              });
              try {
                _pageController.jumpToPage(0);
              } catch (_) {}
            },
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: (index) {
                setState(() => _activeIndex = index);
                if (provider.items.isNotEmpty && provider.hasMore) {
                  final virtualIndex = index % provider.items.length;
                  if (virtualIndex >= provider.items.length - 2) {
                    provider.fetchFeed();
                  }
                }
              },
              // Use infinite builder when we've loaded all pages (loop mode)
              itemCount: provider.items.isEmpty ? 0 : (provider.hasMore ? provider.items.length : null),
              itemBuilder: (context, index) {
                final displayedItem = provider.items[index % provider.items.length];
                if (displayedItem.type == FeedItemType.VIDEO) {
                  return VideoFeedTile(
                    key: ValueKey(displayedItem.id),
                    item: displayedItem,
                    isActive: (index % provider.items.length) == (_activeIndex % provider.items.length),
                    preload: (index % provider.items.length) == ((_activeIndex + 1) % provider.items.length),
                  );
                } else {
                  return PostFeedItem(key: ValueKey(displayedItem.id), item: displayedItem);
                }
              },

            ),
          );
        },
      ),
    );
  }
}
