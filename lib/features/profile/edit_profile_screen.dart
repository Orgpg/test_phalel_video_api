import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:mime/mime.dart';
import 'package:dio/dio.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;
  
  XFile? _imageFile;
  bool _isSaving = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user!;
    _nameController = TextEditingController(text: user.name);
    _usernameController = TextEditingController(text: user.username);
    _bioController = TextEditingController(text: user.bio);
    _phoneController = TextEditingController(text: user.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _imageFile = image);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _status = 'Saving profile...';
    });

    try {
      final userService = context.read<UserService>();
      final authProvider = context.read<AuthProvider>();

      String? avatarKey;
      String? fileName;
      int? fileSize;
      String? fileType;

      if (_imageFile != null) {
        setState(() => _status = 'Uploading avatar...');
        final bytes = await _imageFile!.readAsBytes();
        fileName = _imageFile!.name;
        fileSize = bytes.length;
        fileType = lookupMimeType(_imageFile!.path) ?? 'image/jpeg';

        final presigned = await userService.getAvatarPresignedUrl(
          fileName: fileName,
          fileType: fileType,
          fileSize: fileSize,
        );

        // Upload to presigned URL without Auth header
        await Dio().put(
          presigned['presignedUrl'],
          data: bytes,
          options: Options(headers: {'Content-Type': fileType}),
        );
        avatarKey = presigned['objectKey'];
      }

      setState(() => _status = 'Updating profile details...');
      await userService.updateMe(
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        phone: _phoneController.text.trim(),
        avatarObjectKey: avatarKey,
        avatarFileName: fileName,
        avatarFileSize: fileSize,
        avatarFileType: fileType,
      );

      await authProvider.refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
          else
            TextButton(onPressed: _save, child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _buildAvatarProvider(user),
                      child: (_imageFile == null && user.avatarUrl == null) ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        radius: 18,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (_status.isNotEmpty && _isSaving) ...[
                Text(_status, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: 'Bio', border: OutlineInputBorder(), alignLabelWithHint: true),
                maxLines: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider? _buildAvatarProvider(dynamic user) {
    if (_imageFile != null) {
      if (kIsWeb) {
        return NetworkImage(_imageFile!.path);
      } else {
        return FileImage(File(_imageFile!.path));
      }
    }
    
    if (user.avatarUrl != null) {
      final url = user.avatarUrl!.startsWith('/api') 
          ? 'https://phaleldb.waiphyoaung.dev${user.avatarUrl}' 
          : user.avatarUrl!;
      return NetworkImage(url);
    }
    
    return null;
  }
}
