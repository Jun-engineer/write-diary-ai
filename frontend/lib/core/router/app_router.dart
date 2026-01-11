import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/diary/presentation/screens/diary_list_screen.dart';
import '../../features/diary/presentation/screens/diary_editor_screen.dart';
import '../../features/diary/presentation/screens/diary_detail_screen.dart';
import '../../features/diary/presentation/screens/camera_screen.dart';
import '../../features/review/presentation/screens/review_list_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/diaries',
    debugLogDiagnostics: true,
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      
      // Main App with Bottom Navigation
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          // Diary Tab
          GoRoute(
            path: '/diaries',
            name: 'diaries',
            builder: (context, state) => const DiaryListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'diary-new',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  final scannedText = extra?['scannedText'] as String?;
                  return DiaryEditorScreen(initialText: scannedText);
                },
              ),
              GoRoute(
                path: 'camera',
                name: 'diary-camera',
                builder: (context, state) => const CameraScreen(),
              ),
              GoRoute(
                path: ':diaryId',
                name: 'diary-detail',
                builder: (context, state) => DiaryDetailScreen(
                  diaryId: state.pathParameters['diaryId']!,
                ),
              ),
            ],
          ),
          
          // Review Tab
          GoRoute(
            path: '/review',
            name: 'review',
            builder: (context, state) => const ReviewListScreen(),
          ),
          
          // Settings Tab
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    // Redirect to login if not authenticated
    // redirect: (context, state) {
    //   final isAuthenticated = ref.read(authStateProvider);
    //   final isLoggingIn = state.matchedLocation == '/login' || 
    //                       state.matchedLocation == '/signup';
    //   
    //   if (!isAuthenticated && !isLoggingIn) {
    //     return '/login';
    //   }
    //   if (isAuthenticated && isLoggingIn) {
    //     return '/diaries';
    //   }
    //   return null;
    // },
  );
});
