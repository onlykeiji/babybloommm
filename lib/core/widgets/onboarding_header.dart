import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// The card-style step header shared by every onboarding screen: an
/// optional brand row with a skip action, plus a "STEP X OF N" progress bar.
class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({
    super.key,
    required this.step,
    required this.totalSteps,
    this.onSkip,
    this.showBrand = true,
  });

  final int step;
  final int totalSteps;
  final VoidCallback? onSkip;
  final bool showBrand;

  @override
  Widget build(BuildContext context) {
    final progress = step / totalSteps;
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      child: Column(
        children: [
          if (showBrand) ...[
            Row(
              children: [
                const Icon(
                  Icons.spa_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'BabyBloom',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                if (onSkip != null)
                  TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'SKIP',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: AppColors.primary.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STEP $step OF $totalSteps',
                style: GoogleFonts.nunitoSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  color: AppColors.primary.withValues(alpha: 0.6),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: GoogleFonts.nunitoSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: AppColors.secondary,
              backgroundColor: const Color(0x33CBC4CE),
            ),
          ),
        ],
      ),
    );
  }
}
