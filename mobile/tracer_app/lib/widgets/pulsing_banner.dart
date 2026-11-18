import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Sentinel-style pulsing Quick Trap banner with cyan-to-danger gradient and
/// a breathing glow border. All existing functionality preserved.
class PulsingQuickTrapBanner extends StatefulWidget {
  final VoidCallback onTap;
  const PulsingQuickTrapBanner({super.key, required this.onTap});

  @override
  State<PulsingQuickTrapBanner> createState() => _PulsingQuickTrapBannerState();
}

class _PulsingQuickTrapBannerState extends State<PulsingQuickTrapBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glowAnim;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 6, end: 18).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
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
      builder: (_, __) {
        final borderAlpha = 0.35 + 0.45 * _ctrl.value;
        final glowAlpha   = 0.15 + 0.2  * _ctrl.value;

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit:  (_) => setState(() => _isHovered = false),
          child: AnimatedScale(
            scale: _isHovered ? 1.015 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0F2440),
                      Color(0xFF0A1A30),
                      Color(0xFF12213A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppConstants.danger.withValues(alpha: borderAlpha),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.danger.withValues(alpha: glowAlpha),
                      blurRadius: _glowAnim.value,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: AppConstants.accent.withValues(alpha: 0.05),
                      blurRadius: 24,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Animated icon badge
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppConstants.dangerGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.danger.withValues(alpha: 0.5),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                '1-Click Quick Trap',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppConstants.danger.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: AppConstants.danger.withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  'INSTANT',
                                  style: TextStyle(
                                    color: AppConstants.danger,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Deploy honeypot to extract scammer GPS & IP',
                            style: TextStyle(
                              color: AppConstants.textSecondary,
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppConstants.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppConstants.danger.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppConstants.danger,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
