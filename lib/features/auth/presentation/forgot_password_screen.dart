import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';

enum _Stage { requestCode, resetPassword, success }

/// Forgot-password flow, in one screen:
/// 1. User enters their email — we call Supabase's `resetPasswordForEmail`,
///    which emails them a recovery code.
/// 2. User pastes that code + a new password — we verify the code with
///    `verifyOTP` (establishing a temporary recovery session) then call
///    `updateUser` to actually change the password.
///
/// This avoids needing deep-link/redirect-URL setup (which is finicky across
/// Windows/web/mobile) — everything happens with the user copy-pasting a
/// code, the same way the email-verification screen already works.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  _Stage _stage = _Stage.requestCode;
  bool _loading = false;
  bool _resending = false;
  String? _errorMessage;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (!_emailPattern.hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseConfig.client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      setState(() {
        _stage = _Stage.resetPassword;
        _loading = false;
      });
    } on AuthException catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> _resendCode() async {
    if (_resending) return;
    setState(() => _resending = true);
    try {
      await SupabaseConfig.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code resent — check your email.')),
        );
      }
    } catch (_) {
      // Best-effort; the user can still use the first code if it arrived.
    }
    if (mounted) setState(() => _resending = false);
  }

  Future<void> _resetPassword() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (code.isEmpty) {
      setState(() => _errorMessage = 'Enter the code we emailed you.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseConfig.client.auth.verifyOTP(
        type: OtpType.recovery,
        token: code,
        email: _emailController.text.trim(),
      );
      await SupabaseConfig.client.auth.updateUser(
        UserAttributes(password: password),
      );
      if (!mounted) return;
      setState(() {
        _stage = _Stage.success;
        _loading = false;
      });
    } on AuthException catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFDF8FC), Color(0xFFF3EBFF)],
              ),
            ),
          ),
          _blob(
            top: -120,
            left: -80,
            size: 360,
            color: const Color(0xFFEBDCFF),
          ),
          _blob(
            bottom: -100,
            right: -100,
            size: 420,
            color: const Color(0xFFF8F2F6),
          ),
          SafeArea(
            child: Column(
              children: [
                _appBar(),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: switch (_stage) {
                          _Stage.requestCode => _requestCodeCard(),
                          _Stage.resetPassword => _resetPasswordCard(),
                          _Stage.success => _successCard(),
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _appBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    child: Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
        ),
      ],
    ),
  );

  Widget _card({required Widget child}) => ClipRRect(
    borderRadius: BorderRadius.circular(28),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryContainer.withValues(alpha: 0.10),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: child,
      ),
    ),
  );

  Widget _title(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: GoogleFonts.nunitoSans(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        subtitle,
        style: GoogleFonts.nunitoSans(
          fontSize: 14,
          color: AppColors.onSurfaceVariant,
          height: 1.4,
        ),
      ),
    ],
  );

  Widget _errorText() => _errorMessage == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            _errorMessage!,
            style: GoogleFonts.nunitoSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Colors.red.shade400,
            ),
          ),
        );

  Widget _requestCodeCard() => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(
          'Forgot password?',
          "Enter your email and we'll send you a code to reset it.",
        ),
        const SizedBox(height: 24),
        _field(
          label: 'EMAIL ADDRESS',
          hint: 'sarah.johnson@email.com',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        _errorText(),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Send Reset Code',
          trailingIcon: Icons.arrow_forward,
          loading: _loading,
          onPressed: _sendCode,
        ),
      ],
    ),
  );

  Widget _resetPasswordCard() => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(
          'Check your email',
          'We sent a reset code to ${_emailController.text.trim()}. Enter it below with your new password.',
        ),
        const SizedBox(height: 24),
        _field(
          label: 'RESET CODE',
          hint: 'Code from your email',
          controller: _codeController,
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 16),
        _field(
          label: 'NEW PASSWORD',
          hint: 'At least 6 characters',
          controller: _passwordController,
          isPassword: true,
        ),
        const SizedBox(height: 16),
        _field(
          label: 'CONFIRM PASSWORD',
          hint: 'Repeat your new password',
          controller: _confirmController,
          isPassword: true,
        ),
        _errorText(),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Reset Password',
          trailingIcon: Icons.check_rounded,
          loading: _loading,
          onPressed: _resetPassword,
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton(
            onPressed: _resending ? null : _resendCode,
            child: Text(
              _resending ? 'Resending…' : "Didn't get a code? Resend",
              style: GoogleFonts.nunitoSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primary.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _successCard() => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: AppColors.secondary,
          size: 48,
        ),
        const SizedBox(height: 16),
        _title(
          'Password reset!',
          'Your password has been updated. You can now log in with your new password.',
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Back to Login',
          trailingIcon: Icons.arrow_forward,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          label,
          style: GoogleFonts.nunitoSans(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: AppColors.primary.withValues(alpha: 0.8),
          ),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          style: GoogleFonts.nunitoSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
          decoration: InputDecoration(
            isCollapsed: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: InputBorder.none,
            hintText: hint,
            hintStyle: GoogleFonts.nunitoSans(
              color: AppColors.outlineVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    ],
  );

  Widget _blob({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
  }) => Positioned(
    top: top,
    bottom: bottom,
    left: left,
    right: right,
    child: ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
      ),
    ),
  );
}
