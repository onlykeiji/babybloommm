import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/user_profile_store.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../../home/presentation/baby_care_dashboard.dart';
import '../../home/presentation/family_planning_dashboard.dart';
import '../../home/presentation/pregnancy_dashboard.dart';

class OnboardingCompleteScreen extends StatelessWidget {
  const OnboardingCompleteScreen({
    super.key,
    this.isBabyCare = false,
    this.isPregnancy = false,
  });

  final bool isBabyCare;
  final bool isPregnancy;

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
          _blob(top: -110, left: -110, color: AppColors.secondaryContainer),
          _blob(top: 300, right: -130, color: AppColors.lavender),
          SafeArea(
            child: Column(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: const OnboardingHeader(step: 4, totalSteps: 4),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          children: [
                            _celebration(),
                            const SizedBox(height: 28),
                            _message(),
                            const SizedBox(height: 30),
                            _infoCard(
                              icon: isBabyCare
                                  ? Icons.child_care_outlined
                                  : Icons.calendar_month,
                              label: isBabyCare
                                  ? 'YOUR BABY CARE PLAN'
                                  : isPregnancy
                                  ? 'CURRENT STATUS'
                                  : 'CYCLE TRACKING',
                              title: isBabyCare
                                  ? 'Ready for daily care'
                                  : isPregnancy
                                  ? 'Your pregnancy journey is ready'
                                  : 'Your cycle tracker is ready',
                              detail: isBabyCare
                                  ? 'Track feedings, sleep, and growth in one place'
                                  : isPregnancy
                                  ? 'Track your milestones and appointments in one place'
                                  : 'Your estimates will update from the cycle date you entered',
                            ),
                            const SizedBox(height: 14),
                            _infoCard(
                              icon: Icons.lightbulb_outline,
                              label: 'TIP OF THE DAY',
                              title: isPregnancy
                                  ? "Staying hydrated supports amniotic fluid and your baby's development."
                                  : 'Staying hydrated supports cervical mucus health, which is key for your fertility journey.',
                            ),
                            const SizedBox(height: 14),
                            TextButton(
                              onPressed: () =>
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Your personalized plan is ready.',
                                      ),
                                    ),
                                  ),
                              child: Text(
                                'VIEW MY PERSONALIZED PLAN',
                                style: GoogleFonts.nunitoSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.4,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: PrimaryButton(
                      label: 'Go to Dashboard',
                      trailingIcon: Icons.arrow_forward,
                      onPressed: () {
                        if (isPregnancy) {
                          AppSession.mode = AppMode.pregnancy;
                          ProfileStore.rememberAppMode(AppMode.pregnancy);
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const PregnancyDashboard(),
                            ),
                            (route) => false,
                          );
                          return;
                        }
                        if (!isBabyCare) {
                          AppSession.mode = AppMode.familyPlanning;
                          ProfileStore.rememberAppMode(AppMode.familyPlanning);
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const FamilyPlanningDashboard(),
                            ),
                            (route) => false,
                          );
                          return;
                        }
                        AppSession.mode = AppMode.babyCare;
                        ProfileStore.rememberAppMode(AppMode.babyCare);
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const BabyCareDashboard(),
                          ),
                          (route) => false,
                        );
                      },
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

  Widget _celebration() => SizedBox(
    width: 220,
    height: 220,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 190,
          height: 190,
          decoration: const BoxDecoration(
            color: Color(0x33D3BBFE),
            shape: BoxShape.circle,
          ),
        ),
        const Positioned(
          top: 14,
          right: 27,
          child: Icon(
            Icons.auto_awesome,
            color: AppColors.lavenderLight,
            size: 25,
          ),
        ),
        const Positioned(
          bottom: 25,
          left: 20,
          child: Icon(
            Icons.circle,
            color: AppColors.secondaryContainer,
            size: 14,
          ),
        ),
        ClipOval(
          child: Container(
            width: 158,
            height: 158,
            color: const Color(0xFFEBDCFF),
            padding: const EdgeInsets.all(17),
            child: Image.asset(
              'lib/assets/images/logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _message() => Column(
    children: [
      Text(
        "You're All Set!",
        style: GoogleFonts.nunitoSans(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        isBabyCare
            ? 'Your personalized baby care guide is ready with the tools you selected.'
            : isPregnancy
            ? 'Your personalized pregnancy guide is ready.'
            : 'Your cycle tracker is ready. Log your symptoms and period dates to keep its estimates up to date.',
        textAlign: TextAlign.center,
        style: GoogleFonts.nunitoSans(
          fontSize: 17,
          height: 1.5,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String title,
    String? detail,
  }) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .45),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: .15),
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFEBDCFF),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                        color: AppColors.onSurfaceVariant.withValues(alpha: .7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: GoogleFonts.nunitoSans(
                        fontSize: detail == null ? 14 : 20,
                        height: 1.4,
                        fontWeight: detail == null
                            ? FontWeight.w600
                            : FontWeight.w700,
                        color: detail == null
                            ? AppColors.onSurfaceVariant
                            : AppColors.primary,
                      ),
                    ),
                    if (detail != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        detail,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant.withValues(
                            alpha: .7,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _blob({
    double? top,
    double? right,
    double? left,
    required Color color,
  }) => Positioned(
    top: top,
    right: right,
    left: left,
    child: ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 72, sigmaY: 72),
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .25),
          shape: BoxShape.circle,
        ),
      ),
    ),
  );
}
