import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_session.dart';
import '../../../core/app_settings_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/screen_background.dart';
import '../../../core/widgets/settings_toggle_row.dart';
import '../../onboarding/presentation/welcome_screen.dart';

class AppPreferencesScreen extends StatefulWidget {
  const AppPreferencesScreen({super.key});

  @override
  State<AppPreferencesScreen> createState() => _AppPreferencesScreenState();
}

class _AppPreferencesScreenState extends State<AppPreferencesScreen> {
  String _units = 'Metric';
  bool _hapticFeedback = true;

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
      _units = s.units;
      _hapticFeedback = s.hapticFeedback;
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
    );
  }

  Future<void> _confirmResetOnboarding() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Restart onboarding?',
                style: GoogleFonts.nunitoSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You'll be taken back to the welcome screen and walked through setup again.",
                style: GoogleFonts.nunitoSans(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        foregroundColor: AppColors.onSurfaceVariant,
                        side: BorderSide(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.nunitoSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        'Restart',
                        style: GoogleFonts.nunitoSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true && mounted) {
      AppSession.mode = AppMode.familyPlanning;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('Display'),
                          const SizedBox(height: 10),
                          _card([
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Units',
                                          style: GoogleFonts.nunitoSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Used for weight and temperature tracking.',
                                          style: GoogleFonts.nunitoSans(
                                            fontSize: 12,
                                            height: 1.35,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _unitsToggle(),
                            const SizedBox(height: 4),
                          ]),
                          const SizedBox(height: 24),
                          _sectionTitle('Interactions'),
                          const SizedBox(height: 10),
                          _card([
                            SettingsToggleRow(
                              icon: Icons.vibration_rounded,
                              title: 'Haptic feedback',
                              subtitle:
                                  'Feel a light tap when you interact with the app.',
                              value: _hapticFeedback,
                              onChanged: (v) async {
                                setState(() => _hapticFeedback = v);
                                if (v) HapticFeedback.lightImpact();
                                try {
                                  await AppSettingsStore.setHapticFeedback(v);
                                } catch (e) {
                                  setState(() => _hapticFeedback = !v);
                                  _showError('Could not save: $e');
                                }
                              },
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _sectionTitle('General'),
                          const SizedBox(height: 10),
                          _card([
                            _actionRow(
                              icon: Icons.language_rounded,
                              title: 'Language',
                              trailing: 'English',
                              onTap: () =>
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'More languages are coming soon.',
                                      ),
                                    ),
                                  ),
                            ),
                            const Divider(height: 20),
                            _actionRow(
                              icon: Icons.restart_alt_rounded,
                              title: 'Restart onboarding',
                              trailing: '',
                              onTap: _confirmResetOnboarding,
                            ),
                          ]),
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
                'App preferences',
                style: GoogleFonts.nunitoSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Adjust BabyBloom to fit you.',
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

  Widget _unitsToggle() => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.outlineVariant.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      children: ['Metric', 'Imperial'].map((unit) {
        final selected = _units == unit;
        return Expanded(
          child: GestureDetector(
            onTap: () async {
              final previous = _units;
              setState(() => _units = unit);
              try {
                await AppSettingsStore.setUnits(unit);
              } catch (e) {
                setState(() => _units = previous);
                _showError('Could not save: $e');
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: selected ? AppColors.buttonGradient : null,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                unit,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunitoSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );

  Widget _actionRow({
    required IconData icon,
    required String title,
    required String trailing,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFD3BBFE),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.nunitoSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
          ),
          if (trailing.isNotEmpty) ...[
            Text(
              trailing,
              style: GoogleFonts.nunitoSans(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Icon(
            Icons.chevron_right,
            color: AppColors.primary.withValues(alpha: 0.6),
          ),
        ],
      ),
    ),
  );
}
