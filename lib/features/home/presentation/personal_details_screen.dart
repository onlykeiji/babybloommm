import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/user_profile_store.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/screen_background.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  DateTime? _birthDate;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _loadError = 'Log in to view and edit your personal details.';
      });
      return;
    }
    try {
      if (ProfileStore.current.value == null) {
        await ProfileStore.fetchCurrent();
      }
      final profile = ProfileStore.current.value;
      if (!mounted) return;
      setState(() {
        _loading = false;
        _nameController.text = profile?.fullName ?? user.email ?? '';
        _emailController.text = profile?.email ?? user.email ?? '';
        _birthDate = profile?.birthDate;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Could not load your details: $e';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1930),
      lastDate: now,
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
    if (date != null) setState(() => _birthDate = date);
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name cannot be empty.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ProfileStore.update(
        fullName: _nameController.text.trim(),
        birthDate: _birthDate,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your details have been updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ProfileException ? e.message : 'Could not save: $e',
          ),
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
                                if (_loadError != null) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    margin: const EdgeInsets.only(bottom: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.red.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      _loadError!,
                                      style: GoogleFonts.nunitoSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                                _fieldCard(
                                  label: 'FULL NAME',
                                  child: TextField(
                                    controller: _nameController,
                                    enabled: _loadError == null,
                                    decoration: _decoration('Your name'),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _fieldCard(
                                  label: 'EMAIL',
                                  child: TextField(
                                    controller: _emailController,
                                    enabled: false,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: _decoration('Your email'),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _fieldCard(
                                  label: 'DATE OF BIRTH',
                                  child: GestureDetector(
                                    onTap: _pickBirthDate,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _birthDate == null
                                                ? 'Select date'
                                                : MaterialLocalizations.of(
                                                    context,
                                                  ).formatMediumDate(
                                                    _birthDate!,
                                                  ),
                                            style: GoogleFonts.nunitoSans(
                                              fontSize: 16,
                                              color: AppColors.onSurface,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.calendar_month_outlined,
                                          color: AppColors.primary.withValues(
                                            alpha: 0.6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
                'Personal details',
                style: GoogleFonts.nunitoSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Keep your profile up to date.',
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

  Widget _fieldCard({required String label, required Widget child}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.nunitoSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            child,
          ],
        ),
      );

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.nunitoSans(
      color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
    ),
    border: InputBorder.none,
    isDense: true,
    contentPadding: EdgeInsets.zero,
  );

  Widget _bottomBar() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: PrimaryButton(
        label: 'Save Changes',
        trailingIcon: Icons.check_rounded,
        loading: _saving,
        onPressed: _save,
      ),
    ),
  );
}
