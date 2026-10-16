import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../baby_names_screen.dart';
import '../contraction_timer_screen.dart';
import '../hospital_bag_screen.dart';

/// Grid of quick-access pregnancy tools (contraction timer, hospital bag,
/// and baby names).
class PregnancyToolkitGrid extends StatelessWidget {
  const PregnancyToolkitGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = [
      (
        label: 'Contraction timer',
        icon: Icons.timer_outlined,
        builder: (BuildContext _) => const ContractionTimerScreen(),
      ),
      (
        label: 'Hospital bag',
        icon: Icons.luggage_outlined,
        builder: (BuildContext _) => const HospitalBagScreen(),
      ),
      (
        label: 'Baby names',
        icon: Icons.badge_outlined,
        builder: (BuildContext _) => const BabyNamesScreen(),
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tools.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemBuilder: (context, index) {
        final tool = tools[index];
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: tool.builder)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD3BBFE),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(tool.icon, color: AppColors.primary, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tool.label,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
