import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

const _moods = [
  (
    label: 'Great',
    icon: Icons.sentiment_very_satisfied_rounded,
    color: AppColors.primary,
  ),
  (
    label: 'Good',
    icon: Icons.sentiment_satisfied_alt_rounded,
    color: AppColors.secondary,
  ),
  (
    label: 'Okay',
    icon: Icons.sentiment_neutral_rounded,
    color: AppColors.lavender,
  ),
  (
    label: 'Low',
    icon: Icons.sentiment_dissatisfied_rounded,
    color: AppColors.lavenderLight,
  ),
  (
    label: 'Anxious',
    icon: Icons.sentiment_very_dissatisfied_rounded,
    color: AppColors.primaryContainer,
  ),
];

/// Tappable mood picker for today's pregnancy check-in — feeds the same
/// `daily_logs.mood` column the Insights "Mood this week" strip reads from.
class PregnancyMoodRow extends StatelessWidget {
  const PregnancyMoodRow({
    super.key,
    required this.selectedMood,
    required this.onSelect,
  });

  final String? selectedMood;
  final ValueChanged<String?> onSelect;

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
          'How are you feeling?',
          style: GoogleFonts.nunitoSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        _moodChips(),
      ],
    ),
  );

  Widget _moodChips() => Row(
    children: _moods.map((mood) {
      final selected = selectedMood == mood.label;
      return Expanded(
        child: GestureDetector(
          onTap: () => onSelect(selected ? null : mood.label),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? mood.color
                      : Colors.white.withValues(alpha: 0.72),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: mood.color.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  mood.icon,
                  color: selected ? Colors.white : AppColors.onSurfaceVariant,
                  size: 22,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                mood.label,
                style: GoogleFonts.nunitoSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList(),
  );
}
