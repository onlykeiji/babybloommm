import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/screen_background.dart';
import 'contraction_models.dart';

class ContractionTimerScreen extends StatefulWidget {
  const ContractionTimerScreen({super.key});

  @override
  State<ContractionTimerScreen> createState() => _ContractionTimerScreenState();
}

class _ContractionTimerScreenState extends State<ContractionTimerScreen> {
  DateTime? _currentStart;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    ContractionStore.fetchAll();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  bool get _isRunning => _currentStart != null;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
    );
  }

  Future<void> _toggle() async {
    if (_isRunning) {
      final start = _currentStart!;
      final duration = DateTime.now().difference(start);
      if (duration.inSeconds <= 0) {
        _showError('Please time the contraction for at least one second.');
        return;
      }
      final history = ContractionStore.history.value;
      // Use only a contraction that actually started before this one. A
      // server/device-clock difference can otherwise make a future record
      // appear first in the descending history and produce a negative gap.
      Contraction? previous;
      for (final contraction in history) {
        if (contraction.start.isAfter(start)) continue;
        if (previous == null || contraction.start.isAfter(previous.start)) {
          previous = contraction;
        }
      }
      final sincePrevious = previous == null
          ? null
          : start.difference(previous.start);
      _ticker?.cancel();
      setState(() {
        _currentStart = null;
        _elapsed = Duration.zero;
      });
      try {
        await ContractionStore.add(
          Contraction(
            start: start,
            duration: duration,
            sincePrevious: sincePrevious,
          ),
        );
      } catch (e) {
        _showError('Could not save contraction: $e');
      }
    } else {
      setState(() {
        _currentStart = DateTime.now();
        _elapsed = Duration.zero;
      });
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsed = DateTime.now().difference(_currentStart!));
      });
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear contraction history?'),
        content: const Text(
          'This permanently deletes every logged contraction. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ContractionStore.clearAll();
    } catch (e) {
      _showError('Could not clear history: $e');
    }
  }

  String _format(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
                child: ValueListenableBuilder<List<Contraction>>(
                  valueListenable: ContractionStore.history,
                  builder: (context, history, _) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _timerCard(),
                            const SizedBox(height: 20),
                            _guidanceCard(),
                            const SizedBox(height: 30),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'History',
                                    style: GoogleFonts.nunitoSans(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                if (history.isNotEmpty)
                                  TextButton(
                                    onPressed: _clearHistory,
                                    child: Text(
                                      'CLEAR',
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
                            const SizedBox(height: 12),
                            if (history.isEmpty)
                              _emptyHistory()
                            else
                              _historyList(history),
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
                'Contraction timer',
                style: GoogleFonts.nunitoSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Track duration and time between.',
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

  Widget _timerCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.secondary],
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.28),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
      ],
    ),
    child: Column(
      children: [
        Text(
          _isRunning ? 'CONTRACTION IN PROGRESS' : 'READY',
          style: GoogleFonts.nunitoSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: const Color(0xFFEBDDFF),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _format(_elapsed),
          style: GoogleFonts.nunitoSans(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _toggle,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              _isRunning ? 'Stop Contraction' : 'Start Contraction',
              style: GoogleFonts.nunitoSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _guidanceCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFEBDDFF),
          AppColors.lavender.withValues(alpha: 0.6),
        ],
      ),
      borderRadius: BorderRadius.circular(22),
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The 5-1-1 rule',
                style: GoogleFonts.nunitoSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Many providers suggest heading to the hospital when contractions are 5 minutes apart, lasting 1 minute each, for at least 1 hour. Always follow your own provider\'s specific guidance.',
                style: GoogleFonts.nunitoSans(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _emptyHistory() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 30),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: AppColors.outlineVariant.withValues(alpha: 0.25),
      ),
    ),
    child: Text(
      'No contractions logged yet.',
      style: GoogleFonts.nunitoSans(
        fontSize: 13,
        color: AppColors.onSurfaceVariant,
      ),
    ),
  );

  Widget _historyList(List<Contraction> history) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
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
      children: List.generate(history.length, (index) {
        final c = history[index];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD3BBFE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.timer_outlined,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Duration ${_format(c.duration)}',
                          style: GoogleFonts.nunitoSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          c.sincePrevious == null
                              ? 'First logged contraction'
                              : '${_format(c.sincePrevious!)} since previous',
                          style: GoogleFonts.nunitoSans(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${c.start.hour.toString().padLeft(2, '0')}:${c.start.minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (index != history.length - 1)
              Divider(
                height: 1,
                indent: 12,
                endIndent: 12,
                color: AppColors.outlineVariant.withValues(alpha: 0.2),
              ),
          ],
        );
      }),
    ),
  );
}
