import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/app_settings_store.dart';
import 'core/supabase_config.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_scroll_behavior.dart';
import 'core/user_profile_store.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/home/presentation/baby_care_models.dart';
import 'features/home/presentation/daily_log_models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  try {
    await BabyProfileStore.fetchAll();
  } catch (_) {
    // No network / bad config on first launch — screens that read
    // BabyProfileStore.active will show once a retry succeeds.
  }
  try {
    await AppSettingsStore.fetch();
  } catch (_) {
    // Settings screens will retry loading themselves when opened.
  }
  try {
    await ProfileStore.fetchCurrent();
  } catch (_) {
    // No session yet, or offline — restored once the user logs in.
  }
  try {
    await DailyLogStore.fetchAll();
  } catch (_) {
    // Cycle predictions will retry loading themselves when a relevant
    // screen opens.
  }
  runApp(const BabyBloomApp());
}

class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

class BabyBloomApp extends StatelessWidget {
  const BabyBloomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BabyBloom',
      debugShowCheckedModeBanner: false,
      scrollBehavior: AppScrollBehavior(),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        textTheme: GoogleFonts.nunitoSansTextTheme(),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: NoTransitionsBuilder(),
            TargetPlatform.iOS: NoTransitionsBuilder(),
            TargetPlatform.windows: NoTransitionsBuilder(),
            TargetPlatform.macOS: NoTransitionsBuilder(),
            TargetPlatform.linux: NoTransitionsBuilder(),
          },
        ),
      ),
      home: const AuthGate(),
    );
  }
}
