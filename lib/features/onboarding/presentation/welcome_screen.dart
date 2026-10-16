import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/presentation/signup_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnim;

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Stack(
          children: [
            _blob(
              top: -80,
              left: -80,
              size: 256,
              color: AppColors.secondaryContainer,
            ),
            _blob(
              bottom: -80,
              right: -80,
              size: 320,
              color: AppColors.lavender,
            ),

            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Column(
                                        children: [
                                          const SizedBox(height: 28),
                                          _hero(),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      Column(
                                        children: [
                                          _copy(),
                                          const SizedBox(height: 32),
                                          _pagination(),
                                          const SizedBox(height: 40),
                                          PrimaryButton(
                                            label: 'Get Started',
                                            trailingIcon: Icons.arrow_forward,
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const SignupScreen(),
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 16),
                                          PrimaryButton(
                                            label: 'I Already Have an Account',
                                            filled: false,
                                            onPressed: _goToLogin,
                                          ),
                                          const SizedBox(height: 24),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
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
      ),
    );
  }

  // Floating BabyBloom logo.
  Widget _hero() {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _floatAnim.value),
        child: child,
      ),
      child: Center(
        child: Image.asset(
          'lib/assets/images/logo.png',
          width: 400,
          height: 500,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Text(
            'BabyBloom',
            style: GoogleFonts.nunitoSans(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  // Marketing copy.
  Widget _copy() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Your Journey, Our Support',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunitoSans(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: 300,
          child: Text(
            'BabyBloom guides you every step of the way — with trusted '
            'information, helpful tools, and a community that cares.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunitoSans(
              fontSize: 15,
              height: 1.5,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  // Onboarding pagination dots.
  Widget _pagination() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final active = i == 0;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: active
                ? AppColors.secondary
                : AppColors.outlineVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  // Blurred background blob.
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
        imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
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
