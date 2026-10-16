import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/app_session.dart';
import '../../../core/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/user_profile_store.dart';
import '../../../core/widgets/primary_button.dart';
import '../../home/presentation/baby_care_dashboard.dart';
import '../../home/presentation/baby_care_models.dart';
import '../../home/presentation/family_planning_dashboard.dart';
import '../../home/presentation/pregnancy_dashboard.dart';
import '../../onboarding/presentation/journey_stage_screen.dart';
import 'email_verification_screen.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _loading = false;
  String? _errorMessage;

  /// Set when login fails specifically because the email hasn't been
  /// verified yet — lets the error area offer a "resend" shortcut instead
  /// of just a dead-end error string.
  String? _unconfirmedEmail;

  Future<void> _logIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email and password.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _unconfirmedEmail = null;
    });

    try {
      await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      try {
        await ProfileStore.fetchCurrent();
      } catch (_) {
        // Non-fatal — falls through to the onboarding quiz below.
      }
      if (!mounted) return;
      final mode = ProfileStore.current.value?.appMode;
      if (mode == AppMode.babyCare) {
        await BabyProfileStore.fetchAll();
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => switch (mode) {
            AppMode.pregnancy => const PregnancyDashboard(),
            AppMode.babyCare => const BabyCareDashboard(),
            AppMode.familyPlanning => const FamilyPlanningDashboard(),
            null => const JourneyStageScreen(),
          },
        ),
        (route) => false,
      );
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
        if (e.code == 'email_not_confirmed') _unconfirmedEmail = email;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Top-to-bottom background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFDF8FC), Color(0xFFF3EBFF)],
              ),
            ),
          ),
          // Soft floating blobs
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
                      _card(context),
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

  // ── Hero: logo + title + subtitle ────────────────────────
  Widget _hero() {
    return Column(
      children: [
        Image.asset(
          'lib/assets/images/logo.png',
          height: 88,
          fit: BoxFit.contain,
          // Fallback tile if the logo asset isn't found.
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
          'Welcome Back',
          style: GoogleFonts.nunitoSans(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Continue your maternal wellness journey',
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

  // ── Glass card with the form ─────────────────────────────
  Widget _card(BuildContext context) {
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
              _ElegantField(
                label: 'EMAIL ADDRESS',
                hint: 'name@babybloom.com',
                icon: Icons.alternate_email,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              _ElegantField(
                label: 'PASSWORD',
                hint: '••••••••',
                icon: Icons.lock_open_rounded,
                controller: _passwordController,
                isPassword: true,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Remember me
              Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (v) =>
                          setState(() => _rememberMe = v ?? false),
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
                  Text(
                    'Remember this device',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
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
                if (_unconfirmedEmail != null)
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EmailVerificationScreen(
                            email: _unconfirmedEmail!,
                          ),
                        ),
                      ),
                      child: Text(
                        'Resend verification email',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Continue to BabyBloom',
                trailingIcon: Icons.chevron_right,
                loading: _loading,
                onPressed: _logIn,
              ),
              const SizedBox(height: 16),
              // Trust message
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
              // Sign up footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'New to our community? ',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sign Up',
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

  // ── Thin progress decoration ─────────────────────────────
  Widget _progressBar() {
    return Opacity(
      opacity: 0.4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: 0.25,
          minHeight: 4,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          valueColor: AlwaysStoppedAnimation(
            AppColors.primary.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  // ── Blurred background blob ──────────────────────────────
  Widget _blob({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
  }) {
    return Positioned(
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
}

/// A rounded input with a leading icon that highlights on focus,
/// plus an optional password visibility toggle.
class _ElegantField extends StatefulWidget {
  const _ElegantField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.isPassword = false,
    this.keyboardType,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType? keyboardType;

  @override
  State<_ElegantField> createState() => _ElegantFieldState();
}

class _ElegantFieldState extends State<_ElegantField> {
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
  Widget build(BuildContext context) {
    return Column(
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
            color: _focused
                ? Colors.white
                : Colors.white.withValues(alpha: 0.6),
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
                  obscureText: widget.isPassword ? _obscure : false,
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
}
