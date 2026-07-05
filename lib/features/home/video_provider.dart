import 'package:flutter/material.dart';
import '../../core/models/video_model.dart';
import '../../core/services/video_service.dart';

enum VideoState { initial, loading, loaded, error }

class VideoProvider with ChangeNotifier {
  final VideoService _service;

  VideoProvider(this._service);

  List<VideoModel> _allVideos = [];
  List<String> _apiFolders = [];
  VideoState _state = VideoState.initial;
  String _errorMessage = '';

  List<VideoModel> get allVideos => _allVideos;
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
    return _allVideos.where((v) {
      final vFolder = (v.folder == null || v.folder!.trim().isEmpty) ? 'General' : v.folder!.trim();
      return vFolder.toLowerCase() == folderName.trim().toLowerCase();
    }).toList();
  }

  Future<void> loadVideos() async {
    _state = VideoState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.fetchVideos(),
        _service.fetchFolders(),
      ]);

      _allVideos = results[0] as List<VideoModel>;
      _apiFolders = results[1] as List<String>;

      _state = VideoState.loaded;
    } catch (e) {
      _state = VideoState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }
}
