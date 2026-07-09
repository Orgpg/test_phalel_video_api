import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/models/feed_item.dart';
import '../../../core/providers/feed_provider.dart';
import 'comment_bottom_sheet.dart';
import 'related_videos_sheet.dart';

class VideoFeedItem extends StatefulWidget {
  final FeedItem item;
  const VideoFeedItem({super.key, required this.item});

  @override
  State<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends State<VideoFeedItem> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  String? _errorMessage;
  String? _playbackUrl;
  Timer? _viewTimer;
  int _secondsWatched = 0;
  bool _viewRecorded = false;
  bool _completedRecorded = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
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
        _errorMessage = 'Invalid playback URL from API.';
      });
      return;
    }

    if (_playbackUrl!.contains('/api/uploads/') || _playbackUrl!.contains('/stream')) {
      debugPrint('Refusing to play API stream URL: $_playbackUrl');
      setState(() {
        _errorMessage = 'Invalid playback URL from API.';
      });
      return;
    }

    _controller = VideoPlayerController.networkUrl(Uri.parse(_playbackUrl!));
    try {
      await _controller.initialize();
      _controller.setLooping(true);
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _errorMessage = null;
        });
        _controller.play();
        _startViewTimer();
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      final msg = e.toString();
      if (msg.contains('401') || msg.contains('Response code: 401')) {
        setState(() {
          _errorMessage = 'Video URL is protected. Expected CDN URL. Playback: $_playbackUrl';
        });
      } else {
        setState(() {
          _errorMessage = 'Video failed to load.';
        });
      }
    }

    _controller.addListener(() {
      if (_controller.value.hasError) {
        final desc = _controller.value.errorDescription ?? 'Unknown';
        debugPrint('VideoPlayer error (${widget.item.id}): $desc');
        if (desc.contains('401') || desc.contains('Response code: 401')) {
          setState(() {
            _errorMessage = 'Video URL is protected. Expected CDN URL. Playback: $_playbackUrl';
          });
        } else if (desc.contains('404')) {
          setState(() {
            _errorMessage = 'Video file not found.';
          });
        } else {
          setState(() {
            _errorMessage = 'Video playback error: $desc';
          });
        }
      }

      if (_controller.value.isInitialized && _controller.value.duration > Duration.zero) {
        if (_controller.value.position >= _controller.value.duration && !_completedRecorded) {
          _recordView(completed: true);
        }
      }
    });
  }

  void _startViewTimer() {
    _viewTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_controller.value.isPlaying) {
        _secondsWatched++;
        if (_secondsWatched >= 3 && !_viewRecorded) {
          _recordView(completed: false);
        }
      }
      if (_controller.value.position >= _controller.value.duration && _controller.value.duration > Duration.zero && !_completedRecorded) {
        _recordView(completed: true);
      }
    });
  }

  void _recordView({required bool completed}) {
    if (completed) {
      _completedRecorded = true;
    } else {
      _viewRecorded = true;
    }
    
    context.read<FeedProvider>().recordView(
      widget.item.id,
      _secondsWatched,
      completed,
    );
  }

  @override
  void dispose() {
    _viewTimer?.cancel();
    if (!_viewRecorded && _secondsWatched >= 3 && !_completedRecorded) {
      _recordView(completed: false);
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Thumbnail/Background
        _buildThumbnail(),

        if (_errorMessage != null)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                Text(_errorMessage!, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                    });
                    _initializePlayer();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),

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
          ),
        
        // Pause Overlay
        if (_isInitialized && !_controller.value.isPlaying)
          Center(
            child: GestureDetector(
              onTap: () {
                _controller.play();
                setState(() {});
              },
              child: const Icon(Icons.play_arrow, size: 80, color: Colors.white54),
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
                onTap: () => _showComments(context),
              ),
              _buildAction(
                icon: Icons.auto_awesome_motion, // Related videos icon
                label: 'Related',
                onTap: () => _showRelated(context),
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
                  Text(
                    '@${widget.item.author.name}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  if (widget.item.viewerState.friendStatus != FriendStatus.SELF) ...[
                    _buildFollowButton(),
                    const SizedBox(width: 8),
                    _buildFriendButton(),
                  ],
                ],
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

  Widget _buildThumbnail() {
    String? thumbUrl;
    if (widget.item.thumbnail?.source == ThumbnailSource.UPLOADED) {
      thumbUrl = widget.item.thumbnail?.url;
    }

    if (thumbUrl != null) {
      return Image.network(thumbUrl, fit: BoxFit.cover);
    }
    
    // For VIDEO_FRAME, in a real app we'd use a package or a service to get the frame.
    // For now we show a placeholder or the fallback if it was an image.
    return Container(color: Colors.black);
  }

  Widget _buildFollowButton() {
    final followed = widget.item.viewerState.followedAuthor;
    return GestureDetector(
      onTap: () => context.read<FeedProvider>().toggleFollow(widget.item.author.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(4),
          color: followed ? Colors.transparent : Colors.white.withOpacity(0.2),
        ),
        child: Text(
          followed ? 'Following' : 'Follow',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildFriendButton() {
    final status = widget.item.viewerState.friendStatus;
    if (status == FriendStatus.FRIENDS) {
      return const Icon(Icons.people, color: Colors.blue, size: 20);
    }
    return GestureDetector(
      onTap: () {
        context.read<FeedProvider>().sendFriendRequest(widget.item.author.id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Friend request sent')));
      },
      child: const Icon(Icons.person_add_outlined, color: Colors.white, size: 20),
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

  void _showRelated(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RelatedVideosSheet(videoId: widget.item.id),
    );
  }
}
