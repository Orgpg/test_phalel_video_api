import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import 'email_verification_screen.dart';
import 'forgot_password_confirm_screen.dart';
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

        if (auth.state == AuthState.signupVerificationRequired) {
          return const EmailVerificationScreen();
        }

        if (auth.state == AuthState.forgotPasswordCodeRequired) {
          return const ForgotPasswordConfirmScreen();
        }

        if (auth.isAuthenticated) {
          final user = auth.user!;
          
          // 1. Check Preferences (Role & Skills)
          if (user.preference == null) {
            return const OnboardingScreen();
          }

          final role = user.preference!.role.toUpperCase();

          // 2. If LEARNER, skip KYC and go to main app
          if (role == 'LEARNER') {
            return const HomeScreen();
          }

          // 3. If TEACHER or BOTH, handle Verification logic
          if (role == 'TEACHER' || role == 'BOTH') {
            if (user.verification == null) {
              // Show KYC verification form (located in ProfileScreen for this app structure)
              return const ProfileScreen();
            }

            final vStatus = user.verification!.status.toUpperCase();

            if (vStatus == 'PENDING') {
              // Show waiting-for-review screen
              return _buildWaitingScreen(context, auth);
            }

            if (vStatus == 'REJECTED') {
              // Show rejected state (handled inline in ProfileScreen)
              return const ProfileScreen();
            }

            if (vStatus == 'VERIFIED') {
              return const HomeScreen();
            }
          }

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

  Widget _buildWaitingScreen(BuildContext context, AuthProvider auth) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review in Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_bottom, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              const Text(
                'Waiting for Review',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Our team is currently reviewing your verification documents. This usually takes 24-48 hours.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => auth.refreshUser(),
                icon: const Icon(Icons.refresh),
                label: const Text('Check Status'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => auth.logout(),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
