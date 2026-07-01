import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';
import '../../core/repositories/upload_repository.dart';
import '../../core/network/dio_client.dart';
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
  
  final _fileNameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  
  String? _selectedFolder;
  List<String> _folders = ['General'];
  String? _selectedCategory;
  List<String> _categories = [];
  String _accessType = 'FREE';

  bool _isUploading = false;
  bool _isLoadingData = true;
  double _uploadProgress = 0;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final repo = UploadRepository(context.read<DioClient>());
      final results = await Future.wait([
        repo.fetchFolders(),
        repo.fetchCategories(),
      ]);

      final folders = results[0] as List<String>;
      final categories = results[1] as List<String>;

      setState(() {
        _folders = folders.isNotEmpty ? folders : ['General'];
        _selectedFolder = _folders.contains('General') ? 'General' : _folders.first;
        
        _categories = categories;
        if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first;
        }
        
        _isLoadingData = false;
      });
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      setState(() {
        _folders = ['General'];
        _selectedFolder = 'General';
        _isLoadingData = false;
      });
    }
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: true,
    );
    if (result != null) {
      setState(() {
        _videoFile = result.files.first;
        if (_fileNameController.text.isEmpty) {
          _fileNameController.text = _videoFile!.name;
        }
        if (_displayNameController.text.isEmpty) {
          _displayNameController.text = _videoFile!.name.split('.').first;
        }
      });
    }
  }

  Future<void> _pickThumbnail() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null) {
      setState(() {
        _thumbnailFile = result.files.first;
      });
    }
  }

  Future<void> _startUpload() async {
    if (!_formKey.currentState!.validate() || _videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video file and fill all required fields')),
      );
      return;
    }

    final folder = _selectedFolder ?? 'General';
    final folderRegex = RegExp(r'^[a-zA-Z0-9\._\-]+$');
    if (!folderRegex.hasMatch(folder)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Folder name can only contain letters, numbers, dots, dashes, and underscores')),
      );
      return;
    }

    final videoMime = lookupMimeType(_videoFile!.name) ?? 'video/mp4';
    if (videoMime != 'video/mp4' && videoMime != 'video/webm') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Allowed video types: video/mp4, video/webm')),
      );
      return;
    }

    if (_thumbnailFile != null) {
      final thumbMime = lookupMimeType(_thumbnailFile!.name) ?? 'image/jpeg';
      if (thumbMime != 'image/jpeg' && thumbMime != 'image/png' && thumbMime != 'image/webp') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Allowed thumbnail types: image/jpeg, image/png, image/webp')),
        );
        return;
      }
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _statusMessage = 'Starting upload...';
    });

    try {
      final repo = UploadRepository(context.read<DioClient>());

      // Step 1: Video Presigned URL
      setState(() => _statusMessage = 'Requesting video upload URL...');
      final videoInfo = await repo.getPresignedUrl(
        assetType: 'video',
        folder: folder,
        fileName: _videoFile!.name,
        fileType: videoMime,
        fileSize: _videoFile!.size,
      );

      final String? videoPresignedUrl = videoInfo['presignedUrl'];
      final String? videoR2Key = videoInfo['r2ObjectKey'] ?? videoInfo['objectKey'];

      if (videoPresignedUrl == null || videoR2Key == null) {
        throw Exception('Failed to get video upload URL or Object Key from server');
      }

      // Step 2: Upload Video Bytes
      setState(() => _statusMessage = 'Uploading video file...');
      await repo.uploadBytes(
        url: videoPresignedUrl,
        bytes: _videoFile!.bytes!,
        contentType: videoMime,
        onProgress: (sent, total) {
          setState(() {
            _uploadProgress = sent / total * 0.7; // 70% for video
          });
        },
      );

      String? finalThumbnailR2Key;
      String? finalThumbnailMime;

      // Step 3: Optional Thumbnail
      if (_thumbnailFile != null) {
        setState(() => _statusMessage = 'Requesting thumbnail upload URL...');
        finalThumbnailMime = lookupMimeType(_thumbnailFile!.name) ?? 'image/jpeg';
        final thumbInfo = await repo.getPresignedUrl(
          assetType: 'thumbnail',
          folder: folder,
          fileName: _thumbnailFile!.name,
          fileType: finalThumbnailMime,
          fileSize: _thumbnailFile!.size,
        );

        final String? thumbPresignedUrl = thumbInfo['presignedUrl'];
        final String? thumbR2Key = thumbInfo['r2ObjectKey'] ?? thumbInfo['objectKey'];

        if (thumbPresignedUrl != null && thumbR2Key != null) {
          setState(() => _statusMessage = 'Uploading thumbnail...');
          await repo.uploadBytes(
            url: thumbPresignedUrl,
            bytes: _thumbnailFile!.bytes!,
            contentType: finalThumbnailMime,
            onProgress: (sent, total) {
              setState(() {
                _uploadProgress = 0.7 + (sent / total * 0.2); // +20% for thumb
              });
            },
          );
          finalThumbnailR2Key = thumbR2Key;
        } else {
          debugPrint('Thumbnail upload skipped: Could not get presigned URL');
        }
      }

      // Step 4: Submit Metadata (Only if video upload succeeded)
      setState(() => _statusMessage = 'Submitting metadata for review...');
      final tags = _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      
      await repo.submitMetadata(
        fileName: _fileNameController.text,
        folder: folder,
        fileSize: _videoFile!.size,
        fileType: videoMime,
        objectKey: videoR2Key,
        thumbnailFileName: _thumbnailFile?.name,
        thumbnailFileSize: _thumbnailFile?.size,
        thumbnailFileType: finalThumbnailMime,
        thumbnailObjectKey: finalThumbnailR2Key,
        displayName: _displayNameController.text,
        author: _authorController.text,
        category: _selectedCategory ?? '',
        description: _descriptionController.text,
        tags: tags,
        accessType: _accessType,
      );

      // Refresh data after successful upload
      if (mounted) {
        context.read<VideoProvider>().loadVideos();
      }

      setState(() {
        _isUploading = false;
        _uploadProgress = 1.0;
        _statusMessage = 'Video submitted for admin review';
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Video submitted for admin review. It will appear once approved by admin.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Upload Error: $e');
      setState(() {
        _isUploading = false;
        _statusMessage = 'Error: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload New Video')),
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
                title: Text(_videoFile?.name ?? 'Select Video File (Required)'),
                subtitle: _videoFile != null ? Text('${(_videoFile!.size / 1024 / 1024).toStringAsFixed(2)} MB') : null,
                trailing: ElevatedButton(onPressed: _isUploading ? null : _pickVideo, child: const Text('Pick')),
                shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              ),
              const SizedBox(height: 16),

              if (_thumbnailFile != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(_thumbnailFile!.bytes!, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.image, color: Colors.deepPurple),
                title: Text(_thumbnailFile?.name ?? 'Select Thumbnail (Optional)'),
                trailing: ElevatedButton(onPressed: _isUploading ? null : _pickThumbnail, child: const Text('Pick')),
                shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedFolder,
                decoration: const InputDecoration(labelText: 'Select Folder', border: OutlineInputBorder()),
                items: _folders.map((folder) => DropdownMenuItem(value: folder, child: Text(folder))).toList(),
                onChanged: _isUploading ? null : (v) => setState(() => _selectedFolder = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fileNameController,
                decoration: const InputDecoration(labelText: 'File Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(labelText: 'Display Name', border: OutlineInputBorder()),
                maxLength: 120,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(labelText: 'Author', border: OutlineInputBorder()),
                maxLength: 120,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              if (_categories.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                  onChanged: _isUploading ? null : (v) => setState(() => _selectedCategory = v),
                  validator: (v) => v == null ? 'Required' : null,
                )
              else
                TextFormField(
                  onChanged: (v) => _selectedCategory = v,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  maxLength: 80,
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 3,
                maxLength: 1000,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(labelText: 'Tags (comma separated)', border: OutlineInputBorder(), hintText: 'networking, tutorial'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'At least one tag required';
                  final tags = v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                  if (tags.isEmpty) return 'At least one tag required';
                  if (tags.length > 20) return 'Maximum 20 tags allowed';
                  for (var tag in tags) {
                    if (tag.length > 40) return 'Each tag must be max 40 chars';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              const Text('Video Access', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('FREE'),
                      value: 'FREE',
                      groupValue: _accessType,
                      onChanged: _isUploading ? null : (v) => setState(() => _accessType = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('PREMIUM'),
                      value: 'PREMIUM',
                      groupValue: _accessType,
                      onChanged: _isUploading ? null : (v) => setState(() => _accessType = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isUploading ? null : _startUpload,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isUploading ? const CircularProgressIndicator(color: Colors.white) : const Text('UPLOAD VIDEO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
