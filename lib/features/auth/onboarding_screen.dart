import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/user_preference.dart';
import '../../core/providers/auth_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _selectedRole = 'learner';
  String _selectedLanguage = 'my';
  final _teachSkillsController = TextEditingController();
  final _learnSkillsController = TextEditingController();
  bool _isSaving = false;

  void _handleSave() async {
    setState(() => _isSaving = true);
    try {
      final teachSkills = _teachSkillsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final learnSkills = _learnSkillsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      final pref = UserPreference(
        userId: '', // Server handles this
        role: _selectedRole,
        teachSkills: teachSkills,
        learnSkills: learnSkills,
        preferredLanguage: _selectedLanguage,
        updatedAt: DateTime.now(),
      );

      await context.read<AuthProvider>().savePreference(pref);
      // AuthWrapper will handle the logic of where to go next based on the new role
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save preferences: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tell us about you'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Customize your experience',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text('What is your primary role?', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              items: const [
                DropdownMenuItem(value: 'learner', child: Text('Learner')),
                DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                DropdownMenuItem(value: 'both', child: Text('Both')),
              ],
              onChanged: (v) => setState(() => _selectedRole = v!),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            const Text('Preferred Language', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Myanmar'),
                    value: 'my',
                    groupValue: _selectedLanguage,
                    onChanged: (v) => setState(() => _selectedLanguage = v!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('English'),
                    value: 'en',
                    groupValue: _selectedLanguage,
                    onChanged: (v) => setState(() => _selectedLanguage = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Skills you want to learn (comma separated)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _learnSkillsController,
              decoration: const InputDecoration(
                hintText: 'Flutter, Networking, Piano...',
                border: OutlineInputBorder(),
              ),
            ),
            if (_selectedRole != 'learner') ...[
              const SizedBox(height: 24),
              const Text('Skills you can teach (comma separated)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _teachSkillsController,
                decoration: const InputDecoration(
                  hintText: 'Math, Guitar, Cooking...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('SAVE AND CONTINUE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
