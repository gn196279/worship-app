import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'auth_gate.dart';
import 'sign_up_screen.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/google_icon.dart';
import '../widgets/gilgal_style1_logo.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isSigningIn = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isOtpSent = false;
  bool _isEmailMode = false;
  bool _showPassword = false;
  bool _showInlinePassword = false;
  String? _emailForOtp;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogle() async {
    if (_isSigningIn) return;
    setState(() => _isSigningIn = true);
    try {
      await context.read<AuthProvider>().signInWithGoogle();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Google sign-in failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  void _showEmailNotReady() {
    setState(() {
      _isEmailMode = true;
    });
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    try {
      await context.read<AuthProvider>().sendSignInOtp(email);
      if (!mounted) return;
      setState(() {
        _isOtpSent = true;
        _emailForOtp = email;
      });
      AppSnackBar.success(context, 'OTP link sent to your email.');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Failed to send OTP: $e');
    }
  }

  Future<void> _signInWithOtp() async {
    final email = _emailForOtp;
    final otp = _otpController.text.trim();
    if (email == null || otp.isEmpty) return;
    if (!otp.contains('oobCode=') && !otp.startsWith('http')) {
      AppSnackBar.warning(
        context,
        'Please paste the full email link. A numeric OTP code is not supported.',
      );
      return;
    }
    setState(() => _isSigningIn = true);
    try {
      await context.read<AuthProvider>().signInWithEmailLink(email, otp);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'OTP sign-in failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  Future<void> _pasteOtpLink() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      if (!mounted) return;
      AppSnackBar.info(context, 'Clipboard is empty.');
      return;
    }
    _otpController.text = text;
  }

  Future<void> _signInWithEmailPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) return;
    setState(() => _isSigningIn = true);
    try {
      await context.read<AuthProvider>().signInWithEmail(email, password);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Email sign-in failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  const GilgalStyle1Logo(size: 64, radius: 24),
                  if (_isEmailMode) ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            controller: _emailController,
                            decoration:
                                const InputDecoration(labelText: 'Email'),
                          ),
                          if (!_isOtpSent) ...[
                            TextField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(
                                        () => _showPassword = !_showPassword);
                                  },
                                ),
                              ),
                              obscureText: !_showPassword,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _signInWithEmailPassword,
                                    child: const Text('Login with Password'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _sendOtp,
                                    child: const Text('Send OTP Link'),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            TextField(
                              controller: _otpController,
                              decoration: const InputDecoration(
                                labelText: 'Enter OTP / Email link',
                                helperText: 'Paste the email link sent to you.',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _pasteOtpLink,
                                    child: const Text('Paste from clipboard'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _signInWithOtp,
                                    child: const Text('Verify'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Gilgal Worship',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Welcome back to worship',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.hintColor),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _isSigningIn ? null : _handleGoogle,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GoogleIcon(size: 22),
                                SizedBox(width: 10),
                                Text('Continue with Google'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: Divider(color: theme.dividerColor)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                'OR EMAIL LOGIN',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.hintColor,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: theme.dividerColor)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: !_showInlinePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showInlinePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(
                                  () => _showInlinePassword =
                                      !_showInlinePassword,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showEmailNotReady,
                            child: const Text('Use OTP Link'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _signInWithEmailPassword,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Login'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Don\'t have an account?',
                                style: theme.textTheme.bodySmall),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const SignUpScreen()),
                                );
                              },
                              child: const Text('Create an account'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isSigningIn)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
