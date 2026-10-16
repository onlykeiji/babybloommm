import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/screen_background.dart';
import 'health_schedule_models.dart';

class RemindersHealthScreen extends StatefulWidget {
  const RemindersHealthScreen({super.key, this.babyCare = false});

  final bool babyCare;

  @override
  State<RemindersHealthScreen> createState() => _RemindersHealthScreenState();
}

class _RemindersHealthScreenState extends State<RemindersHealthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    MedicationStore.fetchAll();
    AppointmentStore.fetchAll();
    VaccineLogStore.fetchAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
    );
  }

  Future<bool> _confirmDelete(String title, String message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return confirmed ?? false;
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
                  child: Column(
                    children: [
                      _header(context),
                      const SizedBox(height: 14),
                      _tabBar(),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _medicationsTab(),
                        _appointmentsTab(),
                        _vaccinesTab(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => switch (_tabController.index) {
        0 => _openMedicationForm(),
        1 => _openAppointmentForm(),
        _ => _openVaccineLogForm(),
      },
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.add_rounded, color: Colors.white),
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
                widget.babyCare
                    ? 'Baby health & reminders'
                    : 'Reminders & health schedule',
                style: GoogleFonts.nunitoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                widget.babyCare
                    ? 'Medicine, pediatric visits & vaccines.'
                    : 'Medications, appointments & vaccines.',
                style: GoogleFonts.nunitoSans(
                  fontSize: 12.5,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _tabBar() => Container(
    margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: AppColors.outlineVariant.withValues(alpha: 0.25),
      ),
    ),
    child: TabBar(
      controller: _tabController,
      onTap: (_) => setState(() {}),
      indicator: BoxDecoration(
        gradient: AppColors.buttonGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      labelColor: Colors.white,
      unselectedLabelColor: AppColors.primary,
      labelStyle: GoogleFonts.nunitoSans(
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
      ),
      unselectedLabelStyle: GoogleFonts.nunitoSans(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
      ),
      tabs: [
        Tab(text: widget.babyCare ? 'Medicine' : 'Medications'),
        Tab(text: widget.babyCare ? 'Checkups' : 'Appointments'),
        Tab(text: 'Vaccines'),
      ],
    ),
  );

  // ---------------- Medications ----------------

  Widget _medicationsTab() => ValueListenableBuilder<bool>(
    valueListenable: MedicationStore.isLoading,
    builder: (context, loading, _) =>
        ValueListenableBuilder<List<MedicationReminder>>(
          valueListenable: MedicationStore.items,
          builder: (context, medications, _) {
            if (loading && medications.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (medications.isEmpty) {
              return _emptyState(
                icon: Icons.medication_outlined,
                message: 'No medications or vitamins added yet.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
              itemCount: medications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _medicationCard(medications[index]),
            );
          },
        ),
  );

  Widget _medicationCard(MedicationReminder med) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFD3BBFE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.medication_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${med.dosage} · ${med.frequency.label}',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12.5,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lavender.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    med.time.format(context),
                    style: GoogleFonts.nunitoSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () => _openMedicationForm(existing: med),
                tooltip: 'Edit',
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              IconButton(
                onPressed: () async {
                  try {
                    await MedicationStore.setReminderEnabled(
                      med,
                      !med.reminderEnabled,
                    );
                  } catch (e) {
                    _showError('Could not update reminder: $e');
                  }
                },
                tooltip: med.reminderEnabled ? 'Reminder on' : 'Reminder off',
                icon: Icon(
                  med.reminderEnabled
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_outlined,
                  color: med.reminderEnabled
                      ? AppColors.secondary
                      : AppColors.onSurfaceVariant,
                  size: 20,
                ),
              ),
              IconButton(
                onPressed: () async {
                  final confirmed = await _confirmDelete(
                    'Remove medication?',
                    'This permanently deletes "${med.name}" from your list.',
                  );
                  if (!confirmed) return;
                  try {
                    await MedicationStore.remove(med);
                  } catch (e) {
                    _showError('Could not remove: $e');
                  }
                },
                tooltip: 'Remove',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openMedicationForm({MedicationReminder? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final dosageController = TextEditingController(
      text: existing?.dosage ?? '',
    );
    TimeOfDay time = existing?.time ?? const TimeOfDay(hour: 9, minute: 0);
    MedFrequency frequency = existing?.frequency ?? MedFrequency.onceDaily;
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
          child: _formSheet(
            title: existing == null ? 'Add medication' : 'Edit medication',
            saving: saving,
            errorText: formError,
            onSave: () async {
              setSheetState(() {
                formError = null;
                saving = true;
              });
              try {
                final draft = MedicationReminder(
                  id: existing?.id,
                  name: nameController.text.trim(),
                  dosage: dosageController.text.trim().isEmpty
                      ? '—'
                      : dosageController.text.trim(),
                  time: time,
                  frequency: frequency,
                  reminderEnabled: existing?.reminderEnabled ?? true,
                );
                if (existing == null) {
                  await MedicationStore.add(draft);
                } else {
                  await MedicationStore.update(draft);
                }
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              } catch (e) {
                setSheetState(() {
                  saving = false;
                  formError = e is HealthRecordValidationError
                      ? e.message
                      : 'Could not save: $e';
                });
              }
            },
            children: [
              _textField(nameController, 'Medication or vitamin name'),
              const SizedBox(height: 12),
              _textField(dosageController, 'Dosage (e.g. 1 tablet, 400 mcg)'),
              const SizedBox(height: 16),
              _pickerRow(
                label: 'Reminder time',
                value: time.format(sheetContext),
                icon: Icons.access_time_rounded,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: sheetContext,
                    initialTime: time,
                  );
                  if (picked != null) setSheetState(() => time = picked);
                },
              ),
              const SizedBox(height: 16),
              _chipLabel('Frequency'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MedFrequency.values
                    .map(
                      (f) => _choiceChip(
                        f.label,
                        frequency == f,
                        () => setSheetState(() => frequency = f),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Appointments ----------------

  List<HealthAppointment> _sorted(List<HealthAppointment> list) =>
      [...list]..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  Widget _appointmentsTab() => ValueListenableBuilder<bool>(
    valueListenable: AppointmentStore.isLoading,
    builder: (context, loading, _) =>
        ValueListenableBuilder<List<HealthAppointment>>(
          valueListenable: AppointmentStore.items,
          builder: (context, appointments, _) {
            if (loading && appointments.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (appointments.isEmpty) {
              return _emptyState(
                icon: Icons.event_available_outlined,
                message: 'No appointments scheduled yet.',
              );
            }
            final sorted = _sorted(appointments);
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _appointmentCard(sorted[index]),
            );
          },
        ),
  );

  Widget _appointmentCard(HealthAppointment appt) {
    final isPast = appt.dateTime.isBefore(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isPast ? 0.5 : 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFD3BBFE),
              shape: BoxShape.circle,
            ),
            child: Icon(appt.type.icon, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        appt.title,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lavenderLight.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        appt.type.label,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Builder(
                  builder: (context) => Text(
                    '${MaterialLocalizations.of(context).formatMediumDate(appt.date)} · ${appt.time.format(context)}',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                if (appt.notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    appt.notes,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 12.5,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () => _openAppointmentForm(existing: appt),
                tooltip: 'Edit',
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              IconButton(
                onPressed: () async {
                  try {
                    await AppointmentStore.setReminderEnabled(
                      appt,
                      !appt.reminderEnabled,
                    );
                  } catch (e) {
                    _showError('Could not update reminder: $e');
                  }
                },
                tooltip: appt.reminderEnabled ? 'Reminder on' : 'Reminder off',
                icon: Icon(
                  appt.reminderEnabled
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_outlined,
                  color: appt.reminderEnabled
                      ? AppColors.secondary
                      : AppColors.onSurfaceVariant,
                  size: 20,
                ),
              ),
              IconButton(
                onPressed: () async {
                  final confirmed = await _confirmDelete(
                    'Remove appointment?',
                    'This permanently deletes "${appt.title}".',
                  );
                  if (!confirmed) return;
                  try {
                    await AppointmentStore.remove(appt);
                  } catch (e) {
                    _showError('Could not remove: $e');
                  }
                },
                tooltip: 'Remove',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openAppointmentForm({HealthAppointment? existing}) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    DateTime date =
        existing?.date ?? DateTime.now().add(const Duration(days: 7));
    TimeOfDay time = existing?.time ?? const TimeOfDay(hour: 9, minute: 0);
    AppointmentType type = existing?.type ?? AppointmentType.checkup;
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
          child: _formSheet(
            title: existing == null ? 'Add appointment' : 'Edit appointment',
            saving: saving,
            errorText: formError,
            onSave: () async {
              setSheetState(() {
                formError = null;
                saving = true;
              });
              try {
                final draft = HealthAppointment(
                  id: existing?.id,
                  title: titleController.text.trim(),
                  date: date,
                  time: time,
                  type: type,
                  notes: notesController.text.trim(),
                  reminderEnabled: existing?.reminderEnabled ?? true,
                );
                if (existing == null) {
                  await AppointmentStore.add(draft);
                } else {
                  await AppointmentStore.update(draft);
                }
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              } catch (e) {
                setSheetState(() {
                  saving = false;
                  formError = e is HealthRecordValidationError
                      ? e.message
                      : 'Could not save: $e';
                });
              }
            },
            children: [
              _textField(titleController, 'Appointment title'),
              const SizedBox(height: 16),
              _chipLabel('Type'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppointmentType.values
                    .map(
                      (t) => _choiceChip(
                        t.label,
                        type == t,
                        () => setSheetState(() => type = t),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              _pickerRow(
                label: 'Date',
                value: MaterialLocalizations.of(
                  sheetContext,
                ).formatMediumDate(date),
                icon: Icons.calendar_month_outlined,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: sheetContext,
                    initialDate: date,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null) setSheetState(() => date = picked);
                },
              ),
              const SizedBox(height: 10),
              _pickerRow(
                label: 'Time',
                value: time.format(sheetContext),
                icon: Icons.access_time_rounded,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: sheetContext,
                    initialTime: time,
                  );
                  if (picked != null) setSheetState(() => time = picked);
                },
              ),
              const SizedBox(height: 12),
              _textField(notesController, 'Notes (optional)', maxLines: 3),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Vaccines ----------------

  Widget _vaccinesTab() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
    children: [
      _disclaimerBanner(),
      const SizedBox(height: 20),
      Text(
        'Recommended reference',
        style: GoogleFonts.nunitoSans(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        widget.babyCare
            ? 'General child-immunization information — not a prescription.'
            : 'General maternal vaccine information — not a prescription.',
        style: GoogleFonts.nunitoSans(
          fontSize: 12.5,
          color: AppColors.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 12),
      ...(widget.babyCare ? babyVaccineReferences : maternalVaccineReferences)
          .map(
            (v) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _vaccineReferenceCard(v),
            ),
          ),
      const SizedBox(height: 16),
      Text(
        'Your vaccine log',
        style: GoogleFonts.nunitoSans(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        'What you or your provider have logged.',
        style: GoogleFonts.nunitoSans(
          fontSize: 12.5,
          color: AppColors.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 12),
      ValueListenableBuilder<bool>(
        valueListenable: VaccineLogStore.isLoading,
        builder: (context, loading, _) =>
            ValueListenableBuilder<List<VaccineLogEntry>>(
              valueListenable: VaccineLogStore.items,
              builder: (context, vaccineLogs, _) {
                if (loading && vaccineLogs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }
                if (vaccineLogs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 26),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      'Nothing logged yet.',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return Column(
                  children: vaccineLogs
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _vaccineLogCard(entry),
                        ),
                      )
                      .toList(),
                );
              },
            ),
      ),
    ],
  );

  Widget _disclaimerBanner() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFEBDDFF),
          AppColors.lavender.withValues(alpha: 0.6),
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            "This is for informational tracking only. Always follow your healthcare provider's advice.",
            style: GoogleFonts.nunitoSans(
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _vaccineReferenceCard(VaccineReference v) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: AppColors.outlineVariant.withValues(alpha: 0.25),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          v.name,
          style: GoogleFonts.nunitoSans(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          v.recommendedTiming,
          style: GoogleFonts.nunitoSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          v.description,
          style: GoogleFonts.nunitoSans(
            fontSize: 12.5,
            height: 1.4,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          v.sourceNote,
          style: GoogleFonts.nunitoSans(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _openVaccineLogForm(prefillName: v.name),
            child: Text(
              'LOG THIS VACCINE',
              style: GoogleFonts.nunitoSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _vaccineLogCard(VaccineLogEntry entry) {
    final completed = entry.status == VaccineLogStatus.completed;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: completed ? AppColors.secondary : const Color(0xFFD3BBFE),
              shape: BoxShape.circle,
            ),
            child: Icon(
              completed ? Icons.check_rounded : Icons.schedule_rounded,
              color: completed ? Colors.white : AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.vaccineName,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (completed
                                    ? AppColors.secondary
                                    : AppColors.lavenderLight)
                                .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        completed ? 'Completed' : 'Scheduled',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Builder(
                      builder: (context) => Text(
                        MaterialLocalizations.of(
                          context,
                        ).formatMediumDate(entry.date),
                        style: GoogleFonts.nunitoSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                if (entry.notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.notes,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 12.5,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () => _openVaccineLogForm(existing: entry),
                tooltip: 'Edit',
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              if (!completed)
                IconButton(
                  onPressed: () async {
                    try {
                      await VaccineLogStore.setReminderEnabled(
                        entry,
                        !entry.reminderEnabled,
                      );
                    } catch (e) {
                      _showError('Could not update reminder: $e');
                    }
                  },
                  tooltip: entry.reminderEnabled
                      ? 'Reminder on'
                      : 'Reminder off',
                  icon: Icon(
                    entry.reminderEnabled
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_outlined,
                    color: entry.reminderEnabled
                        ? AppColors.secondary
                        : AppColors.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              IconButton(
                onPressed: () async {
                  final confirmed = await _confirmDelete(
                    'Remove vaccine log?',
                    'This permanently deletes "${entry.vaccineName}" from your log.',
                  );
                  if (!confirmed) return;
                  try {
                    await VaccineLogStore.remove(entry);
                  } catch (e) {
                    _showError('Could not remove: $e');
                  }
                },
                tooltip: 'Remove',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openVaccineLogForm({String? prefillName, VaccineLogEntry? existing}) {
    final references = widget.babyCare
        ? babyVaccineReferences
        : maternalVaccineReferences;
    final initialName = existing?.vaccineName ?? prefillName;
    final isReference = references.any((v) => v.name == initialName);
    final customNameController = TextEditingController(
      text: isReference ? '' : (initialName ?? ''),
    );
    final notesController = TextEditingController(text: existing?.notes ?? '');
    String? selectedName = isReference ? initialName : null;
    bool useCustomName = !isReference;
    VaccineLogStatus status = existing?.status ?? VaccineLogStatus.scheduled;
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
          child: _formSheet(
            title: existing == null ? 'Log a vaccine' : 'Edit vaccine log',
            saving: saving,
            errorText: formError,
            onSave: () async {
              final name = useCustomName
                  ? customNameController.text.trim()
                  : (selectedName ?? '');
              setSheetState(() {
                formError = null;
                saving = true;
              });
              try {
                final draft = VaccineLogEntry(
                  id: existing?.id,
                  vaccineName: name,
                  status: status,
                  date: date,
                  notes: notesController.text.trim(),
                  reminderEnabled: existing?.reminderEnabled ?? true,
                );
                if (existing == null) {
                  await VaccineLogStore.add(draft);
                } else {
                  await VaccineLogStore.update(draft);
                }
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              } catch (e) {
                setSheetState(() {
                  saving = false;
                  formError = e is HealthRecordValidationError
                      ? e.message
                      : 'Could not save: $e';
                });
              }
            },
            children: [
              _chipLabel('Vaccine'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...(widget.babyCare
                          ? babyVaccineReferences
                          : maternalVaccineReferences)
                      .map(
                        (v) => _choiceChip(
                          v.name.split(' (').first,
                          !useCustomName && selectedName == v.name,
                          () => setSheetState(() {
                            useCustomName = false;
                            selectedName = v.name;
                          }),
                        ),
                      ),
                  _choiceChip(
                    'Other',
                    useCustomName,
                    () => setSheetState(() => useCustomName = true),
                  ),
                ],
              ),
              if (useCustomName) ...[
                const SizedBox(height: 12),
                _textField(customNameController, 'Vaccine name'),
              ],
              const SizedBox(height: 16),
              _chipLabel('Status'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _choiceChip(
                    'Scheduled',
                    status == VaccineLogStatus.scheduled,
                    () => setSheetState(
                      () => status = VaccineLogStatus.scheduled,
                    ),
                  ),
                  _choiceChip(
                    'Completed',
                    status == VaccineLogStatus.completed,
                    () => setSheetState(
                      () => status = VaccineLogStatus.completed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _pickerRow(
                label: 'Date',
                value: MaterialLocalizations.of(
                  sheetContext,
                ).formatMediumDate(date),
                icon: Icons.calendar_month_outlined,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: sheetContext,
                    initialDate: date,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null) setSheetState(() => date = picked);
                },
              ),
              const SizedBox(height: 12),
              _textField(notesController, 'Notes (optional)', maxLines: 3),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Shared form widgets ----------------

  Widget _emptyState({required IconData icon, required String message}) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: AppColors.lavenderLight),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunitoSans(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _formSheet({
    required String title,
    required VoidCallback onSave,
    required List<Widget> children,
    bool saving = false,
    String? errorText,
  }) => Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(20),
    constraints: const BoxConstraints(maxHeight: 640),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: GoogleFonts.nunitoSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 12),
          Text(
            errorText,
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
            onPressed: saving ? null : onSave,
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
                    'Save',
                    style: GoogleFonts.nunitoSans(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    ),
  );

  Widget _textField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) => TextField(
    controller: controller,
    maxLines: maxLines,
    style: GoogleFonts.nunitoSans(fontSize: 14, color: AppColors.onSurface),
    decoration: InputDecoration(
      hintText: hint,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );

  Widget _chipLabel(String label) => Text(
    label,
    style: GoogleFonts.nunitoSans(
      fontSize: 12.5,
      fontWeight: FontWeight.w800,
      color: AppColors.onSurfaceVariant,
    ),
  );

  Widget _choiceChip(String label, bool selected, VoidCallback onTap) =>
      InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.nunitoSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      );

  Widget _pickerRow({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.onSurfaceVariant,
          ),
        ],
      ),
    ),
  );
}
