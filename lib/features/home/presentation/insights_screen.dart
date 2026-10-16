import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_session.dart';
import '../../../core/app_settings_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/highlight_card.dart';
import '../../../core/widgets/notifications_panel.dart';
import '../../../core/widgets/screen_background.dart';
import '../../../core/widgets/stat_chip.dart';
import 'app_navigation.dart';
import 'baby_care_models.dart';
import 'baby_daily_care_models.dart';
import 'baby_daily_care_screen.dart';
import 'bloom_ai_fab.dart';
import 'daily_log_models.dart';
import 'insights_data.dart';
import 'insights_report_screen.dart';

const _monthAbbrev = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const _weekdayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

const _moodStyles = {
  'Great': (
    icon: Icons.sentiment_very_satisfied_rounded,
    color: AppColors.primary,
  ),
  'Good': (
    icon: Icons.sentiment_satisfied_alt_rounded,
    color: AppColors.secondary,
  ),
  'Okay': (icon: Icons.sentiment_neutral_rounded, color: AppColors.lavender),
  'Low': (
    icon: Icons.sentiment_dissatisfied_rounded,
    color: AppColors.lavenderLight,
  ),
  'Anxious': (
    icon: Icons.sentiment_very_dissatisfied_rounded,
    color: AppColors.primaryContainer,
  ),
};
const _noMoodStyle = (
  icon: Icons.remove_rounded,
  color: AppColors.outlineVariant,
);

