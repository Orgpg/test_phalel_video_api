import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:mime/mime.dart';
import '../../core/services/post_service.dart';
import '../../core/services/upload_service.dart';
import '../../core/network/dio_client.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _bodyController = TextEditingController();
  XFile? _image;
  bool _isSubmitting = false;
  String _visibility = 'PUBLIC';

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img != null) {
      setState(() => _image = img);
    }
  }

  Future<void> _submit() async {
    if (_bodyController.text.trim().isEmpty && _image == null) return;

    setState(() => _isSubmitting = true);

    try {
      final postService = context.read<PostService>();
      final uploadService = context.read<UploadService>();
      
      String? imageKey;
      String? imageMime;

      if (_image != null) {
        final bytes = await _image!.readAsBytes();
        imageMime = lookupMimeType(_image!.path) ?? 'image/jpeg';
        
        final presigned = await postService.getPostPresignedUrl(
          fileName: _image!.name,
          fileType: imageMime,
          fileSize: bytes.length,
        );

        await uploadService.uploadBytes(
          url: presigned['presignedUrl'],
          bytes: bytes,
          contentType: imageMime,
        );
        imageKey = presigned['objectKey'];
      }

      await postService.createPost(
        body: _bodyController.text.trim(),
        imageObjectKey: imageKey,
        imageFileName: _image?.name,
        imageFileSize: _image != null ? await _image!.length() : null,
        imageFileType: imageMime,
        visibility: _visibility,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Post submitted for approval.'),
            actions: [
              TextButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('OK'))
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          if (_isSubmitting)
            const Center(child: Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
          else
            TextButton(
              onPressed: _submit,
              child: const Text('POST', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _bodyController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),
            if (_image != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildImagePreview(),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => setState(() => _image = null),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Add Photo'),
              onTap: _pickImage,
            ),
            const Divider(),
            DropdownButtonListTile(
              title: const Text('Visibility'),
              value: _visibility,
              items: const [
                DropdownMenuItem(value: 'PUBLIC', child: Text('Public')),
                DropdownMenuItem(value: 'FOLLOWERS_ONLY', child: Text('Followers Only')),
                DropdownMenuItem(value: 'FRIENDS_ONLY', child: Text('Friends Only')),
                DropdownMenuItem(value: 'PRIVATE', child: Text('Private')),
              ],
              onChanged: (v) => setState(() => _visibility = v!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (kIsWeb) {
      return Image.network(_image!.path, height: 200, width: double.infinity, fit: BoxFit.cover);
    } else {
      return Image.file(File(_image!.path), height: 200, width: double.infinity, fit: BoxFit.cover);
    }
  }
}

class DropdownButtonListTile extends StatelessWidget {
  final Widget title;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const DropdownButtonListTile({super.key, required this.title, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: title),
        DropdownButton<String>(value: value, items: items, onChanged: onChanged),
      ],
    );
  }
}
