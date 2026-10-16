import 'package:flutter/foundation.dart';

import '../../../core/supabase_config.dart';

class PregnancyKickLog {
  const PregnancyKickLog({required this.id, required this.occurredAt});

  final String id;
  final DateTime occurredAt;

  factory PregnancyKickLog.fromRow(Map<String, dynamic> row) =>
      PregnancyKickLog(
        id: row['id'] as String,
        occurredAt: DateTime.parse(row['occurred_at'] as String).toLocal(),
      );
}

class PregnancyKickStore {
  PregnancyKickStore._();

  static final logs = ValueNotifier<List<PregnancyKickLog>>([]);

  static String get _userId {
    final id = SupabaseConfig.client.auth.currentUser?.id;
    if (id == null) throw StateError('You must be signed in to log kicks.');
    return id;
  }

  static DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static Future<void> fetchToday() async {
    final start = _startOfToday();
    final end = start.add(const Duration(days: 1));
    final rows = await SupabaseConfig.client
        .from('pregnancy_kick_logs')
        .select()
        .eq('user_id', _userId)
        .gte('occurred_at', start.toUtc().toIso8601String())
        .lt('occurred_at', end.toUtc().toIso8601String())
        .order('occurred_at');
    logs.value = rows.map(PregnancyKickLog.fromRow).toList();
  }

  static Future<void> addKick() async {
    final row = await SupabaseConfig.client
        .from('pregnancy_kick_logs')
        .insert({
          'user_id': _userId,
          'occurred_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select()
        .single();
    logs.value = [...logs.value, PregnancyKickLog.fromRow(row)];
  }

  static Future<void> resetToday() async {
    final start = _startOfToday();
    final end = start.add(const Duration(days: 1));
    await SupabaseConfig.client
        .from('pregnancy_kick_logs')
        .delete()
        .eq('user_id', _userId)
        .gte('occurred_at', start.toUtc().toIso8601String())
        .lt('occurred_at', end.toUtc().toIso8601String());
    logs.value = [];
  }
}
