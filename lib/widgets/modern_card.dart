import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final bool animate;

  const ModernCard({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.elevation,
    this.padding,
    this.margin,
    this.borderRadius,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: elevation ?? 2,
      margin: margin ?? EdgeInsets.zero,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

    if (animate) {
      return card.animate().fadeIn().slideY(
        begin: 0.1,
        duration: 300.ms,
        curve: Curves.easeOut,
      );
    }

    return card;
  }
}
