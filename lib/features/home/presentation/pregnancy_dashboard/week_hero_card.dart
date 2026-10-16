import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../pregnancy_week_content.dart';

/// The large gradient hero card showing the current week's progress ring
/// and baby size comparison.
class PregnancyWeekHeroCard extends StatelessWidget {
  const PregnancyWeekHeroCard({
    super.key,
    required this.currentWeek,
    required this.totalWeeks,
    required this.daysToGo,
  });

  final int currentWeek;
  final int totalWeeks;
  final int daysToGo;

  @override
  Widget build(BuildContext context) {
    final info = pregnancyWeekInfo(currentWeek);
    final measurement = info.weightG == null
        ? 'About ${info.lengthCm.toStringAsFixed(1)} cm long.'
        : 'About ${info.lengthCm.toStringAsFixed(1)} cm and ${info.weightG!.toStringAsFixed(0)} g.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            height: 112,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 112,
                  height: 112,
                  child: CircularProgressIndicator(
                    value: currentWeek / totalWeeks,
                    strokeWidth: 9,
                    strokeCap: StrokeCap.round,
                    color: const Color(0xFFD3BBFE),
                    backgroundColor: const Color(0x336D5B8F),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$currentWeek',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'OF $totalWeeks WEEKS',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: const Color(0xFFEBDDFF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Size of ${info.sizeComparison}',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 19,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$measurement $daysToGo days to go.',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 14,
                    height: 1.4,
                    color: const Color(0xFFEBDDFF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
