import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_settings_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/notifications_panel.dart';
import '../../../core/widgets/screen_background.dart';
import '../../../core/widgets/stat_chip.dart';
import 'app_navigation.dart';
import 'bloom_ai_fab.dart';
import 'cycle_prediction.dart';
import 'daily_log_models.dart';
import 'learn_content.dart';
import 'lesson_detail_screen.dart';
import 'log_entry_screen.dart';

enum _DayType { normal, period, fertile, ovulation }

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

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

class CycleScreen extends StatefulWidget {
  const CycleScreen({super.key});

  @override
  State<CycleScreen> createState() => _CycleScreenState();
}

class _CycleScreenState extends State<CycleScreen> {
  final DateTime _today = _dateOnly(DateTime.now());
  late DateTime _visibleMonth = DateTime(_today.year, _today.month);

  @override
  void initState() {
    super.initState();
    if (AppSettingsStore.current.value == null) AppSettingsStore.fetch();
    if (DailyLogStore.all.value.isEmpty) DailyLogStore.fetchAll();
  }

  void _shiftMonth(int delta) => setState(
    () => _visibleMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + delta,
    ),
  );

  CyclePrediction? _predictionFor(AppSettings? settings, List<DailyLog> logs) {
    if (settings == null) return null;
    return CyclePrediction.compute(
      periodStartDates: CyclePrediction.periodStartDatesFrom(logs),
      cycleLength: settings.cycleLength,
      periodLength: settings.periodLength,
      lutealLength: settings.lutealLength,
    );
  }

  (String title, String description) _phase(CyclePrediction? prediction) {
    if (prediction == null) {
      return (
        'Start tracking',
        'Log your period to see your current cycle phase.',
      );
    }
    if (prediction.isPeriodToday) {
      return (
        'Menstrual phase',
        'Your period is here. Rest and gentle movement help most right now.',
      );
    }
    if (prediction.cycleDayToday == prediction.ovulationDay) {
      return (
        'Ovulation day',
        'Your egg is released today — this is your peak fertility window.',
      );
    }
    if (prediction.cycleDayToday < prediction.ovulationDay) {
      return (
        'Follicular phase',
        'Your body is preparing an egg for release. Energy is typically rising.',
      );
    }
    return (
      'Luteal phase',
      'Post-ovulation — your body is preparing for next cycle.',
    );
  }

  /// The most relevant lesson for the user's current cycle phase — turns
  /// the phase card into a way to keep learning, not just a status readout.
  LearnItem? _phaseLesson(CyclePrediction? prediction) {
    if (prediction == null) return null;
    String title;
    if (prediction.isPeriodToday) {
      title = 'Foods That Support a Healthy Cycle';
    } else if (prediction.cycleDayToday == prediction.ovulationDay) {
      title = 'Hydration and Cervical Mucus';
    } else if (prediction.cycleDayToday < prediction.ovulationDay) {
      title = 'Understanding Ovulation Signs';
    } else {
      title = 'Coping with the Two-Week Wait';
    }
    return allLearnItems.firstWhere((i) => i.title == title);
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<AppSettings?>(
    valueListenable: AppSettingsStore.current,
    builder: (context, settings, _) => ValueListenableBuilder<List<DailyLog>>(
      valueListenable: DailyLogStore.all,
      builder: (context, logs, _) {
        final prediction = _predictionFor(settings, logs);
        final periodDates = CyclePrediction.periodStartDatesFrom(logs);
        final loggedPeriodDates = logs
            .where((l) => l.flow != 'None')
            .map((l) => _dateOnly(l.logDate))
            .toSet();
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
                        child: _stickyHeader(prediction),
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
                                _statsRow(settings, prediction),
                                const SizedBox(height: 16),
                                _phaseCard(prediction),
                                const SizedBox(height: 30),
                                _sectionTitle(
                                  'This month',
                                  'Tap a day to see details.',
                                ),
                                const SizedBox(height: 14),
                                _calendarCard(prediction, loggedPeriodDates),
                                const SizedBox(height: 30),
                                _sectionTitle(
                                  'Recent cycles',
                                  'Your last 3 cycles at a glance.',
                                ),
                                const SizedBox(height: 14),
                                _historyCard(periodDates),
                                const SizedBox(height: 30),
                                _logCtaCard(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    AppBottomNav(
                      current: AppTab.cycle,
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

  Widget _stickyHeader(CyclePrediction? prediction) => Container(
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
                'Your cycle',
                style: GoogleFonts.nunitoSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                prediction == null
                    ? _phase(null).$1
                    : 'Day ${prediction.cycleDayToday} · ${_phase(prediction).$1}',
                style: GoogleFonts.nunitoSans(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LogEntryScreen(initialDate: _today),
            ),
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
                const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 3),
                Text(
                  'Log',
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

  Widget _statsRow(AppSettings? settings, CyclePrediction? prediction) => Row(
    children: [
      Expanded(
        child: StatChip(
          icon: Icons.autorenew_rounded,
          value: settings == null ? '—' : '${settings.cycleLength}',
          label: 'Avg. cycle',
          color: AppColors.secondaryContainer,
          deep: AppColors.primary,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: StatChip(
          icon: Icons.water_drop_outlined,
          value: settings == null ? '—' : '${settings.periodLength}',
          label: 'Avg. period',
          color: AppColors.lavender,
          deep: AppColors.secondary,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: StatChip(
          icon: Icons.event_available_outlined,
          value: prediction == null
              ? '—'
              : _shortDate(prediction.nextPeriodDate),
          label: 'Next period',
          color: AppColors.lavenderLight,
          deep: AppColors.primaryContainer,
        ),
      ),
    ],
  );

  Widget _phaseCard(CyclePrediction? prediction) {
    final (title, description) = _phase(prediction);
    final cycleDay = prediction?.cycleDayToday ?? 0;
    final cycleLength = prediction?.cycleLength ?? 1;
    final lesson = _phaseLesson(prediction);
    return GestureDetector(
      onTap: lesson == null
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LessonDetailScreen(item: lesson),
              ),
            ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                          value: prediction == null
                              ? 0
                              : cycleDay / cycleLength,
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
                            prediction == null ? '—' : '$cycleDay',
                            style: GoogleFonts.nunitoSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            prediction == null ? '' : 'OF $cycleLength',
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
                        description,
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
            if (lesson != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Learn about this phase: ${lesson.title}',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ],
                ),
              ),
            ],
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

  Widget _calendarCard(
    CyclePrediction? prediction,
    Set<DateTime> loggedPeriodDates,
  ) => Container(
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
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _monthNavButton(Icons.chevron_left_rounded, () => _shiftMonth(-1)),
            Text(
              '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
              style: GoogleFonts.nunitoSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            _monthNavButton(Icons.chevron_right_rounded, () => _shiftMonth(1)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        ..._calendarRows(prediction, loggedPeriodDates),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        _legend(),
      ],
    ),
  );

  Widget _monthNavButton(IconData icon, VoidCallback onTap) => Material(
    color: Colors.white.withValues(alpha: 0.8),
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
    ),
  );

  List<Widget> _calendarRows(
    CyclePrediction? prediction,
    Set<DateTime> loggedPeriodDates,
  ) {
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final leadingBlanks =
        DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday % 7;
    final totalCells = leadingBlanks + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    final rows = <Widget>[];
    var day = 1 - leadingBlanks;
    for (var r = 0; r < rowCount; r++) {
      final cells = <Widget>[];
      for (var c = 0; c < 7; c++) {
        if (day < 1 || day > daysInMonth) {
          cells.add(const Expanded(child: SizedBox(height: 42)));
        } else {
          final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
          cells.add(
            Expanded(
              child: _dayCell(
                day,
                _dayType(date, prediction, loggedPeriodDates),
                date == _today,
              ),
            ),
          );
        }
        day++;
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: cells),
        ),
      );
    }
    return rows;
  }

  _DayType _dayType(
    DateTime date,
    CyclePrediction? prediction,
    Set<DateTime> loggedPeriodDates,
  ) {
    if (loggedPeriodDates.contains(date)) return _DayType.period;
    if (prediction == null) return _DayType.normal;
    if (prediction.isOvulationDay(date)) return _DayType.ovulation;
    if (prediction.isPeriodDay(date)) return _DayType.period;
    if (prediction.isFertileDay(date)) return _DayType.fertile;
    return _DayType.normal;
  }

  Widget _dayCell(int day, _DayType type, bool isToday) {
    final fill = switch (type) {
      _DayType.period => AppColors.primary,
      _DayType.ovulation => AppColors.secondary,
      _DayType.fertile => AppColors.secondaryContainer,
      _DayType.normal => Colors.transparent,
    };
    final textColor = switch (type) {
      _DayType.period || _DayType.ovulation => Colors.white,
      _DayType.fertile => AppColors.primary,
      _DayType.normal => isToday ? AppColors.primary : AppColors.onSurface,
    };
    return Center(
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: isToday
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Text(
          '$day',
          style: GoogleFonts.nunitoSans(
            fontSize: 13,
            fontWeight: type == _DayType.normal
                ? FontWeight.w600
                : FontWeight.w800,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _legend() => Wrap(
    spacing: 16,
    runSpacing: 8,
    children: [
      _legendDot(AppColors.primary, 'Period'),
      _legendDot(AppColors.secondaryContainer, 'Fertile window'),
      _legendDot(AppColors.secondary, 'Ovulation'),
      _legendRing('Today'),
    ],
  );

  Widget _legendDot(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: GoogleFonts.nunitoSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _legendRing(String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: GoogleFonts.nunitoSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _historyCard(List<DateTime> periodStartDates) {
    final cycles = CyclePrediction.recentCycleLengths(periodStartDates);
    if (cycles.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 26),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          periodStartDates.isEmpty
              ? 'Log a period to start building your history.'
              : 'Log one more period to see cycle-length history.',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunitoSans(
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      );
    }
    final avg =
        cycles.map((c) => c.length).reduce((a, b) => a + b) / cycles.length;

    return Container(
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
        children: List.generate(cycles.length, (index) {
          final item = cycles[index];
          final status = (item.length - avg).abs() <= 2
              ? 'Regular'
              : 'Irregular';
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
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
                      child: const Icon(
                        Icons.water_drop_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _monthNames[item.start.month - 1],
                            style: GoogleFonts.nunitoSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            '${item.length}-day cycle',
                            style: GoogleFonts.nunitoSans(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lavender.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (index != cycles.length - 1)
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
  }

  Widget _logCtaCard() => Container(
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.water_drop_outlined,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Starting your period today?',
                style: GoogleFonts.nunitoSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Log it to keep your predictions accurate.',
                style: GoogleFonts.nunitoSans(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LogEntryScreen(initialDate: _today),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              'Log',
              style: GoogleFonts.nunitoSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
