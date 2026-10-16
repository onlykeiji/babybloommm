import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'baby_care_models.dart';

/// Draws a simplified growth chart: a shaded P3–P97 reference band, a
/// dashed P50 median line, and the baby's own logged points connected by
/// a solid line. Purely illustrative — not a clinical percentile plot.
class GrowthChartPainter extends CustomPainter {
  GrowthChartPainter({
    required this.reference,
    required this.entries,
    required this.maxAgeMonths,
    required this.babyDateOfBirth,
  });

  final List<ReferencePoint> reference;
  final List<GrowthEntry> entries;
  final double maxAgeMonths;
  final DateTime babyDateOfBirth;

  double _ageMonthsAt(DateTime date) =>
      date.difference(babyDateOfBirth).inDays / 30.44;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 34.0;
    const bottomPad = 22.0;
    const topPad = 10.0;
    const rightPad = 10.0;

    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;

    final minY =
        reference.map((r) => r.p3).reduce((a, b) => a < b ? a : b) * 0.94;
    final maxY =
        reference.map((r) => r.p97).reduce((a, b) => a > b ? a : b) * 1.06;

    double xFor(double ageMonths) =>
        leftPad + (ageMonths / maxAgeMonths).clamp(0.0, 1.0) * chartWidth;
    double yFor(double value) =>
        topPad +
        chartHeight -
        ((value - minY) / (maxY - minY)).clamp(0.0, 1.0) * chartHeight;

    // Axis lines.
    final axisPaint = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(leftPad, topPad),
      Offset(leftPad, topPad + chartHeight),
      axisPaint,
    );
    canvas.drawLine(
      Offset(leftPad, topPad + chartHeight),
      Offset(leftPad + chartWidth, topPad + chartHeight),
      axisPaint,
    );

    // Reference band (P3–P97).
    final bandPath = Path();
    for (var i = 0; i < reference.length; i++) {
      final p = reference[i];
      final point = Offset(xFor(p.ageMonths), yFor(p.p97));
      if (i == 0) {
        bandPath.moveTo(point.dx, point.dy);
      } else {
        bandPath.lineTo(point.dx, point.dy);
      }
    }
    for (var i = reference.length - 1; i >= 0; i--) {
      final p = reference[i];
      bandPath.lineTo(xFor(p.ageMonths), yFor(p.p3));
    }
    bandPath.close();
    canvas.drawPath(
      bandPath,
      Paint()..color = AppColors.lavender.withValues(alpha: 0.35),
    );

    // P50 median dashed line.
    final medianPaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.7)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < reference.length - 1; i++) {
      final a = Offset(xFor(reference[i].ageMonths), yFor(reference[i].p50));
      final b = Offset(
        xFor(reference[i + 1].ageMonths),
        yFor(reference[i + 1].p50),
      );
      _drawDashedLine(canvas, a, b, medianPaint);
    }

    // Baby's logged entries.
    if (entries.isNotEmpty) {
      final linePaint = Paint()
        ..color = AppColors.primary
        ..strokeWidth = 2.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final dotPaint = Paint()..color = AppColors.primary;
      final path = Path();
      for (var i = 0; i < entries.length; i++) {
        final ageMonths = _ageMonthsAt(entries[i].date);
        final point = Offset(xFor(ageMonths), yFor(entries[i].value));
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, linePaint);
      for (final entry in entries) {
        final ageMonths = _ageMonthsAt(entry.date);
        final point = Offset(xFor(ageMonths), yFor(entry.value));
        canvas.drawCircle(point, 4, dotPaint);
        canvas.drawCircle(
          point,
          4,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dashWidth = 5.0;
    const dashGap = 4.0;
    final total = (b - a).distance;
    final direction = (b - a) / total;
    var covered = 0.0;
    var draw = true;
    var current = a;
    while (covered < total) {
      final segment = draw ? dashWidth : dashGap;
      final next = current + direction * segment;
      if (draw) canvas.drawLine(current, next, paint);
      current = next;
      covered += segment;
      draw = !draw;
    }
  }

  @override
  bool shouldRepaint(covariant GrowthChartPainter oldDelegate) =>
      oldDelegate.entries != entries || oldDelegate.reference != reference;
}
