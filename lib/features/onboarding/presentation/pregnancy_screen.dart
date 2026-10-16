import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_settings_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../../../core/widgets/primary_button.dart';
import 'pregnancy_tracking_screen.dart';

/// Collects the date needed to tailor the pregnancy experience.
class PregnancyScreen extends StatefulWidget {
  const PregnancyScreen({super.key});

  @override
  State<PregnancyScreen> createState() => _PregnancyScreenState();
}

class _PregnancyScreenState extends State<PregnancyScreen> {
  bool _usesDueDate = true;
  DateTime? _selectedDate;
  bool _saving = false;
  String? _errorMessage;

  String get _dateLabel =>
      _usesDueDate ? 'MY DUE DATE IS' : 'LAST PERIOD STARTED ON';

  String get _helperText => _usesDueDate
      ? 'Knowing your date helps us provide precise weekly updates and milestones.'
      : "We will use Naegele's rule to estimate your due date based on this date.";

  Future<void> _continue() async {
    if (_selectedDate == null) {
      setState(() => _errorMessage = 'Please select a date to continue.');
      return;
    }
    // Naegele's rule: due date = last period start + 280 days.
    final dueDate = _usesDueDate
        ? _selectedDate!
        : _selectedDate!.add(const Duration(days: 280));

    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await AppSettingsStore.setDueDate(dueDate);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PregnancyTrackingScreen()),
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
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: _usesDueDate ? DateTime(now.year + 2) : now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _selectedDate = date);
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
          _blob(top: -80, left: -80, size: 280, color: AppColors.lavender),
          _blob(bottom: -100, right: -120, size: 340, color: AppColors.primary),
          SafeArea(
            child: Column(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: const OnboardingHeader(step: 2, totalSteps: 4),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        children: [
                          _heading(),
                          const SizedBox(height: 32),
                          _dateCard(),
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
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      children: [
                        PrimaryButton(
                          label: 'Continue',
                          trailingIcon: Icons.arrow_forward,
                          loading: _saving,
                          onPressed: _continue,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => setState(() => _usesDueDate = false),
                          child: Text(
                            'NOT SURE YET? CALCULATE FOR ME',
                            style: GoogleFonts.nunitoSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.3,
                              color: AppColors.onSurfaceVariant.withValues(
                                alpha: .7,
                              ),
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
  }

  Widget _heading() => Column(
    children: [
      Text(
        'Personalize Your Pregnancy',
        textAlign: TextAlign.center,
        style: GoogleFonts.nunitoSans(
          fontSize: 28,
          height: 1.25,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        "Tell us a bit about your baby's expected arrival.",
        textAlign: TextAlign.center,
        style: GoogleFonts.nunitoSans(
          fontSize: 16,
          height: 1.5,
          color: AppColors.onSurfaceVariant.withValues(alpha: .8),
        ),
      ),
    ],
  );

  Widget _dateCard() => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(32),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.14),
          blurRadius: 30,
          offset: const Offset(0, 14),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .7),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: .8)),
          ),
          child: Column(
            children: [
              _tabs(),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _dateLabel,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppColors.onSurfaceVariant.withValues(alpha: .6),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 17,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .5),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_outlined,
                        color: AppColors.primary.withValues(alpha: .6),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _selectedDate == null
                              ? 'Select Date'
                              : MaterialLocalizations.of(
                                  context,
                                ).formatMediumDate(_selectedDate!),
                          style: GoogleFonts.nunitoSans(
                            fontSize: 18,
                            color: _selectedDate == null
                                ? AppColors.onSurfaceVariant.withValues(
                                    alpha: .6,
                                  )
                                : AppColors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _helperText,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  color: AppColors.onSurfaceVariant.withValues(alpha: .65),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0x66E6E1E5),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _tabs() => Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: const Color(0x99F2ECF0),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(children: [_tab('DUE DATE', true), _tab('LAST PERIOD', false)]),
  );

  Widget _tab(String label, bool dueDate) {
    final selected = _usesDueDate == dueDate;
    return Expanded(
      child: TextButton(
        onPressed: () => setState(() => _usesDueDate = dueDate),
        style: TextButton.styleFrom(
          backgroundColor: selected ? AppColors.primary : Colors.transparent,
          foregroundColor: selected ? Colors.white : AppColors.onSurfaceVariant,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: const StadiumBorder(),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunitoSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: .8,
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
      imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .18),
          shape: BoxShape.circle,
        ),
      ),
    ),
  );
}
