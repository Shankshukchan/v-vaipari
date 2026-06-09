import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String method = ''; // 'phone', 'email_otp', 'email_verify', 'register'

  // Phone Login Controllers
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // Email OTP Controllers
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  // Register Controllers
  final _regNameCtrl = TextEditingController();
  final _regPhoneCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _regNameCtrl.dispose();
    _regPhoneCtrl.dispose();
    _regPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handlePhoneLogin() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).login(_phoneCtrl.text, _passCtrl.text);
      if (mounted) context.go('/app/dashboard');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSendOtp() async {
    if (_emailCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).sendOtp(_emailCtrl.text);
      setState(() => method = 'email_verify');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP Sent! Check your console/email.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).verifyOtp(_emailCtrl.text, _otpCtrl.text);
      if (mounted) context.go('/app/dashboard');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleAuth() async {
    setState(() => _isLoading = true);
    try {
      // Typically you'd use google_sign_in here to get the token.
      // We simulate it for now, sending a mock token that the dev backend will handle gracefully.
      await ref.read(authRepositoryProvider).googleAuth('mock_id_token_from_flutter');
      if (mounted) context.go('/app/dashboard');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).register(_regNameCtrl.text, _regPhoneCtrl.text, _regPassCtrl.text);
      if (mounted) context.go('/app/dashboard');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildMethodButton({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.foreground,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: AppTheme.mutedForeground),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppTheme.mutedForeground),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: method.isNotEmpty
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.foreground),
                onPressed: () => setState(() {
                  method = method == 'email_verify' ? 'email_otp' : '';
                }),
              )
            : IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.foreground),
                onPressed: () => context.pop(),
              ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method == '' ? 'Welcome back' :
                      method == 'phone' ? 'Login via Phone' :
                      method == 'email_otp' ? 'Login via Email' :
                      method == 'email_verify' ? 'Verify OTP' : 'Create Account',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.foreground),
                    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                    const SizedBox(height: 8),
                    Text(
                      method == '' ? 'Choose how you want to log in' :
                      method == 'email_verify' ? 'Enter the code sent to your email' :
                      'Enter your details to continue',
                      style: const TextStyle(fontSize: 16, color: AppTheme.mutedForeground),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 48),

                    if (method == '') ...[
                      _buildMethodButton(
                        icon: LucideIcons.mail,
                        iconColor: const Color(0xFFE94235),
                        iconBg: const Color(0xFFE94235).withOpacity(0.1),
                        title: 'Email OTP',
                        subtitle: 'Login with an email code',
                        onTap: () => setState(() => method = 'email_otp'),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                      const SizedBox(height: 16),
                      _buildMethodButton(
                        icon: LucideIcons.phone,
                        iconColor: AppTheme.accent,
                        iconBg: AppTheme.accent.withOpacity(0.1),
                        title: 'Phone Number',
                        subtitle: 'Login with Phone & Password',
                        onTap: () => setState(() => method = 'phone'),
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                      const SizedBox(height: 16),
                      _buildMethodButton(
                        icon: LucideIcons.logIn,
                        iconColor: Colors.green,
                        iconBg: Colors.green.withOpacity(0.1),
                        title: 'Google Sign-In',
                        subtitle: 'Quick login with Google',
                        onTap: _handleGoogleAuth,
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                      const SizedBox(height: 32),
                      Center(
                        child: TextButton(
                          onPressed: () => setState(() => method = 'register'),
                          child: const Text('Don\'t have an account? Register', style: TextStyle(color: AppTheme.primary)),
                        ),
                      ),
                    ],

                    if (method == 'email_otp') ...[
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: const Icon(LucideIcons.mail),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ).animate().fadeIn().slideY(begin: 0.1),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _handleSendOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Send OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                    ],

                    if (method == 'email_verify') ...[
                      TextField(
                        controller: _otpCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Enter 6-digit OTP',
                          prefixIcon: const Icon(LucideIcons.key),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ).animate().fadeIn().slideY(begin: 0.1),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _handleVerifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Verify & Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                    ],

                    if (method == 'phone') ...[
                      TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: const Icon(LucideIcons.phone),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ).animate().fadeIn().slideY(begin: 0.1),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(LucideIcons.lock),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _handlePhoneLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                    ],

                    if (method == 'register') ...[
                      TextField(
                        controller: _regNameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: const Icon(LucideIcons.user),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ).animate().fadeIn().slideY(begin: 0.1),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _regPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: const Icon(LucideIcons.phone),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _regPassCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(LucideIcons.lock),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                    ]
                  ],
                ),
              ),
      ),
    );
  }
}
