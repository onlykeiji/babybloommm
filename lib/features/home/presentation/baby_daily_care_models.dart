import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_config.dart';

enum BabyCareLogKind { feeding, diaper, sleep }

extension BabyCareLogKindMeta on BabyCareLogKind {
  String get label => switch (this) {
    BabyCareLogKind.feeding => 'Feeding',
    BabyCareLogKind.diaper => 'Diaper',
    BabyCareLogKind.sleep => 'Sleep',
  };

  IconData get icon => switch (this) {
    BabyCareLogKind.feeding => Icons.restaurant_outlined,
    BabyCareLogKind.diaper => Icons.baby_changing_station_outlined,
    BabyCareLogKind.sleep => Icons.nightlight_round,
  };
}

class BabyCareLog {
  const BabyCareLog({
    required this.id,
    required this.babyId,
    required this.kind,
    required this.occurredAt,
    this.durationMinutes,
    this.amount,
    this.details = '',
  });

  final String id;
  final String babyId;
  final BabyCareLogKind kind;
  final DateTime occurredAt;
  final int? durationMinutes;
  final double? amount;
  final String details;

  factory BabyCareLog.fromRow(Map<String, dynamic> row) => BabyCareLog(
    id: row['id'] as String,
    babyId: row['baby_id'] as String,
    kind: BabyCareLogKind.values.byName(row['kind'] as String),
    occurredAt: DateTime.parse(row['occurred_at'] as String).toLocal(),
    durationMinutes: row['duration_minutes'] as int?,
    amount: (row['amount'] as num?)?.toDouble(),
    details: (row['details'] as String?) ?? '',
  );
}

class BabyCareLogStore {
  BabyCareLogStore._();

  static const _table = 'baby_care_logs';
  static SupabaseClient get _db => SupabaseConfig.client;
  static final entries = ValueNotifier<List<BabyCareLog>>([]);

  static String get _userId {
    final id = _db.auth.currentUser?.id;
    if (id == null) {
      throw StateError('You must be signed in to save baby care logs.');
    }
    return id;
  }

  static void _validate({
    required DateTime occurredAt,
    int? durationMinutes,
    double? amount,
    required String details,
  }) {
    if (occurredAt.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      throw ArgumentError('Activity time cannot be in the future.');
    }
    if (durationMinutes != null &&
        (durationMinutes <= 0 || durationMinutes > 1440)) {
      throw ArgumentError('Duration must be between 1 and 1,440 minutes.');
    }
    if (amount != null && (amount <= 0 || amount > 2000)) {
      throw ArgumentError('Amount must be between 1 and 2,000 ml.');
    }
    if (details.trim().length > 250) {
      throw ArgumentError('Details cannot exceed 250 characters.');
    }
  }

  static Future<void> fetchForBaby(String babyId) async {
    final rows = await _db
        .from(_table)
        .select()
        .eq('baby_id', babyId)
        .order('occurred_at', ascending: false);
    entries.value = rows.map(BabyCareLog.fromRow).toList();
  }

  static Future<void> add({
    required String babyId,
    required BabyCareLogKind kind,
    required DateTime occurredAt,
    int? durationMinutes,
    double? amount,
    String details = '',
  }) async {
    _validate(
      occurredAt: occurredAt,
      durationMinutes: durationMinutes,
      amount: amount,
      details: details,
    );
    final row = await _db
        .from(_table)
        .insert({
          'user_id': _userId,
          'baby_id': babyId,
          'kind': kind.name,
          'occurred_at': occurredAt.toUtc().toIso8601String(),
          'duration_minutes': durationMinutes,
          'amount': amount,
          'details': details.trim(),
        })
        .select()
        .single();
    entries.value = [BabyCareLog.fromRow(row), ...entries.value];
  }

  static Future<void> update({
    required BabyCareLog entry,
    required DateTime occurredAt,
    int? durationMinutes,
    double? amount,
    required String details,
  }) async {
    _validate(
      occurredAt: occurredAt,
      durationMinutes: durationMinutes,
      amount: amount,
      details: details,
    );
    final row = await _db
        .from(_table)
        .update({
          'occurred_at': occurredAt.toUtc().toIso8601String(),
          'duration_minutes': durationMinutes,
          'amount': amount,
          'details': details.trim(),
        })
        .eq('id', entry.id)
        .select()
        .single();
    final saved = BabyCareLog.fromRow(row);
    entries.value = [
      for (final item in entries.value) item.id == saved.id ? saved : item,
    ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }

  static Future<void> remove(BabyCareLog entry) async {
    await _db.from(_table).delete().eq('id', entry.id);
    entries.value = entries.value.where((item) => item.id != entry.id).toList();
  }
}
