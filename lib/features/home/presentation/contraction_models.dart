import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_config.dart';

class Contraction {
  Contraction({
    this.id,
    required this.start,
    required this.duration,
    this.sincePrevious,
  });

  final String? id;
  final DateTime start;
  final Duration duration;
  final Duration? sincePrevious;

  factory Contraction.fromRow(Map<String, dynamic> row) => Contraction(
    id: row['id'] as String,
    start: DateTime.parse(row['start_time'] as String),
    duration: Duration(seconds: row['duration_seconds'] as int),
    sincePrevious: row['since_previous_seconds'] == null
        ? null
        : Duration(seconds: row['since_previous_seconds'] as int),
  );

  Map<String, dynamic> toRow() => {
    'start_time': start.toIso8601String(),
    'duration_seconds': duration.isNegative ? 0 : duration.inSeconds,
    // The SQL constraint correctly rejects negative values. Keep client data
    // valid too, so a bad device clock or imported row cannot block saving.
    'since_previous_seconds': sincePrevious?.isNegative == true
        ? 0
        : sincePrevious?.inSeconds,
  };
}

/// Backs [Contraction] with the `contractions` Supabase table.
class ContractionStore {
  ContractionStore._();

  static const String _table = 'contractions';
  static SupabaseClient get _db => SupabaseConfig.client;

  static final ValueNotifier<List<Contraction>> history =
      ValueNotifier<List<Contraction>>([]);
  static final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  static Future<void> fetchAll() async {
    isLoading.value = true;
    try {
      final rows = await _db
          .from(_table)
          .select()
          .order('start_time', ascending: false);
      history.value = rows.map(Contraction.fromRow).toList();
    } finally {
      isLoading.value = false;
    }
  }

  static Future<void> add(Contraction contraction) async {
    final row = await _db
        .from(_table)
        .insert(contraction.toRow())
        .select()
        .single();
    history.value = [Contraction.fromRow(row), ...history.value];
  }

  static Future<void> clearAll() async {
    final ids = history.value.map((c) => c.id).whereType<String>().toList();
    if (ids.isEmpty) return;
    await _db.from(_table).delete().inFilter('id', ids);
    history.value = [];
  }
}
