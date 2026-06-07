import 'package:flutter/foundation.dart';

enum _Level { debug, info, warn, error }

class AppLogger {
  static void _log(_Level level, String tag, String message, [Object? error, StackTrace? stack]) {
    if (!kDebugMode && level == _Level.debug) return;
    final prefix = switch (level) {
      _Level.debug => '🔍 DEBUG',
      _Level.info  => 'ℹ️  INFO ',
      _Level.warn  => '⚠️  WARN ',
      _Level.error => '🔴 ERROR',
    };
    debugPrint('$prefix [$tag] $message');
    if (error != null) debugPrint('       ↳ $error');
    if (stack != null && level == _Level.error) debugPrintStack(stackTrace: stack, maxFrames: 8);
  }

  static void d(String tag, String message) => _log(_Level.debug, tag, message);
  static void i(String tag, String message) => _log(_Level.info,  tag, message);
  static void w(String tag, String message) => _log(_Level.warn,  tag, message);
  static void e(String tag, String message, [Object? error, StackTrace? stack]) =>
      _log(_Level.error, tag, message, error, stack);
}
