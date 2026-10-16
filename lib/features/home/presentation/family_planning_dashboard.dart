import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_session.dart';
import '../../../core/app_settings_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/user_profile_store.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/highlight_card.dart';
import '../../../core/widgets/notifications_panel.dart';
import '../../../core/widgets/screen_background.dart';
import '../../../core/widgets/stat_chip.dart';
import 'app_navigation.dart';
import 'bloom_ai_fab.dart';
import 'cycle_prediction.dart';
import 'cycle_screen.dart';
import 'daily_log_models.dart';
import 'learn_content.dart';
import 'learn_library_screen.dart';
import 'lesson_detail_screen.dart';
import 'log_entry_screen.dart';
import 'reminders_health_screen.dart';

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

String _shortDate(DateTime d) => '${_monthAbbrev[d.month - 1]} ${d.day}';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class FamilyPlanningDashboard extends StatefulWidget {
  const FamilyPlanningDashboard({super.key});

  @override
  State<FamilyPlanningDashboard> createState() =>
      _FamilyPlanningDashboardState();
}

class _FamilyPlanningDashboardState extends State<FamilyPlanningDashboard> {
  final ScrollController _learnScrollController = ScrollController();
  bool _savingCheckIn = false;

  @override
  void initState() {
    super.initState();
    // Safety net: guarantees the bottom nav's "Cycle" tab shows the regular
    // menstrual-cycle tracker even if this screen is ever reached another way.
    AppSession.mode = AppMode.familyPlanning;
    if (AppSettingsStore.current.value == null) AppSettingsStore.fetch();
    if (DailyLogStore.all.value.isEmpty) DailyLogStore.fetchAll();
    LearnProgress.fetch();
  }

  @override
  void dispose() {
    _learnScrollController.dispose();
    super.dispose();
  }

