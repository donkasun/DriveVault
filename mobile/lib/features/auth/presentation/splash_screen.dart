import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      backgroundColor: Color(0xFFF3F4F7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo / icon
            Icon(
              Icons.directions_car_filled,
              size: 80,
              color: Color(0xFF16A34A),
            ),
            SizedBox(height: 24),
            // Loading spinner
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
            ),
            SizedBox(height: 16),
            // Descriptive loading text
            Text(
              'DriveVault is loading...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF15151C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
