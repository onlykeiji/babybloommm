import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../home/presentation/terms_privacy_screen.dart';
import 'email_verification_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptedTerms = false;
  bool _loading = false;
  String? _errorMessage;

  late final TapGestureRecognizer _termsTapRecognizer = TapGestureRecognizer()
    ..onTap = () => Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TermsPrivacyScreen()));

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  String? _validate() {
    if (_nameController.text.trim().isEmpty) {
      return 'Please enter your full name.';
    }
    if (!_emailPattern.hasMatch(_emailController.text.trim())) {
      return 'Please enter a valid email address.';
    }
    if (_passwordController.text.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      return 'Passwords do not match.';
    }
    if (!_acceptedTerms) {
      return 'Please accept the Terms of Service to continue.';
    }
    return null;
  }

  Future<void> _signUp() async {
    final validationError = _validate();
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseConfig.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {'full_name': _nameController.text.trim()},
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              EmailVerificationScreen(email: _emailController.text.trim()),
        ),
      );
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _termsTapRecognizer.dispose();
    super.dispose();
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
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _hero(),
                      const SizedBox(height: 24),
                      _card(),
                      const SizedBox(height: 24),
                      _progressBar(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    return Column(
      children: [
        Image.asset(
          'lib/assets/images/logo.png',
          height: 88,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.spa_rounded, color: Colors.white, size: 38),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Create Your Account',
          style: GoogleFonts.nunitoSans(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Begin your maternal wellness journey',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunitoSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _card() {
    return ClipRRect(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SignupField(
                label: 'FULL NAME',
                hint: 'Enter your full name',
                icon: Icons.person_outline_rounded,
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 20),
              _SignupField(
                label: 'EMAIL ADDRESS',
                hint: 'Enter your email address',
                icon: Icons.alternate_email,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              _SignupField(
                label: 'PASSWORD',
                hint: 'Create a secure password',
                icon: Icons.lock_open_rounded,
                controller: _passwordController,
                isPassword: true,
              ),
              const SizedBox(height: 20),
              _SignupField(
                label: 'CONFIRM PASSWORD',
                hint: 'Repeat your password',
                icon: Icons.lock_outline_rounded,
                controller: _confirmPasswordController,
                isPassword: true,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _acceptedTerms,
                      onChanged: (value) =>
                          setState(() => _acceptedTerms = value ?? false),
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: GoogleFonts.nunitoSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurfaceVariant,
                        ),
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Terms of Service and Privacy Policy',
                            style: GoogleFonts.nunitoSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: _termsTapRecognizer,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade400,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Create My Account',
                trailingIcon: Icons.arrow_forward,
                loading: _loading,
                onPressed: _signUp,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Your information is encrypted and secure',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(
                color: AppColors.primary.withValues(alpha: 0.08),
                height: 1,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already part of our community? ',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Log In',
                          style: GoogleFonts.nunitoSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
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

  Widget _progressBar() => Opacity(
    opacity: 0.4,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: 0.5,
        minHeight: 4,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        valueColor: AlwaysStoppedAnimation(
          AppColors.primary.withValues(alpha: 0.4),
        ),
      ),
    ),
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

class _SignupField extends StatefulWidget {
  const _SignupField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.isPassword = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  State<_SignupField> createState() => _SignupFieldState();
}

class _SignupFieldState extends State<_SignupField> {
  final _focusNode = FocusNode();
  bool _focused = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(
      () => setState(() => _focused = _focusNode.hasFocus),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          widget.label,
          style: GoogleFonts.nunitoSans(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: AppColors.primary.withValues(alpha: 0.8),
          ),
        ),
      ),
      AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _focused ? Colors.white : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _focused
                ? AppColors.lavender
                : AppColors.outlineVariant.withValues(alpha: 0.6),
            width: _focused ? 1.5 : 1,
          ),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: AppColors.primaryContainer.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 18, right: 12),
              child: Icon(
                widget.icon,
                size: 20,
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                keyboardType: widget.keyboardType,
                textCapitalization: widget.textCapitalization,
                obscureText: widget.isPassword && _obscure,
                style: GoogleFonts.nunitoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  border: InputBorder.none,
                  hintText: widget.hint,
                  hintStyle: GoogleFonts.nunitoSans(
                    color: AppColors.outlineVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            if (widget.isPassword)
              IconButton(
                splashRadius: 20,
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            else
              const SizedBox(width: 12),
          ],
        ),
      ),
    ],
  );
}
