import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';
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
  
  String? _selectedCategory;
  List<String> _categories = [];
  String _accessType = 'FREE';
  String _visibility = 'PUBLIC';
  final List<String> _visibilityOptions = ['PUBLIC', 'FOLLOWERS_ONLY', 'FRIENDS_ONLY', 'PRIVATE'];

  bool _isUploading = false;
  bool _isLoadingData = true;
  double _uploadProgress = 0;
  String _statusMessage = '';

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
      final service = UploadService(context.read<DioClient>());
      final categories = await service.fetchCategories();
      
      // Auto-fill author from logged-in user if available
      final authProvider = context.read<AuthProvider>();
      final userName = authProvider.user?.name ?? authProvider.user?.username ?? '';
      if (userName.isNotEmpty) {
        _authorController.text = userName;
      }

      setState(() {
        _categories = categories;
        if (_categories.isNotEmpty) _selectedCategory = _categories.first;
        _isLoadingData = false;
      });
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video, withData: true);
    if (result != null) {
      setState(() {
        _videoFile = result.files.first;
        if (_displayNameController.text.isEmpty) {
          _displayNameController.text = _videoFile!.name.split('.').first;
        }
      });
    }
  }

  Future<void> _pickThumbnail() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null) setState(() => _thumbnailFile = result.files.first);
  }

  Future<void> _startUpload() async {
    if (!_formKey.currentState!.validate() || _videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a video file and fill all required fields')));
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _statusMessage = 'Preparing upload...';
    });

    try {
      final service = UploadService(context.read<DioClient>());
      final videoMime = lookupMimeType(_videoFile!.name) ?? 'video/mp4';

      setState(() => _statusMessage = 'Uploading video...');
      final videoInfo = await service.getPresignedUrl(
        assetType: 'video', 
        fileName: _videoFile!.name, 
        fileType: videoMime, 
        fileSize: _videoFile!.size,
      );

      final String? videoUrl = videoInfo['presignedUrl'];
      final String? videoKey = videoInfo['r2ObjectKey'] ?? videoInfo['objectKey'];

      if (videoUrl == null || videoKey == null) throw Exception('Failed to get video upload URL');

      await service.uploadBytes(url: videoUrl, bytes: _videoFile!.bytes!, contentType: videoMime, onProgress: (sent, total) {
        setState(() => _uploadProgress = sent / total * 0.7);
      });

      String? thumbKey;
      String? thumbMime;

      if (_thumbnailFile != null) {
        setState(() => _statusMessage = 'Uploading thumbnail...');
        thumbMime = lookupMimeType(_thumbnailFile!.name) ?? 'image/jpeg';
        final thumbInfo = await service.getPresignedUrl(
          assetType: 'thumbnail', 
          fileName: _thumbnailFile!.name, 
          fileType: thumbMime, 
          fileSize: _thumbnailFile!.size,
        );
        final String? tUrl = thumbInfo['presignedUrl'];
        final String? tKey = thumbInfo['r2ObjectKey'] ?? thumbInfo['objectKey'];

        if (tUrl != null && tKey != null) {
          await service.uploadBytes(url: tUrl, bytes: _thumbnailFile!.bytes!, contentType: thumbMime, onProgress: (sent, total) {
            setState(() => _uploadProgress = 0.7 + (sent / total * 0.2));
          });
          thumbKey = tKey;
        }
      }

      setState(() => _statusMessage = 'Saving metadata...');
      await service.submitMetadata(
        fileName: _videoFile!.name,
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
        _statusMessage = 'Video submitted for review';
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Your video has been submitted for admin review.'),
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
                trailing: ElevatedButton(onPressed: _isUploading ? null : _pickVideo, child: const Text('Pick')),
                shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.image, color: Colors.deepPurple),
                title: Text(_thumbnailFile?.name ?? 'Select Thumbnail (Optional)'),
                trailing: ElevatedButton(onPressed: _isUploading ? null : _pickThumbnail, child: const Text('Pick')),
                shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(labelText: 'Author', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Author is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 3,
                validator: (v) => (v == null || v.isEmpty) ? 'Description is required' : null,
              ),
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
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)', 
                  hintText: 'flutter, networking, tutorial',
                  border: OutlineInputBorder()
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'At least one tag is required';
                  final tags = v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                  if (tags.isEmpty) return 'At least one tag is required';
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
                onPressed: _isUploading ? null : _startUpload,
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

