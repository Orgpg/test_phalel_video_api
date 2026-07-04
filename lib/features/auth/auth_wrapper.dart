import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.state == AuthState.loading || auth.state == AuthState.initial) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_filled, size: 100, color: Colors.deepPurple),
                  SizedBox(height: 24),
                  CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }

        if (auth.state == AuthState.unauthenticated) {
          return const LoginScreen();
        }

        if (auth.isAuthenticated) {
          final user = auth.user!;
          
          // 1. Check Preferences (Onboarding)
          if (user.preference == null) {
            return const OnboardingScreen();
          }

          // 2. Check Verification
          // If no verification submitted or if it's rejected, show verification screen
          // In a real app, maybe you allow Home access but with restricted features.
          // The prompt says: "If verification is null or rejected show verification form -> Submit verification -> Home/Profile"
          if (user.verification == null || user.verification!.status == 'REJECTED') {
            return const ProfileScreen();
          }

          // 3. Authenticated, Onboarded, and Verified (or Pending)
          return const HomeScreen();
        }

        // Error state
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${auth.errorMessage}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => auth.initialize(),
                  child: const Text('Retry'),
                ),
                TextButton(
                  onPressed: () => auth.logout(),
                  child: const Text('Go to Login'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
