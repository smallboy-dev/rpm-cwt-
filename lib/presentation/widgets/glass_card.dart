import 'package:flutter/material.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(16),
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(borderRadius),
      blur: 20,
      border: Border.fromBorderSide(
        BorderSide(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          width: 1.5,
        ),
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.02),
          isDark
              ? Colors.white.withOpacity(0.03)
              : Colors.black.withOpacity(0.01),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
