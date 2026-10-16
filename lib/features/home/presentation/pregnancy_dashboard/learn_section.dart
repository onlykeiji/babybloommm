import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/highlight_card.dart';
import '../../../../core/widgets/section_title.dart';
import '../learn_content.dart';
import '../learn_library_screen.dart';
import '../lesson_detail_screen.dart';
import '../pregnancy_learn_content.dart';

/// Horizontally scrollable "Learn & grow" lesson carousel, scoped to the
/// current pregnancy week.
class PregnancyLearnSection extends StatefulWidget {
  const PregnancyLearnSection({super.key, required this.currentWeek});

  final int currentWeek;

  @override
  State<PregnancyLearnSection> createState() => _PregnancyLearnSectionState();
}

class _PregnancyLearnSectionState extends State<PregnancyLearnSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessons = allPregnancyLearnItems.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SectionTitle(
                title: 'Learn & grow',
                detail:
                    'Bite-sized lessons picked for week ${widget.currentWeek}.',
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LearnLibraryScreen(
                    items: allPregnancyLearnItems,
                    title: 'Learn & grow',
                    subtitle: 'Every pregnancy lesson, in one place.',
                  ),
                ),
              ),
              child: Text(
                'SEE ALL',
                style: GoogleFonts.nunitoSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 190,
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            trackVisibility: true,
            radius: const Radius.circular(999),
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.only(bottom: 14),
              itemCount: lessons.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) =>
                  _learnCard(context, lessons[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _learnCard(BuildContext context, LearnItem item) => GestureDetector(
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            LessonDetailScreen(item: item, allItems: allPregnancyLearnItems),
      ),
    ),
    child: ValueListenableBuilder<Set<String>>(
      valueListenable: LearnProgress.completedTitles,
      builder: (context, completed, _) => HighlightCard(
        icon: item.icon,
        category: item.category,
        title: item.title,
        meta: item.meta,
        color: item.color,
        deep: item.deep,
        completed: completed.contains(item.title),
      ),
    ),
  );
}
