import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_session.dart';
import '../theme/app_colors.dart';

enum AppTab {
  today('Home', Icons.home_outlined, Icons.home_rounded),
  cycle('Cycle', Icons.calendar_month_outlined, Icons.calendar_month_rounded),
  community('Community', Icons.groups_outlined, Icons.groups_rounded),
  insights('Insights', Icons.insights_outlined, Icons.insights_rounded),
  profile('Profile', Icons.person_outline, Icons.person_rounded);

  const AppTab(this.label, this.icon, this.activeIcon);

  final String label;
  final IconData icon;
  final IconData activeIcon;

  /// Label/icon shown for this tab, adjusted for the user's [AppSession.mode]
  /// — e.g. the "Cycle" tab becomes "Journey" for pregnancy users and "Grow"
  /// for baby-care users, since a menstrual-cycle tracker doesn't apply.
  String get displayLabel {
    if (this != AppTab.cycle) return label;
    return switch (AppSession.mode) {
      AppMode.pregnancy => 'Journey',
      AppMode.babyCare => 'Grow',
      AppMode.familyPlanning => label,
    };
  }

  IconData get displayIcon {
    if (this != AppTab.cycle) return icon;
    return switch (AppSession.mode) {
      AppMode.pregnancy => Icons.pregnant_woman_outlined,
      AppMode.babyCare => Icons.child_care_outlined,
      AppMode.familyPlanning => icon,
    };
  }

  IconData get displayActiveIcon {
    if (this != AppTab.cycle) return activeIcon;
    return switch (AppSession.mode) {
      AppMode.pregnancy => Icons.pregnant_woman_rounded,
      AppMode.babyCare => Icons.child_care_rounded,
      AppMode.familyPlanning => activeIcon,
    };
  }
}

/// The floating pill nav bar shared by every main-tab screen.
///
/// Screens pass their own [current] tab; [onSelect] is only called for a tab
/// other than [current], so screens don't need to guard against re-taps.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final AppTab current;
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.6),
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: AppTab.values.map(_navItem).toList(),
      ),
    ),
  );

  Widget _navItem(AppTab tab) {
    final selected = tab == current;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: selected ? null : () => onSelect(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: EdgeInsets.symmetric(
            vertical: selected ? 10 : 8,
            horizontal: 4,
          ),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.buttonGradient : null,
            borderRadius: BorderRadius.circular(18),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? tab.displayActiveIcon : tab.displayIcon,
                color: selected ? Colors.white : AppColors.onSurfaceVariant,
                size: 21,
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.nunitoSans(
                  fontSize: selected ? 11 : 10,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? Colors.white : AppColors.onSurfaceVariant,
                ),
                child: Text(
                  tab.displayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
