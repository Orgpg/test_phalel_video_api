import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/models/video_model.dart';
import 'core/network/dio_client.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/booking_provider.dart';
import 'core/providers/mentor_provider.dart';
import 'core/providers/wallet_provider.dart';
import 'core/services/auth_service.dart';
import 'core/services/booking_service.dart';
import 'core/services/mentor_service.dart';
import 'core/services/preference_service.dart';
import 'core/services/verification_service.dart';
import 'core/services/video_service.dart';
import 'core/services/wallet_service.dart';
import 'features/auth/auth_wrapper.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/auth/onboarding_screen.dart';
import 'features/bookings/my_bookings_screen.dart';
import 'features/home/folder_videos_screen.dart';
import 'features/home/home_screen.dart';
import 'features/home/video_provider.dart';
import 'features/mentors/mentor_detail_screen.dart';
import 'features/mentors/mentor_list_screen.dart';
import 'features/mentors/mentor_management_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/upload/upload_video_screen.dart';
import 'features/video_player/video_player_screen.dart';
import 'features/wallet/wallet_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Error loading .env file: $e");
  }

  late final DioClient dioClient;
  dioClient = DioClient(onUnauthorized: () {
    // If a 401 occurs, we should force a logout and redirect to login
    // However, since we're using GoRouter, we can't easily use navigatorKey.currentState
    // without some configuration. 
    // For now, the most reliable way is to let AuthProvider handle it
    // by catching the error in the service call.
  });

  final authService = AuthService(dioClient);
  final preferenceService = PreferenceService(dioClient);
  final verificationService = VerificationService(dioClient);
  final videoService = VideoService(dioClient);
  final mentorService = MentorService(dioClient);
  final bookingService = BookingService(dioClient);
  final walletService = WalletService(dioClient);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: dioClient),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authService,
            preferenceService,
            verificationService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => VideoProvider(videoService),
        ),
        ChangeNotifierProvider(
          create: (_) => MentorProvider(mentorService),
        ),
        ChangeNotifierProvider(
          create: (_) => BookingProvider(bookingService),
        ),
        ChangeNotifierProvider(
          create: (_) => WalletProvider(walletService),
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
    GoRoute(
      path: '/wallet',
      builder: (context, state) => const WalletScreen(),
    ),
    GoRoute(
      path: '/mentors',
      builder: (context, state) => const MentorListScreen(),
    ),
    GoRoute(
      path: '/mentor-detail',
      builder: (context, state) {
        final id = state.extra as String;
        return MentorDetailScreen(mentorId: id);
      },
    ),
    GoRoute(
      path: '/my-bookings',
      builder: (context, state) => const MyBookingsScreen(),
    ),
    GoRoute(
      path: '/mentor-management',
      builder: (context, state) => const MentorManagementScreen(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PhaLel Video',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
    );
  }
}
