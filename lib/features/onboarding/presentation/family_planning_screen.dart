import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../../home/presentation/daily_log_models.dart';
import '../../home/presentation/learn_content.dart';
import '../../home/presentation/lesson_detail_screen.dart';
import 'journey_optimization_screen.dart';
import 'onboarding_orientation_content.dart';

class FamilyPlanningScreen extends StatefulWidget {
  const FamilyPlanningScreen({super.key});

  @override
  State<FamilyPlanningScreen> createState() => _FamilyPlanningScreenState();
}

class _FamilyPlanningScreenState extends State<FamilyPlanningScreen> {
  DateTime? _cycleStartDate;
  bool _saving = false;
  String? _errorMessage;

  Future<void> _continue() async {
    if (_cycleStartDate == null) {
      setState(
        () =>
            _errorMessage = 'Please select the first day of your last period.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      // Seeds real cycle-prediction data (see CyclePrediction) with the
      // date the user just gave us, so predictions are live the moment
      // onboarding finishes instead of waiting for a first manual log.
      await DailyLogStore.save(
        DailyLog(
          logDate: _cycleStartDate!,
          flow: 'Medium',
          symptoms: const {},
          notes: '',
        ),
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const JourneyOptimizationScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = 'Could not save: $e';
      });
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _cycleStartDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.primaryContainer,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      setState(() {
        _cycleStartDate = date;
        _errorMessage = null;
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
          _blob(top: -80, left: -80, size: 256, color: AppColors.secondary),
          _blob(top: 300, right: -160, size: 320, color: AppColors.lavender),
          SafeArea(
            child: Column(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: OnboardingHeader(
                      step: 2,
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
                          _dateCard(),
                          const SizedBox(height: 16),
                          _cycleCard(),
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
                      loading: _saving,
                      onPressed: _continue,
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
        'Personalize Your Planning',
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
        'Tailoring insights for your unique cycle.',
        textAlign: TextAlign.center,
        style: GoogleFonts.nunitoSans(
          fontSize: 17,
          height: 1.5,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _dateCard() => _glassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LAST CYCLE START DATE',
          style: GoogleFonts.nunitoSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: AppColors.primary.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(32),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    MaterialLocalizations.of(
                      context,
                    ).formatMediumDate(_cycleStartDate ?? DateTime.now()),
                    style: GoogleFonts.nunitoSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                const Icon(
                  Icons.edit_calendar_outlined,
                  color: AppColors.outlineVariant,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () =>
              _openLesson(context, familyPlanningOrientationLessons.first),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This helps us calculate your fertile window accurately.',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to learn how the fertile window works →',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  void _openLesson(BuildContext context, LearnItem item) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LessonDetailScreen(
            item: item,
            allItems: familyPlanningOrientationLessons,
          ),
        ),
      );

  Widget _cycleCard() {
    if (_cycleStartDate == null) {
      return _glassCard(
        child: Column(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 48,
              color: AppColors.lavender,
            ),
            const SizedBox(height: 12),
            Text(
              'Select a date to see your cycle estimate',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunitoSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }
    // Preview only, using a typical 28-day cycle / 14-day luteal phase —
    // the real prediction (using the user's actual settings) appears on
    // the Cycle screen once onboarding finishes.
    const cycleLength = 28;
    const ovulationDay = 14;
    final daysSince = DateTime.now().difference(_cycleStartDate!).inDays;
    final cycleDay = (daysSince % cycleLength) + 1;
    final daysToWindow = ((ovulationDay - 5) - cycleDay) % cycleLength;

    return _glassCard(
      child: Column(
        children: [
          GestureDetector(
            onTap: () =>
                _openLesson(context, familyPlanningOrientationLessons[2]),
            child: SizedBox(
              width: 128,
              height: 128,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: cycleDay / cycleLength,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      color: AppColors.lavender,
                      backgroundColor: const Color(0xFFE6E1E5),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Day $cycleDay',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'TODAY',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            daysToWindow == 0
                ? 'Your fertile window is now'
                : 'Your window begins in $daysToWindow days',
            style: GoogleFonts.nunitoSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () =>
                _openLesson(context, familyPlanningOrientationLessons[2]),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  size: 14,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 5),
                Text(
                  'Tap to learn how this is calculated',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({required Widget child}) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(32),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.1),
          blurRadius: 26,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
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
