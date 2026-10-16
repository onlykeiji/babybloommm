import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/user_profile_store.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/screen_background.dart';
import 'community_models.dart';

class PostComposerScreen extends StatefulWidget {
  const PostComposerScreen({super.key, this.existing});

  final CommunityPost? existing;

  @override
  State<PostComposerScreen> createState() => _PostComposerScreenState();
}

class _PostComposerScreenState extends State<PostComposerScreen> {
  final TextEditingController _textController = TextEditingController();

  String _postType = 'Status';
  String _topic = 'TTC';
  bool _anonymous = false;

  static const _maxChars = 500;

  static const _postTypes = [
    (
      label: 'Status',
      icon: Icons.chat_bubble_outline_rounded,
      description: 'Share an update or feeling.',
      hint: "What's on your mind?",
    ),
    (
      label: 'Question',
      icon: Icons.help_outline_rounded,
      description: 'Ask the community for advice.',
      hint: "What's your question?",
    ),
  ];

  static const _topics = [
    'TTC',
    'Pregnancy',
    'Baby Care',
    'Postpartum',
    'Mental Health',
  ];

  static const _topicColors = {
    'TTC': AppColors.primary,
    'Pregnancy': AppColors.secondary,
    'Baby Care': AppColors.lavenderLight,
    'Postpartum': AppColors.primaryContainer,
    'Mental Health': AppColors.lavender,
  };

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _textController.text = existing.text;
      _postType = existing.isQuestion ? 'Question' : 'Status';
      _topic = existing.topic;
      _anonymous = existing.name == 'Anonymous';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something before posting.')),
      );
      return;
    }
    final displayName = ProfileStore.current.value?.fullName ?? 'Cayen Toledo';
    final post = CommunityPost(
      id: widget.existing?.id,
      authorId: widget.existing?.authorId,
      name: _anonymous ? 'Anonymous' : displayName,
      initials: _anonymous ? '?' : _initialsOf(displayName),
      topic: _topic,
      text: text,
      likes: widget.existing?.likes ?? 0,
      comments: widget.existing?.comments ?? 0,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      isQuestion: _postType == 'Question',
    );
    Navigator.of(context).pop(post);
  }

  String _initialsOf(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
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
                          _identityCard(),
                          const SizedBox(height: 26),
                          _sectionTitle(
                            'Post type',
                            'Choose what kind of post this is.',
                          ),
                          const SizedBox(height: 12),
                          _postTypeSelector(),
                          const SizedBox(height: 26),
                          _sectionTitle('Topic', 'Help others find your post.'),
                          const SizedBox(height: 12),
                          _topicSelector(),
                          const SizedBox(height: 26),
                          _sectionTitle('Your post', _currentType.hint),
                          const SizedBox(height: 12),
                          _textCard(),
                          const SizedBox(height: 16),
                          const SizedBox(height: 6),
                          _guidelinesCard(),
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

  ({String label, IconData icon, String description, String hint})
  get _currentType => _postTypes.firstWhere((t) => t.label == _postType);

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
            tooltip: 'Cancel',
            icon: const Icon(Icons.close_rounded, color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create post',
                style: GoogleFonts.nunitoSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Share your thoughts with the community.',
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

  Widget _identityCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _anonymous
                ? AppColors.onSurfaceVariant.withValues(alpha: 0.5)
                : null,
            gradient: _anonymous ? null : AppColors.buttonGradient,
            shape: BoxShape.circle,
          ),
          child: _anonymous
              ? const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 20,
                )
              : Text(
                  _initialsOf(
                    ProfileStore.current.value?.fullName ?? 'Cayen Toledo',
                  ),
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
                _anonymous
                    ? 'Posting anonymously'
                    : (ProfileStore.current.value?.fullName ?? 'Cayen Toledo'),
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                _anonymous
                    ? 'Your name will be hidden.'
                    : 'Posting as yourself.',
                style: GoogleFonts.nunitoSans(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: _anonymous,
          onChanged: (value) => setState(() => _anonymous = value),
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.secondary,
          inactiveTrackColor: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ],
    ),
  );

  Widget _sectionTitle(String title, String detail) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: GoogleFonts.nunitoSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        detail,
        style: GoogleFonts.nunitoSans(
          fontSize: 13,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _postTypeSelector() => Row(
    children: _postTypes.map((type) {
      final selected = _postType == type.label;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _postType = type.label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              gradient: selected ? AppColors.buttonGradient : null,
              color: selected ? null : Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : AppColors.outlineVariant.withValues(alpha: 0.3),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  type.icon,
                  color: selected ? Colors.white : AppColors.primary,
                  size: 24,
                ),
                const SizedBox(height: 10),
                Text(
                  type.label,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  type.description,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 11,
                    height: 1.3,
                    color: selected
                        ? Colors.white.withValues(alpha: 0.85)
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList(),
  );

  Widget _topicSelector() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: _topics.map((topic) {
      final selected = _topic == topic;
      final color = _topicColors[topic] ?? AppColors.primary;
      return GestureDetector(
        onTap: () => setState(() => _topic = topic),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? color : Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : AppColors.outlineVariant.withValues(alpha: 0.4),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
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
    }).toList(),
  );

  Widget _textCard() => Container(
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
    child: TextField(
      controller: _textController,
      maxLines: 6,
      maxLength: _maxChars,
      textCapitalization: TextCapitalization.sentences,
      style: GoogleFonts.nunitoSans(
        fontSize: 14,
        height: 1.45,
        color: AppColors.onSurface,
      ),
      decoration: InputDecoration(
        hintText: _currentType.hint,
        hintStyle: GoogleFonts.nunitoSans(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(16),
        counterStyle: GoogleFonts.nunitoSans(
          fontSize: 11,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    ),
  );

  Widget _guidelinesCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFEBDDFF),
          AppColors.lavender.withValues(alpha: 0.6),
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AppColors.secondary.withValues(alpha: 0.15),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.favorite_outline,
            color: AppColors.primary,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Be kind — this is a safe space to share and support each other.',
            style: GoogleFonts.nunitoSans(
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _bottomBar() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: PrimaryButton(
        label: 'Post to Community',
        trailingIcon: Icons.send_rounded,
        onPressed: _submit,
      ),
    ),
  );
}
