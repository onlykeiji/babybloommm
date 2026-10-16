import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

/// Tap-to-count kick tracker card.
class PregnancyKickCounterCard extends StatelessWidget {
  const PregnancyKickCounterCard({
    super.key,
    required this.kickCount,
    required this.saving,
    required this.onIncrement,
    required this.onReset,
  });

  final int kickCount;
  final bool saving;
  final VoidCallback onIncrement;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kicks today',
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$kickCount',
                style: GoogleFonts.nunitoSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Visibility(
                visible: kickCount > 0,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: GestureDetector(
                  onTap: saving ? null : onReset,
                  child: Text(
                    'Reset',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: saving ? null : onIncrement,
            customBorder: const CircleBorder(),
            child: Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.buttonGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
            ),
          ),
        ),
      ],
    ),
  );
}
