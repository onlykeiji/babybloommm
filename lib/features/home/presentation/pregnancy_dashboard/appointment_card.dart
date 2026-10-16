import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../health_schedule_models.dart';
import '../reminders_health_screen.dart';

/// Shows the next upcoming appointment and links to the full schedule.
class PregnancyAppointmentCard extends StatelessWidget {
  const PregnancyAppointmentCard({super.key, required this.today});

  final DateTime today;

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<List<HealthAppointment>>(
    valueListenable: AppointmentStore.items,
    builder: (context, appointments, _) {
      final upcoming =
          appointments.where((a) => a.dateTime.isAfter(today)).toList()
            ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      final next = upcoming.isNotEmpty ? upcoming.first : null;

      return Container(
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
                Icons.medical_services_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NEXT APPOINTMENT',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    next?.title ?? 'No appointments yet',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    next == null
                        ? 'Add one in Reminders & health'
                        : 'In ${next.dateTime.difference(today).inDays} days',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RemindersHealthScreen(),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.buttonGradient,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  next == null ? 'Add' : 'View',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
