import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../core/models/feed_item.dart';
import '../../../core/providers/feed_provider.dart';

class VideoFeedTile extends StatefulWidget {
  final FeedItem item;
  final bool isActive;
  final bool preload;

  const VideoFeedTile({Key? key, required this.item, required this.isActive, this.preload = false}) : super(key: key);

  @override
  State<VideoFeedTile> createState() => _VideoFeedTileState();
}

class _VideoFeedTileState extends State<VideoFeedTile> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isError = false;
  String? _errorMessage;
  String? _playbackUrl;
  Timer? _viewTimer;
  int _secondsWatched = 0;
  bool _viewRecorded = false;
  bool _completedRecorded = false;

  static final Set<String> _recordedThisSession = {}; // ensure single record per session

  bool get _shouldInit => widget.isActive || widget.preload;

  @override
  void initState() {
    super.initState();
    if (_shouldInit) {
      _initializePlayer();
    }
  }

  @override
  void didUpdateWidget(covariant VideoFeedTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Initialize when parent requests preload or activation
    if (_controller == null && _shouldInit) {
      _initializePlayer();
    }

    // Play/pause when active flag changes
    if (_controller != null && _controller!.value.isInitialized) {
      if (widget.isActive && !_controller!.value.isPlaying) {
        _controller!.play();
        _startViewTimer();
      } else if (!widget.isActive && _controller!.value.isPlaying) {
        _controller!.pause();
        _stopViewTimer();
      }
    }
  }

  String resolvePlaybackUrl(FeedItem item) {
    final url = item.videoUrl;
    final videoBase = dotenv.get('VIDEO_BASE_URL', fallback: '');

    if (url != null && url.isNotEmpty && videoBase.isNotEmpty && url.startsWith(videoBase) && !url.contains('/api/uploads/') && !url.contains('/stream')) {
      return url;
    }

    if (item.objectKey != null && item.objectKey!.isNotEmpty) {
      final cleanKey = item.objectKey!.replaceFirst(RegExp(r'^/+'), '');
      return '$videoBase/$cleanKey';
    }

    throw Exception('Missing valid videoUrl/objectKey for video ${item.id}');
  }

  Future<void> _initializePlayer() async {
    try {
      _playbackUrl = resolvePlaybackUrl(widget.item);
    } catch (e) {
      debugPrint('Invalid playback URL for ${widget.item.id}: $e');
      setState(() {
        _isError = true;
        _errorMessage = 'Invalid playback URL from API.';
      });
      return;
    }

    // Prevent playing API stream URLs
    if (_playbackUrl!.contains('/api/uploads/') || _playbackUrl!.contains('/stream')) {
      debugPrint('Refusing to play API stream URL: $_playbackUrl');
      setState(() {
        _isError = true;
        _errorMessage = 'Invalid playback URL from API.';
      });
      return;
    }

    _controller = VideoPlayerController.networkUrl(
      Uri.parse(_playbackUrl!),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
    );

    try {
      await _controller!.initialize();
      _controller!.setLooping(true);
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isError = false;
          _errorMessage = null;
        });
      }

      if (widget.isActive) {
        await _controller!.play();
        _startViewTimer();
      }
    } catch (e) {
      debugPrint('Video init error for ${widget.item.id}: $e');
      final msg = e.toString();
      if (msg.contains('401') || msg.contains('Response code: 401')) {
        setState(() {
          _isError = true;
          _errorMessage = 'Video URL is protected. Expected CDN URL. Playback: $_playbackUrl';
        });
      } else {
        setState(() {
          _isError = true;
          _errorMessage = 'Video failed to load.';
        });
      }
    }

    // Listen for playback errors and completion
    _controller?.addListener(() {
      if (_controller == null) return;
      final controller = _controller!;

      if (controller.value.hasError) {
        final desc = controller.value.errorDescription ?? 'Unknown';
        debugPrint('VideoPlayer error (${widget.item.id}): $desc');
        if (desc.contains('401') || desc.contains('Response code: 401')) {
          setState(() {
            _isError = true;
            _errorMessage = 'Video URL is protected. Expected CDN URL. Playback: $_playbackUrl';
          });
        } else if (desc.contains('404')) {
          setState(() {
            _isError = true;
            _errorMessage = 'Video file not found.';
          });
        } else {
          setState(() {
            _isError = true;
            _errorMessage = 'Video playback error: $desc';
          });
        }
      }

      if (controller.value.isInitialized && controller.value.duration > Duration.zero) {
        if (controller.value.position >= controller.value.duration && !_completedRecorded) {
          _recordView(completed: true);
        }
      }
    });
  }

  void _startViewTimer() {
    if (_viewTimer != null) return;
    _viewTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_controller?.value.isPlaying ?? false) {
        _secondsWatched++;
        if (_secondsWatched >= 8 && !_viewRecorded) {
          _recordView(completed: false);
        }
      }
    });
  }

  void _stopViewTimer() {
    _viewTimer?.cancel();
    _viewTimer = null;
  }

  void _recordView({required bool completed}) {
    if (_recordedThisSession.contains(widget.item.id)) return;

    if (completed) {
      _completedRecorded = true;
    } else {
      _viewRecorded = true;
    }

    _recordedThisSession.add(widget.item.id);
    try {
      context.read<FeedProvider>().recordView(widget.item.id, _secondsWatched >= 8 ? 8 : _secondsWatched, completed);
    } catch (_) {}
  }

  @override
  void dispose() {
    _stopViewTimer();
    if (!_viewRecorded && _secondsWatched >= 8 && !_completedRecorded) {
      _recordView(completed: false);
    }
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Thumbnail / placeholder
        _buildThumbnail(),

        if (_isInitialized && _controller != null)
          GestureDetector(
            onTap: () async {
              if (_controller!.value.isPlaying) {
                await _controller!.pause();
                _stopViewTimer();
              } else {
                await _controller!.play();
                _startViewTimer();
              }
              setState(() {});
            },
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),
            ),
          ),

        if (!_isInitialized && !_isError)
          const Center(child: CircularProgressIndicator(color: Colors.white)),

        if (_isInitialized && _controller != null && !_controller!.value.isPlaying)
          Center(
            child: GestureDetector(
              onTap: () async {
                await _controller!.play();
                _startViewTimer();
                setState(() {});
              },
              child: const Icon(Icons.play_arrow, size: 80, color: Colors.white54),
            ),
          ),

        if (_isError)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                Text(_errorMessage ?? 'Video failed to load', style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isError = false;
                    });
                    _initializePlayer();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),

        // Right side actions
        Positioned(
          right: 8,
          bottom: 100,
          child: Column(
            children: [
              _buildAction(
                icon: widget.item.viewerState.liked ? Icons.favorite : Icons.favorite_border,
                label: '${widget.item.stats.likes}',
                color: widget.item.viewerState.liked ? Colors.red : Colors.white,
                onTap: () => context.read<FeedProvider>().toggleLike(widget.item.id),
              ),
              _buildAction(
                icon: Icons.comment,
                label: '${widget.item.stats.comments}',
                onTap: () {},
              ),
              _buildAction(
                icon: Icons.auto_awesome_motion,
                label: 'Related',
                onTap: () {},
              ),
              _buildAction(
                icon: Icons.remove_red_eye_outlined,
                label: '${widget.item.stats.views}',
                onTap: () {},
              ),
            ],
          ),
        ),

        // Bottom info
        Positioned(
          left: 16,
          bottom: 40,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('@${widget.item.author.name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 8),
              Text(widget.item.title ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
              if (widget.item.description != null) ...[
                const SizedBox(height: 4),
                Text(widget.item.description!, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnail() {
    final thumb = widget.item.thumbnail?.url;
    if (thumb != null && thumb.isNotEmpty) {
      return Image.network(thumb, fit: BoxFit.cover);
    }
    return Container(color: Colors.black);
  }

  Widget _buildAction({required IconData icon, required String label, Color color = Colors.white, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          IconButton(icon: Icon(icon, color: color, size: 35), onPressed: onTap),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
