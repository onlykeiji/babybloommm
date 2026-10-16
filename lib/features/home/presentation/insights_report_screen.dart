import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/app_session.dart';
import '../../../core/app_settings_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/user_profile_store.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/screen_background.dart';
import 'daily_log_models.dart';
import 'insights_data.dart';

const _weekdayAbbrev = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthAbbrev = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

class InsightsReportScreen extends StatefulWidget {
  const InsightsReportScreen({super.key});

  @override
  State<InsightsReportScreen> createState() => _InsightsReportScreenState();
}

class _InsightsReportScreenState extends State<InsightsReportScreen> {
  bool _sharing = false;
  bool get _isPregnancy => AppSession.mode == AppMode.pregnancy;

  @override
  void initState() {
    super.initState();
    if (AppSettingsStore.current.value == null) AppSettingsStore.fetch();
    if (DailyLogStore.all.value.isEmpty) DailyLogStore.fetchAll();
  }

  Future<void> _sharePdf() async {
    setState(() => _sharing = true);
    try {
      final data = InsightsData.compute(
        DailyLogStore.all.value,
        AppSettingsStore.current.value,
      );
      final bytes = await _buildPdf(data);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'babybloom_insights_report.pdf',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not generate the PDF. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String _summaryText(InsightsData data) {
    if (_isPregnancy) {
      return 'This report summarizes your pregnancy check-ins, including symptoms and mood. '
          'Continue logging how you feel to build a clearer picture over time.';
    }
    final regularity = data.regularityPct;
    if (regularity == null) {
      return 'Not enough logged cycles yet to summarize regularity. Keep logging your period in '
          'Cycle to unlock this section.';
    }
    final regularityWord = regularity >= 80
        ? 'highly regular'
        : regularity >= 50
        ? 'fairly regular'
        : 'irregular';
    return 'Your cycles are $regularityWord. Length varied by up to ${data.variabilityDays} days over your '
        'last ${data.cycleLengthTrend.length} cycles, giving $regularity% regularity and '
        '${data.totalSymptomsLogged} symptoms logged.';
  }

  String _formattedToday() {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  Future<Uint8List> _buildPdf(InsightsData data) async {
    final doc = pw.Document();
    final primary = PdfColor.fromInt(0xFF4E4068);
    final secondary = PdfColor.fromInt(0xFF68548F);
    final muted = PdfColor.fromInt(0xFF49454E);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'BabyBloom',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: secondary,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Insights Report',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: primary,
              ),
            ),
            pw.Text(
              '${ProfileStore.current.value?.fullName ?? "You"}  ·  Generated ${_formattedToday()}',
              style: pw.TextStyle(fontSize: 10, color: muted),
            ),
            pw.SizedBox(height: 12),
            pw.Divider(color: PdfColor.fromInt(0xFFCBC4CE)),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 9, color: muted),
          ),
        ),
        build: (context) => [
          _pdfSectionTitle('Summary', primary),
          pw.Text(
            _summaryText(data),
            style: pw.TextStyle(fontSize: 11, color: muted, lineSpacing: 3),
          ),
          pw.SizedBox(height: 18),
          _pdfSectionTitle(
            _isPregnancy
                ? 'Pregnancy check-ins'
                : 'Cycle length trend (last ${data.cycleLengthTrend.length} cycles)',
            primary,
          ),
          _isPregnancy || data.cycleLengthTrend.isEmpty
              ? pw.Text(
                  _isPregnancy
                      ? 'Your recent check-ins are reflected in the symptoms and mood summaries below.'
                      : 'Not enough logged periods yet.',
                  style: pw.TextStyle(fontSize: 10, color: muted),
                )
              : pw.TableHelper.fromTextArray(
                  headers: const ['Month', 'Length (days)'],
                  data: data.cycleLengthTrend
                      .map(
                        (c) => [_monthAbbrev[c.start.month - 1], '${c.days}'],
                      )
                      .toList(),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 10,
                  ),
                  headerDecoration: pw.BoxDecoration(color: primary),
                  cellStyle: const pw.TextStyle(fontSize: 10),
                  cellAlignment: pw.Alignment.centerLeft,
                  border: null,
                  cellPadding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                ),
          pw.SizedBox(height: 18),
          _pdfSectionTitle('Top symptoms (last 30 days)', primary),
          data.topSymptoms.isEmpty
              ? pw.Text(
                  'No symptoms logged in the last 30 days.',
                  style: pw.TextStyle(fontSize: 10, color: muted),
                )
              : pw.TableHelper.fromTextArray(
                  headers: const ['Symptom', 'Frequency'],
                  data: data.topSymptoms
                      .map((s) => [s.label, '${(s.pct * 100).round()}%'])
                      .toList(),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 10,
                  ),
                  headerDecoration: pw.BoxDecoration(color: secondary),
                  cellStyle: const pw.TextStyle(fontSize: 10),
                  cellAlignment: pw.Alignment.centerLeft,
                  border: null,
                  cellPadding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                ),
          pw.SizedBox(height: 18),
          _pdfSectionTitle('Mood this week', primary),
          pw.TableHelper.fromTextArray(
            headers: data.moodWeek
                .map((m) => _weekdayAbbrev[m.date.weekday - 1])
                .toList(),
            data: [data.moodWeek.map((m) => m.mood ?? '—').toList()],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 10,
            ),
            headerDecoration: pw.BoxDecoration(color: primary),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignment: pw.Alignment.center,
            headerAlignment: pw.Alignment.center,
            border: null,
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 6,
            ),
          ),
          pw.SizedBox(height: 18),
          _pdfSectionTitle('Personalized insights', primary),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: data.personalizedInsights
                .map(
                  (insight) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 10),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 5,
                          height: 5,
                          margin: const pw.EdgeInsets.only(top: 4, right: 8),
                          decoration: pw.BoxDecoration(
                            color: secondary,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                insight.category.toUpperCase(),
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: secondary,
                                  letterSpacing: 1,
                                ),
                              ),
                              pw.Text(
                                insight.title,
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  color: primary,
                                ),
                              ),
                              pw.Text(
                                insight.meta,
                                style: pw.TextStyle(fontSize: 9, color: muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          pw.SizedBox(height: 24),
          pw.Divider(color: PdfColor.fromInt(0xFFCBC4CE)),
          pw.SizedBox(height: 8),
          pw.Text(
            'This report is generated from your self-reported data in BabyBloom and is not medical advice. '
            'Please consult a healthcare provider with any concerns.',
            style: pw.TextStyle(
              fontSize: 8,
              color: muted,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _pdfSectionTitle(String title, PdfColor color) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
        color: color,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<AppSettings?>(
    valueListenable: AppSettingsStore.current,
    builder: (context, settings, _) => ValueListenableBuilder<List<DailyLog>>(
      valueListenable: DailyLogStore.all,
      builder: (context, logs, _) {
        final data = InsightsData.compute(logs, settings);
        return Scaffold(
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
                                _titleCard(data),
                                const SizedBox(height: 26),
                                _sectionTitle(
                                  _isPregnancy
                                      ? 'Pregnancy check-ins'
                                      : 'Cycle length trend',
                                  _isPregnancy
                                      ? 'Your recent daily check-in activity.'
                                      : 'Last ${data.cycleLengthTrend.length} cycles, in days.',
                                ),
                                const SizedBox(height: 12),
                                _isPregnancy || data.cycleLengthTrend.isEmpty
                                    ? _emptyNote(
                                        _isPregnancy
                                            ? 'Your symptoms and mood summaries reflect your pregnancy check-ins.'
                                            : 'Not enough logged periods yet.',
                                      )
                                    : _tableCard(
                                        headers: const ['Month', 'Length'],
                                        rows: data.cycleLengthTrend
                                            .map(
                                              (c) => [
                                                _monthAbbrev[c.start.month - 1],
                                                '${c.days} days',
                                              ],
                                            )
                                            .toList(),
                                      ),
                                const SizedBox(height: 26),
                                _sectionTitle('Top symptoms', 'Last 30 days.'),
                                const SizedBox(height: 12),
                                data.topSymptoms.isEmpty
                                    ? _emptyNote(
                                        'No symptoms logged in the last 30 days.',
                                      )
                                    : _tableCard(
                                        headers: const ['Symptom', 'Frequency'],
                                        rows: data.topSymptoms
                                            .map(
                                              (s) => [
                                                s.label,
                                                '${(s.pct * 100).round()}%',
                                              ],
                                            )
                                            .toList(),
                                      ),
                                const SizedBox(height: 26),
                                _sectionTitle(
                                  'Mood this week',
                                  'How you felt, day by day.',
                                ),
                                const SizedBox(height: 12),
                                _tableCard(
                                  headers: data.moodWeek
                                      .map(
                                        (m) =>
                                            _weekdayAbbrev[m.date.weekday - 1],
                                      )
                                      .toList(),
                                  rows: [
                                    data.moodWeek
                                        .map((m) => m.mood ?? '—')
                                        .toList(),
                                  ],
                                ),
                                const SizedBox(height: 26),
                                _sectionTitle(
                                  'Personalized insights',
                                  'Patterns we noticed in your logs.',
                                ),
                                const SizedBox(height: 12),
                                _insightsList(data, isPregnancy: _isPregnancy),
                                const SizedBox(height: 26),
                                _disclaimer(),
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
      },
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
                'Insights report',
                style: GoogleFonts.nunitoSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Generated ${_formattedToday()}',
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

  Widget _titleCard(InsightsData data) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
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
    child: Row(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.picture_as_pdf_outlined,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isPregnancy
                    ? 'Your pregnancy insights summary'
                    : data.cycleLengthTrend.isEmpty
                    ? 'Your insights summary'
                    : 'Your ${data.cycleLengthTrend.length}-cycle insights summary',
                style: GoogleFonts.nunitoSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ready to share with your provider or save for yourself.',
                style: GoogleFonts.nunitoSans(
                  fontSize: 13,
                  height: 1.4,
                  color: const Color(0xFFEBDDFF),
                ),
              ),
            ],
          ),
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

  Widget _emptyNote(String message) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: AppColors.outlineVariant.withValues(alpha: 0.25),
      ),
    ),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: GoogleFonts.nunitoSans(
        fontSize: 13,
        color: AppColors.onSurfaceVariant,
      ),
    ),
  );

  Widget _tableCard({
    required List<String> headers,
    required List<List<String>> rows,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: headers
                .map(
                  (h) => Expanded(
                    child: Text(
                      h,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Divider(
          height: 1,
          color: AppColors.outlineVariant.withValues(alpha: 0.25),
        ),
        ...rows.map(
          (row) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: row
                      .map(
                        (cell) => Expanded(
                          child: Text(
                            cell,
                            style: GoogleFonts.nunitoSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              if (row != rows.last)
                Divider(
                  height: 1,
                  color: AppColors.outlineVariant.withValues(alpha: 0.15),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _insightsList(InsightsData data, {required bool isPregnancy}) {
    final insights = isPregnancy
        ? data.personalizedInsights
              .where(
                (insight) =>
                    insight.category == 'Symptoms' || insight.category == 'Tip',
              )
              .toList()
        : data.personalizedInsights;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
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
      child: Column(
        children: List.generate(insights.length, (index) {
          final insight = insights[index];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6, right: 10),
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            insight.category.toUpperCase(),
                            style: GoogleFonts.nunitoSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                              color: AppColors.secondary,
                            ),
                          ),
                          Text(
                            insight.title,
                            style: GoogleFonts.nunitoSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            insight.meta,
                            style: GoogleFonts.nunitoSans(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (index != insights.length - 1)
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

  Widget _disclaimer() => Text(
    'This report is generated from your self-reported data and is not medical advice. Please consult a healthcare provider with any concerns.',
    style: GoogleFonts.nunitoSans(
      fontSize: 12,
      height: 1.5,
      fontStyle: FontStyle.italic,
      color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
    ),
  );

  Widget _bottomBar() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: PrimaryButton(
        label: _sharing ? 'Preparing PDF…' : 'Share as PDF',
        trailingIcon: _sharing ? null : Icons.ios_share_rounded,
        onPressed: _sharing ? () {} : _sharePdf,
      ),
    ),
  );
}
