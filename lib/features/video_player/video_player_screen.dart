import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:video_player/video_player.dart';
import '../../core/models/video_model.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final token = dotenv.get('API_TOKEN');
    final videoUrl = widget.video.videoUrl;
    
    debugPrint('Initializing video: $videoUrl');
    
    try {
      if (videoUrl.isEmpty) {
        throw Exception('Video URL is empty');
      }

      final baseUrl = dotenv.get('BASE_URL', fallback: '');
      final isInternalUrl = videoUrl.startsWith(baseUrl);

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        httpHeaders: isInternalUrl ? {
          'Authorization': 'Bearer $token',
        } : {},
      );

      await _videoPlayerController.initialize();
      
      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        deviceOrientationsAfterFullScreen: [
          DeviceOrientation.portraitUp,
        ],
        placeholder: const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.white, size: 42),
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Video Player Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Playback Error: $e\n\nURL: $videoUrl';
        });
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.video.displayName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Center(
              child: _isLoading
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text('Loading Video...', style: TextStyle(color: Colors.white)),
                      ],
                    )
                  : _errorMessage != null
                      ? Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 60),
                              const SizedBox(height: 16),
                              Text(
                                'Failed to load video: $_errorMessage',
                                style: const TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isLoading = true;
                                    _errorMessage = null;
                                  });
                                  _initializePlayer();
                                },
                                child: const Text('Retry'),
                              )
                            ],
                          ),
                        )
                      : _chewieController != null
                          ? Chewie(controller: _chewieController!)
                          : const Text('Initialization Failed', style: TextStyle(color: Colors.white)),
            ),
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.video.displayName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    if (widget.video.author != null)
                      Text(
                        'By ${widget.video.author}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.deepPurple,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildInfoChip(context, widget.video.accessType, widget.video.isPremium ? Colors.amber : Colors.green),
                        const SizedBox(width: 8),
                        _buildInfoChip(context, widget.video.category ?? 'Uncategorized', Colors.blue),
                        const SizedBox(width: 8),
                        _buildInfoChip(context, widget.video.normalizedFolder, Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.video.description ?? 'No description provided.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Tags',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: widget.video.tags.map((tag) => Chip(label: Text(tag))).toList(),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
