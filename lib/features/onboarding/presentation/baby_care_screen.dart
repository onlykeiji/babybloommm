import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../../home/presentation/baby_care_models.dart';
import 'baby_tracking_screen.dart';

class BabyCareScreen extends StatefulWidget {
  const BabyCareScreen({super.key});

  @override
  State<BabyCareScreen> createState() => _BabyCareScreenState();
}

class _BabyCareScreenState extends State<BabyCareScreen> {
  final _nameController = TextEditingController();
  int _genderIndex = 0;
  DateTime? _birthDate;
  bool _saving = false;
  String? _errorMessage;

  static const _genders = [BabyGender.boy, BabyGender.girl];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = "Please enter your baby's name.");
      return;
    }
    if (_birthDate == null) {
      setState(() => _errorMessage = "Please select your baby's birthdate.");
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await BabyProfileStore.addBaby(
        BabyProfile(
          id: '',
          name: name,
          dateOfBirth: _birthDate!,
          gender: _genders[_genderIndex],
        ),
      );
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const BabyTrackingScreen()));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = e is BabyProfileValidationError
            ? e.message
            : 'Could not save: $e';
      });
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _birthDate = date);
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
          _blob(top: -88, right: -88, size: 256, color: AppColors.lavender),
          _blob(top: 300, left: -130, size: 320, color: AppColors.lavender),
          SafeArea(
            child: Column(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: const OnboardingHeader(
                      step: 2,
                      totalSteps: 4,
                      showBrand: false,
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
                          _hero(),
                          const SizedBox(height: 32),
                          _detailsCard(),
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
                          const SizedBox(height: 32),
                          PrimaryButton(
                            label: 'Continue',
                            trailingIcon: Icons.arrow_forward,
                            loading: _saving,
                            onPressed: _continue,
                          ),
                          const SizedBox(height: 22),
                          TextButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.chevron_left, size: 18),
                            label: Text(
                              'Go back',
                              style: GoogleFonts.nunitoSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.onSurfaceVariant
                                  .withValues(alpha: .6),
                            ),
                          ),
                        ],
                      ),
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

  Widget _hero() => Column(
    children: [
      Image.asset(
        'lib/assets/images/logo.png',
        width: 180,
        height: 180,
        fit: BoxFit.contain,
      ),
      const SizedBox(height: 22),
      Text(
        'Tell us about your little one',
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
        "Personalize your experience by sharing your baby's details.",
        textAlign: TextAlign.center,
        style: GoogleFonts.nunitoSans(
          fontSize: 17,
          height: 1.45,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _detailsCard() => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.12),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .45),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: .5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your baby',
                style: GoogleFonts.nunitoSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 22),
              _fieldLabel("BABY'S NAME"),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: _inputDecoration('Enter name'),
              ),
              const SizedBox(height: 22),
              _fieldLabel('BIRTHDATE'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickBirthDate,
                borderRadius: BorderRadius.circular(999),
                child: InputDecorator(
                  decoration: _inputDecoration('').copyWith(
                    suffixIcon: const Icon(
                      Icons.calendar_month_outlined,
                      color: AppColors.outlineVariant,
                    ),
                  ),
                  child: Text(
                    _birthDate == null
                        ? ''
                        : MaterialLocalizations.of(
                            context,
                          ).formatMediumDate(_birthDate!),
                    style: GoogleFonts.nunitoSans(
                      fontSize: 16,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _fieldLabel('GENDER'),
              const SizedBox(height: 8),
              _segmentedControl(
                ['Boy', 'Girl'],
                _genderIndex,
                (index) => setState(() => _genderIndex = index),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _segmentedControl(
    List<String> labels,
    int selected,
    ValueChanged<int> onSelected,
  ) => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: const Color(0x99F8F2F6),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AppColors.outlineVariant.withValues(alpha: .2)),
    ),
    child: Row(
      children: List.generate(
        labels.length,
        (index) => Expanded(
          child: TextButton(
            onPressed: () => onSelected(index),
            style: TextButton.styleFrom(
              backgroundColor: selected == index
                  ? AppColors.primaryContainer
                  : Colors.transparent,
              foregroundColor: selected == index
                  ? Colors.white
                  : AppColors.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: const StadiumBorder(),
            ),
            child: Text(
              labels[index],
              style: GoogleFonts.nunitoSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _fieldLabel(String text) => Text(
    text,
    style: GoogleFonts.nunitoSans(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
      color: AppColors.onSurfaceVariant,
    ),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.nunitoSans(
      color: AppColors.outlineVariant.withValues(alpha: .8),
    ),
    filled: true,
    fillColor: Colors.white.withValues(alpha: .6),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: BorderSide(
        color: AppColors.outlineVariant.withValues(alpha: .3),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: BorderSide(
        color: AppColors.outlineVariant.withValues(alpha: .3),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: const BorderSide(color: AppColors.primary),
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
