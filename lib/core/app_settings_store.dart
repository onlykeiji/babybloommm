import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// All app settings live in one shared row (`app_settings`) — the same
/// simplified, non-per-account approach used elsewhere in this project (see
/// CRUD_DOCUMENTATION.md "Known limitations").
class AppSettings {
  AppSettings({
    required this.periodReminders,
    required this.fertileWindowAlerts,
    required this.dailyCheckin,
    required this.dailyCheckinTime,
    required this.communityActivity,
    required this.weeklyInsights,
    required this.bloomAiCheckins,
    required this.postAnonymously,
    required this.shareResearchData,
    required this.appLock,
    required this.cycleLength,
    required this.periodLength,
    required this.lutealLength,
    required this.cycleTracking,
    required this.pregnancyCurrentWeek,
    this.dueDate,
    required this.prePregnancyWeightLb,
    required this.pregnancyTracking,
    required this.units,
    required this.hapticFeedback,
  });

  bool periodReminders;
  bool fertileWindowAlerts;
  bool dailyCheckin;
  TimeOfDay dailyCheckinTime;
  bool communityActivity;
  bool weeklyInsights;
  bool bloomAiCheckins;
  bool postAnonymously;
  bool shareResearchData;
  bool appLock;
  int cycleLength;
  int periodLength;
  int lutealLength;
  Set<String> cycleTracking;

  /// Manually-set fallback week, used only when [dueDate] is null (e.g. set
  /// once via Pregnancy Settings without a due date). Prefer
  /// [currentPregnancyWeek] everywhere else — it stays correct as days pass,
  /// this doesn't.
  int pregnancyCurrentWeek;

  /// The real anchor date onboarding/settings collect — everything
  /// pregnancy-related should derive from this instead of a stored week
  /// number, so it never goes stale.
  DateTime? dueDate;

  double prePregnancyWeightLb;
  Set<String> pregnancyTracking;
  String units;
  bool hapticFeedback;

