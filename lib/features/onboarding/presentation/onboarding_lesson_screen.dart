import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/screen_background.dart';
import '../../home/presentation/learn_content.dart';

/// A mandatory, quiz-gated multi-lesson curriculum shown at the end of
/// onboarding, one per journey. [next] only becomes reachable once every
/// lesson's quiz has been passed, in order — this is the app's "force
/// learning" requirement: you cannot reach your dashboard without
/// demonstrating you understood the basics of the journey you're starting.
class OnboardingLessonScreen extends StatefulWidget {
  const OnboardingLessonScreen({
    super.key,
    required this.lessons,
    required this.next,
  });

  final List<LearnItem> lessons;
  final WidgetBuilder next;

  @override
  State<OnboardingLessonScreen> createState() => _OnboardingLessonScreenState();
}

class _OnboardingLessonScreenState extends State<OnboardingLessonScreen> {
  static const _cooldownDuration = 5;

  int _index = 0;
  final Map<int, int> _selectedAnswers = {};
  bool _submitted = false;

  /// Per-question display order (values are the option's real index into
  /// `question.options`), reshuffled on every lesson change and every
  /// retry so memorizing "always tap the first option" doesn't work.
  final Map<int, List<int>> _optionOrder = {};

  final ScrollController _scrollController = ScrollController();
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  LearnItem get _item => widget.lessons[_index];
  bool get _isLastLesson => _index == widget.lessons.length - 1;

