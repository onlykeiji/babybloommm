import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_config.dart';

enum BabyGender { boy, girl, other }

extension BabyGenderMeta on BabyGender {
  String get label => switch (this) {
    BabyGender.boy => 'Boy',
    BabyGender.girl => 'Girl',
    BabyGender.other => 'Prefer not to say',
  };
}

class BabyProfile {
  BabyProfile({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    this.birthWeightLb,
    this.birthLengthIn,
  });

  final String id;
  String name;
  DateTime dateOfBirth;
  BabyGender gender;
  double? birthWeightLb;
  double? birthLengthIn;

  factory BabyProfile.fromRow(Map<String, dynamic> row) => BabyProfile(
    id: row['id'] as String,
    name: row['name'] as String,
    dateOfBirth: DateTime.parse(row['date_of_birth'] as String),
    gender: BabyGender.values.byName(row['gender'] as String),
    birthWeightLb: (row['birth_weight_lb'] as num?)?.toDouble(),
    birthLengthIn: (row['birth_length_in'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toRow() => {
    'name': name,
    'date_of_birth': _isoDate(dateOfBirth),
    'gender': gender.name,
    'birth_weight_lb': birthWeightLb,
    'birth_length_in': birthLengthIn,
  };

  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

/// Thrown when a [BabyProfile] fails client-side validation before it's
/// sent to Supabase.
class BabyProfileValidationError implements Exception {
  BabyProfileValidationError(this.message);
  final String message;

  @override
  String toString() => message;
}

void _validateBabyProfile(BabyProfile baby) {
  if (baby.name.trim().isEmpty) {
    throw BabyProfileValidationError("Baby's name is required.");
  }
  if (baby.dateOfBirth.isAfter(DateTime.now())) {
    throw BabyProfileValidationError('Birthdate cannot be in the future.');
  }
  final weight = baby.birthWeightLb;
  if (weight != null && (weight <= 0 || weight > 30)) {
    throw BabyProfileValidationError(
      'Birth weight must be between 0 and 30 lb.',
    );
  }
  final length = baby.birthLengthIn;
  if (length != null && (length <= 0 || length > 30)) {
    throw BabyProfileValidationError(
      'Birth length must be between 0 and 30 in.',
    );
  }
}

/// Human-friendly age like "9 weeks old", "3 months old", "1 year old".
String babyAgeLabel(DateTime dateOfBirth) {
  final days = DateTime.now().difference(dateOfBirth).inDays;
  if (days < 0) return 'Not born yet';
  if (days < 14) return '$days ${days == 1 ? 'day' : 'days'} old';
  final weeks = days ~/ 7;
  if (weeks < 8) return '$weeks ${weeks == 1 ? 'week' : 'weeks'} old';
  final months = (days / 30.44).floor();
  if (months < 24) return '$months ${months == 1 ? 'month' : 'months'} old';
  final years = (months / 12).floor();
  return '$years ${years == 1 ? 'year' : 'years'} old';
}

/// Baby's age in fractional months — used to position points on growth charts.
double babyAgeInMonths(DateTime dateOfBirth) =>
    DateTime.now().difference(dateOfBirth).inDays / 30.44;

/// Backs [BabyProfile] records with the `baby_profiles` table in Supabase.
///
/// Reads/writes go straight to Supabase; [babies] is kept as a local cache
/// so the rest of the app can keep listening to a `ValueNotifier` the same
/// way it did when this store was in-memory only.
class BabyProfileStore {
  BabyProfileStore._();

  static const String _table = 'baby_profiles';
  static SupabaseClient get _db => SupabaseConfig.client;

  static final ValueNotifier<List<BabyProfile>> babies =
      ValueNotifier<List<BabyProfile>>([]);

  static final ValueNotifier<String> activeBabyId = ValueNotifier<String>('');

  static final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  static BabyProfile get active => babies.value.firstWhere(
    (b) => b.id == activeBabyId.value,
    orElse: () => babies.value.first,
  );

  /// READ — loads every baby profile belonging to this project from Supabase.
  static Future<void> fetchAll() async {
    isLoading.value = true;
    try {
      final rows = await _db.from(_table).select().order('created_at');
      final loaded = rows.map(BabyProfile.fromRow).toList();
      babies.value = loaded;
      if (loaded.isNotEmpty && !loaded.any((b) => b.id == activeBabyId.value)) {
        activeBabyId.value = loaded.first.id;
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// CREATE — inserts a new baby profile and adds it to the local cache.
  static Future<void> addBaby(BabyProfile baby) async {
    _validateBabyProfile(baby);
    if (babies.value.isNotEmpty) {
      throw BabyProfileValidationError(
        'Only one baby profile is allowed. Edit the existing profile instead.',
      );
    }
    final userId = _db.auth.currentUser?.id;
    if (userId == null) {
      throw BabyProfileValidationError('You must be signed in first.');
    }
    final row = await _db
        .from(_table)
        .insert({...baby.toRow(), 'user_id': userId})
        .select()
        .single();
    final created = BabyProfile.fromRow(row);
    babies.value = [...babies.value, created];
    activeBabyId.value = created.id;
  }

  /// UPDATE — persists edits to an existing baby profile.
  static Future<void> updateBaby(BabyProfile updated) async {
    _validateBabyProfile(updated);
    final row = await _db
        .from(_table)
        .update(updated.toRow())
        .eq('id', updated.id)
        .select()
        .single();
    final saved = BabyProfile.fromRow(row);
    babies.value = [for (final b in babies.value) b.id == saved.id ? saved : b];
  }

  /// DELETE — removes a baby profile permanently.
  static Future<void> removeBaby(String id) async {
    await _db.from(_table).delete().eq('id', id);
    final remaining = babies.value.where((b) => b.id != id).toList();
    babies.value = remaining;
    if (activeBabyId.value == id && remaining.isNotEmpty) {
      activeBabyId.value = remaining.first.id;
    } else if (remaining.isEmpty) {
      activeBabyId.value = '';
    }
  }

  static void setActive(String id) => activeBabyId.value = id;
}

enum GrowthMetric { weight, height, headCircumference }

extension GrowthMetricMeta on GrowthMetric {
  String get label => switch (this) {
    GrowthMetric.weight => 'Weight',
    GrowthMetric.height => 'Height',
    GrowthMetric.headCircumference => 'Head circumference',
  };

  String get unit => switch (this) {
    GrowthMetric.weight => 'lb',
    GrowthMetric.height => 'in',
    GrowthMetric.headCircumference => 'in',
  };

  IconData get icon => switch (this) {
    GrowthMetric.weight => Icons.monitor_weight_outlined,
    GrowthMetric.height => Icons.straighten_outlined,
    GrowthMetric.headCircumference => Icons.face_outlined,
  };
}

class GrowthEntry {
  GrowthEntry({
    this.id,
    required this.babyId,
    required this.date,
    required this.metric,
    required this.value,
  });

  final String? id;
  final String babyId;
  final DateTime date;
  final GrowthMetric metric;
  final double value;

  factory GrowthEntry.fromRow(Map<String, dynamic> row) => GrowthEntry(
    id: row['id'] as String,
    babyId: row['baby_id'] as String,
    date: DateTime.parse(row['date'] as String),
    metric: GrowthMetric.values.byName(row['metric'] as String),
    value: (row['value'] as num).toDouble(),
  );

  Map<String, dynamic> toRow() => {
    'baby_id': babyId,
    'date': BabyProfile._isoDate(date),
    'metric': metric.name,
    'value': value,
  };
}

void _validateGrowthEntry(GrowthEntry entry) {
  if (entry.date.isAfter(DateTime.now())) {
    throw BabyProfileValidationError('Entry date cannot be in the future.');
  }
  if (entry.value <= 0 || entry.value > 100) {
    throw BabyProfileValidationError('Value must be between 0 and 100.');
  }
}

/// Backs [GrowthEntry] with the `growth_entries` Supabase table.
class GrowthLog {
  GrowthLog._();

  static const String _table = 'growth_entries';
  static SupabaseClient get _db => SupabaseConfig.client;

  static final ValueNotifier<List<GrowthEntry>> entries =
      ValueNotifier<List<GrowthEntry>>([]);

  static List<GrowthEntry> forBaby(String babyId, GrowthMetric metric) =>
      entries.value
          .where((e) => e.babyId == babyId && e.metric == metric)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  /// READ — loads every growth entry for one baby from Supabase.
  static Future<void> fetchForBaby(String babyId) async {
    final rows = await _db
        .from(_table)
        .select()
        .eq('baby_id', babyId)
        .order('date');
    final loaded = rows.map(GrowthEntry.fromRow).toList();
    entries.value = [
      ...entries.value.where((e) => e.babyId != babyId),
      ...loaded,
    ];
  }

  /// CREATE.
  static Future<void> add(GrowthEntry entry) async {
    _validateGrowthEntry(entry);
    final row = await _db.from(_table).insert(entry.toRow()).select().single();
    entries.value = [...entries.value, GrowthEntry.fromRow(row)];
  }

  /// UPDATE.
  static Future<void> update(GrowthEntry entry) async {
    if (entry.id == null) {
      throw BabyProfileValidationError(
        'Cannot update an unsaved growth entry.',
      );
    }
    _validateGrowthEntry(entry);
    final row = await _db
        .from(_table)
        .update(entry.toRow())
        .eq('id', entry.id!)
        .select()
        .single();
    final saved = GrowthEntry.fromRow(row);
    entries.value = [
      for (final item in entries.value) item.id == saved.id ? saved : item,
    ];
  }

  /// DELETE.
  static Future<void> remove(GrowthEntry entry) async {
    await _db.from(_table).delete().eq('id', entry.id!);
    entries.value = entries.value.where((e) => e.id != entry.id).toList();
  }
}

/// A single reference point on a simplified WHO-style growth curve.
/// Values are approximate and meant for general illustration only.
class ReferencePoint {
  const ReferencePoint(this.ageMonths, this.p3, this.p50, this.p97);

  final double ageMonths;
  final double p3;
  final double p50;
  final double p97;
}

// Simplified, approximate WHO child-growth-standard reference curves,
// converted to lb / in. These are for general illustration only — not
// clinical percentile calculations. Always defer to a pediatrician.
const List<ReferencePoint> _weightBoy = [
  ReferencePoint(0, 5.7, 7.3, 9.5),
  ReferencePoint(1, 7.6, 9.9, 12.7),
  ReferencePoint(2, 9.3, 12.3, 15.6),
  ReferencePoint(3, 10.6, 14.1, 17.6),
  ReferencePoint(4, 11.5, 15.4, 19.2),
  ReferencePoint(6, 12.8, 17.4, 21.6),
  ReferencePoint(9, 14.4, 19.6, 24.3),
  ReferencePoint(12, 15.4, 21.2, 26.5),
  ReferencePoint(15, 16.2, 22.7, 28.4),
  ReferencePoint(18, 17.0, 24.0, 30.1),
  ReferencePoint(21, 17.7, 25.3, 31.7),
  ReferencePoint(24, 18.4, 26.5, 33.2),
];

const List<ReferencePoint> _weightGirl = [
  ReferencePoint(0, 5.5, 7.0, 9.1),
  ReferencePoint(1, 7.0, 9.2, 11.8),
  ReferencePoint(2, 8.6, 11.3, 14.5),
  ReferencePoint(3, 9.7, 12.9, 16.5),
  ReferencePoint(4, 10.6, 14.2, 18.1),
  ReferencePoint(6, 11.9, 16.1, 20.6),
  ReferencePoint(9, 13.5, 18.3, 23.4),
  ReferencePoint(12, 14.6, 19.9, 25.6),
  ReferencePoint(15, 15.5, 21.4, 27.6),
  ReferencePoint(18, 16.3, 22.8, 29.4),
  ReferencePoint(21, 17.1, 24.1, 31.1),
  ReferencePoint(24, 17.8, 25.4, 32.8),
];

const List<ReferencePoint> _heightBoy = [
  ReferencePoint(0, 18.0, 19.6, 21.3),
  ReferencePoint(1, 20.4, 21.5, 23.2),
  ReferencePoint(2, 21.9, 23.0, 24.8),
  ReferencePoint(3, 22.9, 24.2, 26.0),
  ReferencePoint(4, 23.7, 25.2, 27.0),
  ReferencePoint(6, 24.9, 26.6, 28.5),
  ReferencePoint(9, 26.4, 28.3, 30.4),
  ReferencePoint(12, 27.6, 29.8, 32.1),
  ReferencePoint(15, 28.6, 31.1, 33.7),
  ReferencePoint(18, 29.5, 32.4, 35.2),
  ReferencePoint(21, 30.3, 33.5, 36.5),
  ReferencePoint(24, 31.0, 34.6, 37.8),
];

const List<ReferencePoint> _heightGirl = [
  ReferencePoint(0, 17.8, 19.3, 21.0),
  ReferencePoint(1, 20.0, 21.1, 22.8),
  ReferencePoint(2, 21.4, 22.6, 24.4),
  ReferencePoint(3, 22.5, 23.8, 25.7),
  ReferencePoint(4, 23.4, 24.8, 26.8),
  ReferencePoint(6, 24.6, 26.2, 28.4),
  ReferencePoint(9, 26.1, 27.9, 30.4),
  ReferencePoint(12, 27.4, 29.5, 32.2),
  ReferencePoint(15, 28.4, 30.9, 33.9),
  ReferencePoint(18, 29.4, 32.2, 35.4),
  ReferencePoint(21, 30.2, 33.4, 36.8),
  ReferencePoint(24, 31.0, 34.5, 38.2),
];

const List<ReferencePoint> _headBoy = [
  ReferencePoint(0, 12.8, 13.6, 14.4),
  ReferencePoint(1, 13.7, 14.7, 15.6),
  ReferencePoint(2, 14.4, 15.4, 16.4),
  ReferencePoint(3, 14.9, 15.9, 16.9),
  ReferencePoint(4, 15.3, 16.4, 17.4),
  ReferencePoint(6, 15.9, 17.0, 18.1),
  ReferencePoint(9, 16.5, 17.7, 18.8),
  ReferencePoint(12, 16.9, 18.1, 19.3),
  ReferencePoint(15, 17.2, 18.5, 19.7),
  ReferencePoint(18, 17.5, 18.8, 20.0),
  ReferencePoint(21, 17.7, 19.0, 20.3),
  ReferencePoint(24, 17.9, 19.2, 20.5),
];

const List<ReferencePoint> _headGirl = [
  ReferencePoint(0, 12.6, 13.4, 14.2),
  ReferencePoint(1, 13.4, 14.4, 15.3),
  ReferencePoint(2, 14.1, 15.1, 16.1),
  ReferencePoint(3, 14.6, 15.6, 16.7),
  ReferencePoint(4, 15.0, 16.1, 17.2),
  ReferencePoint(6, 15.6, 16.7, 17.9),
  ReferencePoint(9, 16.2, 17.4, 18.6),
  ReferencePoint(12, 16.6, 17.8, 19.1),
  ReferencePoint(15, 16.9, 18.2, 19.4),
  ReferencePoint(18, 17.2, 18.5, 19.8),
  ReferencePoint(21, 17.4, 18.7, 20.0),
  ReferencePoint(24, 17.6, 18.9, 20.2),
];

List<ReferencePoint> referenceCurveFor(GrowthMetric metric, BabyGender gender) {
  List<ReferencePoint> pick(
    List<ReferencePoint> boy,
    List<ReferencePoint> girl,
  ) {
    if (gender == BabyGender.boy) return boy;
    if (gender == BabyGender.girl) return girl;
    return [
      for (var i = 0; i < boy.length; i++)
        ReferencePoint(
          boy[i].ageMonths,
          (boy[i].p3 + girl[i].p3) / 2,
          (boy[i].p50 + girl[i].p50) / 2,
          (boy[i].p97 + girl[i].p97) / 2,
        ),
    ];
  }

  return switch (metric) {
    GrowthMetric.weight => pick(_weightBoy, _weightGirl),
    GrowthMetric.height => pick(_heightBoy, _heightGirl),
    GrowthMetric.headCircumference => pick(_headBoy, _headGirl),
  };
}

class MilestoneDef {
  const MilestoneDef({
    required this.title,
    required this.icon,
    required this.targetMonth,
    required this.domain,
    this.targetDays,
    this.legacyTitles = const [],
  });

  final String title;
  final IconData icon;
  final int targetMonth;
  final String domain;
  final int? targetDays;
  final List<String> legacyTitles;

  int get targetAgeDays => targetDays ?? (targetMonth * 30.44).round();

  String get checkpointLabel => targetDays == 14
      ? 'First 2 weeks'
      : targetDays == 28
      ? 'By 4 weeks'
      : targetMonth == 12
      ? 'By 1 year'
      : targetMonth == 24
      ? 'By 2 years'
      : 'By $targetMonth months';

  String get meaning => switch (domain) {
    'Social' =>
      'Shows how your baby connects with familiar people and responds during shared interactions.',
    'Language' =>
      'Shows early communication through sounds, gestures, understanding, or words.',
    'Movement' =>
      'Shows developing strength, balance, coordination, and control of body movements.',
    'Vision' =>
      'Shows that your baby is beginning to focus on and notice nearby people or objects.',
    'Hearing' =>
      'Shows awareness of sounds and growing recognition of familiar voices.',
    _ => 'An age-based developmental skill to observe during everyday care.',
  };

  String get activity => switch (domain) {
    'Social' =>
      'Try: Talk face-to-face, smile, copy your baby\'s expressions, and pause for a response.',
    'Language' =>
      'Try: Narrate daily routines, repeat your baby\'s sounds, sing, and read a short book.',
    'Movement' =>
      'Try: Offer supervised floor or tummy time and place a safe toy just within reach.',
    'Vision' =>
      'Try: Hold your face or a high-contrast object nearby and move it slowly side to side.',
    'Hearing' =>
      'Try: Speak gently from nearby, change sides, and observe whether your baby responds.',
    _ =>
      'Try: Practice through short, playful activities when your baby is calm and alert.',
  };
}

const List<MilestoneDef> babyMilestones = [
  MilestoneDef(
    title: 'Looks briefly at a nearby face',
    icon: Icons.face_outlined,
    targetMonth: 0,
    targetDays: 14,
    domain: 'Vision',
  ),
  MilestoneDef(
    title: 'Reacts or startles to a loud sound',
    icon: Icons.hearing_outlined,
    targetMonth: 0,
    targetDays: 14,
    domain: 'Hearing',
  ),
  MilestoneDef(
    title: 'Moves both arms and both legs',
    icon: Icons.accessibility_new_rounded,
    targetMonth: 0,
    targetDays: 14,
    domain: 'Movement',
  ),
  MilestoneDef(
    title: 'Turns toward a familiar voice',
    icon: Icons.hearing_rounded,
    targetMonth: 1,
    targetDays: 28,
    domain: 'Hearing',
  ),
  MilestoneDef(
    title: 'Brings hands near eyes or mouth',
    icon: Icons.pan_tool_alt_outlined,
    targetMonth: 1,
    targetDays: 28,
    domain: 'Movement',
  ),
  MilestoneDef(
    title: 'Moves head side to side during tummy time',
    icon: Icons.sync_alt_rounded,
    targetMonth: 1,
    targetDays: 28,
    domain: 'Movement',
  ),
  MilestoneDef(
    title: 'Smiles when you talk or smile',
    icon: Icons.mood_outlined,
    targetMonth: 2,
    domain: 'Social',
    legacyTitles: ['Social smile'],
  ),
  MilestoneDef(
    title: 'Makes sounds other than crying',
    icon: Icons.record_voice_over_outlined,
    targetMonth: 2,
    domain: 'Language',
  ),
  MilestoneDef(
    title: 'Holds head up during tummy time',
    icon: Icons.accessibility_new_rounded,
    targetMonth: 2,
    domain: 'Movement',
  ),
  MilestoneDef(
    title: 'Chuckles when encouraged to laugh',
    icon: Icons.sentiment_very_satisfied_outlined,
    targetMonth: 4,
    domain: 'Social',
  ),
  MilestoneDef(
    title: 'Coos and responds with sounds',
    icon: Icons.chat_bubble_outline_rounded,
    targetMonth: 4,
    domain: 'Language',
  ),
  MilestoneDef(
    title: 'Holds head steady without support',
    icon: Icons.accessibility_new_rounded,
    targetMonth: 4,
    domain: 'Movement',
  ),
  MilestoneDef(
    title: 'Laughs and recognizes familiar people',
    icon: Icons.people_outline_rounded,
    targetMonth: 6,
    domain: 'Social',
  ),
  MilestoneDef(
    title: 'Takes turns making sounds with you',
    icon: Icons.forum_outlined,
    targetMonth: 6,
    domain: 'Language',
  ),
  MilestoneDef(
    title: 'Rolls from tummy to back',
    icon: Icons.sync_alt_rounded,
    targetMonth: 6,
    domain: 'Movement',
    legacyTitles: ['Rolling over'],
  ),
  MilestoneDef(
    title: 'Looks when their name is called',
    icon: Icons.visibility_outlined,
    targetMonth: 9,
    domain: 'Social',
  ),
  MilestoneDef(
    title: 'Makes repeated sounds like mamamama',
    icon: Icons.record_voice_over_outlined,
    targetMonth: 9,
    domain: 'Language',
  ),
  MilestoneDef(
    title: 'Sits without support',
    icon: Icons.event_seat_outlined,
    targetMonth: 9,
    domain: 'Movement',
    legacyTitles: ['Sitting without support', 'Crawling'],
  ),
  MilestoneDef(
    title: 'Waves bye-bye',
    icon: Icons.waving_hand_outlined,
    targetMonth: 12,
    domain: 'Social',
  ),
  MilestoneDef(
    title: 'Calls a parent mama, dada, or another name',
    icon: Icons.chat_outlined,
    targetMonth: 12,
    domain: 'Language',
    legacyTitles: ['First words'],
  ),
  MilestoneDef(
    title: 'Pulls up to stand and walks holding furniture',
    icon: Icons.directions_walk_outlined,
    targetMonth: 12,
    domain: 'Movement',
  ),
  MilestoneDef(
    title: 'Copies other children while playing',
    icon: Icons.groups_outlined,
    targetMonth: 15,
    domain: 'Social',
  ),
  MilestoneDef(
    title: 'Tries to say one or two words besides mama or dada',
    icon: Icons.speaker_notes_outlined,
    targetMonth: 15,
    domain: 'Language',
  ),
  MilestoneDef(
    title: 'Takes a few steps independently',
    icon: Icons.directions_walk_rounded,
    targetMonth: 15,
    domain: 'Movement',
  ),
  MilestoneDef(
    title: 'Points to show something interesting',
    icon: Icons.touch_app_outlined,
    targetMonth: 18,
    domain: 'Social',
  ),
  MilestoneDef(
    title: 'Says three or more words besides mama or dada',
    icon: Icons.record_voice_over_outlined,
    targetMonth: 18,
    domain: 'Language',
  ),
  MilestoneDef(
    title: 'Walks without holding on',
    icon: Icons.directions_walk_rounded,
    targetMonth: 18,
    domain: 'Movement',
    legacyTitles: ['Walking independently'],
  ),
  MilestoneDef(
    title: 'Notices when others are hurt or upset',
    icon: Icons.favorite_outline_rounded,
    targetMonth: 24,
    domain: 'Social',
  ),
  MilestoneDef(
    title: 'Says at least two words together',
    icon: Icons.chat_bubble_outline_rounded,
    targetMonth: 24,
    domain: 'Language',
  ),
  MilestoneDef(
    title: 'Runs and kicks a ball',
    icon: Icons.sports_soccer_outlined,
    targetMonth: 24,
    domain: 'Movement',
  ),
];

/// Backs milestone achievements with the `milestones` Supabase table.
class MilestoneLog {
  MilestoneLog._();

  static const String _table = 'milestones';
  static SupabaseClient get _db => SupabaseConfig.client;

  /// babyId -> milestone title -> date achieved.
  static final ValueNotifier<Map<String, Map<String, DateTime>>> achieved =
      ValueNotifier<Map<String, Map<String, DateTime>>>({});

  static bool isAchieved(String babyId, String title) =>
      achieved.value[babyId]?.containsKey(title) ?? false;

  static bool isMilestoneAchieved(String babyId, MilestoneDef milestone) =>
      <String>[
        milestone.title,
        ...milestone.legacyTitles,
      ].any((title) => isAchieved(babyId, title));

  static DateTime? dateOf(String babyId, String title) =>
      achieved.value[babyId]?[title];

  static DateTime? dateOfMilestone(String babyId, MilestoneDef milestone) {
    final entries = achieved.value[babyId];
    if (entries == null) return null;
    for (final title in [milestone.title, ...milestone.legacyTitles]) {
      final date = entries[title];
      if (date != null) return date;
    }
    return null;
  }

  /// READ — loads every achieved milestone for one baby from Supabase.
  static Future<void> fetchForBaby(String babyId) async {
    final rows = await _db.from(_table).select().eq('baby_id', babyId);
    final forBaby = <String, DateTime>{
      for (final row in rows)
        row['title'] as String: DateTime.parse(row['achieved_date'] as String),
    };
    achieved.value = {...achieved.value, babyId: forBaby};
  }

  static Future<void> markAchieved(
    BabyProfile baby,
    MilestoneDef milestone,
    DateTime date,
  ) async {
    final ageDays = DateTime.now().difference(baby.dateOfBirth).inDays;
    if (ageDays < milestone.targetAgeDays) {
      throw BabyProfileValidationError(
        '${milestone.title} becomes available ${milestone.checkpointLabel.toLowerCase()}.',
      );
    }
    if (date.isBefore(baby.dateOfBirth) || date.isAfter(DateTime.now())) {
      throw BabyProfileValidationError(
        'The milestone date must be between the birthdate and today.',
      );
    }
    await _db.from(_table).upsert({
      'baby_id': baby.id,
      'title': milestone.title,
      'achieved_date': BabyProfile._isoDate(date),
    }, onConflict: 'baby_id,title');
    final next = {...achieved.value};
    final forBaby = {...(next[baby.id] ?? {})};
    forBaby[milestone.title] = date;
    next[baby.id] = forBaby;
    achieved.value = next;
  }

  static Future<void> unmark(String babyId, String title) async {
    await _db.from(_table).delete().eq('baby_id', babyId).eq('title', title);
    final next = {...achieved.value};
    final forBaby = {...(next[babyId] ?? {})};
    forBaby.remove(title);
    next[babyId] = forBaby;
    achieved.value = next;
  }

  static Future<void> unmarkMilestone(
    String babyId,
    MilestoneDef milestone,
  ) async {
    for (final title in [milestone.title, ...milestone.legacyTitles]) {
      if (isAchieved(babyId, title)) await unmark(babyId, title);
    }
  }
}
