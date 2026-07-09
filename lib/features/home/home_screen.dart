import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/feed_provider.dart';
import '../../core/models/feed_item.dart';
import '../feed/widgets/video_feed_item.dart';
import '../feed/widgets/post_feed_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();

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
        title: const Text(
          'PHALEL VIDEO',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.stars, color: Colors.amber),
            onPressed: () => context.push('/wallet'),
          ),
          IconButton(
            icon: const Icon(Icons.school, color: Colors.white),
            onPressed: () => context.push('/mentors'),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: Consumer<FeedProvider>(
        builder: (context, provider, child) {
          if (provider.state == FeedState.loading && provider.items.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          if (provider.state == FeedState.error && provider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(provider.errorMessage, style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchFeed(refresh: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No videos available', style: TextStyle(color: Colors.white)),
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
                if (index >= provider.items.length - 3 && provider.hasMore) {
                  provider.fetchFeed();
                }
              },
              itemCount: provider.items.length,
              itemBuilder: (context, index) {
                final item = provider.items[index];
                if (item.type == FeedItemType.VIDEO) {
                  return VideoFeedItem(item: item);
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
