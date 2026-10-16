import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_session.dart';
import '../../../core/app_settings_store.dart';
import '../../../core/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/user_profile_store.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/screen_background.dart';
import '../../../core/widgets/stat_chip.dart';
import '../../onboarding/presentation/welcome_screen.dart';
import 'app_navigation.dart';
import 'app_preferences_screen.dart';
import 'baby_care_models.dart';
import 'baby_profile_screen.dart';
import 'bloom_ai_fab.dart';
import 'change_password_screen.dart';
import 'cycle_prediction.dart';
import 'cycle_settings_screen.dart';
import 'daily_log_models.dart';
import 'learn_content.dart';
import 'notifications_settings_screen.dart';
import 'personal_details_screen.dart';
import 'pregnancy_learn_content.dart';
import 'pregnancy_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'support_screens.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    if (DailyLogStore.all.value.isEmpty) DailyLogStore.fetchAll();
  }

  bool get _isPregnancy => AppSession.mode == AppMode.pregnancy;
  bool get _isBabyCare => AppSession.mode == AppMode.babyCare;

  List<({IconData icon, String label, WidgetBuilder? builder})> get _account =>
      [
        (
          icon: Icons.person_outline,
          label: 'Personal details',
          builder: (BuildContext _) => const PersonalDetailsScreen(),
        ),
        (
          icon: Icons.lock_reset_outlined,
          label: 'Change password',
          builder: (BuildContext _) => const ChangePasswordScreen(),
        ),
        if (_isPregnancy)
          (
            icon: Icons.pregnant_woman_outlined,
            label: 'Pregnancy settings',
            builder: (BuildContext _) => const PregnancySettingsScreen(),
          )
        else if (_isBabyCare)
          (
            icon: Icons.child_care_outlined,
            label: 'Baby profile',
            builder: (BuildContext _) => const BabyProfileScreen(),
          )
        else
          (
            icon: Icons.favorite_outline,
            label: 'Cycle & fertility settings',
            builder: (BuildContext _) => const CycleSettingsScreen(),
          ),
        (
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          builder: (BuildContext _) => const NotificationsSettingsScreen(),
        ),
        (
          icon: Icons.lock_outline,
          label: 'Privacy & data',
          builder: (BuildContext _) => const PrivacySettingsScreen(),
        ),
      ];

  List<({IconData icon, String label, WidgetBuilder? builder})> get _support =>
      [
        (
          icon: Icons.help_outline,
          label: 'Help center',
          builder: (_) => const HelpCenterScreen(),
        ),
        (
          icon: Icons.mail_outline,
          label: 'Contact us',
          builder: (_) => const ContactUsScreen(),
        ),
        (
          icon: Icons.star_outline,
          label: 'Rate BabyBloom',
          builder: (_) => const RateBabyBloomScreen(),
        ),
      ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: Stack(
      children: [
        const ScreenBackground(),
        SafeArea(
          child: Column(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: _stickyHeader(context),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _isBabyCare
                              ? ValueListenableBuilder<List<BabyProfile>>(
                                  valueListenable: BabyProfileStore.babies,
                                  builder: (context, babies, _) {
                                    if (babies.isEmpty) return _noBabyCard();
                                    final baby = BabyProfileStore.active;
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _babyStatsRow(baby),
                                        const SizedBox(height: 16),
                                        _babyJourneyCard(baby),
                                      ],
                                    );
                                  },
                                )
                              : ValueListenableBuilder<AppSettings?>(
                                  valueListenable: AppSettingsStore.current,
                                  builder: (context, settings, _) =>
                                      ValueListenableBuilder<List<DailyLog>>(
                                        valueListenable: DailyLogStore.all,
                                        builder: (context, logs, _) {
                                          final week =
                                              settings?.currentPregnancyWeek ??
                                              12;
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _statsRow(week, logs),
                                              const SizedBox(height: 16),
                                              _journeyCard(week, logs),
                                            ],
                                          );
                                        },
                                      ),
                                ),
                          const SizedBox(height: 30),
                          _sectionTitle(
                            'Account',
                            'Manage your details and preferences.',
                          ),
                          const SizedBox(height: 14),
                          _settingsGroup(context, _account),
                          const SizedBox(height: 30),
                          _sectionTitle(
                            'Support',
                            'We are here if you need us.',
                          ),
                          const SizedBox(height: 14),
                          _settingsGroup(context, _support),
                          const SizedBox(height: 30),
                          PrimaryButton(
                            filled: false,
                            label: 'Sign Out',
                            trailingIcon: Icons.logout_rounded,
                            onPressed: () async {
                              final confirmed = await showConfirmDialog(
                                context,
                                title: 'Sign out?',
                                message:
                                    "You'll need to log back in to see your cycles, logs, and settings.",
                                confirmLabel: 'Sign Out',
                                destructive: true,
                              );
                              if (!confirmed || !context.mounted) return;
                              await SupabaseConfig.client.auth.signOut();
                              ProfileStore.current.value = null;
                              AppSession.mode = AppMode.familyPlanning;
                              if (!context.mounted) return;
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const WelcomeScreen(),
                                ),
                                (route) => false,
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              'BabyBloom v1.0.0',
                              style: GoogleFonts.nunitoSans(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              AppBottomNav(
                current: AppTab.profile,
                onSelect: (tab) => goToTab(context, tab),
              ),
            ],
          ),
        ),
        const Positioned(right: 20, bottom: 100, child: BloomAiFab()),
      ],
    ),
  );

  Widget _stickyHeader(BuildContext context) => Container(
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
        ValueListenableBuilder<UserProfile?>(
          valueListenable: ProfileStore.current,
          builder: (context, profile, _) {
            final user = SupabaseConfig.client.auth.currentUser;
            final name = profile?.fullName ?? user?.email ?? 'You';
            final email = profile?.email ?? user?.email ?? '';
            final initials = _initialsOf(name);
            return Expanded(
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: AppColors.buttonGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Text(
                          initials,
                          style: GoogleFonts.nunitoSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.outlineVariant.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 11,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.nunitoSans(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          email,
                          style: GoogleFonts.nunitoSans(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
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
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AppPreferencesScreen()),
            ),
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined, color: AppColors.primary),
          ),
        ),
      ],
    ),
  );

  /// Consecutive days with a `daily_logs` entry, ending today (or yesterday,
  /// if today just hasn't been logged yet — so the streak doesn't zero out
  /// mid-day before the user has a chance to check in).
  int _dayStreak(List<DailyLog> logs) {
    if (logs.isEmpty) return 0;
    final days = logs
        .map((l) => DateTime(l.logDate.year, l.logDate.month, l.logDate.day))
        .toSet();
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);
    if (!days.contains(cursor)) {
      final yesterday = cursor.subtract(const Duration(days: 1));
      if (!days.contains(yesterday)) return 0;
      cursor = yesterday;
    }
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _monthsSinceAccountCreated() {
    final createdAt = SupabaseConfig.client.auth.currentUser?.createdAt;
    final created = createdAt == null ? null : DateTime.tryParse(createdAt);
    if (created == null) return 0;
    final days = DateTime.now().difference(created).inDays;
    return (days / 30.44).floor().clamp(0, 999);
  }

  Widget _statsRow(int pregnancyWeek, List<DailyLog> logs) => Row(
    children: [
      Expanded(
        child: StatChip(
          icon: Icons.local_fire_department_rounded,
          value: '${_dayStreak(logs)}',
          label: 'Day streak',
          color: AppColors.secondaryContainer,
          deep: AppColors.primary,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _isPregnancy
            ? StatChip(
                icon: Icons.pregnant_woman_outlined,
                value: '$pregnancyWeek',
                label: 'Weeks along',
                color: AppColors.lavender,
                deep: AppColors.secondary,
              )
            : StatChip(
                icon: Icons.favorite_outline,
                value: '${CyclePrediction.periodStartDatesFrom(logs).length}',
                label: 'Cycles tracked',
                color: AppColors.lavender,
                deep: AppColors.secondary,
              ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _isPregnancy
            ? ValueListenableBuilder<Set<String>>(
                valueListenable: LearnProgress.completedTitles,
                builder: (context, completed, _) {
                  final done = allPregnancyLearnItems
                      .where((i) => completed.contains(i.title))
                      .length;
                  return StatChip(
                    icon: Icons.menu_book_rounded,
                    value: '$done/${allPregnancyLearnItems.length}',
                    label: 'Lessons done',
                    color: AppColors.lavenderLight,
                    deep: AppColors.primaryContainer,
                  );
                },
              )
            : StatChip(
                icon: Icons.edit_note_rounded,
                value:
                    '${logs.fold<int>(0, (sum, l) => sum + l.symptoms.length)}',
                label: 'Symptoms logged',
                color: AppColors.lavenderLight,
                deep: AppColors.primaryContainer,
              ),
      ),
    ],
  );

  Widget _journeyCard(int currentWeek, List<DailyLog> logs) {
    const totalWeeks = 40;
    final trimester = currentWeek <= 13
        ? 'first'
        : currentWeek <= 27
        ? 'second'
        : 'third';
    final monthsOnJourney = _monthsSinceAccountCreated();
    final progress = _isPregnancy
        ? currentWeek / totalWeeks
        : monthsOnJourney.clamp(0, 12) / 12;
    final bigNumber = _isPregnancy ? '$currentWeek' : '$monthsOnJourney';
    final unitLabel = _isPregnancy ? 'WEEKS' : 'MONTHS';
    final title = _isPregnancy ? 'Pregnancy journey' : 'Trying to Conceive';
    final detail = _isPregnancy
        ? 'You are $currentWeek weeks along, in your $trimester trimester. We are here with you every step.'
        : 'You have been tracking with BabyBloom for $monthsOnJourney ${monthsOnJourney == 1 ? 'month' : 'months'}. We are here with you every step.';

    return _journeyCardShell(
      progress: progress,
      bigNumber: bigNumber,
      unitLabel: unitLabel,
      title: title,
      detail: detail,
    );
  }

  Widget _babyStatsRow(BabyProfile baby) {
    final weightEntries = GrowthLog.forBaby(baby.id, GrowthMetric.weight);
    final latestWeight = weightEntries.isEmpty
        ? '—'
        : '${weightEntries.last.value.toStringAsFixed(1)} lb';
    final achievedCount = MilestoneLog.achieved.value[baby.id]?.length ?? 0;

    return Row(
      children: [
        Expanded(
          child: StatChip(
            icon: Icons.cake_outlined,
            value: babyAgeLabel(baby.dateOfBirth).split(' ').take(2).join(' '),
            label: 'Age',
            color: AppColors.secondaryContainer,
            deep: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatChip(
            icon: Icons.monitor_weight_outlined,
            value: latestWeight,
            label: 'Latest weight',
            color: AppColors.lavender,
            deep: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatChip(
            icon: Icons.emoji_events_outlined,
            value: '$achievedCount/${babyMilestones.length}',
            label: 'Milestones',
            color: AppColors.lavenderLight,
            deep: AppColors.primaryContainer,
          ),
        ),
      ],
    );
  }

  Widget _babyJourneyCard(BabyProfile baby) {
    final ageMonths = babyAgeInMonths(baby.dateOfBirth);
    final ageLabel = babyAgeLabel(baby.dateOfBirth);
    final ageParts = ageLabel.split(' ');
    return _journeyCardShell(
      progress: (ageMonths / 24).clamp(0.0, 1.0),
      bigNumber: ageParts.isNotEmpty ? ageParts.first : '0',
      unitLabel: ageParts.length > 1 ? ageParts[1].toUpperCase() : '',
      title: "${baby.name}'s journey",
      detail: '${baby.name} is $ageLabel. We are here with you every step.',
    );
  }

  Widget _noBabyCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: AppColors.outlineVariant.withValues(alpha: 0.25),
      ),
    ),
    child: Text(
      "Add your baby's profile to see stats here.",
      textAlign: TextAlign.center,
      style: GoogleFonts.nunitoSans(
        fontSize: 13,
        color: AppColors.onSurfaceVariant,
      ),
    ),
  );

  Widget _journeyCardShell({
    required double progress,
    required String bigNumber,
    required String unitLabel,
    required String title,
    required String detail,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.secondary],
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.28),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
      ],
    ),
    child: Row(
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  color: const Color(0xFFD3BBFE),
                  backgroundColor: const Color(0x336D5B8F),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    bigNumber,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    unitLabel,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: const Color(0xFFEBDDFF),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.nunitoSans(
                  fontSize: 19,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                detail,
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  height: 1.4,
                  color: const Color(0xFFEBDDFF),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _sectionTitle(String title, String detail) => Column(
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

  Widget _settingsGroup(
    BuildContext context,
    List<({IconData icon, String label, WidgetBuilder? builder})> items,
  ) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: AppColors.outlineVariant.withValues(alpha: 0.25),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        return Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  if (item.builder != null) {
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: item.builder!));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item.label} is coming soon.')),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD3BBFE),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.icon,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.label,
                          style: GoogleFonts.nunitoSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.primary.withValues(alpha: 0.6),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (index != items.length - 1)
              Divider(
                height: 1,
                indent: 12,
                endIndent: 12,
                color: AppColors.outlineVariant.withValues(alpha: 0.25),
              ),
          ],
        );
      }),
    ),
  );

  String _initialsOf(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
