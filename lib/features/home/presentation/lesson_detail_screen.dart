import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/highlight_card.dart';
import '../../../core/widgets/screen_background.dart';
import 'learn_content.dart';

class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({
    super.key,
    required this.item,
    this.allItems = allLearnItems,
  });

  final LearnItem item;

  /// The content pool this lesson belongs to — used to find related lessons.
  /// Defaults to the family-planning lessons; pass [allPregnancyLearnItems]
  /// when opening a pregnancy lesson so "More in [category]" stays relevant.
  final List<LearnItem> allItems;

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  bool _saved = false;

  // Quiz interaction state. `_showForm` lets someone retake an
  // already-passed quiz without losing the "completed" badge unless they
  // resubmit.
  final Map<int, int> _selectedAnswers = {};
  bool _submitted = false;
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    _showForm = !LearnProgress.isCompleted(widget.item);
  }

  List<LearnItem> get _related => widget.allItems
      .where(
        (i) =>
            i.category == widget.item.category && i.title != widget.item.title,
      )
      .toList();

  int get _correctCount {
    final item = widget.item;
    var count = 0;
    for (var i = 0; i < item.quiz.length; i++) {
      if (_selectedAnswers[i] == item.quiz[i].correctIndex) count++;
    }
    return count;
  }

  Future<void> _submitQuiz() async {
    setState(() => _submitted = true);
    if (_correctCount == widget.item.quiz.length) {
      try {
        await LearnProgress.markCompleted(widget.item);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save lesson progress. Please try again.'),
          ),
        );
      }
    }
  }

  void _retake() {
    setState(() {
      _selectedAnswers.clear();
      _submitted = false;
      _showForm = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const ScreenBackground(),
          SafeArea(
            child: ValueListenableBuilder<Set<String>>(
              valueListenable: LearnProgress.completedTitles,
              builder: (context, completedTitles, _) {
                final isCompleted = completedTitles.contains(item.title);
                return Column(
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: _header(context, isCompleted),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 720),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _heroCard(item),
                                const SizedBox(height: 22),
                                ...item.body.map(
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
                                _takeawaysCard(item),
                                const SizedBox(height: 22),
                                _quizCard(item, isCompleted),
                                if (_related.isNotEmpty) ...[
                                  const SizedBox(height: 30),
                                  Text(
                                    'More in ${item.category}',
                                    style: GoogleFonts.nunitoSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 190,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      clipBehavior: Clip.none,
                                      itemCount: _related.length,
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(width: 12),
                                      itemBuilder: (context, index) {
                                        final related = _related[index];
                                        return GestureDetector(
                                          onTap: () => Navigator.of(context)
                                              .pushReplacement(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      LessonDetailScreen(
                                                        item: related,
                                                        allItems:
                                                            widget.allItems,
                                                      ),
                                                ),
                                              ),
                                          child: HighlightCard(
                                            icon: related.icon,
                                            category: related.category,
                                            title: related.title,
                                            meta: related.meta,
                                            color: related.color,
                                            deep: related.deep,
                                            completed: completedTitles.contains(
                                              related.title,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, bool isCompleted) => Container(
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
        const Spacer(),
        if (isCompleted)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'Completed',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
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
            onPressed: () {
              setState(() => _saved = !_saved);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _saved
                        ? 'Saved to your library.'
                        : 'Removed from your library.',
                  ),
                ),
              );
            },
            tooltip: _saved ? 'Saved' : 'Save for later',
            icon: Icon(
              _saved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _heroCard(LearnItem item) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [item.color, item.deep],
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: item.deep.withValues(alpha: 0.3),
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
          child: Icon(item.icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 16),
        Text(
          item.category,
          style: GoogleFonts.nunitoSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          item.title,
          style: GoogleFonts.nunitoSans(
            fontSize: 24,
            height: 1.25,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          item.summary,
          style: GoogleFonts.nunitoSans(
            fontSize: 14,
            height: 1.4,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 5),
            Text(
              item.meta,
              style: GoogleFonts.nunitoSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _takeawaysCard(LearnItem item) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(22),
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
        Row(
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.secondary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Key takeaways',
              style: GoogleFonts.nunitoSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...item.takeaways.map(
          (point) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 7, right: 10),
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    point,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _quizCard(LearnItem item, bool isCompleted) => Container(
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
          'Answer both questions correctly to mark this lesson complete.',
          style: GoogleFonts.nunitoSans(
            fontSize: 12,
            height: 1.4,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (isCompleted && !_showForm) ...[
          _resultBanner(passed: true, label: "You've completed this lesson."),
          const SizedBox(height: 12),
          _quizButton(label: 'Retake Quiz', enabled: true, onTap: _retake),
        ] else ...[
          ...List.generate(
            item.quiz.length,
            (index) => _questionBlock(item.quiz[index], index),
          ),
          if (_submitted) ...[
            _resultBanner(
              passed: _correctCount == item.quiz.length,
              label: _correctCount == item.quiz.length
                  ? 'You got $_correctCount/${item.quiz.length} — lesson completed!'
                  : 'You got $_correctCount/${item.quiz.length} — review and try again.',
            ),
            const SizedBox(height: 12),
          ],
          _quizButton(
            label: _submitted ? 'Try Again' : 'Submit Answers',
            enabled: _submitted || _selectedAnswers.length == item.quiz.length,
            onTap: _submitted ? _retake : _submitQuiz,
          ),
        ],
      ],
    ),
  );

  Widget _questionBlock(QuizQuestion question, int index) {
    final selected = _selectedAnswers[index];
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
          ...List.generate(question.options.length, (optionIndex) {
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
}
