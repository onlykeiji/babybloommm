import 'package:flutter/material.dart';

import '../../../core/app_session.dart';
import '../../../core/supabase_config.dart';
import '../../../core/user_profile_store.dart';
import '../../home/presentation/baby_care_dashboard.dart';
import '../../home/presentation/family_planning_dashboard.dart';
import '../../home/presentation/pregnancy_dashboard.dart';
import '../../onboarding/presentation/journey_stage_screen.dart';
import '../../onboarding/presentation/welcome_screen.dart';
import 'email_verification_screen.dart';

/// Decides what the user sees on cold start, based on their real Supabase
/// session — this is the access gate that keeps unverified accounts out.
///
/// - No session at all -> [WelcomeScreen] (sign up / log in).
/// - Signed in but the email hasn't been confirmed yet -> blocked on
///   [EmailVerificationScreen] (which still offers resend + logout). This
///   only matters if a project has "Confirm email" turned off *after*
///   already issuing sessions; normally Supabase won't hand out a session
///   pre-confirmation at all, so login is already gated at the source.
/// - Verified session with a remembered app mode -> straight to that
///   dashboard, skipping onboarding.
/// - Verified session with no app mode yet -> the onboarding quiz.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SupabaseConfig.client.auth.currentUser;

    if (user == null) {
      return const WelcomeScreen();
    }

    if (user.emailConfirmedAt == null) {
      return EmailVerificationScreen(email: user.email ?? '');
    }

    final mode = ProfileStore.current.value?.appMode;
    return switch (mode) {
      AppMode.pregnancy => const PregnancyDashboard(),
      AppMode.babyCare => const BabyCareDashboard(),
      AppMode.familyPlanning => const FamilyPlanningDashboard(),
      null => const JourneyStageScreen(),
    };
  }
}
