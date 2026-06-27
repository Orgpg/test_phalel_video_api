import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'video_provider.dart';
import 'widgets/video_list.dart';

class FolderVideosScreen extends StatefulWidget {
  final String folderName;

  const FolderVideosScreen({super.key, required this.folderName});

  @override
  State<FolderVideosScreen> createState() => _FolderVideosScreenState();
}

class _FolderVideosScreenState extends State<FolderVideosScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search in folder...',
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() {}),
              )
            : Text(widget.folderName),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchController.clear();
              });
            },
          ),
        ],
      ),
      body: Consumer<VideoProvider>(
        builder: (context, provider, child) {
          final allFolderVideos = provider.videosByFolder(widget.folderName);
          final query = _searchController.text.toLowerCase();
          
          final filteredVideos = query.isEmpty 
            ? allFolderVideos 
            : allFolderVideos.where((v) {
                return v.displayName.toLowerCase().contains(query) ||
                    v.fileName.toLowerCase().contains(query) ||
                    (v.author?.toLowerCase().contains(query) ?? false) ||
                    (v.category?.toLowerCase().contains(query) ?? false) ||
                    v.tags.any((tag) => tag.toLowerCase().contains(query));
              }).toList();

          return VideoList(
            videos: filteredVideos,
            onRefresh: provider.loadVideos,
          );
        },
      ),
    );
  }
}
