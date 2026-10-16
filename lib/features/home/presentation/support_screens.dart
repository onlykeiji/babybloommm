import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/screen_background.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const _faqs = [
    (
      'How is my dashboard selected?',
      'Your onboarding choice sets the dashboard for your account. Personal Details no longer changes that journey accidentally.',
    ),
    (
      'Where is my information saved?',
      'Your profiles, logs, settings, and health records are saved in Supabase and protected by account-based row-level security.',
    ),
    (
      'How do I edit a record?',
      'Open the relevant history list and tap the edit icon. Use the delete icon when you want to remove a record.',
    ),
    (
      'Why is an insight empty?',
      'Insights are calculated from your saved inputs. Add care, growth, symptom, mood, or cycle logs to build an overview.',
    ),
    (
      'Is BabyBloom medical advice?',
      'No. BabyBloom helps organize self-reported information. Contact a qualified healthcare professional about medical concerns.',
    ),
  ];

  @override
  Widget build(BuildContext context) => _SupportScaffold(
    title: 'Help center',
    subtitle: 'Quick answers about BabyBloom.',
    child: Column(
      children: _faqs
          .map(
            (faq) => Card(
              color: Colors.white.withValues(alpha: .78),
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ExpansionTile(
                iconColor: AppColors.primary,
                collapsedIconColor: AppColors.primary,
                title: Text(
                  faq.$1,
                  style: GoogleFonts.nunitoSans(
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                children: [
                  Text(
                    faq.$2,
                    style: GoogleFonts.nunitoSans(
                      height: 1.45,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    ),
  );
}

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  String _category = 'question';
  bool _sending = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final subject = _subject.text.trim();
    final message = _message.text.trim();
    if (subject.length < 3 || message.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please add a subject and at least 10 characters of detail.',
          ),
        ),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await SupabaseConfig.client.from('support_requests').insert({
        'user_id': SupabaseConfig.client.auth.currentUser!.id,
        'category': _category,
        'subject': subject,
        'message': message,
      });
      if (!mounted) return;
      _subject.clear();
      _message.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your message was sent. Thank you!')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not send your message: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => _SupportScaffold(
    title: 'Contact us',
    subtitle: 'Send a question or report a problem.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: _inputDecoration('Category'),
          items: const [
            DropdownMenuItem(
              value: 'question',
              child: Text('General question'),
            ),
            DropdownMenuItem(
              value: 'technical',
              child: Text('Technical problem'),
            ),
            DropdownMenuItem(value: 'account', child: Text('Account help')),
            DropdownMenuItem(value: 'feedback', child: Text('Feedback')),
          ],
          onChanged: (value) => setState(() => _category = value!),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _subject,
          maxLength: 120,
          decoration: _inputDecoration('Subject'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _message,
          minLines: 5,
          maxLines: 8,
          maxLength: 4000,
          decoration: _inputDecoration('How can we help?'),
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          label: 'Send message',
          trailingIcon: Icons.send_rounded,
          loading: _sending,
          onPressed: _send,
        ),
      ],
    ),
  );
}

class RateBabyBloomScreen extends StatefulWidget {
  const RateBabyBloomScreen({super.key});

  @override
  State<RateBabyBloomScreen> createState() => _RateBabyBloomScreenState();
}

class _RateBabyBloomScreenState extends State<RateBabyBloomScreen> {
  final _feedback = TextEditingController();
  int _rating = 0;
  bool _saving = false;

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a star rating first.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final userId = SupabaseConfig.client.auth.currentUser!.id;
      await SupabaseConfig.client.from('app_ratings').upsert({
        'user_id': userId,
        'rating': _rating,
        'feedback': _feedback.text.trim(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for rating BabyBloom!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save your rating: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => _SupportScaffold(
    title: 'Rate BabyBloom',
    subtitle: 'Tell us how your experience has been.',
    child: Column(
      children: [
        Text(
          'How would you rate BabyBloom?',
          style: GoogleFonts.nunitoSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (index) => IconButton(
              onPressed: () => setState(() => _rating = index + 1),
              iconSize: 42,
              icon: Icon(
                index < _rating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: AppColors.secondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _feedback,
          minLines: 4,
          maxLines: 6,
          maxLength: 1000,
          decoration: _inputDecoration('Optional feedback'),
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          label: 'Submit rating',
          trailingIcon: Icons.favorite_rounded,
          loading: _saving,
          onPressed: _save,
        ),
      ],
    ),
  );
}

InputDecoration _inputDecoration(String label) => InputDecoration(
  labelText: label,
  filled: true,
  fillColor: Colors.white.withValues(alpha: .76),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide.none,
  ),
);

class _SupportScaffold extends StatelessWidget {
  const _SupportScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: Stack(
      children: [
        const ScreenBackground(),
        SafeArea(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .84),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.nunitoSans(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            subtitle,
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
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: child,
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
}
