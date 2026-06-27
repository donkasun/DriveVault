import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drivevault/shared/widgets/shimmer_box.dart';

void main() {
  testWidgets('ShimmerBox renders with correct height', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ShimmerBox(height: 56, borderRadius: 12)),
      ),
    );
    // Verify ShimmerBox exists and is rendered
    expect(find.byType(ShimmerBox), findsOneWidget);

    // Verify AnimatedBuilder is used internally within ShimmerBox
    expect(
      find.descendant(of: find.byType(ShimmerBox), matching: find.byType(AnimatedBuilder)),
      findsOneWidget,
    );

    // Verify the ShimmerBox has the correct height property
    final shimmerBox = tester.widget<ShimmerBox>(find.byType(ShimmerBox));
    expect(shimmerBox.height, 56.0);
    expect(shimmerBox.borderRadius, 12.0);
  });

  testWidgets('ShimmerBox disposes without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ShimmerBox(height: 40)),
      ),
    );
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
    // No assertion needed — crash on dispose would fail the test
  });
}
