import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../../../core/widgets/primary_button.dart';
import 'baby_care_screen.dart';
import 'family_planning_screen.dart';
import 'pregnancy_screen.dart';

class JourneyStageScreen extends StatefulWidget {
  const JourneyStageScreen({super.key});

  @override
  State<JourneyStageScreen> createState() => _JourneyStageScreenState();
}

class _JourneyStageScreenState extends State<JourneyStageScreen> {
  int _selectedStage = 0;

  static const _stages = [
    _JourneyStage(
      title: 'Family Planning',
      description: 'Track cycles and prepare for parenthood.',
      icon: Icons.favorite_outline_rounded,
    ),
    _JourneyStage(
      title: 'Pregnancy',
      description: 'Monitor growth and key milestones.',
      icon: Icons.pregnant_woman_rounded,
    ),
    _JourneyStage(
      title: 'Baby Care',
      description: 'Daily logging for feeding and sleep.',
      icon: Icons.child_care_rounded,
    ),
  ];

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
          _blob(top: -80, left: -80, size: 256, color: AppColors.secondary),
          _blob(top: 260, right: -160, size: 320, color: AppColors.lavender),
          SafeArea(
            child: Column(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: OnboardingHeader(
                      step: 1,
                      totalSteps: 4,
                      onSkip: () {},
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        children: [
                          _heading(),
                          const SizedBox(height: 40),
                          ...List.generate(
                            _stages.length,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _stageCard(index),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _infoCard(),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: PrimaryButton(
                      label: 'Continue',
                      trailingIcon: Icons.arrow_forward,
                      onPressed: () {
                        if (_selectedStage == 0) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const FamilyPlanningScreen(),
                            ),
                          );
                        } else if (_selectedStage == 1) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PregnancyScreen(),
                            ),
                          );
                        } else if (_selectedStage == 2) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BabyCareScreen(),
                            ),
                          );
                        }
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

  Widget _heading() => Column(
    children: [
      Text(
        'Where are you in your journey?',
        textAlign: TextAlign.center,
        style: GoogleFonts.nunitoSans(
          fontSize: 28,
          height: 1.2,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Choose the stage that best fits you to unlock personalized milestones.',
        textAlign: TextAlign.center,
        style: GoogleFonts.nunitoSans(
          fontSize: 17,
          height: 1.5,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _stageCard(int index) {
    final stage = _stages[index];
    final selected = _selectedStage == index;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: () => setState(() => _selectedStage = index),
        borderRadius: BorderRadius.circular(32),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0x99EBDDFF)
                : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: selected
                  ? AppColors.secondary
                  : AppColors.secondary.withValues(alpha: 0.15),
              width: selected ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? AppColors.secondary.withValues(alpha: 0.3)
                    : AppColors.primary.withValues(alpha: 0.06),
                blurRadius: selected ? 20 : 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFEBDCFF),
                  shape: BoxShape.circle,
                ),
                child: Icon(stage.icon, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stage.title,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stage.description,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: selected ? AppColors.secondary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? AppColors.secondary
                        : AppColors.outlineVariant,
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.secondaryContainer.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(32),
      border: Border.all(color: AppColors.secondaryContainer),
      boxShadow: [
        BoxShadow(
          color: AppColors.secondary.withValues(alpha: 0.12),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, color: AppColors.secondary),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'Every piece of advice is tailored to your stage. Your data is private and encrypted.',
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _blob({
    double? top,
    double? right,
    double? left,
    required double size,
    required Color color,
  }) => Positioned(
    top: top,
    right: right,
    left: left,
    child: ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
      ),
    ),
  );
}

class _JourneyStage {
  const _JourneyStage({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}
