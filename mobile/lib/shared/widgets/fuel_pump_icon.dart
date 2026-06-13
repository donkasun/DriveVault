import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class FuelPumpIcon extends StatelessWidget {
  final bool isFullTank;
  final double size;

  const FuelPumpIcon({super.key, required this.isFullTank, this.size = 22});

  @override
  Widget build(BuildContext context) {
    final icon = Icon(Icons.local_gas_station, size: size, color: Colors.white);
    if (isFullTank) {
      return Icon(
        Icons.local_gas_station,
        size: size,
        color: AppColors.success,
      );
    }

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF5CF), AppColors.primary],
          stops: [0.5, 0.5],
        ).createShader(bounds);
      },
      child: icon,
    );
  }
}
