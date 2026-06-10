import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Stub vehicle detail screen — to be fully implemented in a later task.
class VehicleDetailScreen extends StatelessWidget {
  final String vehicleId;

  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Details'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Center(
        child: Text('Vehicle detail for $vehicleId — coming soon'),
      ),
    );
  }
}
