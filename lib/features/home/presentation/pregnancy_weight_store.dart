import 'package:flutter/foundation.dart';

import '../../../core/supabase_config.dart';

class PregnancyWeightEntry {
  const PregnancyWeightEntry({
    required this.id,
    required this.recordedOn,
    required this.weightLb,
  });

  final String id;
  final DateTime recordedOn;
  final double weightLb;

  factory PregnancyWeightEntry.fromRow(Map<String, dynamic> row) =>
      PregnancyWeightEntry(
        id: row['id'] as String,
        recordedOn: DateTime.parse(row['recorded_on'] as String),
        weightLb: (row['weight_lb'] as num).toDouble(),
      );
}

class PregnancyWeightStore {
  PregnancyWeightStore._();

  static final entries = ValueNotifier<List<PregnancyWeightEntry>>([]);

  static String get _userId {
    final id = SupabaseConfig.client.auth.currentUser?.id;
    if (id == null) throw StateError('You must be signed in to save weight.');
    return id;
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  static Future<void> fetch() async {
    final rows = await SupabaseConfig.client
        .from('pregnancy_weight_entries')
        .select()
        .eq('user_id', _userId)
        .order('recorded_on');
    entries.value = rows.map(PregnancyWeightEntry.fromRow).toList();
  }

  static Future<void> saveToday(double weightLb) async {
    final roundedWeight = double.parse(weightLb.toStringAsFixed(1));
    if (!roundedWeight.isFinite || roundedWeight < 60 || roundedWeight > 400) {
      throw ArgumentError('Weight must be between 27.2 kg and 181.4 kg.');
    }

    final userId = _userId;
    final today = _date(DateTime.now());
    final savedRow = await SupabaseConfig.client
        .from('pregnancy_weight_entries')
        .upsert({
          'user_id': userId,
          'recorded_on': today,
          'weight_lb': roundedWeight,
        }, onConflict: 'user_id,recorded_on')
        .select()
        .single();

    final saved = PregnancyWeightEntry.fromRow(savedRow);
    final updated = [...entries.value]
      ..removeWhere((entry) => entry.id == saved.id)
      ..add(saved)
      ..sort((a, b) => a.recordedOn.compareTo(b.recordedOn));
    entries.value = updated;
  }
}
