import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/notifications_panel.dart';
import '../../../core/widgets/screen_background.dart';
import '../../../core/widgets/stat_chip.dart';
import 'app_navigation.dart';
import 'baby_care_models.dart';
import 'baby_daily_care_models.dart';
import 'baby_daily_care_screen.dart';
import 'baby_growth_screen.dart';
import 'baby_profile_screen.dart';
import 'bloom_ai_fab.dart';
import 'reminders_health_screen.dart';

class BabyCareDashboard extends StatefulWidget {
  const BabyCareDashboard({super.key});

  @override
  State<BabyCareDashboard> createState() => _BabyCareDashboardState();
}

class _BabyCareDashboardState extends State<BabyCareDashboard> {
  @override
  void initState() {
    super.initState();
    // Safety net: guarantees the bottom nav's "Cycle" tab shows the baby
    // growth tracker even if this screen is ever reached another way.
    AppSession.mode = AppMode.babyCare;
    _initializeBabyCare();
    BabyProfileStore.activeBabyId.addListener(_loadActiveBabyData);
  }

  Future<void> _initializeBabyCare() async {
    try {
      await BabyProfileStore.fetchAll();
      _loadActiveBabyData();
    } catch (_) {
      // Keep the dashboard usable offline; pull-to-refresh can retry later.
    }
  }

  @override
  void dispose() {
    BabyProfileStore.activeBabyId.removeListener(_loadActiveBabyData);
    super.dispose();
  }

