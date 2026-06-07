import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_api_service.dart';
import '../../core/services/database_service.dart';
import '../../core/utils/app_logger.dart';
import '../../widgets/neumorphic_button.dart';
import '../../widgets/neumorphic_text_field.dart';
import '../dashboard/dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _tag = 'LoginScreen';

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    AppLogger.i(_tag, 'Login attempt for username: $username');

    if (username.isEmpty || password.isEmpty) {
      AppLogger.w(_tag, 'Validation failed: empty fields');
      setState(() => _errorMessage = 'Please enter your username and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Try the real backend first
      await AuthApiService.login(username: username, password: password);
      AppLogger.i(_tag, 'Backend login succeeded');
      _navigateToDashboard();
    } on ApiException catch (e) {
      AppLogger.w(_tag, 'ApiException during login: ${e.message}');

      if (e.message.contains('offline') || e.message.contains('timed out') || e.message.contains('reach server')) {
        // Network unavailable — allow offline access if we have cached credentials
        AppLogger.i(_tag, 'Network error — checking offline fallback');
        _tryOfflineLogin(username);
      } else {
        // Auth failure (wrong password, unknown user, etc.)
        setState(() => _errorMessage = e.message);
      }
    } catch (e, st) {
      AppLogger.e(_tag, 'Unexpected login error', e, st);
      setState(() => _errorMessage = 'An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _tryOfflineLogin(String username) {
    AppLogger.i(_tag, 'Trying offline login for: $username');
    final cachedUser = DatabaseService.getCurrentUser();
    if (cachedUser != null && cachedUser.username == username) {
      AppLogger.i(_tag, 'Offline login allowed — cached user found');
      _showSnack('Working offline. Data will sync when connected.');
      _navigateToDashboard();
    } else {
      AppLogger.w(_tag, 'Offline login failed — no matching cached user');
      setState(() => _errorMessage =
          'Could not reach server and no offline data found. Please connect to the internet.');
    }
  }

  void _navigateToDashboard() {
    AppLogger.d(_tag, 'Navigating to Dashboard');
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 4)));
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spaceXL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppConstants.spaceXXL),
              _buildLogo(),
              const SizedBox(height: AppConstants.spaceXXL),
              Text('Welcome Back', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: AppConstants.spaceS),
              Text(
                'Sign in to manage your finances',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppConstants.spaceXXXL),
              NeumorphicTextField(
                controller: _usernameController,
                hintText: 'Username',
                prefixIcon: Icons.person_outline,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: AppConstants.spaceL),
              NeumorphicTextField(
                controller: _passwordController,
                hintText: 'Password',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppConstants.spaceM),
                _buildErrorBanner(_errorMessage!),
              ],
              const SizedBox(height: AppConstants.spaceXL),
              NeumorphicButton(
                isPrimary: true,
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: AppConstants.fontL,
                        ),
                      ),
              ),
              const SizedBox(height: AppConstants.spaceXXL),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium),
                  GestureDetector(
                    onTap: () {
                      AppLogger.d(_tag, 'Navigate to RegisterScreen');
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          child: const Center(
            child: Text('☽', style: TextStyle(fontSize: 24)),
          ),
        ),
        const SizedBox(width: AppConstants.spaceM),
        Text(
          'Yenom',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.primaryGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spaceM),
      decoration: BoxDecoration(
        color: AppColors.expenseRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        border: Border.all(color: AppColors.expenseRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.expenseRed, size: 18),
          const SizedBox(width: AppConstants.spaceS),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.expenseRed, fontSize: AppConstants.fontS),
            ),
          ),
        ],
      ),
    );
  }
}
