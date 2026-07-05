import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';
import '../../core/models/user_verification.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/verification_service.dart';
import '../../core/network/dio_client.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _verificationFormKey = GlobalKey<FormState>();
  final _resetPasswordFormKey = GlobalKey<FormState>();
  
  final _fullNameController = TextEditingController();
  final _nrcController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String _selectedGender = 'male';
  bool _isSubmittingVerification = false;
  bool _isResettingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  XFile? _nrcFrontImage;
  XFile? _nrcBackImage;
  XFile? _selfieImage;
  
  String _uploadStatus = '';

  @override
  void dispose() {
    _fullNameController.dispose();
    _nrcController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickImage(String type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: type == 'selfie' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      final size = await image.length();
      if (size > 8 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image size must be less than 8 MB')),
          );
        }
        return;
      }

      setState(() {
        if (type == 'nrc-front') _nrcFrontImage = image;
        if (type == 'nrc-back') _nrcBackImage = image;
        if (type == 'selfie') _selfieImage = image;
      });
    }
  }

  Future<String> _uploadToMinio(XFile file, String documentType) async {
    final service = VerificationService(context.read<DioClient>());
    final bytes = await file.readAsBytes();
    final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
    
    setState(() => _uploadStatus = 'Uploading $documentType...');
    
    final presignedData = await service.getVerificationPresignedUrl(
      fileName: file.name,
      fileType: mimeType,
      fileSize: bytes.length,
      documentType: documentType,
    );

    await service.uploadImageToPresignedUrl(
      url: presignedData['presignedUrl'],
      bytes: bytes,
      contentType: mimeType,
    );

    return presignedData['objectKey'];
  }

  Future<void> _submitVerification() async {
    if (!_verificationFormKey.currentState!.validate()) return;
    
    if (_nrcFrontImage == null || _nrcBackImage == null || _selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all required images')),
      );
      return;
    }

    setState(() {
      _isSubmittingVerification = true;
      _uploadStatus = 'Starting upload...';
    });

    try {
      final frontKey = await _uploadToMinio(_nrcFrontImage!, 'nrc-front');
      final backKey = await _uploadToMinio(_nrcBackImage!, 'nrc-back');
      final selfieKey = await _uploadToMinio(_selfieImage!, 'selfie');

      setState(() => _uploadStatus = 'Submitting metadata...');

      final verification = UserVerification(
        userId: '',
        fullName: _fullNameController.text.trim(),
        nrcNumber: _nrcController.text.trim(),
        phone: _phoneController.text.trim(),
        dateOfBirth: _dobController.text.trim(),
        gender: _selectedGender,
        nrcFrontObjectKey: frontKey,
        nrcBackObjectKey: backKey,
        selfieObjectKey: selfieKey,
        status: 'PENDING',
        submittedAt: DateTime.now(),
      );

      final authProvider = context.read<AuthProvider>();
      await authProvider.submitVerification(verification);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification submitted successfully!'), backgroundColor: Colors.green),
        );
        await authProvider.refreshUser();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingVerification = false;
          _uploadStatus = '';
        });
      }
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_resetPasswordFormKey.currentState!.validate()) return;

    setState(() => _isResettingPassword = true);

    final authProvider = context.read<AuthProvider>();

    try {
      await authProvider.resetPassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully'), backgroundColor: Colors.green),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isResettingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (auth.state == AuthState.loading && user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final role = user.preference?.role.toUpperCase() ?? 'LEARNER';
    final canVerify = role == 'TEACHER' || role == 'BOTH';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => auth.refreshUser(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => auth.refreshUser(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(user),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Account Information'),
                    _buildInfoTile('Username', user.username),
                    _buildInfoTile('Email', user.email),
                    _buildInfoTile('Role', user.preference?.role ?? 'Learner'),
                    
                    const Divider(height: 40),
                    _buildSectionTitle('Reset Password'),
                    _buildResetPasswordForm(),
                    
                    if (canVerify) ...[
                      const Divider(height: 40),
                      _buildSectionTitle('Teacher Tools'),
                      ListTile(
                        leading: const Icon(Icons.dashboard, color: Colors.deepPurple),
                        title: const Text('Manage Mentor Listings'),
                        subtitle: const Text('Create or edit your teaching sessions'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => context.push('/mentor-management'),
                      ),
                      const Divider(height: 40),
                      _buildSectionTitle('Identity Verification'),
                      _buildVerificationSection(auth),
                    ],
                    
                    const Divider(height: 40),
                    _buildLogoutButton(auth),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic user) {
    return Container(
      color: Colors.deepPurple,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 60, color: Colors.deepPurple),
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            user.email,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Chip(
            label: Text(user.role),
            backgroundColor: Colors.white24,
            labelStyle: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildResetPasswordForm() {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _resetPasswordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPasswordField(_currentPasswordController, 'Current Password', _obscureCurrentPassword, () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword)),
              const SizedBox(height: 12),
              _buildPasswordField(_newPasswordController, 'New Password', _obscureNewPassword, () => setState(() => _obscureNewPassword = !_obscureNewPassword), validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v.length < 8) return 'Min 8 characters';
                if (v == _currentPasswordController.text) return 'Cannot be same as old password';
                return null;
              }),
              const SizedBox(height: 12),
              _buildPasswordField(_confirmPasswordController, 'Confirm New Password', _obscureConfirmPassword, () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword), validator: (v) {
                if (v != _newPasswordController.text) return 'Passwords do not match';
                return null;
              }),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isResettingPassword ? null : _handleResetPassword,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: _isResettingPassword ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('UPDATE PASSWORD'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, bool obscure, VoidCallback onToggle, {String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off : Icons.visibility), onPressed: onToggle),
        border: const OutlineInputBorder(),
      ),
      validator: validator ?? (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }

  Widget _buildVerificationSection(AuthProvider auth) {
    final verification = auth.user?.verification;
    final status = verification?.status.toUpperCase() ?? 'NOT_SUBMITTED';

    if (status == 'VERIFIED') {
      return _buildStatusBadge(Icons.verified, Colors.green, 'Verified');
    }

    if (status == 'PENDING') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusBadge(Icons.hourglass_top, Colors.orange, 'Verification Pending'),
          if (verification != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 32),
              child: Text(
                'Submitted on: ${DateFormat('MMM dd, yyyy').format(verification.submittedAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (status == 'REJECTED')
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildStatusBadge(Icons.error_outline, Colors.red, 'Verification Rejected'),
          ),
        _buildVerificationForm(status == 'REJECTED'),
      ],
    );
  }

  Widget _buildStatusBadge(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildVerificationForm(bool isResubmission) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _verificationFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(isResubmission ? 'Update Details' : 'Verify Your Identity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              _buildTextField(_fullNameController, 'Full Name', Icons.person),
              const SizedBox(height: 12),
              _buildTextField(_nrcController, 'NRC Number', Icons.badge),
              const SizedBox(height: 12),
              _buildTextField(_phoneController, 'Phone Number', Icons.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dobController,
                readOnly: true,
                onTap: () => _selectDate(context),
                decoration: const InputDecoration(labelText: 'Date of Birth', prefixIcon: Icon(Icons.calendar_today), border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _selectedGender = v!),
                decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.people), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              const Text('Photo Evidence (Required)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 16),
              _buildImagePickerTile('NRC Front Image', _nrcFrontImage, () => _pickImage('nrc-front')),
              const SizedBox(height: 12),
              _buildImagePickerTile('NRC Back Image', _nrcBackImage, () => _pickImage('nrc-back')),
              const SizedBox(height: 12),
              _buildImagePickerTile('Selfie with ID', _selfieImage, () => _pickImage('selfie')),
              const SizedBox(height: 24),
              if (_uploadStatus.isNotEmpty) ...[
                Text(_uploadStatus, textAlign: TextAlign.center, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
              ],
              ElevatedButton(
                onPressed: _isSubmittingVerification ? null : _submitVerification,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: _isSubmittingVerification ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isResubmission ? 'RESUBMIT VERIFICATION' : 'SUBMIT VERIFICATION'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerTile(String label, XFile? image, VoidCallback onTap) {
    return InkWell(
      onTap: _isSubmittingVerification ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8), color: Colors.white),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
              child: image != null 
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4), 
                    child: kIsWeb 
                      ? Image.network(image.path, fit: BoxFit.cover) 
                      : Image.file(File(image.path), fit: BoxFit.cover)
                  )
                : Icon(Icons.camera_alt, color: Colors.grey.shade400),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(image != null ? 'Image selected' : 'No image selected', style: TextStyle(color: image != null ? Colors.green : Colors.grey, fontSize: 12)),
            ])),
            if (image != null) const Icon(Icons.check_circle, color: Colors.green) else const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder()),
      keyboardType: keyboardType,
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }

  Widget _buildLogoutButton(AuthProvider auth) {
    return ElevatedButton.icon(
      onPressed: () => auth.logout(),
      icon: const Icon(Icons.logout),
      label: const Text('LOGOUT'),
      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.red.shade50, foregroundColor: Colors.red, side: BorderSide(color: Colors.red.shade200)),
    );
  }
}
