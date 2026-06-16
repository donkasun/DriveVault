import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drivevault/core/theme/app_theme.dart';
import 'package:drivevault/features/dashboard/domain/dashboard_data.dart';
import 'package:drivevault/features/vehicles/domain/vehicle.dart';
import 'package:drivevault/shared/widgets/status_pill.dart';

// Wraps [widget] in a minimal MaterialApp so Text can resolve styles.
Widget _wrap(Widget widget) =>
    MaterialApp(home: Scaffold(body: Center(child: widget)));

void main() {
  group('StatusPill — basic rendering', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        _wrap(const StatusPill(label: 'Valid', tone: PillTone.ok)),
      );
      expect(find.text('Valid'), findsOneWidget);
    });

    testWidgets('renders glyph when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const StatusPill(label: 'Overdue', tone: PillTone.overdue, glyph: '⚠'),
        ),
      );
      expect(find.text('⚠'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
    });

    testWidgets('pill background uses successBg for PillTone.ok', (tester) async {
      await tester.pumpWidget(
        _wrap(const StatusPill(label: 'OK', tone: PillTone.ok)),
      );
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.successBg);
    });

    testWidgets('pill background uses warningBg for PillTone.soon', (tester) async {
      await tester.pumpWidget(
        _wrap(const StatusPill(label: 'Soon', tone: PillTone.soon)),
      );
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.warningBg);
    });

    testWidgets('pill background uses dangerBg for PillTone.overdue', (tester) async {
      await tester.pumpWidget(
        _wrap(const StatusPill(label: 'Overdue', tone: PillTone.overdue)),
      );
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.dangerBg);
    });

    testWidgets('pill background uses divider color for PillTone.neutral', (tester) async {
      await tester.pumpWidget(
        _wrap(const StatusPill(label: 'None', tone: PillTone.neutral)),
      );
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.divider);
    });

    testWidgets('non-tappable pill has minHeight 24', (tester) async {
      await tester.pumpWidget(
        _wrap(const StatusPill(label: 'X', tone: PillTone.ok)),
      );
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.minHeight, 24);
    });

    testWidgets('tappable pill has minHeight 44', (tester) async {
      await tester.pumpWidget(
        _wrap(StatusPill(label: 'X', tone: PillTone.ok, onTap: () {})),
      );
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.minHeight, 44);
    });

    testWidgets('onTap fires when pill is tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(StatusPill(label: 'Tap me', tone: PillTone.ok, onTap: () => tapped = true)),
      );
      await tester.tap(find.byType(GestureDetector));
      expect(tapped, isTrue);
    });
  });

  group('StatusPill.fromRenewalStatus', () {
    testWidgets('ok → glyph ✓, label Valid, tone ok', (tester) async {
      await tester.pumpWidget(
        _wrap(StatusPill.fromRenewalStatus(RenewalStatus.ok)),
      );
      expect(find.text('✓'), findsOneWidget);
      expect(find.text('Valid'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container).first);
      expect((container.decoration as BoxDecoration).color, AppColors.successBg);
    });

    testWidgets('soon with daysRemaining → "14d left"', (tester) async {
      await tester.pumpWidget(
        _wrap(StatusPill.fromRenewalStatus(RenewalStatus.soon, daysRemaining: 14)),
      );
      expect(find.text('◷'), findsOneWidget);
      expect(find.text('14d left'), findsOneWidget);
    });

    testWidgets('soon without daysRemaining → "Soon"', (tester) async {
      await tester.pumpWidget(
        _wrap(StatusPill.fromRenewalStatus(RenewalStatus.soon)),
      );
      expect(find.text('Soon'), findsOneWidget);
    });

    testWidgets('overdue → glyph ⚠, label Overdue, danger bg', (tester) async {
      await tester.pumpWidget(
        _wrap(StatusPill.fromRenewalStatus(RenewalStatus.overdue)),
      );
      expect(find.text('⚠'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container).first);
      expect((container.decoration as BoxDecoration).color, AppColors.dangerBg);
    });
  });

  group('StatusPill.fromDocsStatus', () {
    testWidgets('valid → "Docs valid", ok tone', (tester) async {
      await tester.pumpWidget(
        _wrap(StatusPill.fromDocsStatus(
          const DocsStatus(state: 'valid', needsActionCount: 0),
        )),
      );
      expect(find.text('Docs valid'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container).first);
      expect((container.decoration as BoxDecoration).color, AppColors.successBg);
    });

    testWidgets('needs_action with count 1 → warning bg', (tester) async {
      await tester.pumpWidget(
        _wrap(StatusPill.fromDocsStatus(
          const DocsStatus(state: 'needs_action', needsActionCount: 1),
        )),
      );
      expect(find.text('1 need action'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container).first);
      expect((container.decoration as BoxDecoration).color, AppColors.warningBg);
    });

    testWidgets('needs_action with count ≥3 → danger bg', (tester) async {
      await tester.pumpWidget(
        _wrap(StatusPill.fromDocsStatus(
          const DocsStatus(state: 'needs_action', needsActionCount: 3),
        )),
      );
      expect(find.text('3 need action'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container).first);
      expect((container.decoration as BoxDecoration).color, AppColors.dangerBg);
    });

    testWidgets('none → "No docs", neutral (divider) bg', (tester) async {
      await tester.pumpWidget(
        _wrap(StatusPill.fromDocsStatus(DocsStatus.none)),
      );
      expect(find.text('No docs'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container).first);
      expect((container.decoration as BoxDecoration).color, AppColors.divider);
    });
  });
}
