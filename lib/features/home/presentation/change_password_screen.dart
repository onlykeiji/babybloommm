import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/screen_background.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _saving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final current = _currentController.text;
    final next = _newController.text;
    final confirm = _confirmController.text;

    if (current.isEmpty) {
      setState(() => _errorMessage = 'Enter your current password.');
      return;
    }
    if (next.length < 6) {
      setState(
        () => _errorMessage = 'New password must be at least 6 characters.',
      );
      return;
    }
    if (next != confirm) {
      setState(() => _errorMessage = 'New passwords do not match.');
      return;
    }

    final email = SupabaseConfig.client.auth.currentUser?.email;
    if (email == null) {
      setState(
        () => _errorMessage =
            'Could not find your account email. Please log in again.',
      );
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      // Re-verify the current password before changing anything — updateUser
      // alone would happily change the password for whoever currently holds
      // this session, without proving they actually know the old one.
      await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: current,
      );
      await SupabaseConfig.client.auth.updateUser(
        UserAttributes(password: next),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your password has been updated.')),
      );
    } on AuthException catch (e) {
      setState(() {
        _saving = false;
        _errorMessage = e.code == 'invalid_credentials'
            ? 'Current password is incorrect.'
            : e.message;
      });
    } catch (e) {
      setState(() {
        _saving = false;
        _errorMessage = 'Could not update your password: $e';
      });
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
                          _fieldCard(
                            label: 'CURRENT PASSWORD',
                            child: TextField(
                              controller: _currentController,
                              obscureText: true,
                              decoration: _decoration('Your current password'),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _fieldCard(
                            label: 'NEW PASSWORD',
                            child: TextField(
                              controller: _newController,
                              obscureText: true,
                              decoration: _decoration('At least 6 characters'),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _fieldCard(
                            label: 'CONFIRM NEW PASSWORD',
                            child: TextField(
                              controller: _confirmController,
                              obscureText: true,
                              decoration: _decoration(
                                'Repeat your new password',
                              ),
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.nunitoSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
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
                'Change password',
                style: GoogleFonts.nunitoSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Confirm your current password to set a new one.',
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
        label: 'Update Password',
        trailingIcon: Icons.check_rounded,
        loading: _saving,
        onPressed: _save,
      ),
    ),
  );
}
