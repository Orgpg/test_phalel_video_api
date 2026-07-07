import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../../../core/models/feed_item.dart';
import '../../../core/providers/feed_provider.dart';
import 'comment_bottom_sheet.dart';

class VideoFeedItem extends StatefulWidget {
  final FeedItem item;
  const VideoFeedItem({super.key, required this.item});

  @override
  State<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends State<VideoFeedItem> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  Timer? _viewTimer;
  int _secondsWatched = 0;
  bool _viewRecorded = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.item.videoUrl!));
    try {
      await _controller.initialize();
      _controller.setLooping(true);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
        _startViewTimer();
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  void _startViewTimer() {
    _viewTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_controller.value.isPlaying) {
        _secondsWatched++;
        if (_secondsWatched >= 3 && !_viewRecorded) {
          _recordView();
        }
      }
    });
  }

  void _recordView() {
    _viewRecorded = true;
    context.read<FeedProvider>().recordView(
      widget.item.id,
      _secondsWatched,
      _controller.value.position >= _controller.value.duration,
    );
  }

  @override
  void dispose() {
    _viewTimer?.cancel();
    if (!_viewRecorded && _secondsWatched >= 3) {
      _recordView();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_isInitialized)
          GestureDetector(
            onTap: () {
              if (_controller.value.isPlaying) {
                _controller.pause();
              } else {
                _controller.play();
              }
              setState(() {});
            },
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          )
        else
          const Center(child: CircularProgressIndicator(color: Colors.white)),
        
        // Pause Overlay
        if (_isInitialized && !_controller.value.isPlaying)
          const Center(
            child: Icon(Icons.play_arrow, size: 80, color: Colors.white54),
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
                onTap: () => _showComments(context),
              ),
              _buildAction(
                icon: Icons.share,
                label: '${widget.item.stats.shares}',
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
              Text(
                '@${widget.item.author.name}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                widget.item.title ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              if (widget.item.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.item.description!,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAction({required IconData icon, required String label, Color color = Colors.white, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          IconButton(
            icon: Icon(icon, color: color, size: 35),
            onPressed: onTap,
          ),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentBottomSheet(videoId: widget.item.id),
    );
  }
}
