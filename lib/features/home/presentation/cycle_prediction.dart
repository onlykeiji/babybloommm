import 'daily_log_models.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Real cycle-day / fertile-window predictions, computed from the user's
/// own logged period data (`daily_logs`) and their cycle settings
/// (`app_settings`) — no demo numbers.
///
/// Method: standard luteal-phase estimation. Ovulation is assumed to fall
/// `lutealLength` days before the next expected period; the fertile window
/// is the 6 days ending on that ovulation day (sperm can survive up to ~5
/// days, the egg about 1). This is an estimate, like every consumer cycle
/// tracker — not a substitute for medical/fertility guidance.
class CyclePrediction {
  const CyclePrediction({
    required this.currentCycleStart,
    required this.lastLoggedPeriodStart,
    required this.cycleLength,
    required this.periodLength,
    required this.lutealLength,
  });

  /// Start date of the cycle that contains "today" — may be several cycle
  /// lengths after [lastLoggedPeriodStart] if the user hasn't logged a
  /// period in a while; used as the anchor for all day-type math below.
  final DateTime currentCycleStart;

  /// The most recent period-start date actually logged by the user.
  final DateTime lastLoggedPeriodStart;

  final int cycleLength;
  final int periodLength;
  final int lutealLength;

  int get ovulationDay => (cycleLength - lutealLength).clamp(1, cycleLength);
  int get fertileStartDay => (ovulationDay - 5).clamp(1, cycleLength);
  int get fertileEndDay => ovulationDay.clamp(1, cycleLength);

  /// 1-indexed day within the cycle containing [date].
  int cycleDayFor(DateTime date) {
    final diff = _dateOnly(date).difference(currentCycleStart).inDays;
    final mod = diff % cycleLength;
    return (mod < 0 ? mod + cycleLength : mod) + 1;
  }

  bool isPeriodDay(DateTime date) => cycleDayFor(date) <= periodLength;
  bool isFertileDay(DateTime date) {
    final day = cycleDayFor(date);
    return day >= fertileStartDay && day <= fertileEndDay;
  }

  bool isOvulationDay(DateTime date) => cycleDayFor(date) == ovulationDay;

  int get cycleDayToday => cycleDayFor(DateTime.now());
  bool get isPeriodToday => isPeriodDay(DateTime.now());
  bool get isFertileToday => isFertileDay(DateTime.now());

  DateTime get nextPeriodDate =>
      currentCycleStart.add(Duration(days: cycleLength));
  DateTime get fertileWindowStart =>
      currentCycleStart.add(Duration(days: fertileStartDay - 1));
  DateTime get fertileWindowEnd =>
      currentCycleStart.add(Duration(days: fertileEndDay - 1));

  int get daysUntilNextPeriod =>
      nextPeriodDate.difference(_dateOnly(DateTime.now())).inDays;
  int get daysUntilFertileWindow =>
      fertileWindowStart.difference(_dateOnly(DateTime.now())).inDays;

  /// Returns null when there isn't at least one logged period to anchor
  /// predictions on — callers should show a "log your period" prompt
  /// instead of guessing.
  static CyclePrediction? compute({
    required List<DateTime> periodStartDates,
    required int cycleLength,
    required int periodLength,
    required int lutealLength,
  }) {
    if (periodStartDates.isEmpty) return null;
    final today = _dateOnly(DateTime.now());
    final lastLogged = _dateOnly(periodStartDates.last);
    var cycleStart = lastLogged;
    while (!today.isBefore(cycleStart.add(Duration(days: cycleLength)))) {
      cycleStart = cycleStart.add(Duration(days: cycleLength));
    }
    return CyclePrediction(
      currentCycleStart: cycleStart,
      lastLoggedPeriodStart: lastLogged,
      cycleLength: cycleLength,
      periodLength: periodLength,
      lutealLength: lutealLength,
    );
  }

  /// Extracts "day 1 of each period" from logged flow entries: a date
  /// counts as a period start when it has a non-"None" flow and the day
  /// before it doesn't.
  static List<DateTime> periodStartDatesFrom(List<DailyLog> logs) {
    final flowDates = logs
        .where((l) => l.flow != 'None')
        .map((l) => _dateOnly(l.logDate))
        .toSet();
    final starts = <DateTime>[
      for (final d in flowDates)
        if (!flowDates.contains(d.subtract(const Duration(days: 1)))) d,
    ];
    starts.sort();
    return starts;
  }

  /// Actual cycle lengths between consecutive logged period starts, most
  /// recent first — e.g. for "Recent cycles" history. Needs at least 2
  /// period starts to produce anything.
  static List<({DateTime start, int length})> recentCycleLengths(
    List<DateTime> periodStartDates, {
    int maxCount = 3,
  }) {
    final result = <({DateTime start, int length})>[];
    for (var i = periodStartDates.length - 1; i > 0; i--) {
      result.add((
        start: periodStartDates[i - 1],
        length: periodStartDates[i].difference(periodStartDates[i - 1]).inDays,
      ));
      if (result.length >= maxCount) break;
    }
    return result;
  }
}
