import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_snackbar.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) return;
    try {
      await context.read<AuthProvider>().signUpWithEmail(email, password);
      if (mounted) {
        AppSnackBar.success(context, 'Sign up successful! Please log in.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Sign up failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: AppColors.appBarBackground(isDark),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.person_add,
                    color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'Create Account',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _showPassword = !_showPassword);
                    },
                  ),
                ),
                obscureText: !_showPassword,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _signUp,
                  child: const Text('Sign Up'),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Or use the OTP login from the sign-in screen after registration.',
                style:
                    theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
              const Spacer(),
              Text(
                'By signing up, you agree to our Terms and Privacy Policy.',
                textAlign: TextAlign.center,
                style:
                    theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
