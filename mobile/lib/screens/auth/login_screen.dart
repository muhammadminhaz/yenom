import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/neumorphic_button.dart';
import '../../widgets/neumorphic_text_field.dart';
import '../dashboard/dashboard_screen.dart';

import 'package:uuid/uuid.dart';
import '../../core/models/user_model.dart';
import '../../core/services/database_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() async {
    // Create a dummy user and save to Hive
    final user = UserModel(
      id: const Uuid().v4(),
      username: 'muhammad_minhaz',
      email: _emailController.text.isNotEmpty ? _emailController.text : 'muhammad.minhaz@example.com',
      password: _passwordController.text.isNotEmpty ? _passwordController.text : 'StrongPassword123',
      role: 'USER',
      firstName: 'Muhammad',
      lastName: 'Minhaz',
      city: 'New York',
      country: 'USA',
      continent: 'North America',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await DatabaseService.saveUser(user);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

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
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: AppConstants.spaceS),
              Text(
                'Login to manage your expenses',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppConstants.spaceXXXL),
              NeumorphicTextField(
                controller: _emailController,
                hintText: 'Email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppConstants.spaceL),
              NeumorphicTextField(
                controller: _passwordController,
                hintText: 'Password',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: AppConstants.spaceM),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: AppColors.primaryGreen),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spaceXL),
              NeumorphicButton(
                isPrimary: true,
                onPressed: _login,
                child: const Text(
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
                  Text(
                    "Don't have an account? ",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  GestureDetector(
                    onTap: () {},
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
}
