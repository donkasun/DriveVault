import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class ShimmerBox extends StatefulWidget {
  final double height;
  final double borderRadius;
  final double? width;

  const ShimmerBox({
    super.key,
    required this.height,
    this.borderRadius = 8,
    this.width,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final t = _anim.value;
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + 3.0 * t, 0),
              end: Alignment(-0.5 + 3.0 * t, 0),
              colors: const [
                AppColors.divider,
                Color(0xFFF0F0F5), // lighter highlight
                AppColors.divider,
              ],
            ),
          ),
        );
      },
    );
  }
}
