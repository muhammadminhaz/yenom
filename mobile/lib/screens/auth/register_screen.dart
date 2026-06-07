import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/auth_api_service.dart';
import '../../core/utils/app_logger.dart';
import '../../widgets/neumorphic_button.dart';
import '../../widgets/neumorphic_text_field.dart';
import '../dashboard/dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _tag = 'RegisterScreen';

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  String? _validate() {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (username.length < 3) return 'Username must be at least 3 characters.';
    if (!email.contains('@')) return 'Enter a valid email address.';
    if (password.length < 6) return 'Password must be at least 6 characters.';
    if (password != confirm) return 'Passwords do not match.';
    if (firstName.length < 2) return 'First name must be at least 2 characters.';
    if (lastName.length < 2) return 'Last name must be at least 2 characters.';
    return null;
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _register() async {
    AppLogger.i(_tag, 'Register tapped');

    final error = _validate();
    if (error != null) {
      AppLogger.w(_tag, 'Validation failed: $error');
      setState(() => _errorMessage = error);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthApiService.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
      );

      AppLogger.i(_tag, 'Registration succeeded — navigating to Dashboard');
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (_) => false,
        );
      }
    } on ApiException catch (e) {
      AppLogger.w(_tag, 'Registration ApiException: ${e.message}');
      setState(() => _errorMessage = e.message);
    } catch (e, st) {
      AppLogger.e(_tag, 'Unexpected registration error', e, st);
      setState(() => _errorMessage = 'An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              const SizedBox(height: AppConstants.spaceL),
              _buildAppBar(context),
              const SizedBox(height: AppConstants.spaceXL),
              Text('Create Account', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: AppConstants.spaceS),
              Text(
                'Join Yenom to track your finances',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppConstants.spaceXXL),

              _sectionLabel(context, 'Account Info'),
              const SizedBox(height: AppConstants.spaceM),
              NeumorphicTextField(
                controller: _usernameController,
                hintText: 'Username (min 3 characters)',
                prefixIcon: Icons.alternate_email,
              ),
              const SizedBox(height: AppConstants.spaceL),
              NeumorphicTextField(
                controller: _emailController,
                hintText: 'Email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppConstants.spaceL),
              NeumorphicTextField(
                controller: _passwordController,
                hintText: 'Password (min 6 characters)',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: AppConstants.spaceL),
              NeumorphicTextField(
                controller: _confirmPasswordController,
                hintText: 'Confirm Password',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
              ),

              const SizedBox(height: AppConstants.spaceXL),
              _sectionLabel(context, 'Personal Info'),
              const SizedBox(height: AppConstants.spaceM),
              Row(
                children: [
                  Expanded(
                    child: NeumorphicTextField(
                      controller: _firstNameController,
                      hintText: 'First Name',
                      prefixIcon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spaceM),
                  Expanded(
                    child: NeumorphicTextField(
                      controller: _lastNameController,
                      hintText: 'Last Name',
                      prefixIcon: Icons.person_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spaceL),
              NeumorphicTextField(
                controller: _cityController,
                hintText: 'City (optional)',
                prefixIcon: Icons.location_city_outlined,
              ),
              const SizedBox(height: AppConstants.spaceL),
              NeumorphicTextField(
                controller: _countryController,
                hintText: 'Country (optional)',
                prefixIcon: Icons.flag_outlined,
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: AppConstants.spaceL),
                _buildErrorBanner(_errorMessage!),
              ],

              const SizedBox(height: AppConstants.spaceXXL),
              NeumorphicButton(
                isPrimary: true,
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Create Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: AppConstants.fontL,
                        ),
                      ),
              ),
              const SizedBox(height: AppConstants.spaceXL),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: const TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(color: AppColors.lightTextSecondary),
                      children: [
                        TextSpan(
                          text: 'Login',
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spaceXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.primaryGreen),
          SizedBox(width: 6),
          Text('Back', style: TextStyle(color: AppColors.primaryGreen)),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppColors.primaryGreen,
        fontWeight: FontWeight.bold,
      ),
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
