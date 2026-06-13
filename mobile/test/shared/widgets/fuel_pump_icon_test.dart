import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drivevault/core/theme/app_theme.dart';
import 'package:drivevault/shared/widgets/fuel_pump_icon.dart';

void main() {
  testWidgets('renders green icon for full tank', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FuelPumpIcon(isFullTank: true))),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.local_gas_station));
    expect(icon.color, AppColors.success);
    expect(find.byType(ShaderMask), findsNothing);
  });

  testWidgets('renders split yellow icon for partial tank', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FuelPumpIcon(isFullTank: false))),
    );

    expect(find.byType(ShaderMask), findsOneWidget);
  });
}
