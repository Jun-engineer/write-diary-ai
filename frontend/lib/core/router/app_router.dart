import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/confirm_signup_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/diary/presentation/screens/diary_list_screen.dart';
import '../../features/diary/presentation/screens/diary_editor_screen.dart';
import '../../features/diary/presentation/screens/diary_detail_screen.dart';
import '../../features/diary/presentation/screens/diary_edit_screen.dart';
import '../../features/diary/presentation/screens/camera_screen.dart';
import '../../features/review/presentation/screens/review_list_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/onboarding/presentation/screens/language_selection_screen.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../providers/locale_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final languageSelected = ref.watch(languageSelectedProvider);

  return GoRouter(
    initialLocation: '/language-selection',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: _RouterRefreshStream(ref),
    routes: [
      // Language Selection (first launch)
      GoRoute(
        path: '/language-selection',
        name: 'language-selection',
        builder: (context, state) => const LanguageSelectionScreen(),
      ),
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
      GoRoute(
        path: '/confirm-signup',
        name: 'confirm-signup',
        builder: (context, state) {
          final email = state.extra as String?;
          return ConfirmSignUpScreen(email: email);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
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
                  final inputType = extra?['inputType'] as String? ?? 'manual';
                  return DiaryEditorScreen(
                    initialText: scannedText,
                    inputType: inputType,
                  );
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
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'diary-edit',
                    builder: (context, state) {
                      final diary = state.extra as Map<String, dynamic>?;
                      return DiaryEditScreen(
                        diaryId: state.pathParameters['diaryId']!,
                        diary: diary,
                      );
                    },
                  ),
                ],
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
    // Redirect based on authentication state
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.status == AuthStatus.initial || 
                        authState.status == AuthStatus.loading;
      final needsConfirmation = authState.status == AuthStatus.confirmSignUp;
      final signUpComplete = authState.status == AuthStatus.signUpComplete;
      
      final currentPath = state.matchedLocation;
      final isAuthRoute = currentPath == '/login' || 
                         currentPath == '/signup' ||
                         currentPath == '/confirm-signup';
      final isLanguageRoute = currentPath == '/language-selection';

      // If language not yet selected, stay on language selection
      if (!languageSelected && !isLanguageRoute) {
        return '/language-selection';
      }

      // If language already selected and on language route, go to login
      if (languageSelected && isLanguageRoute) {
        return '/login';
      }

      // Don't redirect while loading
      if (isLoading) {
        return null;
      }

      // If signup just completed, go to login (LoginScreen will show success message)
      if (signUpComplete) {
        return '/login';
      }

      // If needs confirmation, go to confirm signup
      if (needsConfirmation && currentPath != '/confirm-signup') {
        return '/confirm-signup';
      }

      // If not authenticated and not on auth route, redirect to login
      if (!isAuthenticated && !isAuthRoute && !isLanguageRoute) {
        return '/login';
      }

      // If authenticated and on auth route, redirect to diaries
      if (isAuthenticated && isAuthRoute) {
        return '/diaries';
      }

      return null;
    },
  );
});

/// A ChangeNotifier that listens to auth state changes and triggers router refresh
class _RouterRefreshStream extends ChangeNotifier {
  _RouterRefreshStream(this._ref) {
    _ref.listen(authProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref _ref;
}
