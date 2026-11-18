import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class StatCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final LinearGradient? gradient;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.gradient,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.08, end: 0.22).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.iconColor ?? AppConstants.accent;
    final int? numericValue = int.tryParse(widget.value);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit:  (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, __) => Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: widget.gradient ??
                  LinearGradient(
                    colors: [
                      AppConstants.cardBg,
                      AppConstants.surfaceAlt.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
              borderRadius: BorderRadius.circular(16),
              border: Border(
                top: BorderSide(
                  color: effectiveColor.withValues(
                    alpha: _isHovered ? 0.65 : _glowAnim.value + 0.1,
                  ),
                  width: 1.5,
                ),
                left: BorderSide(
                  color: effectiveColor.withValues(alpha: 0.1),
                  width: 1,
                ),
                right: BorderSide(
                  color: effectiveColor.withValues(alpha: 0.1),
                  width: 1,
                ),
                bottom: BorderSide(
                  color: effectiveColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: effectiveColor.withValues(
                    alpha: _isHovered ? 0.3 : _glowAnim.value,
                  ),
                  blurRadius: _isHovered ? 18 : 12,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Gradient icon container
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            effectiveColor.withValues(alpha: 0.22),
                            effectiveColor.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: effectiveColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(widget.icon, color: effectiveColor, size: 17),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.trending_up_rounded,
                      color: AppConstants.success.withValues(alpha: 0.7),
                      size: 15,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Animated rolling number
                if (numericValue != null)
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: numericValue.toDouble()),
                    duration: const Duration(milliseconds: 1400),
                    curve: Curves.easeOutCubic,
                    builder: (_, val, __) => Text(
                      val.round().toString(),
                      style: TextStyle(
                        color: AppConstants.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        letterSpacing: -1,
                        shadows: [
                          Shadow(
                            color: effectiveColor.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Text(
                    widget.value,
                    style: const TextStyle(
                      color: AppConstants.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      letterSpacing: -1,
                    ),
                  ),

                const SizedBox(height: 2),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
