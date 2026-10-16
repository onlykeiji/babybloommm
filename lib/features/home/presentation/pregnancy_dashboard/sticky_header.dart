import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/user_profile_store.dart';
import '../../../../core/widgets/notifications_panel.dart';

/// The pinned greeting/streak/notifications bar at the top of the pregnancy
/// dashboard.
class PregnancyStickyHeader extends StatelessWidget {
  const PregnancyStickyHeader({
    super.key,
    required this.streak,
    required this.currentWeek,
    required this.trimester,
  });

  final int streak;
  final int currentWeek;
  final String trimester;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFEBDCFF),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Image.asset('lib/assets/images/logo.png', fit: BoxFit.contain),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValueListenableBuilder<UserProfile?>(
                valueListenable: ProfileStore.current,
                builder: (context, profile, _) => Text(
                  '${greetingForTime()}, ${firstNameOf(profile?.fullName)}',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Text(
                'Week $currentWeek · $trimester',
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            gradient: AppColors.buttonGradient,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 3),
              Text(
                '$streak',
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => showNotificationsPanel(context),
            tooltip: 'Notifications',
            icon: const Badge(
              smallSize: 8,
              backgroundColor: AppColors.secondary,
              child: Icon(
                Icons.notifications_none_rounded,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