const _insightStyles = {
  'Regularity': (
    icon: Icons.verified_outlined,
    metaIcon: Icons.check_circle_outline_rounded,
    color: AppColors.primary,
    deep: AppColors.secondary,
  ),
  'Luteal phase': (
    icon: Icons.nightlight_outlined,
    metaIcon: Icons.bar_chart_rounded,
    color: AppColors.secondary,
    deep: AppColors.lavenderLight,
  ),
  'Symptoms': (
    icon: Icons.healing_outlined,
    metaIcon: Icons.bar_chart_rounded,
    color: AppColors.lavenderLight,
    deep: AppColors.lavender,
  ),
  'Tip': (
    icon: Icons.auto_awesome_outlined,
    metaIcon: Icons.bolt_rounded,
    color: AppColors.primaryContainer,
    deep: AppColors.primary,
  ),
  'Feeding': (
    icon: Icons.restaurant_outlined,
    metaIcon: Icons.schedule_rounded,
    color: AppColors.secondaryContainer,
    deep: AppColors.primary,
  ),
  'Sleep': (
    icon: Icons.nightlight_round,
    metaIcon: Icons.bedtime_outlined,
    color: AppColors.lavender,
    deep: AppColors.secondary,
  ),
  'Diapers': (
    icon: Icons.baby_changing_station_outlined,
    metaIcon: Icons.check_circle_outline_rounded,
    color: AppColors.lavenderLight,
    deep: AppColors.primary,
  ),
  'Care tip': (
    icon: Icons.child_friendly_rounded,
    metaIcon: Icons.auto_awesome_rounded,
    color: AppColors.primaryContainer,
    deep: AppColors.primary,
  ),
};

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  bool get _isPregnancy => AppSession.mode == AppMode.pregnancy;
  bool get _isBabyCare => AppSession.mode == AppMode.babyCare;

  @override
  void initState() {
    super.initState();
    if (AppSettingsStore.current.value == null) AppSettingsStore.fetch();
    if (DailyLogStore.all.value.isEmpty) DailyLogStore.fetchAll();
    if (_isBabyCare) {
      _loadBabyCareData();
      BabyProfileStore.activeBabyId.addListener(_loadActiveBabyLogs);
    }
  }

  Future<void> _loadBabyCareData() async {
    if (BabyProfileStore.babies.value.isEmpty) {
      await BabyProfileStore.fetchAll();
    }
    _loadActiveBabyLogs();
  }

  void _loadActiveBabyLogs() {
    if (BabyProfileStore.babies.value.isNotEmpty) {
      final babyId = BabyProfileStore.active.id;
      BabyCareLogStore.fetchForBaby(babyId);
      GrowthLog.fetchForBaby(babyId);
      MilestoneLog.fetchForBaby(babyId);
    }
  }

  @override
  void dispose() {
    BabyProfileStore.activeBabyId.removeListener(_loadActiveBabyLogs);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _isBabyCare
      ? _babyCareInsightsScreen()
      : ValueListenableBuilder<AppSettings?>(
          valueListenable: AppSettingsStore.current,
          builder: (context, settings, _) => ValueListenableBuilder<List<DailyLog>>(
            valueListenable: DailyLogStore.all,
            builder: (context, logs, _) {
              final data = InsightsData.compute(logs, settings);
              return Scaffold(
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
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                16,
                                20,
                                24,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 720,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _statsRow(data, logs),
                                      const SizedBox(height: 16),
                                      _summaryCard(data, logs),
                                      const SizedBox(height: 30),
                                      _sectionTitle(
                                        _isPregnancy
                                            ? 'Pregnancy check-ins'
                                            : 'Cycle length trend',
                                        _isPregnancy
                                            ? 'Your recent daily check-in activity.'
                                            : 'Your last ${data.cycleLengthTrend.length} cycles, in days.',
                                      ),
                                      const SizedBox(height: 14),
                                      _isPregnancy
                                          ? _pregnancyCheckInCard(logs)
                                          : _trendCard(data),
                                      const SizedBox(height: 30),
                                      _sectionTitle(
                                        'Top symptoms',
                                        'How often you logged each in the last 30 days.',
                                      ),
                                      const SizedBox(height: 14),
                                      _symptomsCard(data),
                                      const SizedBox(height: 30),
                                      _sectionTitle(
                                        'Mood this week',
                                        'How you have been feeling day to day.',
                                      ),
                                      const SizedBox(height: 14),
                                      _moodStrip(data),
                                      const SizedBox(height: 30),
                                      _sectionTitle(
                                        'Personalized for you',
                                        'Patterns we noticed in your logs.',
                                      ),
                                      const SizedBox(height: 14),
                                      _insightsCarousel(
                                        data,
                                        isPregnancy: _isPregnancy,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          AppBottomNav(
                            current: AppTab.insights,
                            onSelect: (tab) => goToTab(context, tab),
                          ),
                        ],
                      ),
                    ),
                    const Positioned(
                      right: 20,
                      bottom: 100,
                      child: BloomAiFab(),
                    ),
                  ],
                ),
              );
            },
          ),
        );

  Widget _babyCareInsightsScreen() => ValueListenableBuilder<List<BabyProfile>>(
    valueListenable: BabyProfileStore.babies,
    builder: (context, babies, _) => ListenableBuilder(
      listenable: Listenable.merge([
        BabyCareLogStore.entries,
        GrowthLog.entries,
        MilestoneLog.achieved,
      ]),
      builder: (context, _) {
        final entries = BabyCareLogStore.entries.value;
        final baby = babies.isEmpty ? null : BabyProfileStore.active;
        final babyEntries = baby == null
            ? const <BabyCareLog>[]
            : entries.where((entry) => entry.babyId == baby.id).toList();
        return Scaffold(
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
                            child: baby == null
                                ? _emptyCard(
                                    'Add a baby profile to start building baby-care insights.',
                                  )
                                : _babyCareContent(baby, babyEntries),
                          ),
                        ),
                      ),
                    ),
                    AppBottomNav(
                      current: AppTab.insights,
                      onSelect: (tab) => goToTab(context, tab),
                    ),
                  ],
                ),
              ),
              const Positioned(right: 20, bottom: 100, child: BloomAiFab()),
            ],
          ),
        );
      },
    ),
  );

  Widget _babyCareContent(BabyProfile baby, List<BabyCareLog> entries) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 6));
    final todayEntries = entries
        .where((entry) => !entry.occurredAt.isBefore(today))
        .toList();
    final weekEntries = entries
        .where((entry) => !entry.occurredAt.isBefore(weekStart))
        .toList();
    int count(BabyCareLogKind kind, List<BabyCareLog> source) =>
        source.where((entry) => entry.kind == kind).length;
    final feedsToday = count(BabyCareLogKind.feeding, todayEntries);
    final diapersToday = count(BabyCareLogKind.diaper, todayEntries);
    final sleepMinutesToday = todayEntries
        .where((entry) => entry.kind == BabyCareLogKind.sleep)
        .fold<int>(0, (sum, entry) => sum + (entry.durationMinutes ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: StatChip(
                icon: Icons.restaurant_outlined,
                value: '$feedsToday',
                label: 'Feeds today',
                color: AppColors.secondaryContainer,
                deep: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatChip(
                icon: Icons.baby_changing_station_outlined,
                value: '$diapersToday',
                label: 'Diapers today',
                color: AppColors.lavender,
                deep: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatChip(
                icon: Icons.nightlight_round,
                value: _durationLabel(sleepMinutesToday),
                label: 'Sleep today',
                color: AppColors.lavenderLight,
                deep: AppColors.primaryContainer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _babySummaryCard(baby, todayEntries.length, weekEntries.length),
        const SizedBox(height: 30),
        _sectionTitle(
          '${baby.name}\'s care this week',
          'A seven-day view based on the care activities you logged.',
        ),
        const SizedBox(height: 14),
        _babyWeeklyCareCard(weekEntries),
        const SizedBox(height: 30),
        _sectionTitle(
          'All logged inputs',
          'Care, growth, and milestone information in one overview.',
        ),
        const SizedBox(height: 14),
        _babyInputOverview(baby, entries),
        const SizedBox(height: 30),
        _sectionTitle(
          'Personalized for ${baby.name}',
          'Patterns and reminders based only on ${baby.name}\'s care logs.',
        ),
        const SizedBox(height: 14),
        _babyInsightsCarousel(baby, entries, weekEntries),
      ],
    );
  }

  Widget _babySummaryCard(
    BabyProfile baby,
    int todayCount,
    int weekCount,
  ) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.secondary],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          todayCount == 0
              ? 'Start ${baby.name}\'s care log for today'
              : '$todayCount care ${todayCount == 1 ? 'activity' : 'activities'} logged today',
          style: GoogleFonts.nunitoSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          weekCount == 0
              ? 'Log feeding, diapers, and sleep to see useful patterns here.'
              : '$weekCount total activities in the last 7 days · ${babyAgeLabel(baby.dateOfBirth)}',
          style: GoogleFonts.nunitoSans(
            fontSize: 13,
            color: Colors.white.withValues(alpha: .86),
          ),
        ),
      ],
    ),
  );

  Widget _babyInputOverview(BabyProfile baby, List<BabyCareLog> entries) {
    final feeds = entries
        .where((e) => e.kind == BabyCareLogKind.feeding)
        .toList();
    final diapers = entries
        .where((e) => e.kind == BabyCareLogKind.diaper)
        .toList();
    final sleeps = entries
        .where((e) => e.kind == BabyCareLogKind.sleep)
        .toList();
    final totalMilk = feeds.fold<double>(0, (sum, e) => sum + (e.amount ?? 0));
    final totalSleep = sleeps.fold<int>(
      0,
      (sum, e) => sum + (e.durationMinutes ?? 0),
    );
    final weights = GrowthLog.forBaby(baby.id, GrowthMetric.weight);
    final heights = GrowthLog.forBaby(baby.id, GrowthMetric.height);
    final headSizes = GrowthLog.forBaby(
      baby.id,
      GrowthMetric.headCircumference,
    );
    final achieved = babyMilestones
        .where((m) => MilestoneLog.isMilestoneAchieved(baby.id, m))
        .length;
    final rows = <({IconData icon, String label, String value})>[
      (
        icon: Icons.restaurant_outlined,
        label: 'Feeding logs',
        value: totalMilk > 0
            ? '${feeds.length} · ${totalMilk.toStringAsFixed(0)} ml'
            : '${feeds.length}',
      ),
      (
        icon: Icons.baby_changing_station_outlined,
        label: 'Diaper logs',
        value: '${diapers.length}',
      ),
      (
        icon: Icons.nightlight_round,
        label: 'Sleep logs',
        value: totalSleep > 0
            ? '${sleeps.length} · ${_durationLabel(totalSleep)}'
            : '${sleeps.length}',
      ),
      (
        icon: Icons.monitor_weight_outlined,
        label: 'Latest weight',
        value: weights.isEmpty
            ? 'Not logged'
            : '${weights.last.value.toStringAsFixed(1)} lb',
      ),
      (
        icon: Icons.height_rounded,
        label: 'Latest height',
        value: heights.isEmpty
            ? 'Not logged'
            : '${heights.last.value.toStringAsFixed(1)} in',
      ),
      (
        icon: Icons.straighten_rounded,
        label: 'Head circumference',
        value: headSizes.isEmpty
            ? 'Not logged'
            : '${headSizes.last.value.toStringAsFixed(1)} in',
      ),
      (
        icon: Icons.emoji_events_outlined,
        label: 'Milestones reached',
        value: '$achieved/${babyMilestones.length}',
      ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: .25),
        ),
      ),
      child: Column(
        children: List.generate(rows.length, (index) {
          final row = rows[index];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(row.icon, size: 20, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        row.label,
                        style: GoogleFonts.nunitoSans(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      row.value,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (index != rows.length - 1)
                Divider(
                  height: 1,
                  color: AppColors.outlineVariant.withValues(alpha: .2),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _babyWeeklyCareCard(List<BabyCareLog> entries) {
    final groups = [
      (BabyCareLogKind.feeding, AppColors.primary),
      (BabyCareLogKind.diaper, AppColors.secondary),
      (BabyCareLogKind.sleep, AppColors.lavender),
    ];
    if (entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .78),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: .25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start with one activity',
              style: GoogleFonts.nunitoSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Log a feed, diaper change, or sleep session. After several entries, this screen summarizes daily counts, amounts, durations, and seven-day routines.',
              style: GoogleFonts.nunitoSans(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: BabyCareLogKind.values
                  .map(
                    (kind) => ActionChip(
                      avatar: Icon(
                        kind.icon,
                        size: 17,
                        color: AppColors.primary,
                      ),
                      label: Text('Log ${kind.label.toLowerCase()}'),
                      onPressed: () => _openBabyCareLogger(kind),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .76),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: .25),
        ),
      ),
      child: Column(
        children: groups.map((group) {
          final kind = group.$1;
          final count = entries.where((entry) => entry.kind == kind).length;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(kind.icon, color: group.$2),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    kind.label,
                    style: GoogleFonts.nunitoSans(
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                Text(
                  '$count ${count == 1 ? 'log' : 'logs'}',
                  style: GoogleFonts.nunitoSans(
                    fontWeight: FontWeight.w800,
                    color: group.$2,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _babyInsightsCarousel(
    BabyProfile baby,
    List<BabyCareLog> allEntries,
    List<BabyCareLog> weekEntries,
  ) {
    final feeds = weekEntries
        .where((entry) => entry.kind == BabyCareLogKind.feeding)
        .toList();
    final diapers = weekEntries
        .where((entry) => entry.kind == BabyCareLogKind.diaper)
        .toList();
    final sleeps = weekEntries
        .where((entry) => entry.kind == BabyCareLogKind.sleep)
        .toList();
    final sleepMinutes = sleeps.fold<int>(
      0,
      (sum, entry) => sum + (entry.durationMinutes ?? 0),
    );
    final items = <PersonalizedInsight>[
      if (feeds.isNotEmpty)
        PersonalizedInsight(
          category: 'Feeding',
          title: '${feeds.length} feedings logged over the last 7 days',
          meta: 'For ${baby.name}',
        ),
      if (sleeps.isNotEmpty)
        PersonalizedInsight(
          category: 'Sleep',
          title: sleepMinutes > 0
              ? '${_durationLabel(sleepMinutes)} of logged sleep this week'
              : '${sleeps.length} sleep sessions logged this week',
          meta: 'From ${sleeps.length} sleep logs',
        ),
      if (diapers.isNotEmpty)
        PersonalizedInsight(
          category: 'Diapers',
          title: '${diapers.length} diaper changes logged this week',
          meta: 'For ${baby.name}',
        ),
      PersonalizedInsight(
        category: 'Care tip',
        title: allEntries.isEmpty
            ? 'Log care activities to reveal ${baby.name}\'s routine'
            : 'Consistent logging makes routine changes easier to notice',
        meta: babyAgeLabel(baby.dateOfBirth),
      ),
    ];
    return SizedBox(
      height: 178,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final style = _insightStyles[item.category]!;
          return HighlightCard(
            icon: style.icon,
            category: item.category.toUpperCase(),
            title: item.title,
            meta: item.meta,
            metaIcon: style.metaIcon,
            color: style.color,
            deep: style.deep,
            onTap: () => _openBabyCareLogger(switch (item.category) {
              'Sleep' => BabyCareLogKind.sleep,
              'Diapers' => BabyCareLogKind.diaper,
              _ => BabyCareLogKind.feeding,
            }),
          );
        },
      ),
    );
  }

  void _openBabyCareLogger(BabyCareLogKind kind) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => BabyDailyCareScreen(initialKind: kind),
          ),
        )
        .then((_) {
          final baby = BabyProfileStore.active;
          BabyCareLogStore.fetchForBaby(baby.id);
        });
  }

  String _durationLabel(int minutes) {
    if (minutes <= 0) return '0m';
    if (minutes < 60) return '${minutes}m';
    final remaining = minutes % 60;
    return remaining == 0
        ? '${minutes ~/ 60}h'
        : '${minutes ~/ 60}h ${remaining}m';
  }

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
        Container(
          width: 44,
          height: 44,
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
              Text(
                'Your insights',
                style: GoogleFonts.nunitoSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                _isBabyCare
                    ? 'Patterns from your baby-care logs'
                    : _isPregnancy
                    ? 'Patterns from your pregnancy check-ins'
                    : 'Patterns from your logged cycles',
                style: GoogleFonts.nunitoSans(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (!_isBabyCare)
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const InsightsReportScreen()),
            ),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    Icons.ios_share_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Share',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
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

  Widget _statsRow(InsightsData data, List<DailyLog> logs) => Row(
    children: [
      Expanded(
        child: StatChip(
          icon: _isPregnancy
              ? Icons.calendar_today_rounded
              : Icons.verified_outlined,
          value: _isPregnancy
              ? '${logs.length}'
              : data.regularityPct != null
              ? '${data.regularityPct}%'
              : '—',
          label: _isPregnancy ? 'Check-ins' : 'Regularity',
          color: AppColors.secondaryContainer,
          deep: AppColors.primary,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: StatChip(
          icon: Icons.edit_note_rounded,
          value: '${data.totalSymptomsLogged}',
          label: 'Symptoms logged',
          color: AppColors.lavender,
          deep: AppColors.secondary,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: StatChip(
          icon: _isPregnancy
              ? Icons.pregnant_woman_rounded
              : Icons.track_changes_rounded,
          value: _isPregnancy
              ? '${AppSettingsStore.current.value?.currentPregnancyWeek ?? 0}'
              : data.variabilityDays != null
              ? '±${data.variabilityDays}d'
              : '—',
          label: _isPregnancy ? 'Pregnancy week' : 'Cycle variability',
          color: AppColors.lavenderLight,
          deep: AppColors.primaryContainer,
        ),
      ),
    ],
  );

  Widget _summaryCard(InsightsData data, List<DailyLog> logs) {
    if (_isPregnancy) return _pregnancySummaryCard(logs);
    final pct = data.regularityPct;
    final (title, subtitle) = pct == null
        ? (
            'Track 2+ cycles to see your regularity',
            'Log your period in Cycle to start building insights here.',
          )
        : pct >= 80
        ? (
            'Your cycles are highly regular',
            'Length varied by up to ${data.variabilityDays} days over your last ${data.cycleLengthTrend.length} cycles.',
          )
        : pct >= 50
        ? (
            'Your cycles are fairly regular',
            'Length varied by up to ${data.variabilityDays} days over your last ${data.cycleLengthTrend.length} cycles.',
          )
        : (
            'Your cycles vary quite a bit',
            'Length varied by up to ${data.variabilityDays} days over your last ${data.cycleLengthTrend.length} cycles.',
          );

    return Container(
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
                    value: (pct ?? 0) / 100,
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
                      pct != null ? '$pct%' : '—',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      pct == null
                          ? 'NO DATA'
                          : pct >= 80
                          ? 'REGULAR'
                          : pct >= 50
                          ? 'VARIED'
                          : 'IRREGULAR',
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
                  subtitle,
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
  }

  Widget _pregnancySummaryCard(List<DailyLog> logs) {
    final streak = dayStreak(logs);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  streak == 0
                      ? 'Start your pregnancy check-ins'
                      : streak == 1
                      ? 'Checked in today'
                      : '$streak-day check-in streak',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 19,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  streak == 0
                      ? 'Track symptoms and how you feel to spot meaningful patterns over time.'
                      : 'Keep it going — consistent check-ins sharpen the patterns below.',
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
  }

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

  Widget _emptyCard(String message) => Container(
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
      message,
      textAlign: TextAlign.center,
      style: GoogleFonts.nunitoSans(
        fontSize: 13,
        color: AppColors.onSurfaceVariant,
      ),
    ),
  );

  Widget _trendCard(InsightsData data) {
    if (data.cycleLengthTrend.isEmpty) {
      return _emptyCard(
        'Log at least 2 periods to see your cycle length trend.',
      );
    }
    final minDays = data.cycleLengthTrend
        .map((c) => c.days)
        .reduce((a, b) => a < b ? a : b);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: data.cycleLengthTrend.map((c) {
          final latest = c == data.cycleLengthTrend.last;
          final barHeight = 36.0 + (c.days - minDays) * 20.0;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${c.days}',
                style: GoogleFonts.nunitoSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 26,
                height: barHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: latest
                        ? [AppColors.primary, AppColors.secondary]
                        : [AppColors.lavender, AppColors.lavenderLight],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _monthAbbrev[c.start.month - 1],
                style: GoogleFonts.nunitoSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _pregnancyCheckInCard(List<DailyLog> logs) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final recentCount = logs
        .where((log) => !log.logDate.isBefore(cutoff))
        .length;
    return _emptyCard(
      recentCount == 0
          ? 'Log symptoms in your daily pregnancy check-ins to see patterns here.'
          : '$recentCount check-in${recentCount == 1 ? '' : 's'} logged in the last 7 days.',
    );
  }

  Widget _symptomsCard(InsightsData data) {
    if (data.topSymptoms.isEmpty) {
      return _emptyCard(
        'Log symptoms in your daily check-ins to see patterns here.',
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        children: data.topSymptoms.map((s) {
          final last = s == data.topSymptoms.last;
          return Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.label,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      '${(s.pct * 100).round()}%',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Stack(
                    children: [
                      Container(
                        height: 10,
                        color: AppColors.outlineVariant.withValues(alpha: 0.2),
                      ),
                      FractionallySizedBox(
                        widthFactor: s.pct.clamp(0, 1),
                        child: Container(
                          height: 10,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _moodStrip(InsightsData data) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
    child: Row(
      children: data.moodWeek
          .map(
            (m) => Expanded(
              child: Column(
                children: [
                  Text(
                    _weekdayInitials[m.date.weekday - 1],
                    style: GoogleFonts.nunitoSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          (m.mood != null ? _moodStyles[m.mood] : null)
                              ?.color ??
                          _noMoodStyle.color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      (m.mood != null ? _moodStyles[m.mood] : null)?.icon ??
                          _noMoodStyle.icon,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    ),
  );

  Widget _insightsCarousel(InsightsData data, {required bool isPregnancy}) {
    final insights = isPregnancy
        ? data.personalizedInsights
              .where(
                (insight) =>
                    insight.category == 'Symptoms' || insight.category == 'Tip',
              )
              .toList()
        : data.personalizedInsights;
    if (insights.isEmpty) {
      return _emptyCard('Keep logging — patterns will show up here.');
    }
    return SizedBox(
      height: 178,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: insights.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = insights[index];
          final style = _insightStyles[item.category]!;
          return HighlightCard(
            icon: style.icon,
            category: item.category.toUpperCase(),
            title: item.title,
            meta: item.meta,
            metaIcon: style.metaIcon,
            color: style.color,
            deep: style.deep,
          );
        },
      ),
    );
  }
}
