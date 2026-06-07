import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';
import '../models/transaction_enums.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../utils/app_logger.dart';

class SyncService {
  static const _tag = 'SyncService';
  static const _lastSyncKey = 'last_sync_time';
  static const _storage = FlutterSecureStorage();
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  // ── Sync to cloud ──────────────────────────────────────────────────────────

  /// Uploads every local transaction with isSynced=false to the backend.
  /// Each successful upload is immediately marked synced in Hive.
  /// Returns a [SyncResult] with counts and any error messages.
  static Future<SyncResult> syncToCloud() async {
    AppLogger.i(_tag, 'syncToCloud: starting');

    if (!await ApiService.hasToken()) {
      AppLogger.w(_tag, 'syncToCloud: no JWT — not authenticated');
      throw const ApiException('Please log in before syncing.');
    }

    final unsynced = DatabaseService.getUnsyncedTransactions();
    AppLogger.i(_tag, 'syncToCloud: ${unsynced.length} transactions to upload');

    int uploaded = 0;
    final errors = <String>[];

    for (final tx in unsynced) {
      try {
        AppLogger.d(_tag, 'Uploading: ${tx.id} "${tx.description}"');
        await ApiService.dio.post('/api/transactions/create', data: {
          'amount': tx.amount,
          'currency': tx.currency,
          'transactionDate': _dateFormat.format(tx.transactionDate),
          'description': tx.description,
          if (tx.category != null) 'category': tx.category,
          'type': tx.type.name, // 'INCOME' | 'EXPENSE'
        });
        await DatabaseService.markAsSynced(tx.id);
        uploaded++;
        AppLogger.d(_tag, 'Uploaded ✓ ${tx.id}');
      } on DioException catch (e, st) {
        final msg = ApiException.fromDio(e).message;
        AppLogger.e(_tag, 'Upload failed for ${tx.id}: $msg', e, st);
        errors.add('"${tx.description}": $msg');
      } catch (e, st) {
        AppLogger.e(_tag, 'Unexpected error uploading ${tx.id}', e, st);
        errors.add('"${tx.description}": unexpected error');
      }
    }

    await _saveLastSyncTime();
    final result = SyncResult(uploaded: uploaded, errors: errors);
    AppLogger.i(_tag, 'syncToCloud complete — ${result.summary}');
    return result;
  }

  // ── Restore from cloud ─────────────────────────────────────────────────────

  /// Downloads ALL transactions from the backend and REPLACES local data.
  /// Intended for phone-reset / fresh-install restoration.
  /// Always shows a confirmation dialog before calling this.
  static Future<SyncResult> restoreFromCloud() async {
    AppLogger.i(_tag, 'restoreFromCloud: starting');

    if (!await ApiService.hasToken()) {
      AppLogger.w(_tag, 'restoreFromCloud: no JWT — not authenticated');
      throw const ApiException('Please log in before restoring.');
    }

    final userId = DatabaseService.getCurrentUser()?.id ?? 'restored_user';

    // Clear local transactions so we get a clean restore with no duplicates.
    AppLogger.i(_tag, 'restoreFromCloud: clearing local transaction box');
    await DatabaseService.getTransactionBox().clear();

    int downloaded = 0;
    int page = 0;
    const pageSize = 50;
    bool hasMore = true;
    final errors = <String>[];

    while (hasMore) {
      try {
        AppLogger.d(_tag, 'Fetching page $page (size $pageSize)');
        final response = await ApiService.dio.get(
          '/api/transactions',
          queryParameters: {'page': page, 'size': pageSize},
        );

        final data = response.data as Map<String, dynamic>;
        final content = data['content'] as List<dynamic>;
        final totalPages = data['totalPages'] as int? ?? 1;

        AppLogger.d(_tag, 'Page $page: ${content.length} records, totalPages=$totalPages');

        for (final item in content) {
          try {
            final tx = _txFromBackend(item, userId: userId);
            await DatabaseService.addTransaction(tx);
            downloaded++;
            AppLogger.d(_tag, 'Restored: ${tx.id} "${tx.description}"');
          } catch (e, st) {
            AppLogger.e(_tag, 'Failed to parse transaction from backend', e, st);
            errors.add('Parse error on one transaction: $e');
          }
        }

        page++;
        hasMore = page < totalPages;
      } on DioException catch (e, st) {
        final msg = ApiException.fromDio(e).message;
        AppLogger.e(_tag, 'Failed to fetch page $page: $msg', e, st);
        errors.add('Page $page: $msg');
        hasMore = false;
      } catch (e, st) {
        AppLogger.e(_tag, 'Unexpected error on page $page', e, st);
        errors.add('Page $page: unexpected error');
        hasMore = false;
      }
    }

    await _saveLastSyncTime();
    final result = SyncResult(downloaded: downloaded, errors: errors);
    AppLogger.i(_tag, 'restoreFromCloud complete — ${result.summary}');
    return result;
  }

  // ── Status helpers ─────────────────────────────────────────────────────────

  static Future<DateTime?> getLastSyncTime() async {
    final str = await _storage.read(key: _lastSyncKey);
    if (str == null) {
      AppLogger.d(_tag, 'getLastSyncTime: never synced');
      return null;
    }
    final time = DateTime.tryParse(str);
    AppLogger.d(_tag, 'getLastSyncTime: $time');
    return time;
  }

  static Future<void> _saveLastSyncTime() async {
    final now = DateTime.now().toIso8601String();
    await _storage.write(key: _lastSyncKey, value: now);
    AppLogger.d(_tag, 'Last sync time saved: $now');
  }

  // ── Mapping ────────────────────────────────────────────────────────────────

  static TransactionModel _txFromBackend(
    Map<String, dynamic> data, {
    required String userId,
  }) {
    final typeStr = data['type'] as String? ?? 'EXPENSE';
    final statusStr = data['status'] as String? ?? 'COMPLETED';
    final dateStr = data['transactionDate'] as String? ?? '';

    AppLogger.d(_tag, '_txFromBackend: id=${data['id']} type=$typeStr date=$dateStr');

    return TransactionModel(
      id: data['id'] as String,
      userId: userId,
      amount: (data['amount'] as num).toDouble(),
      currency: data['currency'] as String? ?? 'USD',
      transactionDate: DateTime.parse(dateStr),
      description: data['description'] as String? ?? '',
      category: data['category'] as String?,
      type: typeStr == 'INCOME' ? TransactionType.INCOME : TransactionType.EXPENSE,
      status: _parseStatus(statusStr),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: true, // came from backend → already persisted
    );
  }

  static TransactionStatus _parseStatus(String s) {
    return switch (s) {
      'PENDING' => TransactionStatus.PENDING,
      'CANCELLED' => TransactionStatus.CANCELLED,
      _ => TransactionStatus.COMPLETED, // COMPLETED + backend's FAILED → COMPLETED
    };
  }
}

// ── SyncResult ─────────────────────────────────────────────────────────────────

class SyncResult {
  final int uploaded;
  final int downloaded;
  final List<String> errors;

  const SyncResult({
    this.uploaded = 0,
    this.downloaded = 0,
    this.errors = const [],
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasChanges => uploaded > 0 || downloaded > 0;

  String get summary {
    final parts = <String>[];
    if (uploaded > 0) parts.add('$uploaded uploaded');
    if (downloaded > 0) parts.add('$downloaded restored');
    if (errors.isNotEmpty) parts.add('${errors.length} error(s)');
    return parts.isEmpty ? 'Already up to date' : parts.join(', ');
  }
}
