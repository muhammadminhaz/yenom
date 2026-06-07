import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/suggestion_model.dart';
import '../services/database_service.dart';
import '../services/suggestion_api_service.dart';
import '../utils/app_logger.dart';

class SuggestionNotifier extends StateNotifier<AsyncValue<List<SuggestionModel>>> {
  static const _tag = 'SuggestionNotifier';

  SuggestionNotifier() : super(const AsyncValue.loading()) {
    _loadFromCache();
  }

  void _loadFromCache() {
    final cached = DatabaseService.getPendingSuggestions();
    AppLogger.d(_tag, 'Loaded ${cached.length} suggestions from cache');
    state = AsyncValue.data(cached);
  }

  Future<void> refresh() async {
    AppLogger.i(_tag, 'refresh: fetching from API');
    try {
      final suggestions = await SuggestionApiService.fetchPendingSuggestions();
      state = AsyncValue.data(suggestions);
      AppLogger.i(_tag, 'refresh: ${suggestions.length} suggestions');
    } catch (e, st) {
      AppLogger.e(_tag, 'refresh error', e, st);
      // Keep previous data on error, don't overwrite with error state
      final cached = DatabaseService.getPendingSuggestions();
      state = AsyncValue.data(cached);
    }
  }

  Future<void> accept(SuggestionModel suggestion) async {
    AppLogger.i(_tag, 'accept: ${suggestion.id}');
    try {
      await SuggestionApiService.acceptSuggestion(suggestion.id);
      _removeLocally(suggestion.id);
      AppLogger.d(_tag, 'accepted and removed: ${suggestion.id}');
    } catch (e, st) {
      AppLogger.e(_tag, 'accept error: ${suggestion.id}', e, st);
      rethrow;
    }
  }

  Future<void> reject(SuggestionModel suggestion) async {
    AppLogger.i(_tag, 'reject: ${suggestion.id}');
    try {
      await SuggestionApiService.rejectSuggestion(suggestion.id);
      _removeLocally(suggestion.id);
      AppLogger.d(_tag, 'rejected and removed: ${suggestion.id}');
    } catch (e, st) {
      AppLogger.e(_tag, 'reject error: ${suggestion.id}', e, st);
      rethrow;
    }
  }

  void _removeLocally(String id) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((s) => s.id != id).toList());
  }

  int get pendingCount => state.valueOrNull?.length ?? 0;
  bool get hasHaram => state.valueOrNull?.any((s) => s.isHaram) ?? false;
}

final suggestionProvider =
    StateNotifierProvider<SuggestionNotifier, AsyncValue<List<SuggestionModel>>>(
  (_) => SuggestionNotifier(),
);
