import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_session.dart';
import 'supabase_config.dart';

/// First word of a full name, for greetings — falls back to "there" when
/// no name is known yet (e.g. profile still loading).
String firstNameOf(String? fullName) {
  final trimmed = fullName?.trim() ?? '';
  if (trimmed.isEmpty) return 'there';
  return trimmed.split(RegExp(r'\s+')).first;
}

/// A friendly dashboard greeting based on the user's local device time.
String greetingForTime([DateTime? time]) {
  final hour = (time ?? DateTime.now()).hour;
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

class UserProfile {
  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.birthDate,
    this.journeyStage,
    this.appMode,
  });

  final String id;
  String fullName;
  String email;
  DateTime? birthDate;
  String? journeyStage;
  AppMode? appMode;

  factory UserProfile.fromRow(Map<String, dynamic> row) => UserProfile(
    id: row['id'] as String,
    fullName: row['full_name'] as String,
    email: row['email'] as String,
    birthDate: row['birth_date'] == null
        ? null
        : DateTime.parse(row['birth_date'] as String),
    journeyStage: row['journey_stage'] as String?,
    appMode: switch (row['app_mode'] as String?) {
      'familyPlanning' => AppMode.familyPlanning,
      'pregnancy' => AppMode.pregnancy,
      'babyCare' => AppMode.babyCare,
      _ => null,
    },
  );
}

/// Thrown when an account-scoped action is attempted without a signed-in
/// user — personal details and the remembered app mode belong to *your*
/// account, so they require an active Supabase session.
class ProfileException implements Exception {
  ProfileException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Reads/writes the signed-in user's row in `profiles`.
class ProfileStore {
  ProfileStore._();

  static const String _table = 'profiles';
  static SupabaseClient get _db => SupabaseConfig.client;

  static final ValueNotifier<UserProfile?> current =
      ValueNotifier<UserProfile?>(null);

  static Future<void> fetchCurrent() async {
    final user = _db.auth.currentUser;
    if (user == null) {
      current.value = null;
      return;
    }
    final row = await _db.from(_table).select().eq('id', user.id).maybeSingle();
    if (row == null) {
      current.value = null;
      return;
    }
    final profile = UserProfile.fromRow(row);
    current.value = profile;
    if (profile.appMode != null) AppSession.mode = profile.appMode!;
  }

  static Future<void> update({
    String? fullName,
    DateTime? birthDate,
    String? journeyStage,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) {
      throw ProfileException('Please log in to save your details.');
    }
    final updates = <String, dynamic>{
      'full_name': ?fullName,
      if (birthDate != null) 'birth_date': _isoDate(birthDate),
      'journey_stage': ?journeyStage,
    };
    if (updates.isEmpty) return;
    final row = await _db
        .from(_table)
        .update(updates)
        .eq('id', user.id)
        .select()
        .single();
    current.value = UserProfile.fromRow(row);
  }

  /// Best-effort: called when onboarding finishes. Silently does nothing
  /// if there's no session yet (e.g. email not confirmed) so it never
  /// blocks the "Go to Dashboard" button.
  static Future<void> rememberAppMode(AppMode mode) async {
    final user = _db.auth.currentUser;
    if (user == null) return;
    try {
      final row = await _db
          .from(_table)
          .update({'app_mode': mode.name})
          .eq('id', user.id)
          .select()
          .single();
      current.value = UserProfile.fromRow(row);
    } catch (_) {
      // Best-effort — AppSession.mode already holds the choice in memory.
    }
  }

  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
