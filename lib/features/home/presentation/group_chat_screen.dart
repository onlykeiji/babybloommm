import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/user_profile_store.dart';
import '../../../core/widgets/screen_background.dart';
import 'community_models.dart';

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({super.key, required this.group});

  final CommunityGroup group;

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _message = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;

  static const _topicColors = {
    'TTC': AppColors.primary,
    'Pregnancy': AppColors.secondary,
    'Baby Care': AppColors.lavenderLight,
    'Postpartum': AppColors.primaryContainer,
    'Mental Health': AppColors.lavender,
  };

  String? get _userId => SupabaseConfig.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final rows = await SupabaseConfig.client
          .from('group_messages')
          .select('user_id, body, author_name, created_at')
          .eq('group_id', widget.group.id)
          .order('created_at');
      if (mounted) {
        setState(() => _messages = rows.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not load messages: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final body = _message.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) throw StateError('Sign in is required.');
      final name = ProfileStore.current.value?.fullName ?? 'Community member';
      await SupabaseConfig.client.from('group_messages').insert({
        'group_id': widget.group.id,
        'user_id': user.id,
        'author_name': name,
        'body': body,
      });
      _message.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not send message: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  IconData _groupIcon(String topic) {
    if (topic == 'TTC') return Icons.favorite_outline;
    if (topic == 'Pregnancy') return Icons.pregnant_woman_outlined;
    if (topic == 'Baby Care') return Icons.child_friendly_outlined;
    return Icons.groups_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final color = _topicColors[widget.group.topic] ?? AppColors.primary;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const ScreenBackground(),
          SafeArea(
            child: Column(
              children: [
                _header(context, color),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : _messages.isEmpty
                      ? Center(
                          child: Text(
                            'Be the first to start the conversation.',
                            style: GoogleFonts.nunitoSans(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) =>
                              _messageBubble(_messages[index], color),
                        ),
                ),
                _composer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, Color color) => Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withValues(alpha: 0.9), AppColors.secondary],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: AppColors.secondary.withValues(alpha: 0.3),
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
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _groupIcon(widget.group.topic),
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.group.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunitoSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
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
                    '${widget.group.memberCount}',
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
        const SizedBox(height: 10),
        Text(
          widget.group.description,
          style: GoogleFonts.nunitoSans(
            fontSize: 13,
            height: 1.4,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    ),
  );

  Widget _messageBubble(Map<String, dynamic> message, Color color) {
    final mine = message['user_id'] != null && message['user_id'] == _userId;
    final author = message['author_name'] as String;
    final body = message['body'] as String;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: mine
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withValues(alpha: 0.9), AppColors.secondary],
                )
              : null,
          color: mine ? null : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
          border: mine
              ? null
              : Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.25),
                ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!mine)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  author,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            Text(
              body,
              style: GoogleFonts.nunitoSans(
                fontSize: 14,
                height: 1.4,
                color: mine ? Colors.white : AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _composer() => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: TextField(
                controller: _message,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  color: AppColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Write a message...',
                  hintStyle: GoogleFonts.nunitoSans(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.buttonGradient,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}
