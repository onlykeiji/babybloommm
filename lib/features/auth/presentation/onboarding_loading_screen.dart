import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class OnboardingLoadingScreen extends StatefulWidget {
  const OnboardingLoadingScreen({super.key});

  @override
  State<OnboardingLoadingScreen> createState() =>
      _OnboardingLoadingScreenState();
}

class _OnboardingLoadingScreenState extends State<OnboardingLoadingScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 54,
              height: 54,
              child: CircularProgressIndicator(
                strokeWidth: 5,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Preparing your personalized journey',
              style: GoogleFonts.nunitoSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
