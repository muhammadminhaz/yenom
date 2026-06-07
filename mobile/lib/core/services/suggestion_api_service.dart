import 'package:dio/dio.dart';

import '../models/suggestion_model.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../utils/app_logger.dart';

class SuggestionApiService {
  static const _tag = 'SuggestionApiService';

  /// Fetches PENDING suggestions from the backend and caches them in Hive.
  /// Returns the list of pending suggestions.
  static Future<List<SuggestionModel>> fetchPendingSuggestions({int page = 0, int size = 20}) async {
    AppLogger.i(_tag, 'fetchPendingSuggestions: page=$page size=$size');

    try {
      final response = await ApiService.dio.get(
        '/api/suggestions',
        queryParameters: {'page': page, 'size': size},
      );

      final List<dynamic> data = response.data as List<dynamic>;
      final suggestions = data
          .map((e) => SuggestionModel.fromJson(e as Map<String, dynamic>))
          .toList();

      AppLogger.i(_tag, 'Fetched ${suggestions.length} suggestions');

      // Merge into Hive (avoid duplicates — use id as key)
      for (final s in suggestions) {
        await DatabaseService.saveSuggestion(s);
      }

      return DatabaseService.getPendingSuggestions();
    } on DioException catch (e, st) {
      final msg = ApiException.fromDio(e).message;
      AppLogger.e(_tag, 'fetchPendingSuggestions failed: $msg', e, st);
      // Return cached suggestions so the UI still works offline
      return DatabaseService.getPendingSuggestions();
    } catch (e, st) {
      AppLogger.e(_tag, 'fetchPendingSuggestions unexpected error', e, st);
      return DatabaseService.getPendingSuggestions();
    }
  }

  /// Accepts a suggestion on the backend and removes it from local cache.
  static Future<void> acceptSuggestion(String id) async {
    AppLogger.i(_tag, 'acceptSuggestion: $id');
    try {
      await ApiService.dio.patch('/api/suggestions/$id/accept');
      await DatabaseService.removeSuggestion(id);
      AppLogger.d(_tag, 'Suggestion accepted and removed from cache: $id');
    } on DioException catch (e, st) {
      AppLogger.e(_tag, 'acceptSuggestion failed: $id', e, st);
      rethrow;
    }
  }

  /// Rejects a suggestion on the backend and removes it from local cache.
  static Future<void> rejectSuggestion(String id) async {
    AppLogger.i(_tag, 'rejectSuggestion: $id');
    try {
      await ApiService.dio.patch('/api/suggestions/$id/reject');
      await DatabaseService.removeSuggestion(id);
      AppLogger.d(_tag, 'Suggestion rejected and removed from cache: $id');
    } on DioException catch (e, st) {
      AppLogger.e(_tag, 'rejectSuggestion failed: $id', e, st);
      rethrow;
    }
  }

  /// Sends raw SMS text to the backend for AI parsing.
  static Future<void> submitSmsText(String text) async {
    AppLogger.i(_tag, 'submitSmsText: length=${text.length}');
    try {
      await ApiService.dio.post('/api/suggestions/sms', data: {'text': text});
      AppLogger.d(_tag, 'SMS submitted for parsing');
    } on DioException catch (e, st) {
      final msg = ApiException.fromDio(e).message;
      AppLogger.e(_tag, 'submitSmsText failed: $msg', e, st);
      // Non-fatal: log and continue
    }
  }

  /// Fetches the Gmail connection status.
  static Future<bool> getGmailStatus() async {
    try {
      final response = await ApiService.dio.get('/api/gmail/status');
      return response.data['connected'] as bool? ?? false;
    } catch (e) {
      AppLogger.w(_tag, 'getGmailStatus error: $e');
      return false;
    }
  }

  /// Gets the Google OAuth2 authorization URL from the backend.
  static Future<String> getGmailAuthUrl() async {
    final response = await ApiService.dio.get('/api/gmail/auth-url');
    return response.data['url'] as String;
  }

  /// Triggers a Gmail inbox sync on the backend.
  static Future<int> triggerGmailSync() async {
    final response = await ApiService.dio.post('/api/gmail/sync');
    return response.data['messagesQueued'] as int? ?? 0;
  }

  /// Disconnects Gmail from the backend.
  static Future<void> disconnectGmail() async {
    await ApiService.dio.post('/api/gmail/disconnect');
    AppLogger.i(_tag, 'Gmail disconnected');
  }
}
