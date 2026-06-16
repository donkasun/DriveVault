import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class FuelPumpIcon extends StatelessWidget {
  final bool isFullTank;
  final double size;

  /// When true, the partial gradient uses primary → dark amber instead of
  /// cream → primary — gives readable contrast on a yellow-tinted background.
  final bool darkInk;

  const FuelPumpIcon({
    super.key,
    required this.isFullTank,
    this.size = 22,
    this.darkInk = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isFullTank) {
      return Icon(Icons.local_gas_station, size: size, color: const Color(0xFF15803D));
    }

    // Partial: top half = "empty", bottom half = "filled".
    // Default (white bg): cream top → primary yellow bottom.
    // darkInk (yellow bg): primary yellow top → dark amber bottom for contrast.
    final colors = darkInk
        ? const [AppColors.primary, Color(0xFFA06800)]
        : const [Color(0xFFFFF5CF), AppColors.primary];

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
        stops: const [0.5, 0.5],
      ).createShader(bounds),
      child: Icon(Icons.local_gas_station, size: size, color: Colors.white),
    );
  }
}
