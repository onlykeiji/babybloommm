import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The gradient + blurred-blob backdrop shared by every main-tab screen.
class ScreenBackground extends StatelessWidget {
  const ScreenBackground({super.key});

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      ),
      _blob(top: -90, right: -100, size: 260, color: AppColors.secondary),
      _blob(top: 420, left: -140, size: 300, color: AppColors.lavender),
    ],
  );

  static Widget _blob({
    double? top,
    double? right,
    double? left,
    required double size,
    required Color color,
  }) => Positioned(
    top: top,
    right: right,
    left: left,
    child: IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
        ),
      ),
    ),
  );
}
