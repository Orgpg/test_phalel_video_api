import 'package:flutter/material.dart';
import '../../core/models/video_model.dart';
import '../../core/repositories/video_repository.dart';

enum VideoState { initial, loading, loaded, error }

class VideoProvider with ChangeNotifier {
  final VideoRepository _repository;

  VideoProvider(this._repository);

  List<VideoModel> _allVideos = [];
  List<String> _apiFolders = [];
  List<String> _apiCategories = [];
  VideoState _state = VideoState.initial;
  String _errorMessage = '';

  List<VideoModel> get allVideos => _allVideos;
  List<VideoModel> get freeVideos => _allVideos.where((v) => v.isFree).toList();
  List<VideoModel> get premiumVideos => _allVideos.where((v) => v.isPremium).toList();
  List<String> get apiCategories => _apiCategories;
  VideoState get state => _state;
  String get errorMessage => _errorMessage;

  // Get all folders from API folders list
  List<String> get folders {
    final folderSet = <String>{};
    
    // 1. Add folders from API response
    for (var f in _apiFolders) {
      if (f.trim().isNotEmpty) {
        folderSet.add(f.trim());
      }
    }

    // 2. Add 'General' if it's not there and we have videos without folders
    if (!folderSet.any((f) => f.toLowerCase() == 'general')) {
      if (_allVideos.any((v) => v.folder == null || v.folder!.trim().isEmpty || v.folder!.trim().toLowerCase() == 'general')) {
        folderSet.add('General');
      }
    }

    // 3. Add folders from allVideos that might not be in _apiFolders (optional, but safer)
    for (var v in _allVideos) {
      final vFolder = (v.folder == null || v.folder!.trim().isEmpty) ? 'General' : v.folder!.trim();
      folderSet.add(vFolder);
    }

    final list = folderSet.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  // Get videos for a specific folder
  List<VideoModel> videosByFolder(String folderName) {
    return _allVideos.where((v) {
      final vFolder = (v.folder == null || v.folder!.trim().isEmpty) ? 'General' : v.folder!.trim();
      return vFolder.toLowerCase() == folderName.trim().toLowerCase();
    }).toList();
  }

  List<VideoModel> searchVideos(String query) {
    if (query.isEmpty) return _allVideos;
    final lowercaseQuery = query.toLowerCase();
    return _allVideos.where((v) {
      return v.displayName.toLowerCase().contains(lowercaseQuery) ||
          v.fileName.toLowerCase().contains(lowercaseQuery) ||
          (v.author?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          (v.category?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          v.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  Future<void> loadVideos() async {
    _state = VideoState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      // Load videos, folders, and categories in parallel
      final results = await Future.wait([
        _repository.fetchVideos(),
        _repository.fetchFolders(),
        _repository.fetchCategories(),
      ]);

      _allVideos = results[0] as List<VideoModel>;
      _apiFolders = results[1] as List<String>;
      _apiCategories = results[2] as List<String>;

      _state = VideoState.loaded;
    } catch (e) {
      _state = VideoState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }
}
