import 'package:flutter/material.dart';

import '../../../core/app_session.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import 'baby_growth_screen.dart';
import 'baby_care_models.dart';
import 'baby_profile_screen.dart';
import 'community_screen.dart';
import 'cycle_screen.dart';
import 'insights_screen.dart';
import 'pregnancy_journey_screen.dart';
import 'profile_screen.dart';

/// Switches to [tab] from any main-tab screen.
///
/// Always collapses the stack back to the dashboard root first, so tabs
/// never pile up (Cycle -> Insights -> Cycle -> ...) — the nav bar's back
/// behavior stays predictable no matter which tab you started from.
void goToTab(BuildContext context, AppTab tab) {
  // Capture the navigator before popping. The supplied context can belong to
  // a route that popUntil disposes, so looking up Navigator from that context
  // again can trigger framework.dart's `_dependents.isEmpty` assertion.
  final navigator = Navigator.of(context);
  navigator.popUntil((route) => route.isFirst);
  switch (tab) {
    case AppTab.today:
      break;
    case AppTab.cycle:
      navigator.push(
        MaterialPageRoute(
          builder: (_) => switch (AppSession.mode) {
            AppMode.pregnancy => const PregnancyJourneyScreen(),
            AppMode.babyCare =>
              BabyProfileStore.babies.value.isEmpty
                  ? const BabyProfileScreen()
                  : const BabyGrowthScreen(),
            AppMode.familyPlanning => const CycleScreen(),
          },
        ),
      );
    case AppTab.community:
      navigator.push(
        MaterialPageRoute(builder: (_) => const CommunityScreen()),
      );
    case AppTab.insights:
      navigator.push(MaterialPageRoute(builder: (_) => const InsightsScreen()));
    case AppTab.profile:
      navigator.push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }
}
