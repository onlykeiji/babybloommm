import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_settings_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/notifications_panel.dart';
import '../../../core/widgets/screen_background.dart';
import '../../../core/widgets/section_title.dart';
import '../../../core/widgets/stat_chip.dart';
import 'app_navigation.dart';
import 'bloom_ai_fab.dart';
import 'health_schedule_models.dart';
import 'pregnancy_dashboard/appointment_card.dart';
import 'pregnancy_dashboard/health_schedule_card.dart';
import 'pregnancy_dashboard/toolkit_grid.dart';
import 'pregnancy_dashboard/weight_card.dart';
import 'pregnancy_weight_store.dart';

class PregnancyJourneyScreen extends StatefulWidget {
  const PregnancyJourneyScreen({super.key});

  @override
  State<PregnancyJourneyScreen> createState() => _PregnancyJourneyScreenState();
}

class _PregnancyJourneyScreenState extends State<PregnancyJourneyScreen> {
  bool _loadingWeights = true;
  bool _savingWeight = false;
  String? _weightLoadError;

  @override
  void initState() {
    super.initState();
    AppointmentStore.fetchAll();
    _loadWeights();
  }

  DateTime get _today => DateTime.now();
  int get _currentWeek =>
      AppSettingsStore.current.value?.currentPregnancyWeek ?? 1;
  static const _totalWeeks = 40;
  DateTime get _dueDate => AppSettingsStore.current.value?.dueDate ?? _today;

  Future<void> _setWeight(double nextWeightLb) async {
    if (_savingWeight) return;
    setState(() => _savingWeight = true);
    try {
      await PregnancyWeightStore.saveToday(nextWeightLb);
    } finally {
      if (mounted) setState(() => _savingWeight = false);
    }
  }

  Future<void> _adjustWeight(double nextWeightLb) async {
    try {
      await _setWeight(nextWeightLb.clamp(60.0, 400.0).toDouble());
    } catch (e) {
      if (mounted) _showError('Could not save weight: $e');
    }
  }

