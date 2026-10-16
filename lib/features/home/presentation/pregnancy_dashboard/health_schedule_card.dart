import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../reminders_health_screen.dart';

/// Links out to the medications/appointments/vaccines schedule.
class PregnancyHealthScheduleCard extends StatelessWidget {
  const PregnancyHealthScheduleCard({super.key});

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(24),
    onTap: () => Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RemindersHealthScreen())),
    child: Container(
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
              Icons.notifications_active_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reminders & health schedule',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Medications, appointments & vaccines.',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
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
    ),
  );
}
