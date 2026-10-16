import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_config.dart';

SupabaseClient get _db => SupabaseConfig.client;

String get _userId {
  final id = _db.auth.currentUser?.id;
  if (id == null) {
    throw StateError('You must be signed in to use the health schedule.');
  }
  return id;
}

String _dateToRow(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _timeToRow(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

TimeOfDay _timeFromRow(String value) {
  final parts = value.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

/// Thrown when a health-schedule record fails client-side validation before
/// it's sent to Supabase.
class HealthRecordValidationError implements Exception {
  HealthRecordValidationError(this.message);
  final String message;

  @override
  String toString() => message;
}

enum MedFrequency { onceDaily, twiceDaily, threeTimesDaily, weekly, asNeeded }

extension MedFrequencyLabel on MedFrequency {
  String get label => switch (this) {
    MedFrequency.onceDaily => 'Once daily',
    MedFrequency.twiceDaily => 'Twice daily',
    MedFrequency.threeTimesDaily => '3x daily',
    MedFrequency.weekly => 'Weekly',
    MedFrequency.asNeeded => 'As needed',
  };
}

class MedicationReminder {
  MedicationReminder({
    this.id,
    required this.name,
    required this.dosage,
    required this.time,
    required this.frequency,
    this.reminderEnabled = true,
  });

  final String? id;
  String name;
  String dosage;
  TimeOfDay time;
  MedFrequency frequency;
  bool reminderEnabled;

  factory MedicationReminder.fromRow(Map<String, dynamic> row) =>
      MedicationReminder(
        id: row['id'] as String,
        name: row['name'] as String,
        dosage: row['dosage'] as String,
        time: _timeFromRow(row['time'] as String),
        frequency: MedFrequency.values.byName(row['frequency'] as String),
        reminderEnabled: row['reminder_enabled'] as bool,
      );

  Map<String, dynamic> toRow() => {
    'name': name,
    'dosage': dosage,
    'time': _timeToRow(time),
    'frequency': frequency.name,
    'reminder_enabled': reminderEnabled,
  };
}

void _validateMedication(MedicationReminder med) {
  if (med.name.trim().isEmpty) {
    throw HealthRecordValidationError(
      'Medication or vitamin name is required.',
    );
  }
}

/// Backs [MedicationReminder] with the `medication_reminders` Supabase table.
class MedicationStore {
  MedicationStore._();

  static const String _table = 'medication_reminders';

  static final ValueNotifier<List<MedicationReminder>> items =
      ValueNotifier<List<MedicationReminder>>([]);
  static final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  static Future<void> fetchAll() async {
    isLoading.value = true;
    try {
      final rows = await _db
          .from(_table)
          .select()
          .eq('user_id', _userId)
          .order('created_at');
      items.value = rows.map(MedicationReminder.fromRow).toList();
    } finally {
      isLoading.value = false;
    }
  }

  static Future<void> add(MedicationReminder med) async {
    _validateMedication(med);
    final row = await _db
        .from(_table)
        .insert({...med.toRow(), 'user_id': _userId})
        .select()
        .single();
    items.value = [...items.value, MedicationReminder.fromRow(row)];
  }

  static Future<void> update(MedicationReminder med) async {
    if (med.id == null) {
      throw HealthRecordValidationError('Cannot update an unsaved medication.');
    }
    _validateMedication(med);
    final row = await _db
        .from(_table)
        .update(med.toRow())
        .eq('id', med.id!)
        .select()
        .single();
    final saved = MedicationReminder.fromRow(row);
    items.value = [
      for (final item in items.value) item.id == saved.id ? saved : item,
    ];
  }

  static Future<void> setReminderEnabled(
    MedicationReminder med,
    bool enabled,
  ) async {
    final row = await _db
        .from(_table)
        .update({'reminder_enabled': enabled})
        .eq('id', med.id!)
        .select()
        .single();
    final updated = MedicationReminder.fromRow(row);
    items.value = [
      for (final m in items.value) m.id == updated.id ? updated : m,
    ];
  }

  static Future<void> remove(MedicationReminder med) async {
    await _db.from(_table).delete().eq('id', med.id!);
    items.value = items.value.where((m) => m.id != med.id).toList();
  }
}

enum AppointmentType { checkup, lab, ultrasound, other }

extension AppointmentTypeMeta on AppointmentType {
  String get label => switch (this) {
    AppointmentType.checkup => 'Checkup',
    AppointmentType.lab => 'Lab test',
    AppointmentType.ultrasound => 'Ultrasound',
    AppointmentType.other => 'Other',
  };

  IconData get icon => switch (this) {
    AppointmentType.checkup => Icons.medical_services_outlined,
    AppointmentType.lab => Icons.biotech_outlined,
    AppointmentType.ultrasound => Icons.pregnant_woman_outlined,
    AppointmentType.other => Icons.event_note_outlined,
  };
}

class HealthAppointment {
  HealthAppointment({
    this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.type,
    this.notes = '',
    this.reminderEnabled = true,
  });

  final String? id;
  String title;
  DateTime date;
  TimeOfDay time;
  AppointmentType type;
  String notes;
  bool reminderEnabled;

  DateTime get dateTime =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  factory HealthAppointment.fromRow(Map<String, dynamic> row) =>
      HealthAppointment(
        id: row['id'] as String,
        title: row['title'] as String,
        date: DateTime.parse(row['date'] as String),
        time: _timeFromRow(row['time'] as String),
        type: AppointmentType.values.byName(row['type'] as String),
        notes: (row['notes'] as String?) ?? '',
        reminderEnabled: row['reminder_enabled'] as bool,
      );

  Map<String, dynamic> toRow() => {
    'title': title,
    'date': _dateToRow(date),
    'time': _timeToRow(time),
    'type': type.name,
    'notes': notes,
    'reminder_enabled': reminderEnabled,
  };
}

void _validateAppointment(HealthAppointment appt) {
  if (appt.title.trim().isEmpty) {
    throw HealthRecordValidationError('Appointment title is required.');
  }
}

/// Backs [HealthAppointment] with the `health_appointments` Supabase table.
class AppointmentStore {
  AppointmentStore._();

  static const String _table = 'health_appointments';

  static final ValueNotifier<List<HealthAppointment>> items =
      ValueNotifier<List<HealthAppointment>>([]);
  static final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  static Future<void> fetchAll() async {
    isLoading.value = true;
    try {
      final rows = await _db
          .from(_table)
          .select()
          .eq('user_id', _userId)
          .order('date');
      items.value = rows.map(HealthAppointment.fromRow).toList();
    } finally {
      isLoading.value = false;
    }
  }

  static Future<void> add(HealthAppointment appt) async {
    _validateAppointment(appt);
    final row = await _db
        .from(_table)
        .insert({...appt.toRow(), 'user_id': _userId})
        .select()
        .single();
    items.value = [...items.value, HealthAppointment.fromRow(row)];
  }

  static Future<void> update(HealthAppointment appt) async {
    if (appt.id == null) {
      throw HealthRecordValidationError(
        'Cannot update an unsaved appointment.',
      );
    }
    _validateAppointment(appt);
    final row = await _db
        .from(_table)
        .update(appt.toRow())
        .eq('id', appt.id!)
        .select()
        .single();
    final saved = HealthAppointment.fromRow(row);
    items.value = [
      for (final item in items.value) item.id == saved.id ? saved : item,
    ];
  }

  static Future<void> setReminderEnabled(
    HealthAppointment appt,
    bool enabled,
  ) async {
    final row = await _db
        .from(_table)
        .update({'reminder_enabled': enabled})
        .eq('id', appt.id!)
        .select()
        .single();
    final updated = HealthAppointment.fromRow(row);
    items.value = [
      for (final a in items.value) a.id == updated.id ? updated : a,
    ];
  }

  static Future<void> remove(HealthAppointment appt) async {
    await _db.from(_table).delete().eq('id', appt.id!);
    items.value = items.value.where((a) => a.id != appt.id).toList();
  }
}

enum VaccineLogStatus { scheduled, completed }

class VaccineReference {
  const VaccineReference({
    required this.name,
    required this.recommendedTiming,
    required this.description,
    required this.sourceNote,
  });

  final String name;
  final String recommendedTiming;
  final String description;
  final String sourceNote;
}

const List<VaccineReference> maternalVaccineReferences = [
  VaccineReference(
    name: 'Tdap (Tetanus, Diphtheria, Pertussis)',
    recommendedTiming: 'Generally recommended 27–36 weeks of each pregnancy',
    description:
        'Helps protect the newborn against whooping cough (pertussis) in their first months of life, before they can be vaccinated themselves.',
    sourceNote: 'Reference: WHO / DOH maternal immunization guidance',
  ),
  VaccineReference(
    name: 'Influenza (Flu)',
    recommendedTiming: 'Any trimester, ideally before flu season',
    description:
        'Pregnancy increases the risk of severe complications from flu. A flu shot may also protect the baby in their first few months.',
    sourceNote: 'Reference: WHO / DOH maternal immunization guidance',
  ),
  VaccineReference(
    name: 'RSV (Respiratory Syncytial Virus)',
    recommendedTiming: 'Generally discussed around 32–36 weeks of pregnancy',
    description:
        'May help protect infants from severe RSV disease in their first months of life. Availability and timing vary by region.',
    sourceNote: 'Reference: WHO / DOH maternal immunization guidance',
  ),
  VaccineReference(
    name: 'COVID-19',
    recommendedTiming: 'Any trimester, per local health guidance',
    description:
        'May reduce the risk of severe illness during pregnancy and can offer some protection to the newborn.',
    sourceNote: 'Reference: WHO / DOH maternal immunization guidance',
  ),
];

/// Philippine National Immunization Program reference for babies. This is a
/// tracking aid; the child's health centre or pediatrician remains the source
/// of truth for catch-up schedules, contraindications, and local availability.
const List<VaccineReference> babyVaccineReferences = [
  VaccineReference(
    name: 'BCG (Bacille Calmette-Guerin)',
    recommendedTiming: 'At birth',
    description:
        'A single birth dose that helps protect babies from severe forms of tuberculosis.',
    sourceNote: 'Reference: Philippine DOH National Immunization Program',
  ),
  VaccineReference(
    name: 'Hepatitis B birth dose (HepB-BD)',
    recommendedTiming: 'At birth, preferably within 24 hours',
    description:
        'The newborn dose helps prevent hepatitis B infection and is separate from hepatitis B contained in pentavalent vaccine.',
    sourceNote: 'Reference: Philippine DOH National Immunization Program',
  ),
  VaccineReference(
    name: 'Pentavalent (DPT-HepB-Hib)',
    recommendedTiming: 'Dose 1: 6 weeks · Dose 2: 10 weeks · Dose 3: 14 weeks',
    description:
        'Protects against diphtheria, pertussis, tetanus, hepatitis B, and Haemophilus influenzae type b.',
    sourceNote: 'Reference: Philippine DOH National Immunization Program',
  ),
  VaccineReference(
    name: 'Oral Polio Vaccine (OPV)',
    recommendedTiming: 'Dose 1: 6 weeks · Dose 2: 10 weeks · Dose 3: 14 weeks',
    description:
        'Oral vaccine used in the routine series to protect against polio.',
    sourceNote: 'Reference: Philippine DOH National Immunization Program',
  ),
  VaccineReference(
    name: 'Inactivated Polio Vaccine (IPV)',
    recommendedTiming: 'Dose 1: 14 weeks · additional dose may apply locally',
    description:
        'Injected polio vaccine. A later dose may be offered in selected areas or under updated local guidance.',
    sourceNote: 'Reference: Philippine DOH National Immunization Program',
  ),
  VaccineReference(
    name: 'Pneumococcal Conjugate Vaccine (PCV)',
    recommendedTiming: 'Dose 1: 6 weeks · Dose 2: 10 weeks · Dose 3: 14 weeks',
    description:
        'Helps protect against serious pneumococcal infections such as pneumonia and meningitis.',
    sourceNote: 'Reference: Philippine DOH National Immunization Program',
  ),
  VaccineReference(
    name: 'Rotavirus vaccine (RV)',
    recommendedTiming: 'Dose 1: 6 weeks · Dose 2: 10 weeks',
    description:
        'Oral vaccine against severe rotavirus diarrhea. Product, eligibility, and availability can vary.',
    sourceNote:
        'Reference: Philippine DOH National Immunization Program manual',
  ),
  VaccineReference(
    name: 'Measles-Mumps-Rubella (MMR)',
    recommendedTiming: 'Dose 1: 9 months · Dose 2: 12 months',
    description: 'Protects against measles, mumps, and rubella.',
    sourceNote: 'Reference: Philippine DOH National Immunization Program',
  ),
  VaccineReference(
    name: 'Japanese Encephalitis (JE)',
    recommendedTiming: 'From 9 months where included or indicated',
    description:
        'May be provided based on the local program, location, travel, and the child\'s risk.',
    sourceNote:
        'Reference: Philippine DOH National Immunization Program manual',
  ),
];

class VaccineLogEntry {
  VaccineLogEntry({
    this.id,
    required this.vaccineName,
    required this.status,
    required this.date,
    this.notes = '',
    this.reminderEnabled = true,
  });

  final String? id;
  String vaccineName;
  VaccineLogStatus status;
  DateTime date;
  String notes;
  bool reminderEnabled;

  factory VaccineLogEntry.fromRow(Map<String, dynamic> row) => VaccineLogEntry(
    id: row['id'] as String,
    vaccineName: row['vaccine_name'] as String,
    status: VaccineLogStatus.values.byName(row['status'] as String),
    date: DateTime.parse(row['date'] as String),
    notes: (row['notes'] as String?) ?? '',
    reminderEnabled: row['reminder_enabled'] as bool,
  );

  Map<String, dynamic> toRow() => {
    'vaccine_name': vaccineName,
    'status': status.name,
    'date': _dateToRow(date),
    'notes': notes,
    'reminder_enabled': reminderEnabled,
  };
}

void _validateVaccineLog(VaccineLogEntry entry) {
  if (entry.vaccineName.trim().isEmpty) {
    throw HealthRecordValidationError('Please choose or enter a vaccine name.');
  }
}

/// Backs [VaccineLogEntry] with the `vaccine_log_entries` Supabase table.
class VaccineLogStore {
  VaccineLogStore._();

  static const String _table = 'vaccine_log_entries';

  static final ValueNotifier<List<VaccineLogEntry>> items =
      ValueNotifier<List<VaccineLogEntry>>([]);
  static final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  static Future<void> fetchAll() async {
    isLoading.value = true;
    try {
      final rows = await _db
          .from(_table)
          .select()
          .eq('user_id', _userId)
          .order('date');
      items.value = rows.map(VaccineLogEntry.fromRow).toList();
    } finally {
      isLoading.value = false;
    }
  }

  static Future<void> add(VaccineLogEntry entry) async {
    _validateVaccineLog(entry);
    if (entry.status == VaccineLogStatus.completed) {
      entry.reminderEnabled = false;
    }
    final row = await _db
        .from(_table)
        .insert({...entry.toRow(), 'user_id': _userId})
        .select()
        .single();
    items.value = [...items.value, VaccineLogEntry.fromRow(row)];
  }

  static Future<void> update(VaccineLogEntry entry) async {
    if (entry.id == null) {
      throw HealthRecordValidationError(
        'Cannot update an unsaved vaccine log.',
      );
    }
    _validateVaccineLog(entry);
    if (entry.status == VaccineLogStatus.completed) {
      entry.reminderEnabled = false;
    }
    final row = await _db
        .from(_table)
        .update(entry.toRow())
        .eq('id', entry.id!)
        .select()
        .single();
    final saved = VaccineLogEntry.fromRow(row);
    items.value = [
      for (final item in items.value) item.id == saved.id ? saved : item,
    ];
  }

  static Future<void> setReminderEnabled(
    VaccineLogEntry entry,
    bool enabled,
  ) async {
    if (entry.status == VaccineLogStatus.completed && enabled) {
      throw HealthRecordValidationError(
        'Completed vaccines do not need reminders.',
      );
    }
    final row = await _db
        .from(_table)
        .update({'reminder_enabled': enabled})
        .eq('id', entry.id!)
        .select()
        .single();
    final updated = VaccineLogEntry.fromRow(row);
    items.value = [
      for (final e in items.value) e.id == updated.id ? updated : e,
    ];
  }

  static Future<void> remove(VaccineLogEntry entry) async {
    await _db.from(_table).delete().eq('id', entry.id!);
    items.value = items.value.where((e) => e.id != entry.id).toList();
  }
}
