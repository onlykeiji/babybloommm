import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../../../core/widgets/primary_button.dart';
import 'onboarding_complete_screen.dart';
import 'onboarding_lesson_screen.dart';
import 'onboarding_orientation_content.dart';

class PregnancyTrackingScreen extends StatefulWidget {
  const PregnancyTrackingScreen({super.key});

  @override
  State<PregnancyTrackingScreen> createState() =>
      _PregnancyTrackingScreenState();
}

class _PregnancyTrackingScreenState extends State<PregnancyTrackingScreen> {
  final Set<String> _selectedTracks = {'Baby Growth'};

  static const _tracks = [
    _Track(
      'Baby Growth',
      'Size comparisons and development.',
      Icons.child_care_outlined,
    ),
    _Track(
      'Symptom Log',
      'Track mood, energy, and body changes.',
      Icons.note_alt_outlined,
    ),
    _Track(
      'Kick Counter',
      "Monitor your baby's movements.",
      Icons.favorite_outline,
    ),
    _Track(
      'Weight Trends',
      'Visual charts of weight changes.',
      Icons.show_chart_outlined,
    ),
  ];

  void _toggleTrack(String title) {
    setState(() {
      if (!_selectedTracks.add(title)) _selectedTracks.remove(title);
    });
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
          _blob(top: -80, left: -80, size: 256, color: AppColors.secondary),
          _blob(top: 320, right: -160, size: 320, color: AppColors.lavender),
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
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OnboardingLessonScreen(
                              lessons: pregnancyOrientationLessons,
                              next: (_) => const OnboardingCompleteScreen(
                                isPregnancy: true,
                              ),
                            ),
                          ),
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

  Widget _heading() => Column(
    children: [
      Text(
        'What to Track?',
        textAlign: TextAlign.center,
        style: GoogleFonts.nunitoSans(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Select the metrics most important to you during your pregnancy journey.',
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
        borderRadius: BorderRadius.circular(32),
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
        onTap: () => _toggleTrack(track.title),
        borderRadius: BorderRadius.circular(32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0x99EBDDFF)
                    : Colors.white.withValues(alpha: .4),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: selected
                      ? AppColors.secondary
                      : AppColors.secondary.withValues(alpha: .15),
                  width: selected ? 2 : 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEBDCFF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(track.icon, color: AppColors.primary),
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
                        const SizedBox(height: 2),
                        Text(
                          track.description,
                          style: GoogleFonts.nunitoSans(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant.withValues(
                              alpha: .7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? AppColors.secondary
                          : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? AppColors.secondary
                            : AppColors.outlineVariant,
                        width: 2,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard() => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.secondaryContainer.withValues(alpha: .3),
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
        const Icon(Icons.info_outline, color: AppColors.secondary),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'These selections help BabyBloom tailor your pregnancy dashboard and daily updates.',
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
              height: 1.5,
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
          color: color.withValues(alpha: .22),
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
