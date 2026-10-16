import '../../../core/app_settings_store.dart';
import 'cycle_prediction.dart';
import 'daily_log_models.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// One point on the cycle-length trend chart.
class CycleLengthPoint {
  const CycleLengthPoint({required this.start, required this.days});
  final DateTime start;
  final int days;
}

/// How often a symptom was logged in the trailing window, as a 0-1 fraction
/// of the logs in that window.
class SymptomFrequency {
  const SymptomFrequency({required this.label, required this.pct});
  final String label;
  final double pct;
}

/// One day's mood, or null if nothing was logged that day.
class MoodDay {
  const MoodDay({required this.date, required this.mood});
  final DateTime date;
  final String? mood;
}

class PersonalizedInsight {
  const PersonalizedInsight({
    required this.category,
    required this.title,
    required this.meta,
  });
  final String category;
  final String title;
  final String meta;
}

/// Everything the Insights screen (and its shareable report) show, derived
/// from the user's own `daily_logs` and `app_settings` rows — no demo data.
class InsightsData {
  const InsightsData({
    required this.regularityPct,
    required this.variabilityDays,
    required this.totalSymptomsLogged,
    required this.cycleLengthTrend,
    required this.topSymptoms,
    required this.symptomLogWindowCount,
    required this.moodWeek,
    required this.personalizedInsights,
  });

  /// % of the recent cycles within 2 days of the average length. Null until
  /// at least 2 cycles have been logged (same "Regular" threshold cycle
  /// history uses elsewhere).
  final int? regularityPct;

  /// Largest deviation from the average recent cycle length, in days.
  final int? variabilityDays;

  /// Total individual symptom tags logged, all-time.
  final int totalSymptomsLogged;

  /// Up to the last 6 logged cycles, oldest first.
  final List<CycleLengthPoint> cycleLengthTrend;

  /// Up to the 4 most-logged symptoms in the last 30 days.
  final List<SymptomFrequency> topSymptoms;

  /// How many daily logs fall in that 30-day window — the denominator
  /// [topSymptoms] percentages are computed against.
  final int symptomLogWindowCount;

  /// Last 7 calendar days, oldest first.
  final List<MoodDay> moodWeek;

  final List<PersonalizedInsight> personalizedInsights;

  static InsightsData compute(List<DailyLog> logs, AppSettings? settings) {
    final periodDates = CyclePrediction.periodStartDatesFrom(logs);
    final recentCycles = CyclePrediction.recentCycleLengths(
      periodDates,
      maxCount: 6,
    ).reversed.toList();

    int? regularityPct;
    int? variabilityDays;
    if (recentCycles.length >= 2) {
      final avg =
          recentCycles.map((c) => c.length).reduce((a, b) => a + b) /
          recentCycles.length;
      final regularCount = recentCycles
          .where((c) => (c.length - avg).abs() <= 2)
          .length;
      regularityPct = (regularCount / recentCycles.length * 100).round();
      variabilityDays = recentCycles
          .map((c) => (c.length - avg).abs().round())
          .reduce((a, b) => a > b ? a : b);
    }

    final totalSymptomsLogged = logs.fold<int>(
      0,
      (sum, l) => sum + l.symptoms.length,
    );

    final cutoff = _dateOnly(DateTime.now()).subtract(const Duration(days: 30));
    final recentLogs = logs
        .where((l) => !_dateOnly(l.logDate).isBefore(cutoff))
        .toList();
    final symptomCounts = <String, int>{};
    for (final log in recentLogs) {
      for (final s in log.symptoms) {
        symptomCounts[s] = (symptomCounts[s] ?? 0) + 1;
      }
    }
    final topSymptoms =
        (symptomCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(4)
            .map(
              (e) => SymptomFrequency(
                label: e.key,
                pct: recentLogs.isEmpty ? 0 : e.value / recentLogs.length,
              ),
            )
            .toList();

    final today = _dateOnly(DateTime.now());
    final moodByDate = {for (final l in logs) _dateOnly(l.logDate): l.mood};
    final moodWeek = List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      return MoodDay(date: d, mood: moodByDate[d]);
    });

    final insights = <PersonalizedInsight>[
      if (regularityPct != null && variabilityDays != null)
        PersonalizedInsight(
          category: 'Regularity',
          title: variabilityDays <= 3
              ? 'Cycles stayed within $variabilityDays days over your last ${recentCycles.length} cycles'
              : 'Cycles varied by up to $variabilityDays days recently',
          meta: '$regularityPct% regular',
        ),
      if (settings != null)
        PersonalizedInsight(
          category: 'Luteal phase',
          title: 'Consistently ${settings.lutealLength} days long',
          meta: 'From settings',
        ),
      if (topSymptoms.isNotEmpty)
        PersonalizedInsight(
          category: 'Symptoms',
          title: '${topSymptoms.first.label} logged most often',
          meta: 'From ${recentLogs.length} logs',
        ),
      const PersonalizedInsight(
        category: 'Tip',
        title: 'Log daily for sharper predictions',
        meta: 'Takes 10 seconds',
      ),
    ];

    return InsightsData(
      regularityPct: regularityPct,
      variabilityDays: variabilityDays,
      totalSymptomsLogged: totalSymptomsLogged,
      cycleLengthTrend: [
        for (final c in recentCycles)
          CycleLengthPoint(start: c.start, days: c.length),
      ],
      topSymptoms: topSymptoms,
      symptomLogWindowCount: recentLogs.length,
      moodWeek: moodWeek,
      personalizedInsights: insights,
    );
  }
}
