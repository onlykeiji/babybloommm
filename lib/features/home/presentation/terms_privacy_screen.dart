import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/screen_background.dart';

const String _lastUpdated = 'August 17, 2026';

const List<({String title, String body})> _termsSections = [
  (
    title: '1. Acceptance of these Terms',
    body:
        'By creating a BabyBloom account or using the app, you agree to these '
        'Terms of Service and the Privacy Policy below. If you do not agree, '
        "please don't use BabyBloom.",
  ),
  (
    title: '2. Who can use BabyBloom',
    body:
        'You must be at least 16 years old to create an account. If you are '
        'signing up on behalf of someone else, you confirm you have the right '
        'to do so.',
  ),
  (
    title: '3. Your account',
    body:
        "You're responsible for the accuracy of the information you enter and "
        'for keeping your password secure. Let us know right away if you '
        'believe your account has been accessed without your permission.',
  ),
  (
    title: '4. Not medical advice',
    body:
        'BabyBloom helps you track cycles, symptoms, pregnancy, and baby care, '
        'and shows predictions and insights based on what you log. These are '
        'estimates, not a diagnosis or medical guidance, and Bloom AI (our '
        'in-app assistant) is not a substitute for a doctor, midwife, or other '
        'healthcare provider. Always consult a qualified professional for '
        'anything that concerns your health or your baby\'s health.',
  ),
  (
    title: '5. Bloom AI',
    body:
        'Bloom AI is powered by a third-party AI model (Google Gemini). Its '
        'replies are generated automatically and may occasionally be '
        'incomplete or inaccurate. Do not rely on Bloom AI for emergencies — '
        'contact emergency services or your healthcare provider instead.',
  ),
  (
    title: '6. Community posts',
    body:
        'The Community section lets you share posts and join topic groups '
        'with other users. Be respectful, do not share medical advice as '
        'fact, and do not post anything abusive, misleading, or that reveals '
        "someone else's private information. You can delete your own posts "
        'at any time, and we may remove content that violates these Terms.',
  ),
  (
    title: '7. Acceptable use',
    body:
        "Don't misuse BabyBloom — for example, by attempting to access "
        "another user's account, scraping data, reverse-engineering the app, "
        'or interfering with its normal operation.',
  ),
  (
    title: '8. Ending your account',
    body:
        'You can delete your account at any time from Profile > Privacy & '
        'data. We may suspend or terminate accounts that violate these Terms.',
  ),
  (
    title: '9. Changes to these Terms',
    body:
        'We may update these Terms as BabyBloom changes. If we make material '
        "changes, we'll let you know in the app before they take effect.",
  ),
];

const List<({String title, String body})> _privacySections = [
  (
    title: '1. What we collect',
    body:
        '• Account info: name, email, and password (handled securely by our '
        'backend provider, Supabase).\n'
        '• Health data you log: period, symptoms, mood, notes, pregnancy '
        'details, and baby profiles/growth entries.\n'
        '• Community activity: posts, comments, and group memberships.\n'
        '• App settings: your notification and privacy preferences.',
  ),
  (
    title: '2. How we use your data',
    body:
        'We use your data to run the app you asked for: computing your cycle '
        'and fertility predictions, showing your personalized insights, '
        'powering Bloom AI conversations, and displaying the community feed. '
        'We do not sell your personal data.',
  ),
  (
    title: '3. Third-party services',
    body:
        'BabyBloom is built on Supabase, which stores your account and '
        'health data behind row-level security so only you can read your own '
        'records. When you message Bloom AI, that message is sent to '
        "Google's Gemini API to generate a reply — please avoid including "
        "information you wouldn't want processed by that service.",
  ),
  (
    title: '4. Your choices',
    body:
        'From Profile > Privacy & data you can: download a copy of '
        'everything you have logged, post to the community anonymously by '
        'default, opt in or out of sharing anonymized research data, and '
        'permanently delete your account and data.',
  ),
  (
    title: '5. Data retention',
    body:
        'We keep your data for as long as your account is active. If you '
        'delete your account, your personal records are permanently removed '
        'from our systems, aside from what we must retain to comply with '
        'the law.',
  ),
  (
    title: "6. Children's privacy",
    body:
        'BabyBloom is not directed at children under 16, and we do not '
        'knowingly collect data from them.',
  ),
  (
    title: '7. Changes to this policy',
    body:
        "If we make material changes to how we handle your data, we'll "
        'notify you in the app before they take effect.',
  ),
  (
    title: '8. Contact us',
    body:
        'Questions about these Terms or your data? Reach us from Profile > '
        'Contact us.',
  ),
];

class TermsPrivacyScreen extends StatelessWidget {
  const TermsPrivacyScreen({super.key});

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
                          Text(
                            'Last updated $_lastUpdated',
                            style: GoogleFonts.nunitoSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _sectionHeader('Terms of Service'),
                          const SizedBox(height: 12),
                          _card(_termsSections),
                          const SizedBox(height: 28),
                          _sectionHeader('Privacy Policy'),
                          const SizedBox(height: 12),
                          _card(_privacySections),
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
                'Terms & Privacy',
                style: GoogleFonts.nunitoSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'How BabyBloom works, and how we handle your data.',
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

  Widget _sectionHeader(String title) => Text(
    title,
    style: GoogleFonts.nunitoSans(
      fontSize: 21,
      fontWeight: FontWeight.w800,
      color: AppColors.primary,
    ),
  );

  Widget _card(List<({String title, String body})> sections) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in sections) ...[
          Text(
            section.title,
            style: GoogleFonts.nunitoSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            section.body,
            style: GoogleFonts.nunitoSans(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (section != sections.last) const SizedBox(height: 18),
        ],
      ],
    ),
  );
}
