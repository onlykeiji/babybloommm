import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/screen_background.dart';
import '../../onboarding/presentation/onboarding_orientation_content.dart';
import 'baby_care_models.dart';
import 'app_navigation.dart';
import 'growth_chart_painter.dart';
import 'learn_library_screen.dart';
import 'lesson_detail_screen.dart';

class BabyGrowthScreen extends StatefulWidget {
  const BabyGrowthScreen({super.key});

  @override
  State<BabyGrowthScreen> createState() => _BabyGrowthScreenState();
}

class _BabyGrowthScreenState extends State<BabyGrowthScreen> {
  GrowthMetric _metric = GrowthMetric.weight;

  BabyProfile get _baby => BabyProfileStore.active;

  @override
  void initState() {
    super.initState();
    GrowthLog.fetchForBaby(_baby.id);
    MilestoneLog.fetchForBaby(_baby.id);
    BabyProfileStore.activeBabyId.addListener(_loadEntriesForActiveBaby);
  }

  @override
  void dispose() {
    BabyProfileStore.activeBabyId.removeListener(_loadEntriesForActiveBaby);
    super.dispose();
  }

  void _loadEntriesForActiveBaby() {
    GrowthLog.fetchForBaby(_baby.id);
    MilestoneLog.fetchForBaby(_baby.id);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
                  child: _header(context),
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: BabyProfileStore.activeBabyId,
                  builder: (context, _, _) =>
                      ValueListenableBuilder<List<GrowthEntry>>(
                        valueListenable: GrowthLog.entries,
                        builder: (context, _, _) => SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 720),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _disclaimerBanner(),
                                  const SizedBox(height: 18),
                                  _learningCard(context),
                                  const SizedBox(height: 18),
                                  _metricTabs(),
                                  const SizedBox(height: 14),
                                  _chartCard(),
                                  const SizedBox(height: 14),
                                  _logHistory(),
                                  const SizedBox(height: 30),
                                  Text(
                                    'Milestones',
                                    style: GoogleFonts.nunitoSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Celebrate every step, at your baby\'s own pace.',
                                    style: GoogleFonts.nunitoSans(
                                      fontSize: 13,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  ValueListenableBuilder<
                                    Map<String, Map<String, DateTime>>
                                  >(
                                    valueListenable: MilestoneLog.achieved,
                                    builder: (context, _, _) =>
                                        _milestoneList(),
                                  ),
                                ],
                              ),
                            ),
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
      ],
    ),
    floatingActionButton: Padding(
      padding: const EdgeInsets.only(bottom: 82),
      child: FloatingActionButton(
        onPressed: _openLogForm,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    ),
  );

  Widget _header(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          decoration: const BoxDecoration(
            color: Color(0xFFEBDDFF),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.child_care_rounded, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Grow',
                style: GoogleFonts.nunitoSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '${_baby.name} · ${babyAgeLabel(_baby.dateOfBirth)}',
                style: GoogleFonts.nunitoSans(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _disclaimerBanner() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFEBDDFF),
          AppColors.lavender.withValues(alpha: 0.6),
        ],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Charts show general WHO-style reference ranges for illustration only — not a diagnosis. Always follow your pediatrician\'s assessment.',
            style: GoogleFonts.nunitoSans(
              fontSize: 11.5,
              height: 1.4,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _learningCard(BuildContext context) {
    final growthLesson = babyCareOrientationLessons[1];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFEBDDFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  color: AppColors.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Baby care lessons',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LearnLibraryScreen(
                      items: babyCareOrientationLessons,
                      title: 'Baby care lessons',
                      subtitle:
                          'Helpful guidance for every stage of your baby\'s growth.',
                    ),
                  ),
                ),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LessonDetailScreen(
                  item: growthLesson,
                  allItems: babyCareOrientationLessons,
                ),
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(growthLesson.icon, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          growthLesson.title,
                          style: GoogleFonts.nunitoSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          growthLesson.meta,
                          style: GoogleFonts.nunitoSans(
                            fontSize: 11.5,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTabs() => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: AppColors.outlineVariant.withValues(alpha: 0.25),
      ),
    ),
    child: Row(
      children: GrowthMetric.values.map((m) {
        final selected = m == _metric;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _metric = m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: selected ? AppColors.buttonGradient : null,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                m.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunitoSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : AppColors.primary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );

  Widget _chartCard() {
    final entries = GrowthLog.forBaby(_baby.id, _metric);
    final reference = referenceCurveFor(_metric, _baby.gender);
    final ageNow = babyAgeInMonths(_baby.dateOfBirth);
    final maxAge = [24.0, ageNow + 2].reduce((a, b) => a > b ? a : b);
    final latest = entries.isEmpty ? null : entries.last;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_metric.icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                _metric.label,
                style: GoogleFonts.nunitoSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              const Spacer(),
              if (latest != null)
                Text(
                  'Latest: ${latest.value.toStringAsFixed(1)} ${_metric.unit}',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 190,
            width: double.infinity,
            child: CustomPaint(
              painter: GrowthChartPainter(
                reference: reference,
                entries: entries,
                maxAgeMonths: maxAge,
                babyDateOfBirth: _baby.dateOfBirth,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _legendDot(AppColors.lavender, 'Typical range (P3–P97)'),
              const SizedBox(width: 14),
              _legendDot(AppColors.secondary, 'Median'),
              const SizedBox(width: 14),
              _legendDot(AppColors.primary, _baby.name),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: GoogleFonts.nunitoSans(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _logHistory() {
    final entries = GrowthLog.forBaby(_baby.id, _metric).reversed.toList();
    if (entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          'No ${_metric.label.toLowerCase()} entries yet.',
          style: GoogleFonts.nunitoSans(
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: List.generate(entries.length, (index) {
          final entry = entries[index];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Builder(
                        builder: (context) => Text(
                          MaterialLocalizations.of(
                            context,
                          ).formatMediumDate(entry.date),
                          style: GoogleFonts.nunitoSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      '${entry.value.toStringAsFixed(1)} ${_metric.unit}',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit measurement',
                      onPressed: () => _openLogForm(existing: entry),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      onPressed: () async {
                        try {
                          await GrowthLog.remove(entry);
                        } catch (e) {
                          _showError('Could not remove entry: $e');
                        }
                      },
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppColors.onSurfaceVariant,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              if (index != entries.length - 1)
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
  }

  Widget _milestoneList() {
    final checkpoints =
        babyMilestones.map((m) => m.targetAgeDays).toSet().toList()..sort();
    final currentAgeDays = DateTime.now().difference(_baby.dateOfBirth).inDays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0x33EBDDFF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'These are age-based developmental checkpoints, not deadlines. '
            'Talk with your child\'s healthcare provider if you have concerns or your child loses a skill.',
            style: GoogleFonts.nunitoSans(
              fontSize: 12.5,
              height: 1.4,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        for (final checkpointDays in checkpoints) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
            child: Row(
              children: [
                Text(
                  babyMilestones
                      .firstWhere((m) => m.targetAgeDays == checkpointDays)
                      .checkpointLabel
                      .toUpperCase(),
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                    color: AppColors.primary,
                  ),
                ),
                if (currentAgeDays >= checkpointDays) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      currentAgeDays <= checkpointDays + 6
                          ? 'CURRENT'
                          : 'PAST CHECKPOINT',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          for (final milestone in babyMilestones.where(
            (m) => m.targetAgeDays == checkpointDays,
          ))
            _milestoneTile(milestone),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _milestoneTile(MilestoneDef m) {
    final achieved = MilestoneLog.isMilestoneAchieved(_baby.id, m);
    final date = MilestoneLog.dateOfMilestone(_baby.id, m);
    final ageDays = DateTime.now().difference(_baby.dateOfBirth).inDays;
    final eligible = ageDays >= m.targetAgeDays;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          try {
            if (achieved) {
              await MilestoneLog.unmarkMilestone(_baby.id, m);
            } else if (eligible) {
              await MilestoneLog.markAchieved(_baby, m, DateTime.now());
            } else {
              _showError(
                'This milestone unlocks ${m.checkpointLabel.toLowerCase()}.',
              );
            }
          } catch (e) {
            _showError('Could not update milestone: $e');
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: achieved
                ? const Color(0x33EBDDFF)
                : Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: achieved
                  ? AppColors.secondary
                  : AppColors.outlineVariant.withValues(alpha: 0.3),
              width: achieved ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: achieved
                      ? AppColors.secondary
                      : const Color(0xFFD3BBFE),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  m.icon,
                  color: achieved ? Colors.white : AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.title,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Builder(
                      builder: (context) => Text(
                        achieved && date != null
                            ? 'Achieved ${MaterialLocalizations.of(context).formatMediumDate(date)}'
                            : m.domain,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      m.meaning,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 11.5,
                        height: 1.35,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      m.activity,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 11.5,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    if (!eligible && !achieved) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Locked until ${m.checkpointLabel.toLowerCase()}',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                achieved
                    ? Icons.check_circle_rounded
                    : eligible
                    ? Icons.radio_button_unchecked_rounded
                    : Icons.lock_outline_rounded,
                color: achieved
                    ? AppColors.secondary
                    : AppColors.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLogForm({GrowthEntry? existing}) {
    GrowthMetric metric = existing?.metric ?? _metric;
    final valueController = TextEditingController(
      text: existing?.value.toStringAsFixed(1) ?? '',
    );
    DateTime date = existing?.date ?? DateTime.now();
    String? formError;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  existing == null ? 'Log a measurement' : 'Edit measurement',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: GrowthMetric.values
                      .map(
                        (m) => InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => setSheetState(() => metric = m),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: metric == m
                                  ? AppColors.primary
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: metric == m
                                    ? AppColors.primary
                                    : AppColors.outlineVariant.withValues(
                                        alpha: 0.4,
                                      ),
                              ),
                            ),
                            child: Text(
                              m.label,
                              style: GoogleFonts.nunitoSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: metric == m
                                    ? Colors.white
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: valueController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: GoogleFonts.nunitoSans(
                    fontSize: 14,
                    color: AppColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Value (${metric.unit})',
                    hintStyle: GoogleFonts.nunitoSans(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: sheetContext,
                      initialDate: date,
                      firstDate: _baby.dateOfBirth,
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setSheetState(() => date = picked);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          MaterialLocalizations.of(
                            sheetContext,
                          ).formatMediumDate(date),
                          style: GoogleFonts.nunitoSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (formError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    formError!,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.red.shade400,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            final value = double.tryParse(
                              valueController.text.trim(),
                            );
                            if (value == null) {
                              setSheetState(
                                () =>
                                    formError = 'Please enter a valid number.',
                              );
                              return;
                            }
                            setSheetState(() {
                              formError = null;
                              saving = true;
                            });
                            try {
                              final draft = GrowthEntry(
                                id: existing?.id,
                                babyId: _baby.id,
                                date: date,
                                metric: metric,
                                value: value,
                              );
                              if (existing == null) {
                                await GrowthLog.add(draft);
                              } else {
                                await GrowthLog.update(draft);
                              }
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                            } catch (e) {
                              setSheetState(() {
                                saving = false;
                                formError = e is BabyProfileValidationError
                                    ? e.message
                                    : 'Could not save entry: $e';
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      elevation: 0,
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            existing == null ? 'Save' : 'Save changes',
                            style: GoogleFonts.nunitoSans(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
