import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/app_logger.dart';

/// Central HTTP client. Reads the stored JWT on every request and injects it
/// as a Bearer token. All network errors are caught and re-thrown as
/// [ApiException] with a human-readable message.
class ApiService {
  static const _tag = 'ApiService';
  static const _jwtKey = 'jwt_access_token';

  // Android emulator → 10.0.2.2 maps to host machine localhost.
  // iOS simulator  → localhost works directly.
  // Real device    → replace with your machine's LAN IP while developing.
  static String get baseUrl =>
      Platform.isAndroid ? 'http://10.0.2.2:8080' : 'http://localhost:8080';

  static final _storage = const FlutterSecureStorage();
  static Dio? _dio;

  static Dio get dio {
    _dio ??= _build();
    return _dio!;
  }

  static Dio _build() {
    AppLogger.i(_tag, 'Building Dio client — baseUrl: $baseUrl');
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Inject JWT on every request
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _jwtKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            AppLogger.d(_tag, 'JWT injected for ${options.method} ${options.path}');
          } else {
            AppLogger.w(_tag, 'No JWT found for ${options.method} ${options.path}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.d(_tag,
              '✓ ${response.requestOptions.method} ${response.requestOptions.path} → ${response.statusCode}');
          handler.next(response);
        },
        onError: (DioException e, handler) {
          AppLogger.e(_tag,
              '✗ ${e.requestOptions.method} ${e.requestOptions.path} → ${e.type}',
              e, e.stackTrace);
          handler.next(e);
        },
      ),
    );

    return dio;
  }

  // ── Token helpers ─────────────────────────────────────────────────────────

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _jwtKey, value: token);
    AppLogger.i(_tag, 'JWT saved to secure storage');
  }

  static Future<String?> getToken() async {
    final token = await _storage.read(key: _jwtKey);
    AppLogger.d(_tag, 'getToken: ${token != null ? 'found' : 'null'}');
    return token;
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _jwtKey);
    AppLogger.i(_tag, 'JWT cleared from secure storage');
  }

  static Future<bool> hasToken() async {
    final token = await _storage.read(key: _jwtKey);
    return token != null && token.isNotEmpty;
  }
}

/// Structured error thrown by all API service calls.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  factory ApiException.fromDio(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const ApiException('Connection timed out. Check your network.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return const ApiException('Could not reach server. Working offline.');
    }
    final statusCode = e.response?.statusCode;
    final serverMsg = e.response?.data is Map
        ? (e.response!.data['message'] as String? ?? e.message)
        : e.message;
    return ApiException(serverMsg ?? 'Unknown error', statusCode: statusCode);
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
