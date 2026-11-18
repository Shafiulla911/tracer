import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Reusable glassmorphism card widget with glow border support.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final Color? glowColor;
  final double glowOpacity;
  final double blurSigma;
  final Color? borderColor;
  final double borderOpacity;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.glowColor,
    this.glowOpacity = 0.15,
    this.blurSigma = 12,
    this.borderColor,
    this.borderOpacity = 0.18,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(18);
    final effectiveBorder = borderColor ?? AppConstants.accent;
    final effectiveGlow = glowColor ?? AppConstants.accent;

    return Container(
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: [
          BoxShadow(
            color: effectiveGlow.withValues(alpha: glowOpacity),
            blurRadius: 18,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: gradient ??
                  LinearGradient(
                    colors: [
                      AppConstants.cardBg.withValues(alpha: 0.85),
                      AppConstants.surfaceAlt.withValues(alpha: 0.65),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
              borderRadius: effectiveRadius,
              border: Border.all(
                color: effectiveBorder.withValues(alpha: borderOpacity),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