  Future<void> _loadWeights() async {
    setState(() {
      _loadingWeights = true;
      _weightLoadError = null;
    });
    try {
      await PregnancyWeightStore.fetch();
    } catch (error) {
      if (mounted) {
        setState(
          () => _weightLoadError = 'Could not load saved weight: $error',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingWeights = false);
    }
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
  );

  static const _milestones = [
    (
      title: 'First trimester screening',
      weekLabel: 'Weeks 11–13',
      start: 11,
      end: 13,
      icon: Icons.biotech_outlined,
    ),
    (
      title: 'Anatomy scan',
      weekLabel: 'Weeks 18–22',
      start: 18,
      end: 22,
      icon: Icons.pregnant_woman_outlined,
    ),
    (
      title: 'Glucose screening',
      weekLabel: 'Weeks 24–28',
      start: 24,
      end: 28,
      icon: Icons.science_outlined,
    ),
    (
      title: 'Third trimester begins',
      weekLabel: 'Week 28',
      start: 28,
      end: 28,
      icon: Icons.flag_outlined,
    ),
    (
      title: 'Full term',
      weekLabel: 'Week 37',
      start: 37,
      end: 37,
      icon: Icons.verified_outlined,
    ),
    (
      title: 'Estimated due date',
      weekLabel: 'Week 40',
      start: 40,
      end: 40,
      icon: Icons.celebration_outlined,
    ),
  ];

  /*static const _recentActivity = [
    (
      date: 'Oct 9',
      detail: 'Logged nausea and fatigue',
      icon: Icons.sick_outlined,
    ),
    (date: 'Oct 8', detail: '10 kicks recorded', icon: Icons.favorite_outline),
    (
      date: 'Oct 7',
      detail: 'Weight logged: 138.0 lb',
      icon: Icons.monitor_weight_outlined,
    ),
  ];*/

  static String _trimesterOf(int week) {
    if (week <= 13) return 'First trimester';
    if (week <= 27) return 'Second trimester';
    return 'Third trimester';
  }

  static Color _trimesterColor(int week) {
    if (week <= 13) return AppColors.primary;
    if (week <= 27) return AppColors.secondary;
    return AppColors.lavenderLight;
  }

  String _statusFor(int start, int end) {
    if (_currentWeek > end) return 'Completed';
    if (_currentWeek >= start && _currentWeek <= end) return 'Now';
    return 'Upcoming';
  }

  @override
  Widget build(BuildContext context) {
    if (AppSettingsStore.current.value == null) AppSettingsStore.fetch();
    return ValueListenableBuilder<AppSettings?>(
      valueListenable: AppSettingsStore.current,
      builder: (context, settings, _) {
        if (settings == null || settings.dueDate == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        return _journey(context);
      },
    );
  }

  Widget _journey(BuildContext context) => Scaffold(
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
                  child: _stickyHeader(context),
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
                          _statsRow(),
                          const SizedBox(height: 16),
                          _trimesterCard(context),
                          const SizedBox(height: 30),
                          _sectionTitle(
                            'Your weeks',
                            'Tap any week to see where it falls.',
                          ),
                          const SizedBox(height: 14),
                          _weekGrid(context),
                          const SizedBox(height: 20),
                          _legend(),
                          const SizedBox(height: 30),
                          _sectionTitle(
                            'Milestones',
                            'Key checkpoints in your pregnancy.',
                          ),
                          const SizedBox(height: 14),
                          _milestonesList(),
                          const SizedBox(height: 30),
                          const SectionTitle(
                            title: 'Weight tracking',
                            detail: 'Log changes to share with your provider.',
                          ),
                          const SizedBox(height: 14),
                          ValueListenableBuilder<List<PregnancyWeightEntry>>(
                            valueListenable: PregnancyWeightStore.entries,
                            builder: (context, weightEntries, _) {
                              if (_loadingWeights) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (_weightLoadError != null) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_weightLoadError!),
                                    TextButton(
                                      onPressed: _loadWeights,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                );
                              }
                              final startingWeight =
                                  AppSettingsStore
                                      .current
                                      .value
                                      ?.prePregnancyWeightLb ??
                                  132.0;
                              final currentWeight = weightEntries.isEmpty
                                  ? startingWeight
                                  : weightEntries.last.weightLb;
                              return PregnancyWeightCard(
                                currentWeight: currentWeight,
                                startingWeight: startingWeight,
                                onAdjust: (delta) =>
                                    _adjustWeight(currentWeight + delta),
                                onSetWeight: _setWeight,
                                enabled: !_savingWeight,
                              );
                            },
                          ),
                          const SizedBox(height: 30),
                          _sectionTitle(
                            'Appointments & reminders',
                            'Medications, checkups & vaccines.',
                          ),
                          const SizedBox(height: 14),
                          PregnancyAppointmentCard(today: _today),
                          const SizedBox(height: 16),
                          const PregnancyHealthScheduleCard(),
                          const SizedBox(height: 30),
                          const SectionTitle(
                            title: 'Pregnancy toolkit',
                            detail: 'Handy utilities for every trimester.',
                          ),
                          const SizedBox(height: 14),
                          const PregnancyToolkitGrid(),
                          const SizedBox(height: 30),
                          _sectionTitle(
                            'Recent activity',
                            'What you have logged lately.',
                          ),
                          const SizedBox(height: 14),
                          _activityCard(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              AppBottomNav(
                current: AppTab.cycle,
                onSelect: (tab) => goToTab(context, tab),
              ),
            ],
          ),
        ),
        const Positioned(right: 20, bottom: 100, child: BloomAiFab()),
      ],
    ),
  );

  Widget _stickyHeader(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: AppColors.outlineVariant.withValues(alpha: 0.2),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.12),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFEBDCFF),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Image.asset('lib/assets/images/logo.png', fit: BoxFit.contain),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your journey',
                style: GoogleFonts.nunitoSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Week $_currentWeek · ${_trimesterOf(_currentWeek)}',
                style: GoogleFonts.nunitoSans(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => showNotificationsPanel(context),
            tooltip: 'Notifications',
            icon: const Badge(
              smallSize: 8,
              backgroundColor: AppColors.secondary,
              child: Icon(
                Icons.notifications_none_rounded,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _statsRow() {
    final weeksToGo = _totalWeeks - _currentWeek;
    return Row(
      children: [
        Expanded(
          child: StatChip(
            icon: Icons.pregnant_woman_outlined,
            value: '$_currentWeek',
            label: 'Weeks along',
            color: AppColors.secondaryContainer,
            deep: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatChip(
            icon: Icons.hourglass_bottom_rounded,
            value: '$weeksToGo',
            label: 'Weeks to go',
            color: AppColors.lavender,
            deep: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatChip(
            icon: Icons.auto_awesome_rounded,
            value: _trimesterOrdinal(_currentWeek),
            label: 'Trimester',
            color: AppColors.lavenderLight,
            deep: AppColors.primaryContainer,
          ),
        ),
      ],
    );
  }

  static String _trimesterOrdinal(int week) {
    if (week <= 13) return '1st';
    if (week <= 27) return '2nd';
    return '3rd';
  }

  Widget _trimesterCard(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.secondary],
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.28),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Week $_currentWeek of $_totalWeeks',
          style: GoogleFonts.nunitoSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Due ${MaterialLocalizations.of(context).formatMediumDate(_dueDate)}',
          style: GoogleFonts.nunitoSans(
            fontSize: 13,
            color: const Color(0xFFEBDDFF),
          ),
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                Expanded(
                  flex: 13,
                  child: Container(
                    color: Colors.white.withValues(
                      alpha: _currentWeek <= 13 ? 1 : 0.55,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  flex: 14,
                  child: Container(
                    color: Colors.white.withValues(
                      alpha: _currentWeek > 13 && _currentWeek <= 27 ? 1 : 0.55,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  flex: 13,
                  child: Container(
                    color: Colors.white.withValues(
                      alpha: _currentWeek > 27 ? 1 : 0.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'First',
              style: GoogleFonts.nunitoSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            Text(
              'Second',
              style: GoogleFonts.nunitoSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            Text(
              'Third',
              style: GoogleFonts.nunitoSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _sectionTitle(String title, String detail) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: GoogleFonts.nunitoSans(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        detail,
        style: GoogleFonts.nunitoSans(
          fontSize: 14,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _weekGrid(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: AppColors.outlineVariant.withValues(alpha: 0.25),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_totalWeeks, (index) {
        final week = index + 1;
        final isPast = week < _currentWeek;
        final isCurrent = week == _currentWeek;
        final color = _trimesterColor(week);
        return GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isCurrent
                    ? "You are here — week $week."
                    : 'Week $week · ${_trimesterOf(week)}',
              ),
            ),
          ),
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isPast || isCurrent ? color : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCurrent
                    ? AppColors.primary
                    : color.withValues(alpha: isPast ? 0 : 0.5),
                width: isCurrent ? 2.4 : 1,
              ),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              '$week',
              style: GoogleFonts.nunitoSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isPast || isCurrent ? Colors.white : color,
              ),
            ),
          ),
        );
      }),
    ),
  );

  Widget _legend() => Wrap(
    spacing: 16,
    runSpacing: 8,
    children: [
      _legendDot(AppColors.primary, 'First trimester'),
      _legendDot(AppColors.secondary, 'Second trimester'),
      _legendDot(AppColors.lavenderLight, 'Third trimester'),
    ],
  );

  Widget _legendDot(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: GoogleFonts.nunitoSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _milestonesList() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: AppColors.outlineVariant.withValues(alpha: 0.25),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      children: List.generate(_milestones.length, (index) {
        final milestone = _milestones[index];
        final status = _statusFor(milestone.start, milestone.end);
        final isNow = status == 'Now';
        final isDone = status == 'Completed';
        final badgeColor = isNow
            ? AppColors.primary
            : (isDone ? AppColors.secondary : AppColors.onSurfaceVariant);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isNow
                          ? const Color(0xFFD3BBFE)
                          : const Color(0xFFF2ECF0),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDone ? Icons.check_circle_rounded : milestone.icon,
                      color: isNow
                          ? AppColors.primary
                          : (isDone
                                ? AppColors.secondary
                                : AppColors.onSurfaceVariant),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          milestone.title,
                          style: GoogleFonts.nunitoSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          milestone.weekLabel,
                          style: GoogleFonts.nunitoSans(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (index != _milestones.length - 1)
              Divider(
                height: 1,
                indent: 12,
                endIndent: 12,
                color: AppColors.outlineVariant.withValues(alpha: 0.2),
              ),
          ],
        );
      }),
    ),
  );

  Widget _activityCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: AppColors.outlineVariant.withValues(alpha: 0.25),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Text(
        'No pregnancy activity has been logged yet.',
        style: GoogleFonts.nunitoSans(
          fontSize: 14,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    ),
  );
}
