import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../core/services/upload_service.dart';
import '../../core/network/dio_client.dart';
import '../../core/providers/auth_provider.dart';
import '../home/video_provider.dart';

class UploadVideoScreen extends StatefulWidget {
  const UploadVideoScreen({super.key});

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  final _formKey = GlobalKey<FormState>();
  
  PlatformFile? _videoFile;
  PlatformFile? _thumbnailFile;
  
  final _displayNameController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  
  bool _isSingleVideo = true;
  String? _selectedFolder;
  List<String> _folders = ['General'];
  String? _selectedCategory;
  List<String> _categories = [];
  String _accessType = 'FREE';
  String _visibility = 'PUBLIC';
  final List<String> _visibilityOptions = ['PUBLIC', 'FOLLOWERS_ONLY', 'FRIENDS_ONLY', 'PRIVATE'];

  bool _isUploading = false;
  bool _isLoadingData = true;
  double _uploadProgress = 0;
  String _statusMessage = '';
  
  int? _videoDurationSeconds;
  bool _isDurationValid = true;
  String? _durationError;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final dioClient = context.read<DioClient>();
      final service = UploadService(dioClient);
      
      final results = await Future.wait([
        service.fetchFolders(),
        service.fetchCategories(),
      ]);
      
      String authorName = '';
      try {
        final authProvider = context.read<AuthProvider>();
        if (authProvider.user != null) {
          authorName = authProvider.user!.name.isNotEmpty 
            ? authProvider.user!.name 
            : authProvider.user!.username;
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _folders = results[0].isNotEmpty ? results[0] : ['General'];
          _selectedFolder = _folders.contains('General') ? 'General' : _folders.first;
          _categories = results[1];
          if (_categories.isNotEmpty) _selectedCategory = _categories.first;
          if (authorName.isNotEmpty) _authorController.text = authorName;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video, withData: true);
    if (result != null) {
      final file = result.files.first;
      setState(() {
        _videoFile = file;
        _statusMessage = 'Checking video duration...';
      });
      await _checkVideoDuration(file);
      if (_displayNameController.text.isEmpty) {
        _displayNameController.text = file.name.split('.').first;
      }
    }
  }

  Future<void> _checkVideoDuration(PlatformFile file) async {
    VideoPlayerController? controller;
    try {
      if (kIsWeb) {
        // On web we use the bytes as a blob URL or just use the data
        // video_player on web supports networkUrl from blob
      } else {
        controller = VideoPlayerController.file(File(file.path!));
      }

      if (controller != null) {
        await controller.initialize();
        final duration = controller.value.duration.inSeconds;
        setState(() {
          _videoDurationSeconds = duration;
          _validateDuration();
        });
        await controller.dispose();
      } else {
        // Fallback or skip duration check if platform not supported easily here
        setState(() {
          _videoDurationSeconds = 0;
          _isDurationValid = true;
        });
      }
    } catch (e) {
      debugPrint('Error checking duration: $e');
      setState(() {
        _videoDurationSeconds = null;
        _isDurationValid = true; // Assume valid if check fails to not block user
      });
    }
  }

  void _validateDuration() {
    if (_videoDurationSeconds == null) return;
    
    final maxSeconds = _isSingleVideo ? 60 : 420;
    if (_videoDurationSeconds! > maxSeconds) {
      _isDurationValid = false;
      _durationError = _isSingleVideo 
          ? "Single videos must be 1 minute or shorter."
          : "Folder videos must be 7 minutes or shorter.";
    } else {
      _isDurationValid = true;
      _durationError = null;
    }
  }

