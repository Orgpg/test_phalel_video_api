import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/models/feed_item.dart';

class VideoThumbnailWidget extends StatefulWidget {
  final FeedItem video;
  final double aspectRatio;

  const VideoThumbnailWidget({
    super.key,
    required this.video,
    this.aspectRatio = 19 / 6,
  });

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _checkAndInitialize();
  }

  @override
  void didUpdateWidget(VideoThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.id != widget.video.id) {
      _cleanup();
      _checkAndInitialize();
    }
  }

  void _cleanup() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _hasError = false;
  }

  void _checkAndInitialize() {
    if (widget.video.thumbnail?.source == ThumbnailSource.VIDEO_FRAME) {
      _initializeVideoFrame();
    }
  }

  Future<void> _initializeVideoFrame() async {
    final videoUrl =
        widget.video.thumbnail?.fallbackVideoUrl ?? widget.video.videoUrl;
    if (videoUrl == null || videoUrl.isEmpty) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    try {
      await _controller!.initialize();
      if (!mounted) return;
      
      final frameSecond = widget.video.thumbnail?.frameSecond ?? 1;
      await _controller!.seekTo(Duration(seconds: frameSecond));
      await _controller!.setVolume(0); // Ensure muted
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video frame for thumbnail (${widget.video.id}): $e');
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final thumb = widget.video.thumbnail;

    // Case 1: Uploaded thumbnail
    if (thumb?.source == ThumbnailSource.UPLOADED) {
      final imageUrl =
          thumb?.url ??
          widget.video.imageUrl ??
          widget.video.videoUrl; // Check all potential URL fields
      
      if (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.contains('/stream')) {
        return CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => _buildPlaceholder(),
          errorWidget: (context, url, error) => _buildError(),
        );
      }
    }

    // Case 2: Video frame (or fallback if Uploaded URL is actually a video stream)
    if (thumb?.source == ThumbnailSource.VIDEO_FRAME || 
        (thumb?.url?.contains('/stream') ?? false) ||
        (widget.video.videoUrl?.contains('/stream') ?? false)) {
      
      if (_hasError) return _buildError();
      if (!_isInitialized) {
        // If not initialized yet, try to initialize if not already doing so
        if (_controller == null) {
          _initializeVideoFrame();
        }
        return _buildPlaceholder();
      }

      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      );
    }

    // Fallback
    return _buildError();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(
          Icons.movie_filter_outlined,
          color: Colors.white24,
          size: 40,
        ),
      ),
    );
  }
}
