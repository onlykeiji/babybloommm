import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'chatbot_screen.dart';

/// The floating chat bubble shown on every main-tab screen, opening Bloom AI.
class BloomAiFab extends StatelessWidget {
  const BloomAiFab({super.key});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Ask Bloom AI',
    child: GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ChatbotScreen())),
      child: Container(
        width: 58,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: AppColors.buttonGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(
          Icons.auto_awesome_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    ),
  );
}
