import 'package:flutter/material.dart';
import '../../core/models/video_model.dart';
import '../../core/repositories/video_repository.dart';

enum VideoState { initial, loading, loaded, error }

class VideoProvider with ChangeNotifier {
  final VideoRepository _repository;

  VideoProvider(this._repository);

  List<VideoModel> _allVideos = [];
  VideoState _state = VideoState.initial;
  String _errorMessage = '';

  List<VideoModel> get allVideos => _allVideos;
  List<VideoModel> get freeVideos => _allVideos.where((v) => v.isFree).toList();
  List<VideoModel> get premiumVideos => _allVideos.where((v) => v.isPremium).toList();
  VideoState get state => _state;
  String get errorMessage => _errorMessage;

  Future<void> loadVideos() async {
    _state = VideoState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      _allVideos = await _repository.fetchVideos();
      _state = VideoState.loaded;
    } catch (e) {
      _state = VideoState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }
}
