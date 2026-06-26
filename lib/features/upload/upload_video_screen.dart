import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';
import '../../core/repositories/upload_repository.dart';
import '../../core/network/dio_client.dart';

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
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  String _accessType = 'FREE';

  bool _isUploading = false;
  double _uploadProgress = 0;
  String _statusMessage = '';

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
    if (!_formKey.currentState!.validate() || _videoFile == null || _thumbnailFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select files')),
      );
      return;
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
      final videoMime = lookupMimeType(_videoFile!.name) ?? 'video/mp4';
      final videoInfo = await repo.getPresignedUrl(
        assetType: 'video',
        fileName: _videoFile!.name,
        fileType: videoMime,
        fileSize: _videoFile!.size,
      );

      // Step 2: Upload Video Bytes
      setState(() => _statusMessage = 'Uploading video file...');
      await repo.uploadBytes(
        url: videoInfo['presignedUrl'],
        bytes: _videoFile!.bytes!,
        contentType: videoMime,
        onProgress: (sent, total) {
          setState(() {
            _uploadProgress = sent / total * 0.7; // 70% for video
          });
        },
      );

      // Step 3: Thumbnail Presigned URL
      setState(() => _statusMessage = 'Requesting thumbnail upload URL...');
      final thumbMime = lookupMimeType(_thumbnailFile!.name) ?? 'image/jpeg';
      final thumbInfo = await repo.getPresignedUrl(
        assetType: 'thumbnail',
        fileName: _thumbnailFile!.name,
        fileType: thumbMime,
        fileSize: _thumbnailFile!.size,
      );

      // Step 4: Upload Thumbnail Bytes
      setState(() => _statusMessage = 'Uploading thumbnail...');
      await repo.uploadBytes(
        url: thumbInfo['presignedUrl'],
        bytes: _thumbnailFile!.bytes!,
        contentType: thumbMime,
        onProgress: (sent, total) {
          setState(() {
            _uploadProgress = 0.7 + (sent / total * 0.2); // +20% for thumb
          });
        },
      );

      // Step 5: Submit Metadata
      setState(() => _statusMessage = 'Submitting metadata for review...');
      final tags = _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      
      await repo.submitMetadata(
        fileName: _fileNameController.text,
        fileSize: _videoFile!.size,
        fileType: videoMime,
        r2ObjectKey: videoInfo['r2ObjectKey'],
        thumbnailFileName: _thumbnailFile!.name,
        thumbnailFileSize: _thumbnailFile!.size,
        thumbnailFileType: thumbMime,
        thumbnailObjectKey: thumbInfo['r2ObjectKey'],
        displayName: _displayNameController.text,
        category: _categoryController.text,
        description: _descriptionController.text,
        tags: tags,
        accessType: _accessType,
      );

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
            content: const Text('Video submitted for admin review'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Section
              if (_isUploading) ...[
                LinearProgressIndicator(value: _uploadProgress),
                const SizedBox(height: 8),
                Text(_statusMessage, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
              ],

              // Video Picker
              ListTile(
                leading: const Icon(Icons.video_library),
                title: Text(_videoFile?.name ?? 'Select Video File'),
                subtitle: _videoFile != null ? Text('${(_videoFile!.size / 1024 / 1024).toStringAsFixed(2)} MB') : null,
                trailing: ElevatedButton(onPressed: _isUploading ? null : _pickVideo, child: const Text('Pick')),
                shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              ),
              const SizedBox(height: 16),

              // Thumbnail Picker
              if (_thumbnailFile != null)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(_thumbnailFile!.bytes!, fit: BoxFit.cover),
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.image),
                title: Text(_thumbnailFile?.name ?? 'Select Thumbnail'),
                trailing: ElevatedButton(onPressed: _isUploading ? null : _pickThumbnail, child: const Text('Pick')),
                shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
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
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(labelText: 'Tags (comma separated)', border: OutlineInputBorder(), hintText: 'flutter, dart, tutorial'),
                validator: (v) => v!.isEmpty ? 'At least one tag required' : null,
              ),
              const SizedBox(height: 16),
              
              const Text('Video Access'),
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
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isUploading ? const CircularProgressIndicator(color: Colors.white) : const Text('UPLOAD VIDEO'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