  /// Weeks pregnant today, computed live from [dueDate] (40 weeks before
  /// it) when known; falls back to the manually-set [pregnancyCurrentWeek]
  /// otherwise.
  int get currentPregnancyWeek {
    if (dueDate == null) return pregnancyCurrentWeek;
    final daysUntilDue = dueDate!.difference(_dateOnly(DateTime.now())).inDays;
    final week = 40 - (daysUntilDue / 7).ceil();
    return week.clamp(1, 42);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  factory AppSettings.fromRow(Map<String, dynamic> row) => AppSettings(
    periodReminders: row['period_reminders'] as bool,
    fertileWindowAlerts: row['fertile_window_alerts'] as bool,
    dailyCheckin: row['daily_checkin'] as bool,
    dailyCheckinTime: _timeFromRow(row['daily_checkin_time'] as String),
    communityActivity: row['community_activity'] as bool,
    weeklyInsights: row['weekly_insights'] as bool,
    bloomAiCheckins: row['bloom_ai_checkins'] as bool,
    postAnonymously: row['post_anonymously'] as bool,
    shareResearchData: row['share_research_data'] as bool,
    appLock: row['app_lock'] as bool,
    cycleLength: row['cycle_length'] as int,
    periodLength: row['period_length'] as int,
    lutealLength: row['luteal_length'] as int,
    cycleTracking: ((row['cycle_tracking'] as List?) ?? const [])
        .map((e) => e as String)
        .toSet(),
    pregnancyCurrentWeek: row['pregnancy_current_week'] as int,
    dueDate: row['due_date'] == null
        ? null
        : DateTime.parse(row['due_date'] as String),
    prePregnancyWeightLb: (row['pre_pregnancy_weight_lb'] as num).toDouble(),
    pregnancyTracking: ((row['pregnancy_tracking'] as List?) ?? const [])
        .map((e) => e as String)
        .toSet(),
    units: row['units'] as String,
    hapticFeedback: row['haptic_feedback'] as bool,
  );

  static TimeOfDay _timeFromRow(String value) {
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}

/// Reads/writes the single [AppSettings] row. Every setter persists
/// immediately (each settings screen already tells the user "changes save
/// automatically") and updates [current] so every screen listening stays
/// in sync.
class AppSettingsStore {
  AppSettingsStore._();

  static const String _table = 'app_settings';
  static SupabaseClient get _db => SupabaseConfig.client;

  static final ValueNotifier<AppSettings?> current =
      ValueNotifier<AppSettings?>(null);

  static String get _userId {
    final id = _db.auth.currentUser?.id;
    if (id == null) {
      throw StateError('You must be signed in to access settings.');
    }
    return id;
  }

  static Future<Map<String, dynamic>?> _readRow() =>
      _db.from(_table).select().eq('user_id', _userId).maybeSingle();

  static Future<Map<String, dynamic>> _createRow(
    Map<String, dynamic> values,
  ) async {
    await _db.from(_table).insert({'user_id': _userId, ...values});
    final row = await _readRow();
    if (row == null) {
      throw StateError(
        'Could not create your settings. Check the app_settings SQL migration and RLS policies.',
      );
    }
    return row;
  }

  static Future<void> fetch() async {
    final row = await _readRow() ?? await _createRow({});
    current.value = AppSettings.fromRow(row);
  }

  /// Explicit select-then-insert-or-update rather than `upsert(onConflict:
  /// ...)` — onboarding can call setters like [setDueDate] before any
  /// `app_settings` row exists yet for this user, and right after email
  /// verification the session is fresh enough that an `INSERT ... ON
  /// CONFLICT ... RETURNING` can come back with zero rows under RLS
  /// (PGRST116) even though the write itself succeeds. A plain, separate
  /// insert/update avoids relying on that merge-and-return-in-one-step
  /// behavior.
  static Future<void> _patch(Map<String, dynamic> updates) async {
    final existing = await _readRow();
    late final Map<String, dynamic> row;
    if (existing == null) {
      try {
        row = await _createRow(updates);
      } on PostgrestException catch (e) {
        // A unique-violation here means a row for this user was created by
        // a concurrent request between the select above and this insert —
        // fall back to updating it instead.
        if (e.code != '23505') rethrow;
        await _db.from(_table).update(updates).eq('user_id', _userId);
        row = (await _readRow())!;
      }
    } else {
      // A settings row can be deleted between the read above and this update
      // (or be hidden briefly while a new session's RLS claims settle). Do
      // not turn that normal zero-row result into PGRST116 for onboarding.
      await _db.from(_table).update(updates).eq('user_id', _userId);
      final updated = await _readRow();
      if (updated != null) {
        row = updated;
      } else {
        row = await _createRow(updates);
      }
    }
    current.value = AppSettings.fromRow(row);
  }

  static String _timeToRow(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static Future<void> setPeriodReminders(bool v) =>
      _patch({'period_reminders': v});
  static Future<void> setFertileWindowAlerts(bool v) =>
      _patch({'fertile_window_alerts': v});
  static Future<void> setDailyCheckin(bool v) => _patch({'daily_checkin': v});
  static Future<void> setDailyCheckinTime(TimeOfDay t) =>
      _patch({'daily_checkin_time': _timeToRow(t)});
  static Future<void> setCommunityActivity(bool v) =>
      _patch({'community_activity': v});
  static Future<void> setWeeklyInsights(bool v) =>
      _patch({'weekly_insights': v});
  static Future<void> setBloomAiCheckins(bool v) =>
      _patch({'bloom_ai_checkins': v});
  static Future<void> setPostAnonymously(bool v) =>
      _patch({'post_anonymously': v});
  static Future<void> setShareResearchData(bool v) =>
      _patch({'share_research_data': v});
  static Future<void> setAppLock(bool v) => _patch({'app_lock': v});
  static Future<void> setUnits(String v) => _patch({'units': v});
  static Future<void> setHapticFeedback(bool v) =>
      _patch({'haptic_feedback': v});

  /// Cycle & pregnancy settings screens save everything at once via a
  /// "Save Settings" button rather than per-field, so they get one combined
  /// call each.
  static Future<void> saveCycleSettings({
    required int cycleLength,
    required int periodLength,
    required int lutealLength,
    required Set<String> tracking,
  }) => _patch({
    'cycle_length': cycleLength,
    'period_length': periodLength,
    'luteal_length': lutealLength,
    'cycle_tracking': tracking.toList(),
  });

  /// Called by onboarding once a due date is known (entered directly, or
  /// computed from a last-period date via Naegele's rule). Also stores the
  /// matching week number so anything still reading the raw
  /// `pregnancy_current_week` column stays consistent.
  static Future<void> setDueDate(DateTime dueDate) {
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
    final week = (40 - (daysUntilDue / 7).ceil()).clamp(1, 42);
    return _patch({
      'due_date': _isoDate(dueDate),
      'pregnancy_current_week': week,
    });
  }

  /// Pregnancy Settings' manual "current week" stepper. Keeps `due_date` in
  /// sync (reverse-computed) so every screen — whichever value it reads —
  /// agrees.
  static Future<void> savePregnancySettings({
    required int currentWeek,
    required double prePregnancyWeightLb,
    required Set<String> tracking,
  }) => _patch({
    'pregnancy_current_week': currentWeek,
    'due_date': _isoDate(
      DateTime.now().add(Duration(days: (40 - currentWeek) * 7)),
    ),
    'pre_pregnancy_weight_lb': prePregnancyWeightLb,
    'pregnancy_tracking': tracking.toList(),
  });
}
