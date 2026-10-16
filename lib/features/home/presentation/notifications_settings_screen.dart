import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_settings_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/screen_background.dart';
import '../../../core/widgets/settings_toggle_row.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool _periodReminders = true;
  bool _fertileWindow = true;
  bool _dailyCheckIn = true;
  bool _communityActivity = true;
  bool _weeklyInsights = false;
  bool _bloomAiCheckIns = false;

  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (AppSettingsStore.current.value == null) {
      try {
        await AppSettingsStore.fetch();
      } catch (e) {
        if (mounted) _showError('Could not load settings: $e');
        return;
      }
    }
    final s = AppSettingsStore.current.value;
    if (s == null || !mounted) return;
    setState(() {
      _periodReminders = s.periodReminders;
      _fertileWindow = s.fertileWindowAlerts;
      _dailyCheckIn = s.dailyCheckin;
      _communityActivity = s.communityActivity;
      _weeklyInsights = s.weeklyInsights;
      _bloomAiCheckIns = s.bloomAiCheckins;
      _reminderTime = s.dailyCheckinTime;
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
    );
  }

  Future<void> _pickReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
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
    if (time == null) return;
    setState(() => _reminderTime = time);
    try {
      await AppSettingsStore.setDailyCheckinTime(time);
    } catch (e) {
      _showError('Could not save: $e');
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('Cycle alerts'),
                          const SizedBox(height: 10),
                          _card([
                            SettingsToggleRow(
                              icon: Icons.water_drop_outlined,
                              title: 'Period reminders',
                              subtitle:
                                  'Your period is expected to start soon.',
                              value: _periodReminders,
                              onChanged: (v) async {
                                setState(() => _periodReminders = v);
                                try {
                                  await AppSettingsStore.setPeriodReminders(v);
                                } catch (e) {
                                  setState(() => _periodReminders = !v);
                                  _showError('Could not save: $e');
                                }
                              },
                            ),
                            const Divider(height: 20),
                            SettingsToggleRow(
                              icon: Icons.favorite_outline,
                              title: 'Fertile window alerts',
                              subtitle:
                                  'Get notified before your fertile window begins.',
                              value: _fertileWindow,
                              onChanged: (v) async {
                                setState(() => _fertileWindow = v);
                                try {
                                  await AppSettingsStore.setFertileWindowAlerts(
                                    v,
                                  );
                                } catch (e) {
                                  setState(() => _fertileWindow = !v);
                                  _showError('Could not save: $e');
                                }
                              },
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _sectionTitle('Reminders'),
                          const SizedBox(height: 10),
                          _card([
                            SettingsToggleRow(
                              icon: Icons.edit_note_rounded,
                              title: 'Daily check-in reminder',
                              subtitle: 'A gentle nudge to log your day.',
                              value: _dailyCheckIn,
                              onChanged: (v) async {
                                setState(() => _dailyCheckIn = v);
                                try {
                                  await AppSettingsStore.setDailyCheckin(v);
                                } catch (e) {
                                  setState(() => _dailyCheckIn = !v);
                                  _showError('Could not save: $e');
                                }
                              },
                            ),
                            if (_dailyCheckIn) ...[
                              const Divider(height: 20),
                              GestureDetector(
                                onTap: _pickReminderTime,
                                child: Row(
                                  children: [
                                    const SizedBox(width: 50),
                                    Expanded(
                                      child: Text(
                                        'Reminder time',
                                        style: GoogleFonts.nunitoSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _reminderTime.format(context),
                                      style: GoogleFonts.nunitoSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.chevron_right,
                                      color: AppColors.primary.withValues(
                                        alpha: 0.6,
                                      ),
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ]),
                          const SizedBox(height: 24),
                          _sectionTitle('Community & insights'),
                          const SizedBox(height: 10),
                          _card([
                            SettingsToggleRow(
                              icon: Icons.groups_outlined,
                              title: 'Community activity',
                              subtitle:
                                  'Likes, comments, and replies on your posts.',
                              value: _communityActivity,
                              onChanged: (v) async {
                                setState(() => _communityActivity = v);
                                try {
                                  await AppSettingsStore.setCommunityActivity(
                                    v,
                                  );
                                } catch (e) {
                                  setState(() => _communityActivity = !v);
                                  _showError('Could not save: $e');
                                }
                              },
                            ),
                            const Divider(height: 20),
                            SettingsToggleRow(
                              icon: Icons.insights_outlined,
                              title: 'Weekly insight reports',
                              subtitle: 'A summary of your patterns each week.',
                              value: _weeklyInsights,
                              onChanged: (v) async {
                                setState(() => _weeklyInsights = v);
                                try {
                                  await AppSettingsStore.setWeeklyInsights(v);
                                } catch (e) {
                                  setState(() => _weeklyInsights = !v);
                                  _showError('Could not save: $e');
                                }
                              },
                            ),
                            const Divider(height: 20),
                            SettingsToggleRow(
                              icon: Icons.auto_awesome_outlined,
                              title: 'Bloom AI check-ins',
                              subtitle:
                                  'Occasional supportive messages from Bloom AI.',
                              value: _bloomAiCheckIns,
                              onChanged: (v) async {
                                setState(() => _bloomAiCheckIns = v);
                                try {
                                  await AppSettingsStore.setBloomAiCheckins(v);
                                } catch (e) {
                                  setState(() => _bloomAiCheckIns = !v);
                                  _showError('Could not save: $e');
                                }
                              },
                            ),
                          ]),
                          const SizedBox(height: 18),
                          Center(
                            child: Text(
                              'Changes save automatically.',
                              style: GoogleFonts.nunitoSans(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ),
                        ],
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
                'Notifications',
                style: GoogleFonts.nunitoSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Choose what you hear from us.',
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

  Widget _sectionTitle(String title) => Text(
    title,
    style: GoogleFonts.nunitoSans(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: AppColors.primary,
    ),
  );

  Widget _card(List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
    child: Column(children: children),
  );
}
