import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drivevault/core/theme/app_theme.dart';
import 'package:drivevault/shared/widgets/stat_card.dart';

Widget _wrap(Widget widget) =>
    MaterialApp(theme: AppTheme.light, home: Scaffold(body: Center(child: widget)));

void main() {
  group('StatCard — basic rendering', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(
        _wrap(const StatCard(label: 'Monthly fuel', value: r'$120.00')),
      );
      // Label is uppercased inside build(), but Text widget receives the
      // un-transformed string for the test.  We check the transformed form.
      expect(find.text('MONTHLY FUEL'), findsOneWidget);
      expect(find.text(r'$120.00'), findsOneWidget);
    });

    testWidgets('renders caption when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(const StatCard(
          label: 'Total cost',
          value: r'$3,500.00',
          caption: '↑ 8% vs last month',
        )),
      );
      expect(find.text('↑ 8% vs last month'), findsOneWidget);
    });

    testWidgets('does not render caption when absent', (tester) async {
      await tester.pumpWidget(
        _wrap(const StatCard(label: 'Vehicles', value: '3')),
      );
      // No caption Text widget beyond label + value.
      expect(find.byType(Text), findsNWidgets(2));
    });

    testWidgets('renders trailing widget when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(const StatCard(
          label: 'Score',
          value: '82',
          trailing: Icon(Icons.trending_up, key: Key('trailing-icon')),
        )),
      );
      expect(find.byKey(const Key('trailing-icon')), findsOneWidget);
    });

    testWidgets('wraps in white surface card decoration', (tester) async {
      await tester.pumpWidget(
        _wrap(const StatCard(label: 'Fuel', value: r'$50.00')),
      );
      // DecoratedBox at the root of StatCard uses appCardDecoration (white surface).
      final box =
          tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
      final deco = box.decoration as BoxDecoration;
      expect(deco.color, AppColors.surface);
    });
  });
}
