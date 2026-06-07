import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../utils/app_logger.dart';

/// Handles registration and login against the Spring Boot backend.
/// On success the JWT is persisted to secure storage and the user
/// profile is cached in Hive for offline access.
class AuthApiService {
  static const _tag = 'AuthApiService';

  // ── Login ─────────────────────────────────────────────────────────────────

  /// Returns the user's first name on success so the UI can greet them.
  /// Throws [ApiException] on network or auth failure.
  static Future<String> login({
    required String username,
    required String password,
  }) async {
    AppLogger.i(_tag, 'Attempting login for username: $username');

    try {
      final response = await ApiService.dio.post(
        '/api/auth/login',
        data: {'username': username.trim(), 'password': password},
      );

      final accessToken = response.data['accessToken'] as String;
      final refreshToken = response.data['refreshToken'] as String? ?? '';

      AppLogger.i(_tag, 'Login successful — storing JWT');
      await ApiService.saveToken(accessToken);

      // Fetch the profile so we have a real UserModel in Hive
      final firstName = await _fetchAndCacheProfile(username: username);
      AppLogger.i(_tag, 'Profile cached for: $username');
      return firstName;
    } on DioException catch (e, st) {
      AppLogger.e(_tag, 'Login DioException', e, st);
      throw ApiException.fromDio(e);
    } catch (e, st) {
      AppLogger.e(_tag, 'Login unexpected error', e, st);
      throw ApiException('Login failed: $e');
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────

  static Future<void> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? city,
    String? country,
    String? continent,
  }) async {
    AppLogger.i(_tag, 'Registering new user: $username');

    try {
      final response = await ApiService.dio.post(
        '/api/auth/register',
        data: {
          'username': username.trim(),
          'email': email.trim(),
          'password': password,
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
          if (city != null && city.isNotEmpty) 'city': city.trim(),
          if (country != null && country.isNotEmpty) 'country': country.trim(),
          if (continent != null && continent.isNotEmpty) 'continent': continent.trim(),
        },
      );

      final accessToken = response.data['accessToken'] as String;
      AppLogger.i(_tag, 'Registration successful — storing JWT');
      await ApiService.saveToken(accessToken);

      // Cache a minimal UserModel so the app works immediately offline
      final user = UserModel(
        id: username, // temporary until we fetch the real UUID profile
        username: username,
        email: email,
        password: '',
        role: 'USER',
        firstName: firstName,
        lastName: lastName,
        city: city,
        country: country,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await DatabaseService.saveUser(user);
      AppLogger.i(_tag, 'User cached locally after registration');
    } on DioException catch (e, st) {
      AppLogger.e(_tag, 'Register DioException', e, st);
      throw ApiException.fromDio(e);
    } catch (e, st) {
      AppLogger.e(_tag, 'Register unexpected error', e, st);
      throw ApiException('Registration failed: $e');
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  static Future<void> logout() async {
    AppLogger.i(_tag, 'Logging out — clearing JWT and local user');
    await ApiService.clearToken();
    await DatabaseService.clearUser();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Calls GET /api/me to get the full profile and caches it in Hive.
  /// Returns the user's first name.
  static Future<String> _fetchAndCacheProfile({required String username}) async {
    AppLogger.d(_tag, 'Fetching profile for: $username');
    try {
      final response = await ApiService.dio.get('/api/me');
      final data = response.data as Map<String, dynamic>;

      final user = UserModel(
        id: data['id']?.toString() ?? username,
        username: data['username'] as String? ?? username,
        email: data['email'] as String? ?? '',
        password: '',
        role: 'USER',
        firstName: data['firstName'] as String? ?? '',
        lastName: data['lastName'] as String? ?? '',
        city: data['city'] as String?,
        country: data['country'] as String?,
        continent: data['continent'] as String?,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await DatabaseService.saveUser(user);
      AppLogger.d(_tag, 'Profile saved — firstName: ${user.firstName}');
      return user.firstName;
    } on DioException catch (e, st) {
      AppLogger.w(_tag, 'Could not fetch profile (non-fatal): ${e.message}');
      // Return empty string — the dashboard will still show whatever is in Hive
      return '';
    }
  }
}