  Future<void> _pickThumbnail() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null) setState(() => _thumbnailFile = result.files.first);
  }

  Future<void> _startUpload() async {
    _validateDuration();
    if (!_isDurationValid) return;

    if (!_formKey.currentState!.validate() || _videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a video file and fill required fields')));
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _statusMessage = 'Starting upload...';
    });

    try {
      final service = UploadService(context.read<DioClient>());
      final videoMime = lookupMimeType(_videoFile!.name) ?? 'video/mp4';

      setState(() => _statusMessage = 'Requesting video upload URL...');
      final videoInfo = await service.getPresignedUrl(
        assetType: 'video', 
        folder: _isSingleVideo ? null : _selectedFolder,
        singleVideoOnly: _isSingleVideo,
        fileName: _videoFile!.name, 
        fileType: videoMime, 
        fileSize: _videoFile!.size,
      );

      final String? videoUrl = videoInfo['presignedUrl'];
      final String? videoKey = videoInfo['r2ObjectKey'] ?? videoInfo['objectKey'];

      if (videoUrl == null || videoKey == null) throw Exception('Failed to get video upload URL');

      setState(() => _statusMessage = 'Uploading video file...');
      await service.uploadBytes(url: videoUrl, bytes: _videoFile!.bytes!, contentType: videoMime, onProgress: (sent, total) {
        setState(() => _uploadProgress = sent / total * 0.7);
      });

      String? thumbKey;
      String? thumbMime;

      if (_thumbnailFile != null) {
        setState(() => _statusMessage = 'Requesting thumbnail upload URL...');
        thumbMime = lookupMimeType(_thumbnailFile!.name) ?? 'image/jpeg';
        final thumbInfo = await service.getPresignedUrl(
          assetType: 'thumbnail', 
          folder: _isSingleVideo ? null : _selectedFolder,
          singleVideoOnly: _isSingleVideo,
          fileName: _thumbnailFile!.name, 
          fileType: thumbMime, 
          fileSize: _thumbnailFile!.size,
        );
        final String? tUrl = thumbInfo['presignedUrl'];
        final String? tKey = thumbInfo['r2ObjectKey'] ?? thumbInfo['objectKey'];

        if (tUrl != null && tKey != null) {
          setState(() => _statusMessage = 'Uploading thumbnail...');
          await service.uploadBytes(url: tUrl, bytes: _thumbnailFile!.bytes!, contentType: thumbMime, onProgress: (sent, total) {
            setState(() => _uploadProgress = 0.7 + (sent / total * 0.2));
          });
          thumbKey = tKey;
        }
      }

      setState(() => _statusMessage = 'Submitting metadata...');
      await service.submitMetadata(
        fileName: _videoFile!.name,
        folder: _isSingleVideo ? null : _selectedFolder,
        singleVideoOnly: _isSingleVideo,
        fileSize: _videoFile!.size,
        fileType: videoMime,
        objectKey: videoKey,
        thumbnailFileName: _thumbnailFile?.name,
        thumbnailFileSize: _thumbnailFile?.size,
        thumbnailFileType: thumbMime,
        thumbnailObjectKey: thumbKey,
        displayName: _displayNameController.text,
        author: _authorController.text,
        category: _selectedCategory ?? '',
        description: _descriptionController.text,
        tags: _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        accessType: _accessType,
        visibility: _visibility,
      );

      if (mounted) context.read<VideoProvider>().loadVideos();

      setState(() {
        _isUploading = false;
        _uploadProgress = 1.0;
        _statusMessage = 'Video submitted successfully';
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Video submitted for review.'),
            actions: [TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('OK'))],
          ),
        );
      }
    } catch (e) {
      setState(() { _isUploading = false; _statusMessage = 'Error: $e'; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Video')),
      body: _isLoadingData 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isUploading) ...[
                LinearProgressIndicator(value: _uploadProgress),
                const SizedBox(height: 8),
                Text(_statusMessage, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 16),
              ],
              ListTile(
                leading: const Icon(Icons.video_library, color: Colors.deepPurple),
                title: Text(_videoFile?.name ?? 'Select Video (Required)'),
                subtitle: _videoDurationSeconds != null 
                    ? Text('Duration: $_videoDurationSeconds seconds', style: TextStyle(color: _isDurationValid ? Colors.green : Colors.red))
                    : null,
                trailing: ElevatedButton(onPressed: _isUploading ? null : _pickVideo, child: const Text('Pick')),
                shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              ),
              if (!_isDurationValid) 
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 16),
                  child: Text(_durationError ?? '', style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.image, color: Colors.deepPurple),
                title: Text(_thumbnailFile?.name ?? 'Select Thumbnail (Optional)'),
                trailing: ElevatedButton(onPressed: _isUploading ? null : _pickThumbnail, child: const Text('Pick')),
                shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Single Video (Feed Only)'),
                subtitle: const Text('Appears in the mixed feed'),
                value: _isSingleVideo, 
                onChanged: _isUploading ? null : (v) => setState(() {
                   _isSingleVideo = v;
                   _validateDuration();
                }),
              ),
              if (!_isSingleVideo) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedFolder,
                  decoration: const InputDecoration(labelText: 'Folder', border: OutlineInputBorder()),
                  items: _folders.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: _isUploading ? null : (v) => setState(() => _selectedFolder = v),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(controller: _displayNameController, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _authorController, decoration: const InputDecoration(labelText: 'Author', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              if (_categories.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: _isUploading ? null : (v) => setState(() => _selectedCategory = v),
                  validator: (v) => v == null ? 'Category is required' : null,
                )
              else
                TextFormField(
                  onChanged: (v) => _selectedCategory = v, 
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? 'Category is required' : null,
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 3,
                validator: (v) => (v == null || v.isEmpty) ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)', 
                  hintText: 'flutter, networking, tutorial',
                  border: OutlineInputBorder()
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'At least one tag required';
                  final tags = v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                  if (tags.isEmpty) return 'At least one tag required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _visibility,
                decoration: const InputDecoration(labelText: 'Visibility', border: OutlineInputBorder()),
                items: _visibilityOptions.map((v) => DropdownMenuItem(value: v, child: Text(v.replaceAll('_', ' ')))).toList(),
                onChanged: _isUploading ? null : (v) => setState(() => _visibility = v!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: (_isUploading || !_isDurationValid) ? null : _startUpload,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                child: _isUploading ? const CircularProgressIndicator(color: Colors.white) : const Text('UPLOAD VIDEO', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
