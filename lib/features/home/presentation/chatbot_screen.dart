import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_session.dart';
import '../../../core/bloom_ai_context.dart';
import '../../../core/gemini_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/screen_background.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatMessage {
  const _ChatMessage(this.text, this.fromBot, {this.isError = false});

  final String text;
  final bool fromBot;
  final bool isError;
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final AppMode _mode = AppSession.mode;

  late final List<_ChatMessage> _messages = [
    _ChatMessage(_greetingFor(_mode), true),
  ];

  bool _botTyping = false;

  /// Set once the GET /models call confirms the API key + model are live.
  String? _modelLabel;
  bool _modelCheckFailed = false;

  /// The signed-in user's own data (profile, cycle logs, pregnancy week,
  /// baby profile) pulled from Supabase — sent with every message so Bloom
  /// AI can personalize replies instead of answering generically. Best
  /// effort: chat still works if this fails to load.
  String? _userContext;

  static String _greetingFor(AppMode mode) => switch (mode) {
    AppMode.familyPlanning =>
      "Hi, I'm Bloom AI 🌸 I'm here to help with your cycle tracking, "
          "fertility, and family planning journey. What's on your mind?",
    AppMode.pregnancy =>
      "Hi, I'm Bloom AI 🌸 I'm here to support you through your pregnancy "
          "journey. What's on your mind?",
    AppMode.babyCare =>
      "Hi, I'm Bloom AI 🌸 I'm here to help with your baby's care and "
          "development. What's on your mind?",
  };

  static List<String> _quickRepliesFor(AppMode mode) => switch (mode) {
    AppMode.familyPlanning => const [
      'When is my next fertile window?',
      'How can I track my ovulation?',
      'What can affect my cycle length?',
      "I'd like to talk to someone.",
    ],
    AppMode.pregnancy => const [
      'How can I ease nausea?',
      'What foods should I avoid?',
      'How is my baby developing this week?',
      "I'd like to talk to someone.",
    ],
    AppMode.babyCare => const [
      'Any tips for better sleep?',
      'How much should my baby be feeding?',
      'What milestones should I expect?',
      "I'd like to talk to someone.",
    ],
  };

  List<String> get _quickReplies => _quickRepliesFor(_mode);

  @override
  void initState() {
    super.initState();
    _loadModelInfo();
    _loadUserContext();
  }

  Future<void> _loadModelInfo() async {
    try {
      final info = await GeminiService.fetchActiveModel();
      if (mounted) setState(() => _modelLabel = info.displayName);
    } catch (_) {
      if (mounted) setState(() => _modelCheckFailed = true);
    }
  }

  Future<void> _loadUserContext() async {
    try {
      final context = await BloomAiContext.build();
      if (mounted) _userContext = context;
    } catch (_) {
      // Best-effort personalization — chat still works without it.
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _botTyping) return;
    setState(() {
      _messages.add(_ChatMessage(trimmed, false));
      _botTyping = true;
    });
    _inputController.clear();
    _scrollToBottom();

    try {
      final history = _messages
          .where((m) => !m.isError)
          .map(
            (m) => GeminiTurn(role: m.fromBot ? 'model' : 'user', text: m.text),
          )
          .toList();
      final reply = await GeminiService.sendMessage(
        history,
        userContext: _userContext,
      );
      if (!mounted) return;
      setState(() {
        _botTyping = false;
        _messages.add(_ChatMessage(reply, true));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _botTyping = false;
        _messages.add(
          _ChatMessage(
            e is GeminiException
                ? e.message
                : 'Something went wrong reaching Bloom AI. Please try again.',
            true,
            isError: true,
          ),
        );
      });
    }
    _scrollToBottom();
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
                  child: _header(),
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      children: [
                        ..._messages.map(_bubble),
                        if (_botTyping) _typingBubble(),
                        if (_messages.length == 1) ...[
                          const SizedBox(height: 4),
                          _quickReplyChips(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              _inputBar(),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _header() => Container(
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
        const SizedBox(width: 8),
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: AppColors.buttonGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bloom AI',
                style: GoogleFonts.nunitoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                _modelLabel != null
                    ? 'Powered by $_modelLabel'
                    : _modelCheckFailed
                    ? 'Connection issue — check your API key'
                    : 'Connecting…',
                style: GoogleFonts.nunitoSans(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
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
            onPressed: () => setState(() {
              _messages
                ..clear()
                ..add(_ChatMessage(_greetingFor(_mode), true));
            }),
            tooltip: 'New chat',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          ),
        ),
      ],
    ),
  );

  Widget _bubble(_ChatMessage message) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: message.fromBot
          ? MainAxisAlignment.start
          : MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (message.fromBot) ...[
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: message.isError ? null : AppColors.buttonGradient,
              color: message.isError ? Colors.red.shade300 : null,
              shape: BoxShape.circle,
            ),
            child: Icon(
              message.isError
                  ? Icons.error_outline_rounded
                  : Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: message.fromBot ? null : AppColors.buttonGradient,
              color: message.fromBot
                  ? (message.isError
                        ? Colors.red.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.85))
                  : null,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(message.fromBot ? 4 : 20),
                bottomRight: Radius.circular(message.fromBot ? 20 : 4),
              ),
              border: message.fromBot
                  ? Border.all(
                      color: message.isError
                          ? Colors.red.withValues(alpha: 0.3)
                          : AppColors.outlineVariant.withValues(alpha: 0.25),
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              message.text,
              style: GoogleFonts.nunitoSans(
                fontSize: 14,
                height: 1.45,
                color: message.fromBot
                    ? (message.isError
                          ? Colors.red.shade700
                          : AppColors.onSurface)
                    : Colors.white,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _typingBubble() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          margin: const EdgeInsets.only(right: 8),
          decoration: const BoxDecoration(
            gradient: AppColors.buttonGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 14,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (i) => Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _quickReplyChips() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: _quickReplies
        .map(
          (reply) => GestureDetector(
            onTap: () => _send(reply),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                reply,
                style: GoogleFonts.nunitoSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        )
        .toList(),
  );

  Widget _inputBar() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.16),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                onSubmitted: _send,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ask Bloom AI anything…',
                  hintStyle: GoogleFonts.nunitoSans(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _send(_inputController.text),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: AppColors.buttonGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
