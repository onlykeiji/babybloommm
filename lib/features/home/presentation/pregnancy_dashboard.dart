import 'package:flutter/material.dart';

import '../../../core/app_session.dart';
import '../../../core/app_settings_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/screen_background.dart';
import '../../../core/widgets/section_title.dart';
import 'app_navigation.dart';
import 'bloom_ai_fab.dart';
import 'daily_log_models.dart';
import 'pregnancy_dashboard/development_card.dart';
import 'pregnancy_dashboard/due_date_card.dart';
import 'pregnancy_dashboard/kick_counter_card.dart';
import 'pregnancy_dashboard/learn_section.dart';
import 'pregnancy_dashboard/mood_row.dart';
import 'pregnancy_dashboard/stats_row.dart';
import 'pregnancy_dashboard/sticky_header.dart';
import 'pregnancy_dashboard/symptom_grid.dart';
import 'pregnancy_dashboard/tip_card.dart';
import 'pregnancy_dashboard/week_hero_card.dart';
import 'pregnancy_kick_store.dart';

class PregnancyDashboard extends StatefulWidget {
  const PregnancyDashboard({super.key});

  @override
  State<PregnancyDashboard> createState() => _PregnancyDashboardState();
}

class _PregnancyDashboardState extends State<PregnancyDashboard> {
  bool _savingCheckIn = false;
  bool _savingKick = false;

  @override
  void initState() {
    super.initState();
    // Safety net: guarantees the bottom nav's "Cycle" tab shows the pregnancy
    // journey tracker even if this screen is ever reached another way.
    AppSession.mode = AppMode.pregnancy;
    if (DailyLogStore.all.value.isEmpty) DailyLogStore.fetchAll();
    AppSettingsStore.current.addListener(_applySettings);
    _loadSupabaseData();
    _loadKicks();
    _applySettings();
  }

  Future<void> _loadSupabaseData() async {
    try {
      // Always reload rather than trusting a previous dashboard's in-memory
      // state. The due date belongs to the signed-in account in Supabase.
      await AppSettingsStore.fetch();
    } catch (_) {
      // The dashboard retains its safe loading state; settings screens show
      // a detailed save error if the database is unavailable.
    }
  }

  @override
  void dispose() {
    AppSettingsStore.current.removeListener(_applySettings);
    super.dispose();
  }

  void _applySettings() {
    final s = AppSettingsStore.current.value;
    if (s == null || !mounted) return;
    setState(() {
      _currentWeek = s.currentPregnancyWeek;
      _dueDate =
          s.dueDate ??
          _today.add(Duration(days: (_totalWeeks - _currentWeek) * 7));
    });
  }

