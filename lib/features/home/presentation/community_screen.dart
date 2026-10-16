import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/user_profile_store.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/notifications_panel.dart';
import '../../../core/widgets/screen_background.dart';
import '../../../core/widgets/stat_chip.dart';
import 'app_navigation.dart';
import 'bloom_ai_fab.dart';
import 'community_models.dart';
import 'group_chat_screen.dart';
import 'post_composer_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _selectedTopic = 'All';
  String _selectedFilter = 'All Posts';
  final Set<String> _likedPostIds = {};
  final Set<String> _pendingLikePostIds = {};

  static const _topics = [
    'All',
    'TTC',
    'Pregnancy',
    'Baby Care',
    'Postpartum',
    'Mental Health',
  ];

  static const _postFilters = [
    ('All Posts', Icons.dynamic_feed_rounded),
    ('My Posts', Icons.person_rounded),
    ('Liked', Icons.favorite_rounded),
  ];

  static const _topicColors = {
    'TTC': AppColors.primary,
    'Pregnancy': AppColors.secondary,
    'Baby Care': AppColors.lavenderLight,
    'Postpartum': AppColors.primaryContainer,
    'Mental Health': AppColors.lavender,
  };

  static const _avatarColors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.lavenderLight,
    AppColors.primaryContainer,
    AppColors.lavender,
  ];

  @override
  void initState() {
    super.initState();
    _loadCommunity();
  }

  Future<void> _loadCommunity() async {
    try {
      await CommunityStore.fetchCommunity();
      final likedIds = await CommunityStore.fetchMyLikedPostIds();
      if (!mounted) return;
      setState(() {
        _likedPostIds
          ..clear()
          ..addAll(likedIds);
      });
    } catch (e) {
      _showError('Could not load Community: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
    );
  }

  List<CommunityPost> _visiblePosts(List<CommunityPost> posts) {
    var result = _selectedTopic == 'All'
        ? posts
        : posts.where((p) => p.topic == _selectedTopic).toList();
    if (_selectedFilter == 'My Posts') {
      final userId = CommunityStore.currentUserId;
      result = result
          .where((p) => p.authorId != null && p.authorId == userId)
          .toList();
    } else if (_selectedFilter == 'Liked') {
      result = result
          .where((p) => p.id != null && _likedPostIds.contains(p.id))
          .toList();
    }
    return result;
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
                  child: _stickyHeader(context),
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<bool>(
                  valueListenable: CommunityStore.isLoading,
                  builder: (context, loading, _) =>
                      ValueListenableBuilder<List<CommunityPost>>(
                        valueListenable: CommunityStore.posts,
                        builder: (context, allPosts, _) {
                          final posts = _visiblePosts(allPosts);
                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 720,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _statsRow(),
                                    const SizedBox(height: 24),
                                    _composerCard(context),
                                    const SizedBox(height: 26),
                                    _sectionTitle(
                                      'Support groups',
                                      'Find people who understand exactly what you are going through.',
                                    ),
                                    const SizedBox(height: 14),
                                    ValueListenableBuilder<
                                      List<CommunityGroup>
                                    >(
                                      valueListenable: CommunityStore.groups,
                                      builder: (context, groups, _) =>
                                          ValueListenableBuilder<Set<String>>(
                                            valueListenable:
                                                CommunityStore.joinedGroupIds,
                                            builder: (context, joinedIds, _) =>
                                                _groupsCarousel(
                                                  context,
                                                  groups,
                                                  joinedIds,
                                                ),
                                          ),
                                    ),
                                    const SizedBox(height: 26),
                                    _postFilterChips(),
                                    const SizedBox(height: 10),
                                    _topicFilter(),
                                    const SizedBox(height: 14),
                                    if (loading && allPosts.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 30,
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      )
                                    else
                                      ...posts.map(
                                        (post) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: _postCard(post),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ),
              AppBottomNav(
                current: AppTab.community,
                onSelect: (tab) => goToTab(context, tab),
              ),
            ],
          ),
        ),
        const Positioned(right: 20, bottom: 100, child: BloomAiFab()),
      ],
    ),
  );

  Widget _stickyHeader(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFEBDCFF),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Image.asset('lib/assets/images/logo.png', fit: BoxFit.contain),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Community',
                style: GoogleFonts.nunitoSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                "You're not alone in this journey.",
                style: GoogleFonts.nunitoSans(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => _openComposer(context),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 3),
                Text(
                  'Post',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
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
            onPressed: () => showNotificationsPanel(context),
            tooltip: 'Notifications',
            icon: const Badge(
              smallSize: 8,
              backgroundColor: AppColors.secondary,
              child: Icon(
                Icons.notifications_none_rounded,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _statsRow() => ValueListenableBuilder<CommunityMetrics?>(
    valueListenable: CommunityStore.metrics,
    builder: (context, metrics, _) => Row(
      children: [
        Expanded(
          child: StatChip(
            icon: Icons.groups_rounded,
            value: '${metrics?.memberCount ?? 0}',
            label: 'Members',
            color: AppColors.secondaryContainer,
            deep: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatChip(
            icon: Icons.forum_rounded,
            value: '${metrics?.postsToday ?? 0}',
            label: 'Posts today',
            color: AppColors.lavender,
            deep: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatChip(
            icon: Icons.diversity_3_rounded,
            value: '${metrics?.myGroupCount ?? 0}',
            label: 'My groups',
            color: AppColors.lavenderLight,
            deep: AppColors.primaryContainer,
          ),
        ),
      ],
    ),
  );

  Future<void> _openComposer(BuildContext context) async {
    final draft = await Navigator.of(context).push<CommunityPost>(
      MaterialPageRoute(builder: (_) => const PostComposerScreen()),
    );
    if (draft == null || !context.mounted) return;
    try {
      await CommunityStore.add(draft);
      if (!context.mounted) return;
      setState(() => _selectedTopic = 'All');
    } catch (e) {
      _showError('Could not post: $e');
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your post has been shared with the community.'),
      ),
    );
  }

  Widget _composerCard(BuildContext context) => GestureDetector(
    onTap: () => _openComposer(context),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
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
      child: Row(
        children: [
          ValueListenableBuilder<UserProfile?>(
            valueListenable: ProfileStore.current,
            builder: (context, profile, _) =>
                _composerAvatar(profile?.fullName),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Share what is on your mind…',
              style: GoogleFonts.nunitoSans(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
        ],
      ),
    ),
  );

  Widget _composerAvatar(String? fullName) {
    final parts = (fullName ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    final initials = parts.isEmpty
        ? '?'
        : parts.length == 1
        ? parts.first.substring(0, 1).toUpperCase()
        : (parts.first.substring(0, 1) + parts.last.substring(0, 1))
              .toUpperCase();

    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: AppColors.buttonGradient,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: GoogleFonts.nunitoSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String detail) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: GoogleFonts.nunitoSans(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        detail,
        style: GoogleFonts.nunitoSans(
          fontSize: 14,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _groupsCarousel(
    BuildContext context,
    List<CommunityGroup> groups,
    Set<String> joinedIds,
  ) {
    return SizedBox(
      height: 196,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: groups.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final group = groups[index];
          final joined = joinedIds.contains(group.id);
          return GestureDetector(
            onTap: () async {
              try {
                if (!joined) await CommunityStore.joinGroup(group.id);
                if (!context.mounted) return;
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GroupChatScreen(group: group),
                  ),
                );
              } catch (e) {
                _showError('Could not join group: $e');
              }
            },
            child: _groupCard(group, joined),
          );
        },
      ),
    );
  }

  Widget _groupCard(CommunityGroup group, bool joined) {
    final color = _topicColors[group.topic] ?? AppColors.primary;
    return Container(
      width: 230,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.9), AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.28),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _groupIcon(group.topic),
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.groups_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${group.memberCount}',
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
          const SizedBox(height: 12),
          Text(
            group.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunitoSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              group.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunitoSans(
                fontSize: 12,
                height: 1.35,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                joined
                    ? Icons.chat_bubble_rounded
                    : Icons.add_circle_outline_rounded,
                color: Colors.white,
                size: 13,
              ),
              const SizedBox(width: 4),
              Text(
                joined ? 'Open conversation' : 'Tap to join',
                style: GoogleFonts.nunitoSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _groupIcon(String topic) {
    if (topic == 'TTC') return Icons.favorite_outline;
    if (topic == 'Pregnancy') return Icons.pregnant_woman_outlined;
    if (topic == 'Baby Care') return Icons.child_friendly_outlined;
    return Icons.groups_outlined;
  }

  Widget _postFilterChips() => SizedBox(
    height: 38,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      itemCount: _postFilters.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final (label, icon) = _postFilters[index];
        final selected = _selectedFilter == label;
        return GestureDetector(
          onTap: () => setState(() => _selectedFilter = label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.14)
                  : Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.6)
                    : AppColors.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: selected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  Widget _topicFilter() => SizedBox(
    height: 40,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      itemCount: _topics.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final topic = _topics[index];
        final selected = _selectedTopic == topic;
        return GestureDetector(
          onTap: () => setState(() => _selectedTopic = topic),
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
              topic,
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

  Widget _postCard(CommunityPost post) {
    final liked = post.id != null && _likedPostIds.contains(post.id);
    final avatarColor =
        _avatarColors[post.name.hashCode.abs() % _avatarColors.length];
    final topicColor = _topicColors[post.topic] ?? AppColors.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: post.name == 'Anonymous'
                      ? AppColors.onSurfaceVariant.withValues(alpha: 0.5)
                      : avatarColor,
                  shape: BoxShape.circle,
                ),
                child: post.name == 'Anonymous'
                    ? const Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      )
                    : Text(
                        post.initials,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.name,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          post.timeAgo,
                          style: GoogleFonts.nunitoSans(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: topicColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            post.topic,
                            style: GoogleFonts.nunitoSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: topicColor,
                            ),
                          ),
                        ),
                        if (post.isQuestion) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.help_outline_rounded,
                                  size: 11,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Question',
                                  style: GoogleFonts.nunitoSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.text,
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
              height: 1.45,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              GestureDetector(
                onTap: post.id == null || _pendingLikePostIds.contains(post.id)
                    ? null
                    : () async {
                        final nowLiked = !liked;
                        setState(() {
                          _pendingLikePostIds.add(post.id!);
                          nowLiked
                              ? _likedPostIds.add(post.id!)
                              : _likedPostIds.remove(post.id);
                        });
                        try {
                          await CommunityStore.setLiked(post, nowLiked);
                        } catch (e) {
                          if (!mounted) return;
                          setState(() {
                            nowLiked
                                ? _likedPostIds.remove(post.id)
                                : _likedPostIds.add(post.id!);
                          });
                          _showError('Could not update like: $e');
                        } finally {
                          if (mounted) {
                            setState(() => _pendingLikePostIds.remove(post.id));
                          }
                        }
                      },
                child: Row(
                  children: [
                    Icon(
                      liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 18,
                      color: liked
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${post.likes}',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: post.id == null ? null : () => _showComments(post),
                child: Row(
                  children: [
                    Icon(
                      Icons.mode_comment_outlined,
                      size: 17,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${post.comments}',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (post.id != null &&
                  post.authorId != null &&
                  post.authorId == CommunityStore.currentUserId) ...[
                IconButton(
                  onPressed: () => _editPost(post),
                  tooltip: 'Edit post',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 17,
                    color: AppColors.primary,
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final confirmed = await showConfirmDialog(
                      context,
                      title: 'Delete post?',
                      message:
                          'This removes your post for everyone. This cannot be undone.',
                      confirmLabel: 'Delete',
                      destructive: true,
                    );
                    if (!confirmed || !context.mounted) return;
                    try {
                      await CommunityStore.remove(post.id!);
                    } catch (e) {
                      _showError('Could not remove post: $e');
                    }
                  },
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 17,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ] else
                Icon(
                  Icons.ios_share_rounded,
                  size: 17,
                  color: AppColors.onSurfaceVariant,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showComments(CommunityPost post) async {
    final controller = TextEditingController();
    var comments = await CommunityStore.fetchComments(post.id!);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SizedBox(
            height: 420,
            child: Column(
              children: [
                Text(
                  'Comments',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: comments.isEmpty
                      ? Center(
                          child: Text(
                            'Be the first to comment.',
                            style: GoogleFonts.nunitoSans(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: comments.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (_, index) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              comments[index].authorName,
                              style: GoogleFonts.nunitoSans(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              comments[index].body,
                              style: GoogleFonts.nunitoSans(),
                            ),
                          ),
                        ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        maxLength: 500,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: AppColors.primary,
                      ),
                      onPressed: () async {
                        final body = controller.text.trim();
                        if (body.isEmpty || body.length > 500) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Comment must contain between 1 and 500 characters.',
                              ),
                            ),
                          );
                          return;
                        }
                        try {
                          final name =
                              ProfileStore.current.value?.fullName ??
                              'Community member';
                          await CommunityStore.addComment(
                            postId: post.id!,
                            authorName: name,
                            body: body,
                          );
                          comments = await CommunityStore.fetchComments(
                            post.id!,
                          );
                          controller.clear();
                          setSheetState(() {});
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Could not add comment: $e'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    controller.dispose();
  }

  Future<void> _editPost(CommunityPost post) async {
    final edited = await Navigator.of(context).push<CommunityPost>(
      MaterialPageRoute(builder: (_) => PostComposerScreen(existing: post)),
    );
    if (edited == null || !mounted) return;
    try {
      await CommunityStore.update(edited);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post updated.')));
      }
    } catch (e) {
      _showError('Could not update post: $e');
    }
  }
}
