import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_settings_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/screen_background.dart';

class PregnancySettingsScreen extends StatefulWidget {
  const PregnancySettingsScreen({super.key});

  @override
  State<PregnancySettingsScreen> createState() =>
      _PregnancySettingsScreenState();
}

class _PregnancySettingsScreenState extends State<PregnancySettingsScreen> {
  int _currentWeek = 12;
  double _prePregnancyWeight = 132.0;
  bool _saving = false;

  final Set<String> _tracking = {'Symptoms', 'Kick counts', 'Weight'};

  static const _trackOptions = [
    (label: 'Symptoms', icon: Icons.sick_outlined),
    (label: 'Kick counts', icon: Icons.child_care_outlined),
    (label: 'Weight', icon: Icons.monitor_weight_outlined),
    (label: 'Mood', icon: Icons.mood_outlined),
    (label: 'Water intake', icon: Icons.water_drop_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (AppSettingsStore.current.value == null) {
      try {
        await AppSettingsStore.fetch();
      } catch (_) {
        return;
      }
    }
    final s = AppSettingsStore.current.value;
    if (s == null || !mounted) return;
    setState(() {
      _currentWeek = s.currentPregnancyWeek;
      _prePregnancyWeight = s.prePregnancyWeightLb;
      _tracking
        ..clear()
        ..addAll(s.pregnancyTracking);
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await AppSettingsStore.savePregnancySettings(
        currentWeek: _currentWeek,
        prePregnancyWeightLb: _prePregnancyWeight,
        tracking: _tracking,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pregnancy settings updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: Stack(
      children: [
        const ScreenBackground(),
        SafeArea(
          child: Column(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: _header(context),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _stepperCard(
                            label: 'Current week',
                            detail: 'Used to tailor your weekly updates.',
                            value: _currentWeek,
                            min: 1,
                            max: 42,
                            onChanged: (v) => setState(() => _currentWeek = v),
                          ),
                          const SizedBox(height: 14),
                          _weightCard(),
                          const SizedBox(height: 26),
                          Text(
                            'What to track',
                            style: GoogleFonts.nunitoSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Choose what shows up in your daily check-in.',
                            style: GoogleFonts.nunitoSans(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._trackOptions.map(
                            (option) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _trackToggle(option.label, option.icon),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _bottomBar(),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _header(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: AppColors.outlineVariant.withValues(alpha: 0.2),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.12),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pregnancy settings',
                style: GoogleFonts.nunitoSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Fine-tune your weekly updates.',
                style: GoogleFonts.nunitoSans(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _stepperCard({
    required String label,
    required String detail,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: AppColors.outlineVariant.withValues(alpha: 0.25),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: GoogleFonts.nunitoSans(
                  fontSize: 12,
                  height: 1.3,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _stepperButton(
          Icons.remove_rounded,
          value > min ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 42,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunitoSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
        _stepperButton(
          Icons.add_rounded,
          value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    ),
  );

  Widget _weightCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: AppColors.outlineVariant.withValues(alpha: 0.25),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pre-pregnancy weight',
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Used as your baseline for healthy-range guidance.',
                style: GoogleFonts.nunitoSans(
                  fontSize: 12,
                  height: 1.3,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _stepperButton(
          Icons.remove_rounded,
          () => setState(
            () => _prePregnancyWeight = (_prePregnancyWeight - 1).clamp(
              80.0,
              300.0,
            ),
          ),
        ),
        SizedBox(
          width: 56,
          child: Text(
            '${_prePregnancyWeight.toStringAsFixed(0)} lb',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunitoSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
        _stepperButton(
          Icons.add_rounded,
          () => setState(
            () => _prePregnancyWeight = (_prePregnancyWeight + 1).clamp(
              80.0,
              300.0,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _stepperButton(IconData icon, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: onTap == null
            ? AppColors.outlineVariant.withValues(alpha: 0.2)
            : const Color(0xFFD3BBFE),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 18,
        color: onTap == null
            ? AppColors.onSurfaceVariant.withValues(alpha: 0.5)
            : AppColors.primary,
      ),
    ),
  );

  Widget _trackToggle(String label, IconData icon) {
    final selected = _tracking.contains(label);
    return GestureDetector(
      onTap: () => setState(
        () => selected ? _tracking.remove(label) : _tracking.add(label),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0x99EBDDFF)
              : Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.secondary
                : AppColors.outlineVariant.withValues(alpha: 0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.secondary : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? AppColors.secondary
                      : AppColors.outlineVariant,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: PrimaryButton(
        label: 'Save Settings',
        trailingIcon: Icons.check_rounded,
        loading: _saving,
        onPressed: _save,
      ),
    ),
  );
}
