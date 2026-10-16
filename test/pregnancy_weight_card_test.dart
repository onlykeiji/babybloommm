import 'dart:async';

import 'package:babybloom2/features/home/presentation/pregnancy_dashboard/weight_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> openEditor(
    WidgetTester tester,
    Future<void> Function(double) save,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PregnancyWeightCard(
            currentWeight: 132,
            startingWeight: 132,
            onAdjust: (_) {},
            onSetWeight: save,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Your current weight'));
    await tester.pumpAndSettle();
  }

  testWidgets('converts comma decimals and waits for save before closing', (
    tester,
  ) async {
    final pending = Completer<void>();
    double? pounds;
    var calls = 0;
    await openEditor(tester, (value) {
      pounds = value;
      calls++;
      return pending.future;
    });
    await tester.enterText(find.byType(TextFormField), '65,5');
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(pounds, closeTo(65.5 * 2.2046226218, 0.00001));
    expect(find.text('Saving...'), findsOneWidget);
    await tester.tap(find.text('Saving...'));
    expect(calls, 1);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed save keeps the input for retry', (tester) async {
    var calls = 0;
    await openEditor(tester, (_) async {
      if (++calls == 1) throw StateError('Database unavailable');
    });
    await tester.enterText(find.byType(TextFormField), '70.2');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Database unavailable'), findsOneWidget);
    expect(find.text('70.2'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rejects invalid weights and cancel safely disposes input', (
    tester,
  ) async {
    var calls = 0;
    await openEditor(tester, (_) async {
      calls++;
    });
    for (final invalid in ['NaN', 'Infinity', 'abc', '27.1', '181.5']) {
      await tester.enterText(find.byType(TextFormField), invalid);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.byType(AlertDialog), findsOneWidget);
    }
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
