import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/screen_background.dart';
import 'learn_content.dart';
import 'lesson_detail_screen.dart';

class LearnLibraryScreen extends StatefulWidget {
  const LearnLibraryScreen({
    super.key,
    this.items = allLearnItems,
    this.title = 'Learn & grow',
    this.subtitle = 'Every lesson, in one place.',
  });

  /// The content pool to browse. Defaults to the family-planning lessons;
  /// pass [allPregnancyLearnItems] for the pregnancy learning library.
  final List<LearnItem> items;
  final String title;
  final String subtitle;

  @override
  State<LearnLibraryScreen> createState() => _LearnLibraryScreenState();
}

class _LearnLibraryScreenState extends State<LearnLibraryScreen> {
  String _selectedCategory = 'All';

  List<String> get _categories => [
    'All',
    ...{for (final item in widget.items) item.category},
  ];

  List<LearnItem> get _visibleItems => _selectedCategory == 'All'
      ? widget.items
      : widget.items.where((i) => i.category == _selectedCategory).toList();

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
                      child: ValueListenableBuilder<Set<String>>(
                        valueListenable: LearnProgress.completedTitles,
                        builder: (context, completedTitles, _) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _progressCard(completedTitles),
                            const SizedBox(height: 20),
                            _categoryFilter(),
                            const SizedBox(height: 16),
                            Text(
                              '${_visibleItems.length} lesson${_visibleItems.length == 1 ? '' : 's'}',
                              style: GoogleFonts.nunitoSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._visibleItems.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _lessonTile(
                                  context,
                                  item,
                                  completedTitles.contains(item.title),
                                ),
                              ),
                            ),
                          ],
                        ),
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
                widget.title,
                style: GoogleFonts.nunitoSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                widget.subtitle,
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

  Widget _progressCard(Set<String> completedTitles) {
    final total = widget.items.length;
    // Only count completions within this content pool — `completedTitles` is
    // a single global set shared across every lesson track.
    final done = widget.items
        .where((i) => completedTitles.contains(i.title))
        .length;
    final progress = total == 0 ? 0.0 : done / total;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your progress',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$done of $total lessons completed',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    color: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    color: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryFilter() => SizedBox(
    height: 40,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      itemCount: _categories.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final category = _categories[index];
        final selected = _selectedCategory == category;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              gradient: selected ? AppColors.buttonGradient : null,
              color: selected ? null : Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : AppColors.outlineVariant.withValues(alpha: 0.4),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              category,
              style: GoogleFonts.nunitoSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.primary,
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _lessonTile(BuildContext context, LearnItem item, bool completed) =>
      GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                LessonDetailScreen(item: item, allItems: widget.items),
          ),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: completed
                  ? AppColors.secondary.withValues(alpha: 0.5)
                  : AppColors.outlineVariant.withValues(alpha: 0.25),
              width: completed ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [item.color, item.deep],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(item.icon, color: Colors.white, size: 24),
                  ),
                  if (completed)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: item.deep.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: item.deep,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.category,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: item.deep,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.title,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: AppColors.onSurfaceVariant.withValues(
                            alpha: 0.8,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.meta,
                          style: GoogleFonts.nunitoSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        if (completed) ...[
                          const SizedBox(width: 8),
                          Text(
                            '· Completed',
                            style: GoogleFonts.nunitoSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ],
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
