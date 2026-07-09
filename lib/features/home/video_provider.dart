import 'package:flutter/material.dart';
import '../../core/models/video_model.dart';
import '../../core/services/video_service.dart';

enum VideoState { initial, loading, loaded, error }

class VideoProvider with ChangeNotifier {
  final VideoService _service;

  VideoProvider(this._service);

  List<VideoModel> _allVideos = [];
  List<VideoModel> _singleVideos = [];
  List<String> _apiFolders = [];
  VideoState _state = VideoState.initial;
  String _errorMessage = '';

  List<VideoModel> get allVideos => _allVideos;
  List<VideoModel> get singleVideos => _singleVideos;
  List<VideoModel> get freeVideos => _allVideos.where((v) => v.isFree).toList();
  List<VideoModel> get premiumVideos => _allVideos.where((v) => v.isPremium).toList();
  VideoState get state => _state;
  String get errorMessage => _errorMessage;

  List<String> get folders {
    final folderSet = <String>{};
    for (var f in _apiFolders) {
      if (f.trim().isNotEmpty) folderSet.add(f.trim());
    }
    // Fallback to folders found in videos if not in API list
    for (var v in _allVideos) {
      final vFolder = (v.folder == null || v.folder!.trim().isEmpty) ? 'General' : v.folder!.trim();
      folderSet.add(vFolder);
    }
    final list = folderSet.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  List<VideoModel> videosByFolder(String folderName) {
    // Prefer server-provided folder field. Keep this for fallback but avoid objectKey parsing.
    return _allVideos.where((v) {
      final vFolder = (v.folder == null || v.folder!.trim().isEmpty) ? 'General' : v.folder!.trim();
      return vFolder.toLowerCase() == folderName.trim().toLowerCase();
    }).toList();
  }

  Future<List<VideoModel>> fetchVideosForFolder(String folderName, {int limit = 50}) async {
    try {
      final results = await _service.fetchVideos(folder: folderName, limit: limit);
      return results;
    } catch (e) {
      return [];
    }
  }

  Future<void> loadVideos() async {
    _state = VideoState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.fetchVideos(), // Default: all or as per API
        _service.fetchFolders(),
        _service.fetchVideos(singleVideoOnly: true),
      ]);

      _allVideos = results[0] as List<VideoModel>;
      _apiFolders = results[1] as List<String>;
      _singleVideos = results[2] as List<VideoModel>;

      _state = VideoState.loaded;
    } catch (e) {
      _state = VideoState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }
}
