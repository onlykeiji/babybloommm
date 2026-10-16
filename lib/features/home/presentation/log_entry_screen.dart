import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/screen_background.dart';
import 'daily_log_models.dart';

class LogEntryScreen extends StatefulWidget {
  LogEntryScreen({super.key, DateTime? initialDate})
    : initialDate = initialDate ?? _defaultDate;

  static final _defaultDate = DateTime(2025, 10, 10);

  final DateTime initialDate;

  @override
  State<LogEntryScreen> createState() => _LogEntryScreenState();
}

class _LogEntryScreenState extends State<LogEntryScreen> {
  late DateTime _selectedDate = widget.initialDate;
  final TextEditingController _notesController = TextEditingController();

  String _flow = 'None';
  String? _mood;
  final Set<String> _symptoms = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadForDate(_selectedDate);
  }

  Future<void> _loadForDate(DateTime date) async {
    setState(() => _loading = true);
    try {
      final existing = await DailyLogStore.fetchForDate(date);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _flow = existing?.flow ?? 'None';
        _mood = existing?.mood;
        _symptoms
          ..clear()
          ..addAll(existing?.symptoms ?? const {});
        _notesController.text = existing?.notes ?? '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load this day: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  static const _flowOptions = [
    (label: 'None', icon: Icons.water_drop_outlined, opacity: 0.0),
    (label: 'Light', icon: Icons.water_drop_rounded, opacity: 0.35),
    (label: 'Medium', icon: Icons.water_drop_rounded, opacity: 0.65),
    (label: 'Heavy', icon: Icons.water_drop_rounded, opacity: 1.0),
  ];

  static const _moods = [
    (
      label: 'Great',
      icon: Icons.sentiment_very_satisfied_rounded,
      color: AppColors.primary,
    ),
    (
      label: 'Good',
      icon: Icons.sentiment_satisfied_alt_rounded,
      color: AppColors.secondary,
    ),
    (
      label: 'Okay',
      icon: Icons.sentiment_neutral_rounded,
      color: AppColors.lavender,
    ),
    (
      label: 'Low',
      icon: Icons.sentiment_dissatisfied_rounded,
      color: AppColors.lavenderLight,
    ),
    (
      label: 'Anxious',
      icon: Icons.sentiment_very_dissatisfied_rounded,
      color: AppColors.primaryContainer,
    ),
  ];

  static const _symptomOptions = [
    (label: 'Cramps', icon: Icons.spa_outlined),
    (label: 'Headache', icon: Icons.sick_outlined),
    (label: 'Bloating', icon: Icons.circle_outlined),
    (label: 'Fatigue', icon: Icons.bedtime_outlined),
    (label: 'Tender breasts', icon: Icons.favorite_outline),
    (label: 'Acne', icon: Icons.face_retouching_natural_outlined),
    (label: 'Backache', icon: Icons.accessibility_new_outlined),
    (label: 'Nausea', icon: Icons.sentiment_dissatisfied_outlined),
    (label: 'Insomnia', icon: Icons.nightlight_outlined),
    (label: 'Cravings', icon: Icons.icecream_outlined),
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null) return;
    setState(() => _selectedDate = date);
    _loadForDate(date);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await DailyLogStore.save(
        DailyLog(
          logDate: _selectedDate,
          flow: _flow,
          mood: _mood,
          symptoms: _symptoms,
          notes: _notesController.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Entry saved for ${MaterialLocalizations.of(context).formatMediumDate(_selectedDate)}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
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
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 720),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _dateCard(context),
                                const SizedBox(height: 26),
                                _sectionTitle(
                                  'Flow',
                                  'Track your period intensity.',
                                ),
                                const SizedBox(height: 12),
                                _flowSelector(),
                                const SizedBox(height: 26),
                                _sectionTitle(
                                  'Mood',
                                  'How are you feeling today?',
                                ),
                                const SizedBox(height: 12),
                                _moodSelector(),
                                const SizedBox(height: 26),
                                _sectionTitle(
                                  'Symptoms',
                                  'Log everything that applies.',
                                ),
                                const SizedBox(height: 12),
                                _symptomGrid(),
                                const SizedBox(height: 26),
                                _sectionTitle(
                                  'Notes',
                                  'Anything else you want to remember?',
                                ),
                                const SizedBox(height: 12),
                                _notesCard(),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
              _bottomBar(),
            ],
          ),
        ),
      ],
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
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Log your day',
                style: GoogleFonts.nunitoSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'A few taps keeps your insights accurate.',
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

  Widget _dateCard(BuildContext context) => GestureDetector(
    onTap: _pickDate,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFD3BBFE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ENTRY DATE',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  MaterialLocalizations.of(
                    context,
                  ).formatMediumDate(_selectedDate),
                  style: GoogleFonts.nunitoSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.edit_calendar_outlined,
            color: AppColors.primary.withValues(alpha: 0.6),
          ),
        ],
      ),
    ),
  );

  Widget _sectionTitle(String title, String detail) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: GoogleFonts.nunitoSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        detail,
        style: GoogleFonts.nunitoSans(
          fontSize: 13,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _flowSelector() => Row(
    children: _flowOptions.map((option) {
      final selected = _flow == option.label;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _flow = option.label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: selected ? AppColors.buttonGradient : null,
              color: selected ? null : Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : AppColors.outlineVariant.withValues(alpha: 0.3),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  option.icon,
                  size: 22,
                  color: selected
                      ? Colors.white
                      : AppColors.primary.withValues(
                          alpha: option.opacity == 0 ? 0.35 : option.opacity,
                        ),
                ),
                const SizedBox(height: 6),
                Text(
                  option.label,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList(),
  );

  Widget _moodSelector() => Row(
    children: _moods.map((mood) {
      final selected = _mood == mood.label;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _mood = selected ? null : mood.label),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? mood.color
                      : Colors.white.withValues(alpha: 0.72),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: mood.color.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  mood.icon,
                  color: selected ? Colors.white : AppColors.onSurfaceVariant,
                  size: 22,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                mood.label,
                style: GoogleFonts.nunitoSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList(),
  );

  Widget _symptomGrid() => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: _symptomOptions.map((symptom) {
      final selected = _symptoms.contains(symptom.label);
      return GestureDetector(
        onTap: () => setState(
          () => selected
              ? _symptoms.remove(symptom.label)
              : _symptoms.add(symptom.label),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.buttonGradient : null,
            color: selected ? null : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : AppColors.outlineVariant.withValues(alpha: 0.4),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                symptom.icon,
                size: 17,
                color: selected ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                symptom.label,
                style: GoogleFonts.nunitoSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList(),
  );

  Widget _notesCard() => Container(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(20),
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
    child: TextField(
      controller: _notesController,
      maxLines: 4,
      textCapitalization: TextCapitalization.sentences,
      style: GoogleFonts.nunitoSans(fontSize: 14, color: AppColors.onSurface),
      decoration: InputDecoration(
        hintText: 'e.g. felt more tired than usual today…',
        hintStyle: GoogleFonts.nunitoSans(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(16),
      ),
    ),
  );

  Widget _bottomBar() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: PrimaryButton(
        label: 'Save Entry',
        trailingIcon: Icons.check_rounded,
        loading: _saving,
        onPressed: _save,
      ),
    ),
  );
}
