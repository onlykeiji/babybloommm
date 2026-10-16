import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_config.dart';

String _isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// One day's period/mood/symptom check-in. One row per [logDate] — saving
/// the same date again overwrites it.
class DailyLog {
  DailyLog({
    this.id,
    required this.logDate,
    required this.flow,
    this.mood,
    required this.symptoms,
    required this.notes,
  });

  final String? id;
  final DateTime logDate;
  final String flow;
  final String? mood;
  final Set<String> symptoms;
  final String notes;

  factory DailyLog.fromRow(Map<String, dynamic> row) => DailyLog(
    id: row['id'] as String,
    logDate: DateTime.parse(row['log_date'] as String),
    flow: row['flow'] as String,
    mood: row['mood'] as String?,
    symptoms: ((row['symptoms'] as List?) ?? const [])
        .map((e) => e as String)
        .toSet(),
    notes: (row['notes'] as String?) ?? '',
  );

  Map<String, dynamic> toRow() => {
    'log_date': _isoDate(logDate),
    'flow': flow,
    'mood': mood,
    'symptoms': symptoms.toList(),
    'notes': notes,
  };
}

/// Consecutive days with a `daily_logs` entry, ending today (or yesterday,
/// if today just hasn't been logged yet).
int dayStreak(List<DailyLog> logs, {DateTime? today}) {
  if (logs.isEmpty) return 0;
  final now = today ?? DateTime.now();
  final days = logs
      .map((l) => DateTime(l.logDate.year, l.logDate.month, l.logDate.day))
      .toSet();
  var cursor = DateTime(now.year, now.month, now.day);
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

/// Backs [DailyLog] with the `daily_logs` Supabase table.
class DailyLogStore {
  DailyLogStore._();

  static const String _table = 'daily_logs';
  static SupabaseClient get _db => SupabaseConfig.client;

  /// Every logged day, ascending by date — the source of truth cycle
  /// predictions (family planning dashboard, cycle screen) are computed
  /// from.
  static final ValueNotifier<List<DailyLog>> all =
      ValueNotifier<List<DailyLog>>([]);

  static Future<void> fetchAll() async {
    final rows = await _db.from(_table).select().order('log_date');
    all.value = rows.map(DailyLog.fromRow).toList();
  }

  static Future<DailyLog?> fetchForDate(DateTime date) async {
    final row = await _db
        .from(_table)
        .select()
        .eq('log_date', _isoDate(date))
        .maybeSingle();
    return row == null ? null : DailyLog.fromRow(row);
  }

  static Future<void> save(DailyLog log) async {
    await _db.from(_table).upsert(log.toRow(), onConflict: 'user_id,log_date');
    await fetchAll();
  }
}
