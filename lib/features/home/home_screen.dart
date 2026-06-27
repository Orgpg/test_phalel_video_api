import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../free_videos/free_videos_tab.dart';
import '../premium_videos/premium_videos_tab.dart';
import 'widgets/folder_list.dart';
import 'widgets/video_list.dart';
import '../../core/models/video_model.dart';
import 'video_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VideoProvider>().loadVideos();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search title, author, category...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {});
                  },
                )
              : const Text('PhaLel Video Test'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Folders', icon: Icon(Icons.folder_copy)),
              Tab(text: 'Free Videos', icon: Icon(Icons.lock_open)),
              Tab(text: 'Premium Videos', icon: Icon(Icons.star)),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<VideoProvider>().loadVideos(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/upload'),
          label: const Text('Upload Video'),
          icon: const Icon(Icons.upload),
        ),
        body: Consumer<VideoProvider>(
          builder: (context, provider, child) {
            if (provider.state == VideoState.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.state == VideoState.error) {
              // ... existing error UI ...
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

            final query = _searchController.text;
            
            return TabBarView(
              children: [
                const FolderList(),
                _buildFilteredVideoList(provider.freeVideos, query, provider.loadVideos),
                _buildFilteredVideoList(provider.premiumVideos, query, provider.loadVideos),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilteredVideoList(List<VideoModel> videos, String query, Future<void> Function() onRefresh) {
    if (query.isEmpty) {
      return VideoList(videos: videos, onRefresh: onRefresh);
    }
    
    final lowercaseQuery = query.toLowerCase();
    final filteredVideos = videos.where((v) {
      return v.displayName.toLowerCase().contains(lowercaseQuery) ||
          v.fileName.toLowerCase().contains(lowercaseQuery) ||
          (v.author?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          (v.category?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          v.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();

    return VideoList(videos: filteredVideos, onRefresh: onRefresh);
  }
}
