import 'dart:io';
import 'package:flutter/foundation.dart';

import '../services/suggestion_api_service.dart';
import '../utils/app_logger.dart';

// SMS reading is Android-only.
// On iOS, users set up an iOS Shortcut that POSTs messages to the backend.
// This service guards all calls with Platform.isAndroid.

class SmsService {
  static const _tag = 'SmsService';

  // Keywords that suggest a message is from a bank or payment service
  static const _financialKeywords = [
    'debit', 'credit', 'payment', 'transaction', 'transfer',
    'balance', 'deposited', 'withdrawn', 'charged', 'received',
    'bank', 'atm', 'upi', 'neft', 'rtgs',
  ];

  /// Reads recent SMS messages on Android and submits financial ones to the backend.
  /// Does nothing on iOS or web.
  static Future<void> processPendingSms() async {
    if (!Platform.isAndroid) {
      AppLogger.d(_tag, 'processPendingSms: skipped (not Android)');
      return;
    }

    AppLogger.i(_tag, 'processPendingSms: starting');

    // Dynamic import guard — telephony package only on Android
    try {
      await _readAndSubmitSms();
    } catch (e, st) {
      AppLogger.e(_tag, 'processPendingSms error', e, st);
    }
  }

  static Future<void> _readAndSubmitSms() async {
    // We use a platform channel approach via the telephony package.
    // The telephony package reads from the SMS content provider.
    // Requires READ_SMS permission granted before calling this.

    // Use dynamic invocation to avoid import errors on iOS/web builds.
    // ignore: avoid_dynamic_calls
    final dynamic telephony = _TelephonyBridge.instance;
    if (telephony == null) {
      AppLogger.w(_tag, 'Telephony not available');
      return;
    }

    final messages = await telephony.getInboxSms(
      columns: ['address', 'body', 'date'],
      filter: SmsFilter.where(SmsColumn.DATE).greaterThanOrEqualTo(
        DateTime.now().subtract(const Duration(hours: 48)).millisecondsSinceEpoch.toString(),
      ),
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    AppLogger.i(_tag, '_readAndSubmitSms: ${messages?.length ?? 0} SMS in last 48h');

    int submitted = 0;
    for (final msg in messages ?? <dynamic>[]) {
      final body = msg.body as String? ?? '';
      if (_isFinancial(body)) {
        AppLogger.d(_tag, 'Financial SMS found from ${msg.address}');
        await SuggestionApiService.submitSmsText(body);
        submitted++;
      }
    }

    AppLogger.i(_tag, '_readAndSubmitSms: submitted $submitted financial SMS');
  }

  static bool _isFinancial(String body) {
    final lower = body.toLowerCase();
    return _financialKeywords.any((kw) => lower.contains(kw));
  }
}

// ── Telephony bridge (lazy import guard) ────────────────────────────────────

class _TelephonyBridge {
  static dynamic get instance {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        // This is compiled away on non-Android targets via tree shaking.
        return _getTelephony();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static dynamic _getTelephony() {
    // Returning null here so callers that don't have the package get null
    // rather than a compile error. The real implementation replaces this
    // when the telephony package is added and imported directly.
    return null;
  }
}

// Stub classes so the file compiles even without the telephony package imported.
// When telephony is imported, these are replaced by the real implementation.
class SmsFilter {
  static _FilterBuilder where(SmsColumn column) => _FilterBuilder(column);
}

class _FilterBuilder {
  final SmsColumn column;
  _FilterBuilder(this.column);
  _FilterBuilder greaterThanOrEqualTo(String value) => this;
}

enum SmsColumn { DATE, ADDRESS, BODY }

class OrderBy {
  final SmsColumn column;
  final Sort sort;
  const OrderBy(this.column, {required this.sort});
}

enum Sort { ASC, DESC }
