import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A small gradient card with an icon badge, category tag, title, and meta
/// row — used for the dashboard's lesson carousel and the insights screen's
/// personalized-insight carousel so both read as one visual system.
class HighlightCard extends StatelessWidget {
  const HighlightCard({
    super.key,
    required this.icon,
    required this.category,
    required this.title,
    required this.meta,
    required this.color,
    required this.deep,
    this.metaIcon = Icons.access_time_rounded,
    this.width = 190,
    this.completed = false,
    this.onTap,
  });

  final IconData icon;
  final String category;
  final String title;
  final String meta;
  final IconData metaIcon;
  final Color color;
  final Color deep;
  final double width;
  final VoidCallback? onTap;

  /// Shows a small checkmark badge in the top-right corner — used to mark a
  /// quiz-gated lesson as passed.
  final bool completed;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            width: width,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withValues(alpha: 0.9), deep],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: deep.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.28),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const Spacer(),
                Text(
                  category,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 15,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(metaIcon, color: Colors.white, size: 13),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      if (completed)
        Positioned(
          top: -6,
          right: -6,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: deep.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(Icons.check_circle_rounded, color: deep, size: 20),
          ),
        ),
    ],
  );
}
