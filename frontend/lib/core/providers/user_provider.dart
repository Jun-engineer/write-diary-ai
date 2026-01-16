import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

/// User profile provider - cached and shared across the app
final userProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getUserProfile();
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
