import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/models/video_model.dart';
import 'core/network/dio_client.dart';
import 'core/providers/auth_provider.dart';
import 'core/repositories/auth_repository.dart';
import 'core/repositories/preference_repository.dart';
import 'core/repositories/verification_repository.dart';
import 'core/repositories/video_repository.dart';
import 'features/auth/auth_wrapper.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/auth/onboarding_screen.dart';
import 'features/home/folder_videos_screen.dart';
import 'features/home/home_screen.dart';
import 'features/home/video_provider.dart';
import 'features/profile/profile_screen.dart';
import 'features/upload/upload_video_screen.dart';
import 'features/video_player/video_player_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env file
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Error loading .env file: $e");
  }

  final dioClient = DioClient();
  final authRepository = AuthRepository(dioClient);
  final preferenceRepository = PreferenceRepository(dioClient);
  final verificationRepository = VerificationRepository(dioClient);
  final videoRepository = VideoRepository(dioClient);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: dioClient),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authRepository,
            preferenceRepository,
            verificationRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => VideoProvider(videoRepository),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

final GoRouter _router = GoRouter(
  initialLocation: '/auth',
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthWrapper(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/player',
      builder: (context, state) {
        final video = state.extra as VideoModel;
        return VideoPlayerScreen(video: video);
      },
    ),
    GoRoute(
      path: '/upload',
      builder: (context, state) => const UploadVideoScreen(),
    ),
    GoRoute(
      path: '/folder-videos',
      builder: (context, state) {
        final folderName = state.extra as String;
        return FolderVideosScreen(folderName: folderName);
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PhaLel Video Test',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      themeMode: ThemeMode.system,
    );
  }
}
