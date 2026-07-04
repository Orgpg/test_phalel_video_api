import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/user_verification.dart';
import '../../core/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form Controllers
  final _fullNameController = TextEditingController();
  final _nrcController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _nrcFrontUrlController = TextEditingController();
  final _nrcBackUrlController = TextEditingController();
  final _selfieUrlController = TextEditingController();
  
  String _selectedGender = 'male';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Profile is already initialized by AuthWrapper. 
    // We only need to call refreshUser if we want to ensure latest data without showing a splash screen.
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _nrcController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _nrcFrontUrlController.dispose();
    _nrcBackUrlController.dispose();
    _selfieUrlController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    await context.read<AuthProvider>().refreshUser();
  }

  bool _isValidUrl(String? value) {
    if (value == null || value.isEmpty) return false;
    final urlPattern = r'^(http|https):\/\/[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,3}(/\S*)?$';
    return RegExp(urlPattern).hasMatch(value);
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

  Future<void> _submitVerification() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        final verification = UserVerification(
          userId: '', // Server handles this
          fullName: _fullNameController.text.trim(),
          nrcNumber: _nrcController.text.trim(),
          phone: _phoneController.text.trim(),
          dateOfBirth: _dobController.text.trim(),
          gender: _selectedGender,
          nrcFrontUrl: _nrcFrontUrlController.text.trim(),
          nrcBackUrl: _nrcBackUrlController.text.trim(),
          selfieUrl: _selfieUrlController.text.trim(),
          status: 'PENDING',
          submittedAt: DateTime.now(),
        );

        await context.read<AuthProvider>().submitVerification(verification);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh profile to update UI
          await context.read<AuthProvider>().refreshUser();
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = 'An error occurred. Please try again.';
          final errorStr = e.toString();
          
          if (errorStr.contains('400')) {
            errorMessage = 'Invalid input. Please check your verification information.';
          } else if (errorStr.contains('401')) {
            // AuthProvider usually handles logout on 401
            return;
          } else if (errorStr.contains('500')) {
            errorMessage = 'Server error. Please try again later.';
          } else if (errorStr.contains('SocketException') || errorStr.contains('Network')) {
            errorMessage = 'Network error. Please try again.';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
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
                    _buildInfoTile('Role Preference', user.preference?.role ?? 'Not set'),
                    _buildInfoTile('Language', user.preference?.preferredLanguage ?? 'Not set'),
                    
                    const Divider(height: 40),
                    _buildSectionTitle('Identity Verification'),
                    _buildVerificationSection(auth),
                    
                    const Divider(height: 40),
                    _buildSectionTitle('Interests'),
                    _buildInterestsSection(user),
                    
                    const SizedBox(height: 40),
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

    // Show form if NOT_SUBMITTED or REJECTED
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
        Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildVerificationForm(bool isResubmission) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isResubmission ? 'Update Details' : 'Verify Your Identity',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildTextField(_fullNameController, 'Full Name', Icons.person),
              const SizedBox(height: 12),
              _buildTextField(_nrcController, 'NRC Number', Icons.badge),
              const SizedBox(height: 12),
              _buildTextField(_phoneController, 'Phone Number', Icons.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              
              // Date Picker Field
              TextFormField(
                controller: _dobController,
                readOnly: true,
                onTap: () => _selectDate(context),
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Gender Dropdown
              DropdownButtonFormField<String>(
                value: _selectedGender,
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _selectedGender = v!),
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.people),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              
              const Text('Photo Evidence URLs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              _buildUrlField(_nrcFrontUrlController, 'NRC Front Image URL'),
              const SizedBox(height: 12),
              _buildUrlField(_nrcBackUrlController, 'NRC Back Image URL'),
              const SizedBox(height: 12),
              _buildUrlField(_selfieUrlController, 'Selfie Image URL'),
              
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isResubmission ? 'RESUBMIT VERIFICATION' : 'SUBMIT VERIFICATION'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }

  Widget _buildUrlField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'https://example.com/image.jpg',
        border: const OutlineInputBorder(),
      ),
      validator: (v) => !_isValidUrl(v) ? 'Enter a valid URL (http/https)' : null,
    );
  }

  Widget _buildInterestsSection(dynamic user) {
    final skills = user.preference?.learnSkills;
    if (skills == null || skills.isEmpty) {
      return const Text('No interests set', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic));
    }
    return Wrap(
      spacing: 8,
      children: skills.map<Widget>((s) => Chip(label: Text(s.toString()))).toList(),
    );
  }

  Widget _buildLogoutButton(AuthProvider auth) {
    return ElevatedButton.icon(
      onPressed: () => auth.logout(),
      icon: const Icon(Icons.logout),
      label: const Text('LOGOUT'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: Colors.red.shade50,
        foregroundColor: Colors.red,
        side: BorderSide(color: Colors.red.shade200),
      ),
    );
  }
}
