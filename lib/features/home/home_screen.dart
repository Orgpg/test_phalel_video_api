import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../free_videos/free_videos_tab.dart';
import '../premium_videos/premium_videos_tab.dart';
import 'video_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VideoProvider>().loadVideos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PhaLel Video Test'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Free Videos', icon: Icon(Icons.lock_open)),
              Tab(text: 'Premium Videos', icon: Icon(Icons.star)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<VideoProvider>().loadVideos(),
            ),
          ],
        ),
        body: Consumer<VideoProvider>(
          builder: (context, provider, child) {
            if (provider.state == VideoState.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.state == VideoState.error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${provider.errorMessage}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: provider.loadVideos,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return const TabBarView(
              children: [
                FreeVideosTab(),
                PremiumVideosTab(),
              ],
            );
          },
        ),
      ),
    );
  }
}
