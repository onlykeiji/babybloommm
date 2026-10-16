import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// A bold title with a smaller detail line underneath, used to introduce
/// sections on dashboard screens.
class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: GoogleFonts.nunitoSans(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        detail,
        style: GoogleFonts.nunitoSans(
          fontSize: 14,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    ],
  );
}
