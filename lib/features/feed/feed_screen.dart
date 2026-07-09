import 'package:flutter/material.dart';
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
            onRefresh: () => provider.fetchFeed(refresh: true),
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: (index) {
                setState(() => _activeIndex = index);
                if (index >= provider.items.length - 2 && provider.hasMore) {
                  provider.fetchFeed();
                }
              },
              itemCount: provider.items.length,
              itemBuilder: (context, index) {
                final item = provider.items[index];
                if (item.type == FeedItemType.VIDEO) {
                  return VideoFeedTile(
                    item: item,
                    isActive: index == _activeIndex,
                    preload: index == _activeIndex + 1,
                  );
                } else {
                  return PostFeedItem(item: item);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
