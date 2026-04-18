import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'locale_provider.dart';

/// User profile provider - cached and shared across the app
final userProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final profile = await apiService.getUserProfile();
  
  // Check if there are onboarding language selections to sync
  final onboardingTarget = await LocaleNotifier.getOnboardingTargetLanguage();
  final onboardingNative = await LocaleNotifier.getOnboardingNativeLanguage();
  if (onboardingTarget != null && onboardingNative != null) {
    try {
      await apiService.updateUserProfile(
        targetLanguage: onboardingTarget,
        nativeLanguage: onboardingNative,
      );
      await LocaleNotifier.clearOnboardingLanguages();
      // Re-fetch updated profile
      final updatedProfile = await apiService.getUserProfile();
      return updatedProfile;
    } catch (_) {
      // If sync fails, continue with existing profile
    }
  }

  // Sync app locale with user's native language when profile is loaded
  final nativeLanguage = profile['nativeLanguage'] as String? ?? 'japanese';
  final currentLocale = ref.read(localeProvider);
  final targetLocale = AppLocale.fromCode(nativeLanguage);
  
  if (currentLocale != targetLocale) {
    Future.microtask(() {
      ref.read(localeProvider.notifier).setLocale(targetLocale);
    });
  }
  
  return profile;
});

/// Check if user is premium
final isPremiumProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(userProvider);
  return userAsync.whenOrNull(
    data: (user) => user['plan'] == 'premium',
  ) ?? false;
});

/// Get user's plan
final userPlanProvider = Provider<String>((ref) {
  final userAsync = ref.watch(userProvider);
  return userAsync.whenOrNull(
    data: (user) => user['plan'] as String? ?? 'free',
  ) ?? 'free';
});

/// Get user's target language (the language they are learning)
final targetLanguageProvider = Provider<String>((ref) {
  final userAsync = ref.watch(userProvider);
  return userAsync.whenOrNull(
    data: (user) => user['targetLanguage'] as String? ?? 'english',
  ) ?? 'english';
});

/// Get user's native language (for explanations)
final nativeLanguageProvider = Provider<String>((ref) {
  final userAsync = ref.watch(userProvider);
  return userAsync.whenOrNull(
    data: (user) => user['nativeLanguage'] as String? ?? 'japanese',
  ) ?? 'japanese';
});
