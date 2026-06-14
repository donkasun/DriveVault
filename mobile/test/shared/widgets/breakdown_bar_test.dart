import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drivevault/core/theme/app_theme.dart';
import 'package:drivevault/shared/widgets/breakdown_bar.dart';

Widget _wrap(Widget widget) =>
    MaterialApp(home: Scaffold(body: Center(child: widget)));

void main() {
  group('BreakdownBar — all-zero / empty', () {
    testWidgets('empty segments list shows neutral track', (tester) async {
      await tester.pumpWidget(
        _wrap(const BreakdownBar(segments: [])),
      );
      // Neutral track rendered as a single DecoratedBox with divider color.
      final box = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.color, AppColors.divider);
    });

    testWidgets('all-zero values show neutral track', (tester) async {
      await tester.pumpWidget(
        _wrap(const BreakdownBar(segments: [
          BreakdownSegment(label: 'Fuel', valueCents: 0, color: Colors.blue),
          BreakdownSegment(label: 'Maintenance', valueCents: 0, color: Colors.red),
        ])),
      );
      final box = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.color, AppColors.divider);
    });
  });

  group('BreakdownBar — with values', () {
    testWidgets('renders ClipRRect + Row when values are non-zero', (tester) async {
      await tester.pumpWidget(
        _wrap(const BreakdownBar(segments: [
          BreakdownSegment(label: 'Fuel', valueCents: 6000, color: Colors.yellow),
          BreakdownSegment(label: 'Maint', valueCents: 4000, color: Colors.grey),
        ])),
      );
      expect(find.byType(ClipRRect), findsOneWidget);
      expect(find.byType(Row), findsAtLeastNWidgets(1));
    });

    testWidgets('renders one Expanded per non-zero segment', (tester) async {
      await tester.pumpWidget(
        _wrap(const BreakdownBar(segments: [
          BreakdownSegment(label: 'A', valueCents: 3000, color: Colors.blue),
          BreakdownSegment(label: 'B', valueCents: 7000, color: Colors.red),
        ])),
      );
      // 2 non-zero segments → 2 Expanded widgets inside the Row.
      expect(find.byType(Expanded), findsNWidgets(2));
    });

    testWidgets('zero-value segment is omitted from Row', (tester) async {
      await tester.pumpWidget(
        _wrap(const BreakdownBar(segments: [
          BreakdownSegment(label: 'Fuel', valueCents: 5000, color: Colors.yellow),
          BreakdownSegment(label: 'Empty', valueCents: 0, color: Colors.grey),
          BreakdownSegment(label: 'Maint', valueCents: 5000, color: Colors.blue),
        ])),
      );
      // Only 2 non-zero segments → 2 Expanded widgets.
      expect(find.byType(Expanded), findsNWidgets(2));
    });

    testWidgets('respects custom height', (tester) async {
      await tester.pumpWidget(
        _wrap(const BreakdownBar(
          segments: [
            BreakdownSegment(label: 'Fuel', valueCents: 1000, color: Colors.orange),
          ],
          height: 16,
        )),
      );
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.height, 16);
    });
  });
}
