import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/home/presentation/health_schedule_models.dart';
import '../app_session.dart';
import '../app_settings_store.dart';
import '../theme/app_colors.dart';

/// Opens the shared, in-app reminder inbox from every journey's bell icon.
Future<void> showNotificationsPanel(BuildContext context) => showGeneralDialog(
  context: context,
  barrierDismissible: true,
  barrierLabel: 'Notifications',
  barrierColor: Colors.black.withValues(alpha: 0.15),
  transitionDuration: const Duration(milliseconds: 220),
  pageBuilder: (context, _, _) => const _NotificationsOverlay(),
  transitionBuilder: (context, animation, _, child) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1).animate(curved),
        alignment: Alignment.topRight,
        child: child,
      ),
    );
  },
);

typedef _NotificationItem = ({
  IconData icon,
  Color color,
  String title,
  String message,
  String timeAgo,
});

class _NotificationsOverlay extends StatefulWidget {
  const _NotificationsOverlay();

  @override
  State<_NotificationsOverlay> createState() => _NotificationsOverlayState();
}

class _NotificationsOverlayState extends State<_NotificationsOverlay> {
  final Set<int> _readIndexes = {};

  @override
  void initState() {
    super.initState();
    _loadReminderSources();
  }

  Future<void> _loadReminderSources() async {
    try {
      await Future.wait([
        AppSettingsStore.fetch(),
        MedicationStore.fetchAll(),
        AppointmentStore.fetchAll(),
        VaccineLogStore.fetchAll(),
      ]);
    } catch (_) {
      // Any reminders already loaded by the active screen can still be shown.
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final width = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        Positioned(
          top: topInset + 74,
          right: 20,
          width: width - 40 > 380 ? 380 : width - 40,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 440),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 30,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: _notificationContent(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _notificationContent() => ValueListenableBuilder<AppSettings?>(
    valueListenable: AppSettingsStore.current,
    builder: (context, settings, _) =>
        ValueListenableBuilder<List<MedicationReminder>>(
          valueListenable: MedicationStore.items,
          builder: (context, medications, _) =>
              ValueListenableBuilder<List<HealthAppointment>>(
                valueListenable: AppointmentStore.items,
                builder: (context, appointments, _) =>
                    ValueListenableBuilder<List<VaccineLogEntry>>(
                      valueListenable: VaccineLogStore.items,
                      builder: (context, vaccines, _) {
                        final items = _reminderItems(
                          settings,
                          medications,
                          appointments,
                          vaccines,
                        );
                        final unreadCount =
                            items.length -
                            _readIndexes.where((i) => i < items.length).length;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _header(context, items.length, unreadCount),
                            const Divider(height: 1),
                            Flexible(
                              child: items.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(28),
                                      child: Text(
                                        'No active reminders yet.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.nunitoSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      itemCount: items.length,
                                      separatorBuilder: (_, _) => Divider(
                                        height: 1,
                                        indent: 64,
                                        color: AppColors.outlineVariant
                                            .withValues(alpha: 0.2),
                                      ),
                                      itemBuilder: (context, index) =>
                                          _notificationTile(
                                            index,
                                            items[index],
                                          ),
                                    ),
                            ),
                            _footer(unreadCount),
                          ],
                        );
                      },
                    ),
              ),
        ),
  );

  List<_NotificationItem> _reminderItems(
    AppSettings? settings,
    List<MedicationReminder> medications,
    List<HealthAppointment> appointments,
    List<VaccineLogEntry> vaccines,
  ) {
    final items = <_NotificationItem>[];
    final mode = AppSession.mode;
    if (settings != null && mode == AppMode.familyPlanning) {
      if (settings.dailyCheckin) {
        items.add((
          icon: Icons.edit_note_rounded,
          color: AppColors.primary,
          title: 'Daily check-in reminder',
          message:
              'Your check-in is set for ${settings.dailyCheckinTime.format(context)}.',
          timeAgo: 'Daily',
        ));
      }
      if (settings.periodReminders) {
        items.add((
          icon: Icons.calendar_month_rounded,
          color: AppColors.secondary,
          title: 'Period reminders are on',
          message: 'We will keep your cycle reminders visible here.',
          timeAgo: 'Active',
        ));
      }
      if (settings.fertileWindowAlerts) {
        items.add((
          icon: Icons.favorite_outline_rounded,
          color: AppColors.primaryContainer,
          title: 'Fertile-window alerts are on',
          message: 'Your upcoming fertile-window reminder will appear here.',
          timeAgo: 'Active',
        ));
      }
    }
    if (mode == AppMode.pregnancy || mode == AppMode.babyCare) {
      for (final medication
          in medications.where((m) => m.reminderEnabled).take(3)) {
        items.add((
          icon: Icons.medication_outlined,
          color: AppColors.primary,
          title:
              '${mode == AppMode.babyCare ? 'Medicine' : 'Medication'} reminder',
          message:
              '${medication.name} at ${medication.time.format(context)} · ${medication.frequency.label}',
          timeAgo: 'Active',
        ));
      }
      final today = DateUtils.dateOnly(DateTime.now());
      for (final appointment
          in appointments
              .where(
                (a) =>
                    a.reminderEnabled &&
                    !DateUtils.dateOnly(a.date).isBefore(today),
              )
              .take(3)) {
        items.add((
          icon: Icons.event_available_outlined,
          color: AppColors.secondary,
          title:
              'Upcoming ${mode == AppMode.babyCare ? 'checkup' : 'appointment'}',
          message:
              '${appointment.title} · ${_dateLabel(appointment.date)} at ${appointment.time.format(context)}',
          timeAgo: _dateLabel(appointment.date),
        ));
      }
      for (final vaccine
          in vaccines
              .where(
                (v) =>
                    v.reminderEnabled &&
                    v.status == VaccineLogStatus.scheduled &&
                    !DateUtils.dateOnly(v.date).isBefore(today),
              )
              .take(3)) {
        items.add((
          icon: Icons.vaccines_outlined,
          color: AppColors.primaryContainer,
          title: 'Vaccine reminder',
          message: '${vaccine.vaccineName} · ${_dateLabel(vaccine.date)}',
          timeAgo: _dateLabel(vaccine.date),
        ));
      }
    }
    return items;
  }

  String _dateLabel(DateTime date) {
    final today = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(date);
    if (day == today) return 'Today';
    if (day == today.add(const Duration(days: 1))) return 'Tomorrow';
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  Widget _header(BuildContext context, int itemCount, int unreadCount) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 10, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Notifications',
                style: GoogleFonts.nunitoSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            if (unreadCount > 0)
              TextButton(
                onPressed: () => setState(
                  () => _readIndexes.addAll(List.generate(itemCount, (i) => i)),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Mark all read',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Close',
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
            ),
          ],
        ),
      );

  Widget _notificationTile(int index, _NotificationItem item) {
    final unread = !_readIndexes.contains(index);
    return InkWell(
      onTap: () => setState(() => _readIndexes.add(index)),
      child: Container(
        color: unread
            ? AppColors.secondaryContainer.withValues(alpha: 0.12)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 13,
                      fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 12,
                      height: 1.35,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.timeAgo,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (unread) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _footer(int unreadCount) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(
      unreadCount == 0
          ? "You're all caught up."
          : '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
      style: GoogleFonts.nunitoSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurfaceVariant,
      ),
    ),
  );
}
