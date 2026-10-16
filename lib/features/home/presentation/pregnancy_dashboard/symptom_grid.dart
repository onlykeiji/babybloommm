import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

const _symptomOptions = [
  (label: 'Nausea', icon: Icons.sick_outlined),
  (label: 'Fatigue', icon: Icons.bedtime_outlined),
  (label: 'Heartburn', icon: Icons.local_fire_department_outlined),
  (label: 'Swelling', icon: Icons.water_drop_outlined),
  (label: 'Backache', icon: Icons.accessibility_new_outlined),
  (label: 'Cravings', icon: Icons.icecream_outlined),
];

/// The tappable chip grid for today's check-in symptoms.
class PregnancySymptomGrid extends StatelessWidget {
  const PregnancySymptomGrid({
    super.key,
    required this.loggedSymptoms,
    required this.saving,
    required this.onToggle,
  });

  final Set<String> loggedSymptoms;
  final bool saving;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(24),
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Symptoms',
          style: GoogleFonts.nunitoSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        _chips(),
      ],
    ),
  );

  Widget _chips() => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: _symptomOptions.map((symptom) {
      final selected = loggedSymptoms.contains(symptom.label);
      return GestureDetector(
        onTap: saving ? null : () => onToggle(symptom.label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.buttonGradient : null,
            color: selected ? null : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : AppColors.outlineVariant.withValues(alpha: 0.45),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                symptom.icon,
                size: 17,
                color: selected ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                symptom.label,
                style: GoogleFonts.nunitoSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList(),
  );
}