  DateTime get _today => DateTime.now();
  int _currentWeek = 12;
  static const _totalWeeks = 40;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 196));

  Future<void> _loadKicks() async {
    try {
      await PregnancyKickStore.fetchToday();
    } catch (e) {
      if (mounted) _showError('Could not load kick logs: $e');
    }
  }

  Future<void> _addKick() async {
    if (_savingKick) return;
    setState(() => _savingKick = true);
    try {
      await PregnancyKickStore.addKick();
    } catch (e) {
      if (mounted) _showError('Could not save kick: $e');
    } finally {
      if (mounted) setState(() => _savingKick = false);
    }
  }

  Future<void> _resetKicks() async {
    if (_savingKick) return;
    setState(() => _savingKick = true);
    try {
      await PregnancyKickStore.resetToday();
    } catch (e) {
      if (mounted) _showError('Could not reset kick logs: $e');
    } finally {
      if (mounted) setState(() => _savingKick = false);
    }
  }

  String get _trimester {
    if (_currentWeek <= 13) return 'First trimester';
    if (_currentWeek <= 27) return 'Second trimester';
    return 'Third trimester';
  }

  int get _daysToGo => _dueDate.difference(_today).inDays;

  /// The one `daily_logs` row for today, if today has already been logged.
  DailyLog? _todayLog(List<DailyLog> logs) {
    final today = DateTime(_today.year, _today.month, _today.day);
    for (final log in logs) {
      final d = log.logDate;
      if (DateTime(d.year, d.month, d.day) == today) return log;
    }
    return null;
  }

  Future<void> _toggleSymptom(String label, DailyLog? todayLog) async {
    final symptoms = {...?todayLog?.symptoms};
    if (!symptoms.remove(label)) symptoms.add(label);
    await _saveCheckIn(todayLog, mood: todayLog?.mood, symptoms: symptoms);
  }

  Future<void> _setMood(String? mood, DailyLog? todayLog) => _saveCheckIn(
    todayLog,
    mood: mood,
    symptoms: todayLog?.symptoms ?? const {},
  );

  Future<void> _saveCheckIn(
    DailyLog? todayLog, {
    required String? mood,
    required Set<String> symptoms,
  }) async {
    if (_savingCheckIn) return;
    setState(() => _savingCheckIn = true);
    try {
      await DailyLogStore.save(
        DailyLog(
          logDate: _today,
          flow: todayLog?.flow ?? 'None',
          mood: mood,
          symptoms: symptoms,
          notes: todayLog?.notes ?? '',
        ),
      );
    } catch (e) {
      if (mounted) _showError('Could not save check-in: $e');
    } finally {
      if (mounted) setState(() => _savingCheckIn = false);
    }
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
  );

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<List<DailyLog>>(
    valueListenable: DailyLogStore.all,
    builder: (context, logs, _) {
      final todayLog = _todayLog(logs);
      final loggedSymptoms = todayLog?.symptoms ?? const <String>{};
      final streak = dayStreak(logs, today: _today);
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            const ScreenBackground(),
            SafeArea(
              child: Column(
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: PregnancyStickyHeader(
                        streak: streak,
                        currentWeek: _currentWeek,
                        trimester: _trimester,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PregnancyStatsRow(
                                streak: streak,
                                loggedToday: loggedSymptoms.length,
                              ),
                              const SizedBox(height: 16),
                              PregnancyWeekHeroCard(
                                currentWeek: _currentWeek,
                                totalWeeks: _totalWeeks,
                                daysToGo: _daysToGo,
                              ),
                              const SizedBox(height: 16),
                              PregnancyDueDateCard(dueDate: _dueDate),
                              const SizedBox(height: 30),
                              const SectionTitle(
                                title: 'Your baby this week',
                                detail: 'What is developing right now.',
                              ),
                              const SizedBox(height: 14),
                              PregnancyDevelopmentCard(
                                currentWeek: _currentWeek,
                              ),
                              const SizedBox(height: 30),
                              const SectionTitle(
                                title: 'Today\'s check-in',
                                detail:
                                    'A few taps keeps your records complete.',
                              ),
                              const SizedBox(height: 14),
                              PregnancyMoodRow(
                                selectedMood: todayLog?.mood,
                                onSelect: (mood) => _setMood(mood, todayLog),
                              ),
                              const SizedBox(height: 16),
                              PregnancySymptomGrid(
                                loggedSymptoms: loggedSymptoms,
                                saving: _savingCheckIn,
                                onToggle: (label) =>
                                    _toggleSymptom(label, todayLog),
                              ),
                              const SizedBox(height: 30),
                              const SectionTitle(
                                title: 'Kick counter',
                                detail:
                                    'Most helpful from around week 28 onward.',
                              ),
                              const SizedBox(height: 14),
                              ValueListenableBuilder<List<PregnancyKickLog>>(
                                valueListenable: PregnancyKickStore.logs,
                                builder: (context, kicks, _) =>
                                    PregnancyKickCounterCard(
                                      kickCount: kicks.length,
                                      saving: _savingKick,
                                      onIncrement: _addKick,
                                      onReset: _resetKicks,
                                    ),
                              ),
                              const SizedBox(height: 30),
                              PregnancyLearnSection(currentWeek: _currentWeek),
                              const SizedBox(height: 30),
                              const PregnancyTipCard(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  AppBottomNav(
                    current: AppTab.today,
                    onSelect: (tab) => goToTab(context, tab),
                  ),
                ],
              ),
            ),
            const Positioned(right: 20, bottom: 100, child: BloomAiFab()),
          ],
        ),
      );
    },
  );
}