  @override
  void initState() {
    super.initState();
    _shuffleOptions();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _shuffleOptions() {
    final random = Random();
    _optionOrder.clear();
    for (var i = 0; i < _item.quiz.length; i++) {
      _optionOrder[i] = List.generate(_item.quiz[i].options.length, (k) => k)
        ..shuffle(random);
    }
  }

  int get _correctCount {
    var count = 0;
    for (var i = 0; i < _item.quiz.length; i++) {
      if (_selectedAnswers[i] == _item.quiz[i].correctIndex) count++;
    }
    return count;
  }

  void _submitQuiz() {
    setState(() => _submitted = true);
    if (_correctCount == _item.quiz.length) {
      LearnProgress.markCompleted(_item);
      return;
    }
    // Wrong answer: scroll back to the lesson content and require a short,
    // real pause before allowing another attempt — otherwise nothing stops
    // rapid-fire random guessing until the quiz passes by chance.
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = _cooldownDuration);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds -= 1);
      }
    });
  }

  void _retake() {
    _cooldownTimer?.cancel();
    setState(() {
      _selectedAnswers.clear();
      _submitted = false;
      _cooldownSeconds = 0;
      _shuffleOptions();
    });
  }

  void _goToLesson(int newIndex) {
    _cooldownTimer?.cancel();
    setState(() {
      _index = newIndex;
      _selectedAnswers.clear();
      _submitted = false;
      _cooldownSeconds = 0;
      _shuffleOptions();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: Stack(
      children: [
        const ScreenBackground(),
        SafeArea(
          child: ValueListenableBuilder<Set<String>>(
            valueListenable: LearnProgress.completedTitles,
            builder: (context, completed, _) {
              final passed = completed.contains(_item.title);
              return Column(
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        children: [
                          _header(context),
                          const SizedBox(height: 12),
                          _lessonProgress(),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _requiredBanner(passed),
                              const SizedBox(height: 18),
                              _heroCard(),
                              const SizedBox(height: 22),
                              ..._item.body.map(
                                (paragraph) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    paragraph,
                                    style: GoogleFonts.nunitoSans(
                                      fontSize: 15,
                                      height: 1.6,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              _quizCard(passed),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _bottomBar(context, passed),
                ],
              );
            },
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
            onPressed: () => _index > 0
                ? _goToLesson(_index - 1)
                : Navigator.of(context).pop(),
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
                'Quick orientation',
                style: GoogleFonts.nunitoSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Lesson ${_index + 1} of ${widget.lessons.length} before your dashboard.',
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

  Widget _lessonProgress() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: List.generate(widget.lessons.length, (i) {
        final done = LearnProgress.isCompleted(widget.lessons[i]);
        final current = i == _index;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: i == widget.lessons.length - 1 ? 0 : 6,
            ),
            height: 5,
            decoration: BoxDecoration(
              color: done
                  ? AppColors.secondary
                  : current
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.outlineVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    ),
  );

  Widget _requiredBanner(bool passed) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFEBDDFF),
          AppColors.lavender.withValues(alpha: 0.6),
        ],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: Icon(
            passed ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
            color: AppColors.primary,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            passed
                ? 'You\'re all set — tap Continue below to reach your dashboard.'
                : 'This short lesson is required. Read it, then pass the quiz to unlock your dashboard.',
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

  Widget _heroCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_item.color, _item.deep],
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: _item.deep.withValues(alpha: 0.3),
          blurRadius: 26,
          offset: const Offset(0, 14),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            shape: BoxShape.circle,
          ),
          child: Icon(_item.icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 16),
        Text(
          _item.category,
          style: GoogleFonts.nunitoSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _item.title,
          style: GoogleFonts.nunitoSans(
            fontSize: 24,
            height: 1.25,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _item.summary,
          style: GoogleFonts.nunitoSans(
            fontSize: 14,
            height: 1.4,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    ),
  );

  Widget _quizCard(bool passed) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: AppColors.secondary.withValues(alpha: 0.3),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.quiz_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Quick check',
                style: GoogleFonts.nunitoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Answer both questions correctly to unlock your dashboard.',
          style: GoogleFonts.nunitoSans(
            fontSize: 12,
            height: 1.4,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (passed) ...[
          _resultBanner(passed: true, label: 'Nice work — lesson complete.'),
        ] else ...[
          ...List.generate(
            _item.quiz.length,
            (index) => _questionBlock(_item.quiz[index], index),
          ),
          if (_submitted) ...[
            _resultBanner(
              passed: false,
              label: _cooldownSeconds > 0
                  ? 'You got $_correctCount/${_item.quiz.length} — re-read the lesson above before trying again.'
                  : 'You got $_correctCount/${_item.quiz.length} — ready to try again.',
            ),
            const SizedBox(height: 12),
          ],
          _quizButton(
            label: !_submitted
                ? 'Submit Answers'
                : _cooldownSeconds > 0
                ? 'Review above · retry in ${_cooldownSeconds}s'
                : 'Try Again',
            enabled: !_submitted
                ? _selectedAnswers.length == _item.quiz.length
                : _cooldownSeconds == 0,
            onTap: !_submitted ? _submitQuiz : _retake,
          ),
        ],
      ],
    ),
  );

  Widget _questionBlock(QuizQuestion question, int index) {
    final selected = _selectedAnswers[index];
    final order =
        _optionOrder[index] ?? List.generate(question.options.length, (k) => k);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}. ${question.question}',
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(question.options.length, (displayPos) {
            final optionIndex = order[displayPos];
            final isSelected = selected == optionIndex;
            final isCorrectOption = optionIndex == question.correctIndex;

            Color background = Colors.white.withValues(alpha: 0.6);
            Color border = AppColors.outlineVariant.withValues(alpha: 0.4);
            IconData leadingIcon = Icons.radio_button_off_rounded;
            Color leadingColor = AppColors.onSurfaceVariant;

            if (_submitted) {
              if (isCorrectOption) {
                background = AppColors.secondaryContainer.withValues(
                  alpha: 0.4,
                );
                border = AppColors.secondary;
                leadingIcon = Icons.check_circle_rounded;
                leadingColor = AppColors.secondary;
              } else if (isSelected) {
                background = AppColors.outlineVariant.withValues(alpha: 0.2);
                border = AppColors.primary.withValues(alpha: 0.5);
                leadingIcon = Icons.cancel_rounded;
                leadingColor = AppColors.primary;
              }
            } else if (isSelected) {
              background = AppColors.secondaryContainer.withValues(alpha: 0.35);
              border = AppColors.secondary;
              leadingIcon = Icons.radio_button_checked_rounded;
              leadingColor = AppColors.secondary;
            }

            return GestureDetector(
              onTap: _submitted
                  ? null
                  : () => setState(() => _selectedAnswers[index] = optionIndex),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: border,
                    width: isSelected || (_submitted && isCorrectOption)
                        ? 1.6
                        : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(leadingIcon, size: 18, color: leadingColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        question.options[optionIndex],
                        style: GoogleFonts.nunitoSans(
                          fontSize: 13,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _resultBanner({required bool passed, required String label}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: passed
              ? AppColors.secondaryContainer.withValues(alpha: 0.4)
              : AppColors.outlineVariant.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: passed
                ? AppColors.secondary
                : AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              passed ? Icons.celebration_rounded : Icons.refresh_rounded,
              color: passed ? AppColors.secondary : AppColors.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.nunitoSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: passed
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _quizButton({
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: enabled ? AppColors.buttonGradient : null,
        color: enabled ? null : AppColors.outlineVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(999),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
      ),
      child: Text(
        label,
        style: GoogleFonts.nunitoSans(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: enabled ? Colors.white : AppColors.onSurfaceVariant,
        ),
      ),
    ),
  );

  Widget _bottomBar(BuildContext context, bool passed) {
    final label = !passed
        ? 'Pass the quiz to continue'
        : _isLastLesson
        ? 'Continue to Dashboard'
        : 'Next Lesson';
    final onTap = !passed
        ? null
        : _isLastLesson
        ? () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: widget.next))
        : () => _goToLesson(_index + 1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: passed ? AppColors.buttonGradient : null,
              color: passed
                  ? null
                  : AppColors.outlineVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(999),
              boxShadow: passed
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: passed ? Colors.white : AppColors.onSurfaceVariant,
                  ),
                ),
                if (passed) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
