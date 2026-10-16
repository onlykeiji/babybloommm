import 'app_session.dart';
import 'app_settings_store.dart';
import 'user_profile_store.dart';
import '../features/home/presentation/baby_care_models.dart';
import '../features/home/presentation/cycle_prediction.dart';
import '../features/home/presentation/daily_log_models.dart';

/// Builds a short, human-readable summary of the signed-in user's own data
/// — profile, cycle logs, pregnancy settings, baby profiles — pulled live
/// from Supabase, so Bloom AI can personalize its replies with real data
/// instead of answering as a generic chatbot that knows nothing about the
/// user.
class BloomAiContext {
  BloomAiContext._();

  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _modeLabel(AppMode mode) => switch (mode) {
    AppMode.familyPlanning => 'Family planning',
    AppMode.pregnancy => 'Pregnancy',
    AppMode.babyCare => 'Baby care',
  };

  /// Best-effort: every fetch is wrapped so a failure (not signed in, no
  /// network, no rows yet) just omits that section instead of blocking chat.
  static Future<String> build() async {
    final lines = <String>[];

    try {
      await ProfileStore.fetchCurrent();
      final profile = ProfileStore.current.value;
      if (profile != null) lines.add('Name: ${firstNameOf(profile.fullName)}');
    } catch (_) {}

    AppSettings? settings;
    try {
      await AppSettingsStore.fetch();
      settings = AppSettingsStore.current.value;
    } catch (_) {}

    final mode = AppSession.mode;
    lines.add('App mode: ${_modeLabel(mode)}');

    switch (mode) {
      case AppMode.familyPlanning:
        await _addFamilyPlanning(lines, settings);
        break;
      case AppMode.pregnancy:
        _addPregnancy(lines, settings);
        break;
      case AppMode.babyCare:
        await _addBabyCare(lines);
        break;
    }

    return lines.join('\n');
  }

  static Future<void> _addFamilyPlanning(
    List<String> lines,
    AppSettings? settings,
  ) async {
    if (settings == null) return;
    lines.add(
      'Cycle settings: ${settings.cycleLength}-day cycle, '
      '${settings.periodLength}-day period, ${settings.lutealLength}-day luteal phase.',
    );
    try {
      await DailyLogStore.fetchAll();
      final periodStarts = CyclePrediction.periodStartDatesFrom(
        DailyLogStore.all.value,
      );
      final prediction = CyclePrediction.compute(
        periodStartDates: periodStarts,
        cycleLength: settings.cycleLength,
        periodLength: settings.periodLength,
        lutealLength: settings.lutealLength,
      );
      if (prediction == null) {
        lines.add(
          'No period has been logged yet, so no cycle predictions are available.',
        );
        return;
      }
      lines.add(
        'Currently on cycle day ${prediction.cycleDayToday} '
        '(${prediction.isPeriodToday
            ? 'on period'
            : prediction.isFertileToday
            ? 'in fertile window'
            : 'not fertile'} today). '
        'Fertile window: ${_fmtDate(prediction.fertileWindowStart)} to ${_fmtDate(prediction.fertileWindowEnd)}. '
        'Next period expected around ${_fmtDate(prediction.nextPeriodDate)}.',
      );
    } catch (_) {}
  }

  static void _addPregnancy(List<String> lines, AppSettings? settings) {
    if (settings == null) return;
    lines.add('Currently ${settings.currentPregnancyWeek} weeks pregnant.');
    if (settings.dueDate != null) {
      lines.add('Due date: ${_fmtDate(settings.dueDate!)}.');
    }
    if (settings.prePregnancyWeightLb > 0) {
      lines.add(
        'Pre-pregnancy weight: ${settings.prePregnancyWeightLb.toStringAsFixed(1)} lb.',
      );
    }
  }

  static Future<void> _addBabyCare(List<String> lines) async {
    try {
      await BabyProfileStore.fetchAll();
      final babies = BabyProfileStore.babies.value;
      for (final baby in babies) {
        lines.add(
          'Baby: ${baby.name}, ${babyAgeLabel(baby.dateOfBirth)}, ${baby.gender.label.toLowerCase()}.',
        );
      }
    } catch (_) {}
  }
}
