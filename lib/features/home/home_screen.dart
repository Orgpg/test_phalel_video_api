import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
  String _version = "v1.1.1";

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VideoProvider>().loadVideos();
    });
  }

  Future<void> _initPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _version = "v${info.version}";
      });
    } catch (e) {
      debugPrint('Error getting package info: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search title, category, tags...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) => setState(() {}),
                )
              : Row(
                  children: [
                    const Icon(Icons.play_circle_filled, color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'PHALEL VIDEO',
                          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 18),
                        ),
                        Text(
                          _version,
                          style: const TextStyle(fontSize: 10, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          bottom: TabBar(
            isScrollable: !isDesktop,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
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
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
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
      final titleMatch = v.displayName.toLowerCase().contains(lowercaseQuery);
      final categoryMatch = v.category?.toLowerCase().contains(lowercaseQuery) ?? false;
      final tagsMatch = v.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
      return titleMatch || categoryMatch || tagsMatch;
    }).toList();

    return VideoList(videos: filteredVideos, onRefresh: onRefresh);
  }
}
