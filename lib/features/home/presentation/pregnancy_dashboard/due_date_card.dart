import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

/// Shows the estimated due date on the pregnancy dashboard.
class PregnancyDueDateCard extends StatelessWidget {
  const PregnancyDueDateCard({super.key, required this.dueDate});

  final DateTime dueDate;

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
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: Color(0xFFD3BBFE),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.calendar_month_outlined,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ESTIMATED DUE DATE',
                style: GoogleFonts.nunitoSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                MaterialLocalizations.of(context).formatMediumDate(dueDate),
                style: GoogleFonts.nunitoSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.chevron_right,
            color: AppColors.primary,
            size: 20,
          ),
        ),
      ],
    ),
  );
}