  CyclePrediction? _predictionFor(AppSettings? settings, List<DailyLog> logs) {
    if (settings == null) return null;
    return CyclePrediction.compute(
      periodStartDates: CyclePrediction.periodStartDatesFrom(logs),
      cycleLength: settings.cycleLength,
      periodLength: settings.periodLength,
      lutealLength: settings.lutealLength,
    );
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<AppSettings?>(
    valueListenable: AppSettingsStore.current,
    builder: (context, settings, _) => ValueListenableBuilder<List<DailyLog>>(
      valueListenable: DailyLogStore.all,
      builder: (context, logs, _) {
        final prediction = _predictionFor(settings, logs);
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
                        child: _stickyHeader(prediction, logs),
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
                                _statsRow(logs),
                                const SizedBox(height: 24),
                                _cycleOverview(prediction),
                                const SizedBox(height: 16),
                                _upcomingWindow(prediction),
                                const SizedBox(height: 16),
                                _healthScheduleCard(context),
                                const SizedBox(height: 30),
                                _sectionTitle(
                                  'Today’s check-in',
                                  'A few seconds now can make your insights clearer.',
                                ),
                                const SizedBox(height: 14),
                                _symptomGrid(logs),
                                const SizedBox(height: 30),
                                _sectionTitle(
                                  'Your week',
                                  prediction == null
                                      ? 'Log your period to see your week at a glance.'
                                      : 'Ovulation is expected around day ${prediction.ovulationDay}.',
                                ),
                                const SizedBox(height: 14),
                                _weekStrip(prediction),
                                const SizedBox(height: 30),
                                _learnSection(prediction),
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
              ),
              const Positioned(right: 20, bottom: 100, child: BloomAiFab()),
            ],
          ),
        );
      },
    ),
  );

  Widget _stickyHeader(CyclePrediction? prediction, List<DailyLog> logs) =>
      Container(
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
              child: Image.asset(
                'lib/assets/images/logo.png',
                fit: BoxFit.contain,
              ),
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
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Text(
                    prediction == null
                        ? 'Log a period to start tracking'
                        : 'Cycle day ${prediction.cycleDayToday}',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 13,
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
                    '${_dayStreak(logs)}',
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

  int _dayStreak(List<DailyLog> logs) {
    final loggedDates = logs.map((log) => _dateOnly(log.logDate)).toSet();
    var date = _dateOnly(DateTime.now());
    if (!loggedDates.contains(date)) {
      date = date.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (loggedDates.contains(date)) {
      streak++;
      date = date.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _badgeCount(List<DailyLog> logs, Set<String> completed) {
    var count = 0;
    if (logs.isNotEmpty || completed.isNotEmpty) count++;
    if (_dayStreak(logs) >= 3) count++;
    if (completed.length >= 3) count++;
    return count;
  }

  Widget _statsRow(List<DailyLog> logs) => Row(
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
        child: ValueListenableBuilder<Set<String>>(
          valueListenable: LearnProgress.completedTitles,
          builder: (context, completed, _) {
            // Only count completions within this dashboard's own lesson
            // pool — `completed` is a single global set shared with the
            // pregnancy track's lessons too.
            final done = allLearnItems
                .where((i) => completed.contains(i.title))
                .length;
            return StatChip(
              icon: Icons.menu_book_rounded,
              value: '$done/${allLearnItems.length}',
              label: 'Lessons done',
              color: AppColors.lavender,
              deep: AppColors.secondary,
            );
          },
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: ValueListenableBuilder<Set<String>>(
          valueListenable: LearnProgress.completedTitles,
          builder: (context, completed, _) => StatChip(
            icon: Icons.emoji_events_rounded,
            value: '${_badgeCount(logs, completed)}',
            label: 'Badges',
            color: AppColors.lavenderLight,
            deep: AppColors.primaryContainer,
          ),
        ),
      ),
    ],
  );

  Widget _cycleOverview(CyclePrediction? prediction) => Container(
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
    child: prediction == null
        ? _cycleOverviewEmpty(context)
        : _cycleOverviewFilled(prediction),
  );

  Widget _cycleOverviewEmpty(BuildContext context) => Row(
    children: [
      Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.water_drop_outlined,
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
              'No predictions yet',
              style: GoogleFonts.nunitoSans(
                fontSize: 19,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Log your period once and BabyBloom will start predicting your cycle day and fertile window.',
              style: GoogleFonts.nunitoSans(
                fontSize: 14,
                height: 1.4,
                color: const Color(0xFFEBDDFF),
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LogEntryScreen(initialDate: DateTime.now()),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Log your period',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _cycleOverviewFilled(CyclePrediction prediction) {
    final (title, detail) = switch (prediction) {
      _ when prediction.isFertileToday => (
        'You\'re in your fertile window',
        'High fertility today — day ${prediction.cycleDayToday} of ${prediction.cycleLength}.',
      ),
      _ when prediction.daysUntilFertileWindow > 0 => (
        'Your fertile window is coming up',
        'You are entering your high-fertility phase in ${prediction.daysUntilFertileWindow} day${prediction.daysUntilFertileWindow == 1 ? '' : 's'}.',
      ),
      _ => (
        'Your fertile window has passed',
        'Next period expected around ${_shortDate(prediction.nextPeriodDate)}.',
      ),
    };

    return Row(
      children: [
        SizedBox(
          width: 112,
          height: 112,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: CircularProgressIndicator(
                  value: prediction.cycleDayToday / prediction.cycleLength,
                  strokeWidth: 9,
                  strokeCap: StrokeCap.round,
                  color: const Color(0xFFD3BBFE),
                  backgroundColor: const Color(0x336D5B8F),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${prediction.cycleDayToday}',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'CYCLE DAY',
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
    );
  }

  Widget _healthScheduleCard(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(24),
    onTap: () => Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RemindersHealthScreen())),
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
              Icons.notifications_active_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reminders & health schedule',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Vitamins, appointments & vaccines.',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chevron_right,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _upcomingWindow(CyclePrediction? prediction) {
    String valueText;
    if (prediction == null) {
      valueText = 'Log a period to see this';
    } else {
      var start = prediction.fertileWindowStart;
      var end = prediction.fertileWindowEnd;
      if (end.isBefore(_dateOnly(DateTime.now()))) {
        start = start.add(Duration(days: prediction.cycleLength));
        end = end.add(Duration(days: prediction.cycleLength));
      }
      valueText = '${_shortDate(start)} - ${_shortDate(end)}';
    }

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const CycleScreen())),
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
                Icons.calendar_month_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next fertile window',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    valueText,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ],
        ),
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

  /// The one `daily_logs` row for today, if today has already been logged —
  /// the table's `unique (user_id, log_date)` constraint means there can
  /// only ever be one, so today's check-in is inherently "log once per day":
  /// every tap here edits that same row instead of creating another.
  DailyLog? _todayLog(List<DailyLog> logs) {
    final today = _dateOnly(DateTime.now());
    for (final log in logs) {
      if (_dateOnly(log.logDate) == today) return log;
    }
    return null;
  }

  Future<void> _toggleSymptom(String label, DailyLog? todayLog) async {
    if (_savingCheckIn) return;
    final symptoms = {...?todayLog?.symptoms};
    if (!symptoms.remove(label)) symptoms.add(label);

    setState(() => _savingCheckIn = true);
    try {
      await DailyLogStore.save(
        DailyLog(
          logDate: DateTime.now(),
          flow: todayLog?.flow ?? 'None',
          mood: todayLog?.mood,
          symptoms: symptoms,
          notes: todayLog?.notes ?? '',
        ),
      );
    } catch (e) {
      if (mounted) _showError('Could not save check-in: $e');
    } finally {
      if (mounted) setState(() => _savingCheckIn = false);
    }
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
  );

  Widget _symptomGrid(List<DailyLog> logs) {
    final todayLog = _todayLog(logs);
    final loggedSymptoms = todayLog?.symptoms ?? const <String>{};
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _symptomChip(
          'Mood',
          Icons.sentiment_satisfied_alt_outlined,
          loggedSymptoms,
          todayLog,
        ),
        _symptomChip('Energy', Icons.bolt_outlined, loggedSymptoms, todayLog),
        _symptomChip('Cramps', Icons.spa_outlined, loggedSymptoms, todayLog),
        _symptomChip(
          'Discharge',
          Icons.water_drop_outlined,
          loggedSymptoms,
          todayLog,
        ),
      ],
    );
  }

  Widget _symptomChip(
    String label,
    IconData icon,
    Set<String> loggedSymptoms,
    DailyLog? todayLog,
  ) {
    final selected = loggedSymptoms.contains(label);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
      ),
      child: FilterChip(
        selected: selected,
        onSelected: _savingCheckIn
            ? null
            : (_) => _toggleSymptom(label, todayLog),
        avatar: Icon(
          icon,
          size: 19,
          color: selected ? Colors.white : AppColors.primary,
        ),
        label: Text(
          label,
          style: GoogleFonts.nunitoSans(fontWeight: FontWeight.w700),
        ),
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.primary,
        ),
        selectedColor: AppColors.secondary,
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        side: BorderSide(
          color: selected
              ? AppColors.secondary
              : AppColors.outlineVariant.withValues(alpha: .45),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }

  Widget _weekStrip(CyclePrediction? prediction) {
    const weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = _dateOnly(DateTime.now());
    final days = List.generate(7, (i) => today.add(Duration(days: i - 3)));

    return Container(
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
        children: List.generate(days.length, (index) {
          final date = days[index];
          final isToday = index == 3;
          final isPeriod = prediction?.isPeriodDay(date) ?? false;
          final isOvulation = prediction?.isOvulationDay(date) ?? false;
          final isFertile = prediction?.isFertileDay(date) ?? false;
          final fill = isToday
              ? AppColors.primary
              : isPeriod
              ? AppColors.primary.withValues(alpha: 0.75)
              : isOvulation
              ? AppColors.secondary
              : isFertile
              ? const Color(0xFFD3BBFE)
              : Colors.white;
          return Expanded(
            child: Column(
              children: [
                Text(
                  weekdayLetters[date.weekday - 1],
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: fill,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isToday
                          ? AppColors.primary
                          : AppColors.outlineVariant.withValues(alpha: .35),
                    ),
                    boxShadow: isToday
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    '${date.day}',
                    style: GoogleFonts.nunitoSans(
                      fontWeight: FontWeight.w800,
                      color: isToday || isPeriod || isOvulation
                          ? Colors.white
                          : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _learnSection(CyclePrediction? prediction) {
    final lessons = allLearnItems.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _sectionTitle(
                'Learn & grow',
                prediction == null
                    ? 'Bite-sized lessons for your journey.'
                    : 'Bite-sized lessons picked for cycle day ${prediction.cycleDayToday}.',
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LearnLibraryScreen()),
              ),
              child: Text(
                'SEE ALL',
                style: GoogleFonts.nunitoSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 190,
          child: Scrollbar(
            controller: _learnScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            radius: const Radius.circular(999),
            child: ListView.separated(
              controller: _learnScrollController,
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.only(bottom: 14),
              itemCount: lessons.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _learnCard(lessons[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _learnCard(LearnItem item) => GestureDetector(
    onTap: () => Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => LessonDetailScreen(item: item))),
    child: ValueListenableBuilder<Set<String>>(
      valueListenable: LearnProgress.completedTitles,
      builder: (context, completed, _) => HighlightCard(
        icon: item.icon,
        category: item.category,
        title: item.title,
        meta: item.meta,
        color: item.color,
        deep: item.deep,
        completed: completed.contains(item.title),
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
                'Hydration supports cervical mucus health. Keep your water bottle close today.',
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
