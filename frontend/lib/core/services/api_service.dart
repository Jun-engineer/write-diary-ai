import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_config.dart';
import '../../features/auth/data/auth_provider.dart';

/// Provider for API service
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref);
});

/// API Service for communicating with the backend
class ApiService {
  final Ref _ref;
  late final Dio _dio;

  ApiService(this._ref) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Get token from auth provider
        final token = await _ref.read(authProvider.notifier).getIdToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // Handle 401 errors - sign out user
        if (error.response?.statusCode == 401) {
          _ref.read(authProvider.notifier).signOut();
        }
        return handler.next(error);
      },
    ));
  }

  // ==================== Diary APIs ====================

  /// Create a new diary entry
  Future<Map<String, dynamic>> createDiary({
    required String date,
    required String originalText,
    required String inputType,
    String? imageBase64,
  }) async {
    final response = await _dio.post('/diaries', data: {
      'date': date,
      'originalText': originalText,
      'inputType': inputType,
      if (imageBase64 != null) 'imageBase64': imageBase64,
    });
    return response.data;
  }

  /// Get list of diaries
  Future<List<Map<String, dynamic>>> getDiaries({
    String? startDate,
    String? endDate,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
    };
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;

    final response = await _dio.get('/diaries', queryParameters: queryParams);
    final diaries = response.data['diaries'] as List<dynamic>;
    return diaries.cast<Map<String, dynamic>>();
  }

  /// Get a single diary by ID
  Future<Map<String, dynamic>> getDiary(String diaryId) async {
    final response = await _dio.get('/diaries/$diaryId');
    return response.data;
  }

  /// Update a diary
  Future<Map<String, dynamic>> updateDiary({
    required String diaryId,
    required String originalText,
  }) async {
    final response = await _dio.put('/diaries/$diaryId', data: {
      'originalText': originalText,
    });
    return response.data;
  }

  /// Delete a diary
  Future<void> deleteDiary(String diaryId) async {
    await _dio.delete('/diaries/$diaryId');
  }

  /// Request AI correction for a diary
  Future<Map<String, dynamic>> correctDiary({
    required String diaryId,
    required String mode, // 'beginner', 'intermediate', 'advanced'
  }) async {
    final response = await _dio.post('/diaries/$diaryId/correct', data: {
      'mode': mode,
    });
    return response.data;
  }

  /// Scan handwritten text using Claude Vision
  Future<String> scanImage(String imageBase64) async {
    final response = await _dio.post('/scan', data: {
      'imageBase64': imageBase64,
    });
    return response.data['text'] ?? '';
  }

  // ==================== Review Card APIs ====================

  /// Create review cards from selected corrections
  Future<Map<String, dynamic>> createReviewCardsFromSelection({
    required String diaryId,
    required List<int> selectedIndices,
  }) async {
    final response = await _dio.post('/review-cards', data: {
      'diaryId': diaryId,
      'selectedCorrections': selectedIndices,
    });
    return response.data;
  }

  /// Get all review cards
  Future<List<Map<String, dynamic>>> getReviewCards({
    bool? dueOnly,
    int limit = 100,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
    };
    if (dueOnly == true) queryParams['dueOnly'] = 'true';

    final response = await _dio.get('/review-cards', queryParameters: queryParams);
    final cards = response.data['cards'] as List<dynamic>;
    return cards.cast<Map<String, dynamic>>();
  }

  /// Delete a review card
  Future<void> deleteReviewCard(String cardId) async {
    await _dio.delete('/review-cards/$cardId');
  }

  // ==================== Usage APIs ====================

  /// Get today's scan usage
  Future<Map<String, dynamic>> getScanUsage() async {
    final response = await _dio.get('/scan-usage/today');
    return response.data;
  }

  // ==================== User APIs ====================

  /// Get current user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    final response = await _dio.get('/users/me');
    return response.data;
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateUserProfile({
    required String displayName,
  }) async {
    final response = await _dio.put('/users/me', data: {
      'displayName': displayName,
    });
    return response.data;
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    await _dio.delete('/users/me');
  }
}
