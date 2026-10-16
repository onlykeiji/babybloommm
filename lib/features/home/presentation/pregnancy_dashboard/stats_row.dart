import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/stat_chip.dart';
import '../learn_content.dart';
import '../pregnancy_learn_content.dart';

/// The streak / logged-today / lessons-done row shown under the sticky
/// header on the pregnancy dashboard.
class PregnancyStatsRow extends StatelessWidget {
  const PregnancyStatsRow({
    super.key,
    required this.streak,
    required this.loggedToday,
  });

  final int streak;
  final int loggedToday;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: StatChip(
          icon: Icons.local_fire_department_rounded,
          value: '$streak',
          label: 'Day streak',
          color: AppColors.secondaryContainer,
          deep: AppColors.primary,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: StatChip(
          icon: Icons.edit_note_rounded,
          value: '$loggedToday',
          label: 'Logged today',
          color: AppColors.lavender,
          deep: AppColors.secondary,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: ValueListenableBuilder<Set<String>>(
          valueListenable: LearnProgress.completedTitles,
          builder: (context, completed, _) {
            final done = allPregnancyLearnItems
                .where((i) => completed.contains(i.title))
                .length;
            return StatChip(
              icon: Icons.menu_book_rounded,
              value: '$done/${allPregnancyLearnItems.length}',
              label: 'Lessons done',
              color: AppColors.lavenderLight,
              deep: AppColors.primaryContainer,
            );
          },
        ),
      ),
    ],
  );
}