  void _loadActiveBabyData() {
    if (BabyProfileStore.babies.value.isEmpty) return;
    final babyId = BabyProfileStore.active.id;
    GrowthLog.fetchForBaby(babyId);
    MilestoneLog.fetchForBaby(babyId);
    BabyCareLogStore.fetchForBaby(babyId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: Stack(
      children: [
        const ScreenBackground(),
        SafeArea(
          child: ValueListenableBuilder<List<BabyProfile>>(
            valueListenable: BabyProfileStore.babies,
            builder: (context, babies, _) => ValueListenableBuilder<String>(
              valueListenable: BabyProfileStore.activeBabyId,
              builder: (context, activeId, _) {
                if (babies.isEmpty) return _emptyDashboard(context);
                final baby = BabyProfileStore.active;
                return ListenableBuilder(
                  listenable: Listenable.merge([
                    GrowthLog.entries,
                    MilestoneLog.achieved,
                    BabyCareLogStore.entries,
                  ]),
                  builder: (context, _) => Column(
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: _stickyHeader(context, baby),
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
                                  if (babies.length > 1) ...[
                                    _babySwitcher(babies, activeId),
                                    const SizedBox(height: 16),
                                  ],
                                  _statsRow(baby),
                                  const SizedBox(height: 16),
                                  _todayCareCard(context, baby),
                                  const SizedBox(height: 16),
                                  _growthCard(context, baby),
                                  const SizedBox(height: 16),
                                  _milestoneCard(context, baby),
                                  const SizedBox(height: 16),
                                  _healthScheduleCard(context),
                                  const SizedBox(height: 16),
                                  _profileCard(context, baby),
                                  const SizedBox(height: 30),
                                  _tipCard(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      AppBottomNav(
                        current: AppTab.today,
                        onSelect: (tab) => goToTab(context, tab),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const Positioned(right: 20, bottom: 100, child: BloomAiFab()),
      ],
    ),
  );

  Widget _emptyDashboard(BuildContext context) => Column(
    children: [
      Container(
        margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .84),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFEBDDFF),
              child: Icon(Icons.child_care_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text(
              'Baby Care',
              style: GoogleFonts.nunitoSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .8),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: .25),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add_reaction_outlined,
                    size: 52,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Add your baby profile',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create a profile to track daily care, growth, health, and milestones.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunitoSans(
                      height: 1.4,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BabyProfileScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add baby profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
        current: AppTab.today,
        onSelect: (tab) => goToTab(context, tab),
      ),
    ],
  );

  Widget _stickyHeader(BuildContext context, BabyProfile baby) => Container(
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
          decoration: const BoxDecoration(
            color: Color(0xFFD3BBFE),
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          child: const Icon(
            Icons.child_care_rounded,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                baby.name,
                style: GoogleFonts.nunitoSans(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                babyAgeLabel(baby.dateOfBirth),
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
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

  Widget _babySwitcher(List<BabyProfile> babies, String activeId) => SizedBox(
    height: 42,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      itemCount: babies.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final baby = babies[index];
        final selected = baby.id == activeId;
        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => BabyProfileStore.setActive(baby.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              gradient: selected ? AppColors.buttonGradient : null,
              color: selected ? null : Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : AppColors.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              baby.name,
              style: GoogleFonts.nunitoSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : AppColors.primary,
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _statsRow(BabyProfile baby) {
    final weightEntries = GrowthLog.forBaby(baby.id, GrowthMetric.weight);
    final latestWeight = weightEntries.isEmpty
        ? '—'
        : '${weightEntries.last.value.toStringAsFixed(1)} lb';
    final achievedCount = babyMilestones
        .where(
          (milestone) => MilestoneLog.isMilestoneAchieved(baby.id, milestone),
        )
        .length;

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

  Widget _todayCareCard(BuildContext context, BabyProfile baby) {
    final todayEntries = BabyCareLogStore.entries.value
        .where(
          (entry) =>
              entry.babyId == baby.id &&
              DateUtils.isSameDay(entry.occurredAt, DateTime.now()),
        )
        .toList();
    final feeds = todayEntries
        .where((entry) => entry.kind == BabyCareLogKind.feeding)
        .length;
    final diapers = todayEntries
        .where((entry) => entry.kind == BabyCareLogKind.diaper)
        .length;
    final sleepMinutes = todayEntries
        .where((entry) => entry.kind == BabyCareLogKind.sleep)
        .fold<int>(0, (sum, entry) => sum + (entry.durationMinutes ?? 0));
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const BabyDailyCareScreen())),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .78),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: .25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFEBDDFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.today_outlined, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todayEntries.isEmpty
                        ? 'Start today\'s care log'
                        : 'Baby today',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    todayEntries.isEmpty
                        ? 'Track feeds, diapers and sleep in one place.'
                        : '$feeds feeds  ·  $diapers diapers  ·  ${_shortDuration(sleepMinutes)} sleep',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 12.5,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  String _shortDuration(int minutes) =>
      minutes < 60 ? '${minutes}m' : '${minutes ~/ 60}h ${minutes % 60}m';

  Widget _growthCard(BuildContext context, BabyProfile baby) => InkWell(
    borderRadius: BorderRadius.circular(28),
    onTap: () => Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BabyGrowthScreen())),
    child: Container(
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
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.show_chart_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Growth & milestones',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Log weight, height & head circumference — with WHO-style reference charts.',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 13,
                    height: 1.4,
                    color: const Color(0xFFEBDDFF),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white),
        ],
      ),
    ),
  );

  Widget _milestoneCard(BuildContext context, BabyProfile baby) {
    final ageDays = DateTime.now().difference(baby.dateOfBirth).inDays;
    final unachieved = babyMilestones
        .where((m) => !MilestoneLog.isMilestoneAchieved(baby.id, m))
        .toList();
    final nextUp = unachieved.firstWhere(
      (m) => m.targetAgeDays >= ageDays,
      orElse: () => unachieved.isEmpty ? babyMilestones.last : unachieved.first,
    );
    final allDone = unachieved.isEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const BabyGrowthScreen())),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
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
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Color(0xFFD3BBFE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                allDone ? Icons.celebration_outlined : nextUp.icon,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    allDone
                        ? 'ALL MILESTONES LOGGED'
                        : nextUp.checkpointLabel.toUpperCase(),
                    style: GoogleFonts.nunitoSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    allDone ? 'What a journey so far!' : nextUp.title,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  if (!allDone)
                    Text(
                      nextUp.domain,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _healthScheduleCard(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(24),
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RemindersHealthScreen(babyCare: true),
      ),
    ),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: Color(0xFFEBDDFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.health_and_safety_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Baby health & reminders',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Medicine, pediatric visits & vaccine tracking.',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
        ],
      ),
    ),
  );

  Widget _profileCard(BuildContext context, BabyProfile baby) => InkWell(
    borderRadius: BorderRadius.circular(24),
    onTap: () => Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BabyProfileScreen())),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: Color(0xFFD3BBFE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.family_restroom_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Baby profile',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Edit details or add another little one.',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
        ],
      ),
    ),
  );

  Widget _tipCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFEBDDFF),
          AppColors.lavender.withValues(alpha: 0.6),
        ],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: AppColors.secondary.withValues(alpha: 0.15),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lightbulb_outline, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gentle reminder',
                style: GoogleFonts.nunitoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Every baby grows at their own pace — these charts are a general guide, not a race.',
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
