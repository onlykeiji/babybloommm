import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// A small purple-tinted stat card used in header rows across main screens.
class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.deep,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color deep;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.08)],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: deep, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.nunitoSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.nunitoSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}
