import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/screen_background.dart';
import 'baby_care_models.dart';
import 'baby_daily_care_models.dart';

class BabyDailyCareScreen extends StatefulWidget {
  const BabyDailyCareScreen({
    super.key,
    this.initialKind = BabyCareLogKind.feeding,
  });

  final BabyCareLogKind initialKind;

  @override
  State<BabyDailyCareScreen> createState() => _BabyDailyCareScreenState();
}

class _BabyDailyCareScreenState extends State<BabyDailyCareScreen> {
  late BabyCareLogKind _kind;
  BabyProfile get _baby => BabyProfileStore.active;

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
    BabyCareLogStore.fetchForBaby(_baby.id);
    BabyProfileStore.activeBabyId.addListener(_reload);
  }

  @override
  void dispose() {
    BabyProfileStore.activeBabyId.removeListener(_reload);
    super.dispose();
  }

  void _reload() => BabyCareLogStore.fetchForBaby(_baby.id);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    floatingActionButton: FloatingActionButton(
      onPressed: () => _openLogSheet(_kind),
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.add_rounded, color: Colors.white),
    ),
    body: Stack(
      children: [
        const ScreenBackground(),
        SafeArea(
          child: Column(
            children: [
              _header(),
              Expanded(
                child: ValueListenableBuilder<List<BabyCareLog>>(
                  valueListenable: BabyCareLogStore.entries,
                  builder: (context, entries, _) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _todayCard(entries),
                            const SizedBox(height: 18),
                            Text(
                              'Today\'s activity',
                              style: GoogleFonts.nunitoSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _todayTimeline(entries),
                            const SizedBox(height: 24),
                            Text(
                              'Log & review care',
                              style: GoogleFonts.nunitoSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _tabs(),
                            const SizedBox(height: 16),
                            _quickActions(),
                            const SizedBox(height: 20),
                            Text(
                              '${_kind.label} history',
                              style: GoogleFonts.nunitoSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _history(
                              entries.where((e) => e.kind == _kind).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _header() => Container(
    margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .82),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Baby today',
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

  Widget _todayCard(List<BabyCareLog> entries) {
    final today = DateUtils.dateOnly(DateTime.now());
    final todayEntries = entries
        .where((e) => DateUtils.isSameDay(e.occurredAt, today))
        .toList();
    final feeds = todayEntries
        .where((e) => e.kind == BabyCareLogKind.feeding)
        .toList();
    final diapers = todayEntries
        .where((e) => e.kind == BabyCareLogKind.diaper)
        .length;
    final sleepMinutes = todayEntries
        .where((e) => e.kind == BabyCareLogKind.sleep)
        .fold<int>(0, (sum, e) => sum + (e.durationMinutes ?? 0));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.buttonGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TODAY AT A GLANCE',
            style: GoogleFonts.nunitoSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: Colors.white.withValues(alpha: .8),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _summary(
                Icons.restaurant_outlined,
                '${feeds.length}',
                'Feeds today',
              ),
              _summary(
                Icons.baby_changing_station_outlined,
                '$diapers',
                'Diapers today',
              ),
              _summary(
                Icons.nightlight_round,
                _minutesLabel(sleepMinutes),
                'Sleep today',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summary(IconData icon, String value, String label) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 19),
        const SizedBox(height: 7),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.nunitoSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.nunitoSans(
            fontSize: 10.5,
            color: Colors.white.withValues(alpha: .8),
          ),
        ),
      ],
    ),
  );

  Widget _todayTimeline(List<BabyCareLog> entries) {
    final todayEntries = entries
        .where((entry) => DateUtils.isSameDay(entry.occurredAt, DateTime.now()))
        .toList();
    if (todayEntries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: .25),
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.edit_calendar_outlined, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              'Nothing logged yet today',
              style: GoogleFonts.nunitoSans(
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            Text(
              'Use a quick action below to start today\'s care timeline.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunitoSans(
                fontSize: 12.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .74),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: todayEntries.take(5).map((entry) {
          final measurement = entry.amount != null
              ? '${entry.amount!.toStringAsFixed(0)} ml'
              : entry.durationMinutes != null
              ? '${entry.durationMinutes} min'
              : entry.kind.label;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              children: [
                Icon(entry.kind.icon, size: 19, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.details.isEmpty ? entry.kind.label : entry.details,
                    style: GoogleFonts.nunitoSans(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                Text(
                  measurement,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  MaterialLocalizations.of(
                    context,
                  ).formatTimeOfDay(TimeOfDay.fromDateTime(entry.occurredAt)),
                  style: GoogleFonts.nunitoSans(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _tabs() => Row(
    children: BabyCareLogKind.values
        .map(
          (kind) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: ChoiceChip(
                label: Text(kind.label),
                selected: _kind == kind,
                onSelected: (_) => setState(() => _kind = kind),
                avatar: Icon(
                  kind.icon,
                  size: 16,
                  color: _kind == kind ? Colors.white : AppColors.primary,
                ),
                selectedColor: AppColors.primary,
                labelStyle: GoogleFonts.nunitoSans(
                  fontWeight: FontWeight.w800,
                  color: _kind == kind ? Colors.white : AppColors.primary,
                ),
              ),
            ),
          ),
        )
        .toList(),
  );

  Widget _quickActions() => Row(
    children: BabyCareLogKind.values
        .map(
          (kind) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: OutlinedButton.icon(
                onPressed: () => _openLogSheet(kind),
                icon: Icon(kind.icon, size: 17),
                label: Text(
                  'Log ${kind.label}',
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        )
        .toList(),
  );

  Widget _history(List<BabyCareLog> entries) {
    if (entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .7),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          'No ${_kind.label.toLowerCase()} logs yet.',
          style: GoogleFonts.nunitoSans(color: AppColors.onSurfaceVariant),
        ),
      );
    }
    return Column(
      children: entries
          .map(
            (entry) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .75),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(entry.kind.icon, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.details.isEmpty
                              ? entry.kind.label
                              : entry.details,
                          style: GoogleFonts.nunitoSans(
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          MaterialLocalizations.of(context).formatTimeOfDay(
                            TimeOfDay.fromDateTime(entry.occurredAt),
                          ),
                          style: GoogleFonts.nunitoSans(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (entry.amount != null)
                    Text(
                      '${entry.amount!.toStringAsFixed(0)} ml',
                      style: GoogleFonts.nunitoSans(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  if (entry.durationMinutes != null)
                    Text(
                      '${entry.durationMinutes} min',
                      style: GoogleFonts.nunitoSans(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  IconButton(
                    tooltip: 'Edit log',
                    onPressed: () => _openLogSheet(entry.kind, existing: entry),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                  IconButton(
                    onPressed: () => BabyCareLogStore.remove(entry),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Future<void> _openLogSheet(
    BabyCareLogKind kind, {
    BabyCareLog? existing,
  }) async {
    final amount = TextEditingController(
      text: existing?.amount?.toStringAsFixed(0) ?? '',
    );
    final duration = TextEditingController(
      text: existing?.durationMinutes?.toString() ?? '',
    );
    String details =
        existing?.details ??
        switch (kind) {
          BabyCareLogKind.feeding => 'Breastfeeding',
          BabyCareLogKind.diaper => 'Wet diaper',
          BabyCareLogKind.sleep => 'Nap',
        };
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existing == null
                    ? 'Log ${kind.label.toLowerCase()}'
                    : 'Edit ${kind.label.toLowerCase()}',
                style: GoogleFonts.nunitoSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: details,
                items: _detailsFor(kind)
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
                onChanged: (value) => setSheetState(() => details = value!),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              if (kind == BabyCareLogKind.feeding)
                TextField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Bottle/formula/pumped milk (ml, optional)',
                  ),
                ),
              if (kind != BabyCareLogKind.diaper)
                TextField(
                  controller: duration,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration in minutes (optional)',
                  ),
                ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (existing == null) {
                      await BabyCareLogStore.add(
                        babyId: _baby.id,
                        kind: kind,
                        occurredAt: DateTime.now(),
                        amount: double.tryParse(amount.text),
                        durationMinutes: int.tryParse(duration.text),
                        details: details,
                      );
                    } else {
                      await BabyCareLogStore.update(
                        entry: existing,
                        occurredAt: existing.occurredAt,
                        amount: double.tryParse(amount.text),
                        durationMinutes: int.tryParse(duration.text),
                        details: details,
                      );
                    }
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(existing == null ? 'Save log' : 'Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    amount.dispose();
    duration.dispose();
  }

  List<String> _detailsFor(BabyCareLogKind kind) => switch (kind) {
    BabyCareLogKind.feeding => [
      'Breastfeeding',
      'Bottle feeding',
      'Formula',
      'Pumped milk',
    ],
    BabyCareLogKind.diaper => ['Wet diaper', 'Dirty diaper', 'Mixed diaper'],
    BabyCareLogKind.sleep => ['Nap', 'Night sleep', 'Awake period'],
  };
  String _minutesLabel(int minutes) =>
      minutes < 60 ? '${minutes}m' : '${minutes ~/ 60}h ${minutes % 60}m';
}
