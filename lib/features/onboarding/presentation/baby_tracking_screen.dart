import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../../../core/widgets/primary_button.dart';
import 'onboarding_complete_screen.dart';
import 'onboarding_lesson_screen.dart';
import 'onboarding_orientation_content.dart';

class BabyTrackingScreen extends StatefulWidget {
  const BabyTrackingScreen({super.key});

  @override
  State<BabyTrackingScreen> createState() => _BabyTrackingScreenState();
}

class _BabyTrackingScreenState extends State<BabyTrackingScreen> {
  final Set<String> _selectedTracks = {'Feeding & Nutrition'};

  static const _tracks = [
    _Track(
      'Feeding & Nutrition',
      'Breast milk, formula, and solid food intake tracking.',
      Icons.restaurant_outlined,
    ),
    _Track(
      'Sleep Patterns',
      'Log naps, nighttime sleep, and wake windows.',
      Icons.bedtime_outlined,
    ),
    _Track(
      'Diaper Changes',
      'Track hydration and digestive health daily.',
      Icons.baby_changing_station_outlined,
    ),
    _Track(
      'Growth & Weight',
      'Percentiles and physical development charts.',
      Icons.monitor_weight_outlined,
    ),
    _Track(
      'Developmental Milestones',
      'Capture first words, steps, and social interactions.',
      Icons.stars_outlined,
    ),
  ];

  void _toggle(String title) => setState(() {
    if (!_selectedTracks.add(title)) _selectedTracks.remove(title);
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
        ),
        _blob(
          top: -80,
          right: -110,
          size: 340,
          color: AppColors.secondaryContainer,
        ),
        _blob(
          bottom: -90,
          left: -110,
          size: 320,
          color: const Color(0xFFEBDCFF),
        ),
        SafeArea(
          child: Column(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: OnboardingHeader(
                    step: 3,
                    totalSteps: 4,
                    onSkip: () {},
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        children: [
                          _heading(),
                          const SizedBox(height: 32),
                          ..._tracks.map(
                            (track) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _trackCard(track),
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
                  child: Column(
                    children: [
                      PrimaryButton(
                        label: 'Continue Journey',
                        trailingIcon: Icons.arrow_forward,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OnboardingLessonScreen(
                              lessons: babyCareOrientationLessons,
                              next: (_) => const OnboardingCompleteScreen(
                                isBabyCare: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You can change these settings anytime from your profile.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant.withValues(
                            alpha: .75,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _heading() => Column(
    children: [
      Text(
        'What would you like to track?',
        textAlign: TextAlign.center,
        style: GoogleFonts.nunitoSans(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        "Select the most important metrics for your baby's daily care.",
        textAlign: TextAlign.center,
        style: GoogleFonts.nunitoSans(
          fontSize: 17,
          height: 1.5,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _trackCard(_Track track) {
    final selected = _selectedTracks.contains(track.title);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: selected
                ? AppColors.secondary.withValues(alpha: 0.28)
                : AppColors.primary.withValues(alpha: 0.06),
            blurRadius: selected ? 18 : 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _toggle(track.title),
        borderRadius: BorderRadius.circular(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0x66EBDDFF)
                    : Colors.white.withValues(alpha: .42),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: selected
                      ? AppColors.secondary
                      : AppColors.secondary.withValues(alpha: .15),
                  width: selected ? 2 : 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEBDCFF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(track.icon, color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          style: GoogleFonts.nunitoSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          track.description,
                          style: GoogleFonts.nunitoSans(
                            fontSize: 13,
                            height: 1.35,
                            color: AppColors.onSurfaceVariant.withValues(
                              alpha: .8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedOpacity(
                    opacity: selected ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.check_circle,
                      color: AppColors.secondary,
                      size: 25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _blob({
    double? top,
    double? right,
    double? bottom,
    double? left,
    required double size,
    required Color color,
  }) => Positioned(
    top: top,
    right: right,
    bottom: bottom,
    left: left,
    child: ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .24),
          shape: BoxShape.circle,
        ),
      ),
    ),
  );
}

class _Track {
  const _Track(this.title, this.description, this.icon);

  final String title;
  final String description;
  final IconData icon;
}
