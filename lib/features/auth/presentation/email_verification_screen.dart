import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/user_profile_store.dart';
import '../../../core/widgets/primary_button.dart';
import '../../onboarding/presentation/journey_stage_screen.dart';
import 'login_screen.dart';

/// Blocks the user here until their email is verified — required, since
/// [AuthGate] (main.dart) refuses to let an unverified session into the app.
///
/// Verification happens by the user pasting the code Supabase emailed them
/// (`verifyOTP(type: signup, ...)`), the same code-based pattern used by
/// [ForgotPasswordScreen] — this avoids needing deep-link/redirect-URL setup
/// across Windows/web/desktop. Clicking the link in the email also still
/// works (Supabase confirms the account either way); a user who does that
/// just needs to come back here and log in normally afterwards, since
/// confirming via an external browser tab doesn't hand a session back to
/// this running app instance.
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key, required this.email});

  final String email;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _codeController = TextEditingController();

  bool _resending = false;
  bool _resent = false;
  bool _verifying = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Enter the code we emailed you.');
      return;
    }

    setState(() {
      _verifying = true;
      _errorMessage = null;
    });

    try {
      await SupabaseConfig.client.auth.verifyOTP(
        type: OtpType.signup,
        token: code,
        email: widget.email,
      );
      // verifyOTP succeeds -> a real, confirmed session is now live.
      try {
        await ProfileStore.fetchCurrent();
      } catch (_) {
        // Non-fatal — the profile trigger already ran server-side; this
        // just refreshes the local cache.
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const JourneyStageScreen()),
      );
    } on AuthException catch (e) {
      setState(() {
        _verifying = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _verifying = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> _resend() async {
    if (_resending) return;
    setState(() => _resending = true);
    try {
      await SupabaseConfig.client.auth.resend(
        type: OtpType.signup,
        email: widget.email,
      );
    } catch (_) {
      // Best-effort — the user can still use an already-sent code/link.
    }
    if (mounted) {
      setState(() {
        _resending = false;
        _resent = true;
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
              gradient: AppColors.backgroundGradient,
            ),
          ),
          _blob(top: -100, right: -90, color: AppColors.primary),
          _blob(bottom: -100, left: -90, color: AppColors.secondaryContainer),
          SafeArea(
            child: Column(
              children: [
                _appBar(context),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          children: [
                            _illustration(),
                            const SizedBox(height: 38),
                            Text(
                              'Check Your Email',
                              style: GoogleFonts.nunitoSans(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              "We've sent a verification code to ${widget.email}. Enter it below to confirm your account.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunitoSans(
                                fontSize: 17,
                                height: 1.55,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 30),
                            _codeField(),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 14),
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
                              label: 'Verify Email',
                              trailingIcon: Icons.arrow_forward,
                              loading: _verifying,
                              onPressed: _verify,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _resending ? null : _resend,
                              icon: Icon(
                                _resent
                                    ? Icons.check_circle_outline
                                    : Icons.refresh,
                              ),
                              label: Text(
                                _resending
                                    ? 'Sending...'
                                    : _resent
                                    ? 'Code Sent!'
                                    : 'Resend code',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _resent
                                    ? Colors.green.shade700
                                    : AppColors.secondary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                side: BorderSide(
                                  color: AppColors.secondary.withValues(
                                    alpha: .3,
                                  ),
                                ),
                                shape: const StadiumBorder(),
                                textStyle: GoogleFonts.nunitoSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  ),
                              child: Text(
                                'Clicked the link in your email instead? Log in',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunitoSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _helpCard(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    'SECURE VERIFICATION BY BABYBLOOM',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: AppColors.outlineVariant,
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

  Widget _appBar(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    child: Row(
      children: [
        const Icon(Icons.spa_outlined, color: AppColors.primary, size: 26),
        const SizedBox(width: 8),
        Text(
          'BabyBloom',
          style: GoogleFonts.nunitoSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () async {
            await SupabaseConfig.client.auth.signOut();
            if (context.mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
          child: Text(
            'LOGOUT',
            style: GoogleFonts.nunitoSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _codeField() => Container(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: AppColors.outlineVariant.withValues(alpha: 0.5),
      ),
    ),
    child: TextField(
      controller: _codeController,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.text,
      style: GoogleFonts.nunitoSans(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppColors.onSurface,
        letterSpacing: 4,
      ),
      decoration: InputDecoration(
        isCollapsed: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: InputBorder.none,
        hintText: 'Verification code',
        hintStyle: GoogleFonts.nunitoSans(
          color: AppColors.outlineVariant,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
      ),
    ),
  );

  Widget _illustration() => Stack(
    alignment: Alignment.center,
    children: [
      Container(
        width: 224,
        height: 224,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: .55)),
          boxShadow: const [
            BoxShadow(color: Color(0x184E4068), blurRadius: 24),
          ],
        ),
      ),
      Container(
        width: 146,
        height: 112,
        decoration: BoxDecoration(
          gradient: AppColors.buttonGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x28665781),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.mark_email_unread_outlined,
          color: Colors.white,
          size: 64,
        ),
      ),
      const Positioned(
        top: 16,
        right: 20,
        child: Icon(
          Icons.auto_awesome,
          color: AppColors.lavenderLight,
          size: 24,
        ),
      ),
      const Positioned(
        bottom: 26,
        left: 14,
        child: Icon(
          Icons.circle,
          color: AppColors.secondaryContainer,
          size: 14,
        ),
      ),
    ],
  );

  Widget _helpCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0x99F8F2F6),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white.withValues(alpha: .6)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.help_outline, color: AppColors.outlineVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            "Didn't see it? Check your spam folder, or resend the code above.",
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
              height: 1.5,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _blob({
    double? top,
    double? right,
    double? bottom,
    double? left,
    required Color color,
  }) => Positioned(
    top: top,
    right: right,
    bottom: bottom,
    left: left,
    child: ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: Container(
        width: 270,
        height: 270,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .14),
          shape: BoxShape.circle,
        ),
      ),
    ),
  );
}
