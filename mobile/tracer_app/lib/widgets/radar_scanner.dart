import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// A cyber-security radar scanner with a rotating sweep beam,
/// concentric circular range rings, crosshairs, and pulsing sonar ripples.
class RadarScanner extends StatefulWidget {
  final double size;
  final Color beamColor;
  final Color ringColor;
  final bool hasTarget;
  final String? statusText;

  const RadarScanner({
    super.key,
    this.size = 200,
    this.beamColor = AppConstants.accent,
    this.ringColor = AppConstants.divider,
    this.hasTarget = false,
    this.statusText,
  });

  @override
  State<RadarScanner> createState() => _RadarScannerState();
}

class _RadarScannerState extends State<RadarScanner>
    with TickerProviderStateMixin {
  late AnimationController _sweepController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: Listenable.merge([_sweepController, _pulseController]),
            builder: (context, child) {
              return CustomPaint(
                painter: _RadarPainter(
                  sweepAngle: _sweepController.value * 2 * math.pi,
                  pulseProgress: _pulseController.value,
                  beamColor: widget.beamColor,
                  ringColor: widget.ringColor,
                  hasTarget: widget.hasTarget,
                ),
                child: Center(
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.hasTarget
                          ? AppConstants.success
                          : widget.beamColor,
                      boxShadow: [
                        BoxShadow(
                          color: (widget.hasTarget
                                  ? AppConstants.success
                                  : widget.beamColor)
                              .withValues(alpha: 0.8),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.statusText != null) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BlinkingDot(
                color: widget.hasTarget
                    ? AppConstants.success
                    : widget.beamColor,
              ),
              const SizedBox(width: 8),
              Text(
                widget.statusText!,
                style: TextStyle(
                  color: widget.hasTarget
                      ? AppConstants.success
                      : AppConstants.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double sweepAngle;
  final double pulseProgress;
  final Color beamColor;
  final Color ringColor;
  final bool hasTarget;

  _RadarPainter({
    required this.sweepAngle,
    required this.pulseProgress,
    required this.beamColor,
    required this.ringColor,
    required this.hasTarget,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Dark radar background
    final bgPaint = Paint()
      ..color = const Color(0xFF090E1A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Concentric range rings
    final ringPaint = Paint()
      ..color = ringColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * (i / 4), ringPaint);
    }

    // Crosshairs
    final crosshairPaint = Paint()
      ..color = ringColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(
        Offset(center.dx, 0), Offset(center.dx, size.height), crosshairPaint);
    canvas.drawLine(
        Offset(0, center.dy), Offset(size.width, center.dy), crosshairPaint);

    // Expanding Sonar Pulse Ring
    final pulseRadius = radius * pulseProgress;
    final pulseOpacity = (1.0 - pulseProgress).clamp(0.0, 1.0);
    final pulsePaint = Paint()
      ..color = beamColor.withValues(alpha: pulseOpacity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, pulseRadius, pulsePaint);

    // Rotating Sweep Gradient Beam
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepGradient = SweepGradient(
      center: Alignment.center,
      startAngle: sweepAngle - (math.pi / 2.5),
      endAngle: sweepAngle,
      colors: [
        beamColor.withValues(alpha: 0.0),
        beamColor.withValues(alpha: 0.08),
        beamColor.withValues(alpha: 0.35),
      ],
      stops: const [0.0, 0.5, 1.0],
      transform: const GradientRotation(0),
    );

    final sweepPaint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, sweepPaint);

    // Leading sweep line
    final lineEnd = Offset(
      center.dx + radius * math.cos(sweepAngle),
      center.dy + radius * math.sin(sweepAngle),
    );
    final sweepLinePaint = Paint()
      ..color = beamColor.withValues(alpha: 0.7)
      ..strokeWidth = 1.5;
    canvas.drawLine(center, lineEnd, sweepLinePaint);

    // Outer boundary ring
    final borderPaint = Paint()
      ..color = beamColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, borderPaint);

    // If target detected, draw a blip at 70% radius
    if (hasTarget) {
      const targetAngle = 0.8 * math.pi;
      final targetPos = Offset(
        center.dx + (radius * 0.65) * math.cos(targetAngle),
        center.dy + (radius * 0.65) * math.sin(targetAngle),
      );
      final blipPaint = Paint()
        ..color = AppConstants.success
        ..style = PaintingStyle.fill;
      canvas.drawCircle(targetPos, 4, blipPaint);

      final blipHalo = Paint()
        ..color = AppConstants.success.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(targetPos, 8, blipHalo);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.hasTarget != hasTarget;
  }
}

/// A cyber blinking status dot indicator (e.g. ● LIVE)
class _BlinkingDot extends StatefulWidget {
  final Color color;
  const _BlinkingDot({required this.color});

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final opacity = 0.3 + (0.7 * _ctrl.value);
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: opacity),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: opacity * 0.8),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Standalone blinking status indicator for use anywhere in the app
class CyberStatusIndicator extends StatefulWidget {
  final String label;
  final Color color;

  const CyberStatusIndicator({
    super.key,
    required this.label,
    this.color = AppConstants.success,
  });

  @override
  State<CyberStatusIndicator> createState() => _CyberStatusIndicatorState();
}

class _CyberStatusIndicatorState extends State<CyberStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final alpha = 0.3 + (0.7 * _ctrl.value);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.3 + 0.3 * _ctrl.value),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: alpha),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: alpha),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
