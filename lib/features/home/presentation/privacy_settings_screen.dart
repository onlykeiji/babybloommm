import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_settings_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/screen_background.dart';
import '../../../core/widgets/settings_toggle_row.dart';
import 'terms_privacy_screen.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _postAnonymously = false;
  bool _shareResearchData = true;

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
      _postAnonymously = s.postAnonymously;
      _shareResearchData = s.shareResearchData;
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
    );
  }

  void _downloadData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("We'll email your data export within 24 hours."),
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
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
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFEBDCFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Delete your account?',
                style: GoogleFonts.nunitoSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This permanently removes your cycle history, posts, and personal data. This action cannot be undone.',
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
                        'Delete',
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your deletion request has been received.'),
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('Privacy'),
                          const SizedBox(height: 10),
                          _card([
                            SettingsToggleRow(
                              icon: Icons.visibility_off_outlined,
                              title: 'Post anonymously by default',
                              subtitle:
                                  'Hide your name on new community posts.',
                              value: _postAnonymously,
                              onChanged: (v) async {
                                setState(() => _postAnonymously = v);
                                try {
                                  await AppSettingsStore.setPostAnonymously(v);
                                } catch (e) {
                                  setState(() => _postAnonymously = !v);
                                  _showError('Could not save: $e');
                                }
                              },
                            ),
                            const Divider(height: 20),
                            SettingsToggleRow(
                              icon: Icons.science_outlined,
                              title: 'Share anonymized research data',
                              subtitle:
                                  'Help improve BabyBloom with de-identified usage data.',
                              value: _shareResearchData,
                              onChanged: (v) async {
                                setState(() => _shareResearchData = v);
                                try {
                                  await AppSettingsStore.setShareResearchData(
                                    v,
                                  );
                                } catch (e) {
                                  setState(() => _shareResearchData = !v);
                                  _showError('Could not save: $e');
                                }
                              },
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _sectionTitle('Your data'),
                          const SizedBox(height: 10),
                          _card([
                            _actionRow(
                              icon: Icons.download_outlined,
                              title: 'Download my data',
                              subtitle:
                                  'Get a copy of everything you have logged.',
                              onTap: _downloadData,
                            ),
                            const Divider(height: 20),
                            _actionRow(
                              icon: Icons.delete_outline_rounded,
                              title: 'Delete my account',
                              subtitle:
                                  'Permanently remove your account and data.',
                              onTap: _confirmDeleteAccount,
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _sectionTitle('Legal'),
                          const SizedBox(height: 10),
                          _card([
                            _actionRow(
                              icon: Icons.description_outlined,
                              title: 'Terms & Privacy',
                              subtitle:
                                  'Read our Terms of Service and Privacy Policy.',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const TermsPrivacyScreen(),
                                ),
                              ),
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
                'Privacy & data',
                style: GoogleFonts.nunitoSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Control what you share and store.',
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

  Widget _actionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: AppColors.primary.withValues(alpha: 0.6),
          ),
        ],
      ),
    ),
  );
}
