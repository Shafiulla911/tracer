import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class CustomButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final LinearGradient? gradient;
  final IconData? icon;
  final bool isLoading;
  final double height;
  final double borderRadius;
  final Color? solidColor;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.gradient,
    this.icon,
    this.isLoading = false,
    this.height = 52,
    this.borderRadius = 12,
    this.solidColor,
  });

  factory CustomButton.danger({
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    Key? key,
  }) =>
      CustomButton(
        key: key,
        label: label,
        onPressed: onPressed,
        gradient: AppConstants.dangerGradient,
        icon: icon,
        isLoading: isLoading,
      );

  factory CustomButton.action({
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    Key? key,
  }) =>
      CustomButton(
        key: key,
        label: label,
        onPressed: onPressed,
        gradient: AppConstants.actionGradient,
        icon: icon,
        isLoading: isLoading,
      );

  factory CustomButton.outlined({
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    Key? key,
  }) =>
      CustomButton(
        key: key,
        label: label,
        onPressed: onPressed,
        solidColor: Colors.transparent,
        icon: icon,
      );

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = widget.gradient ??
        (widget.solidColor == null ? AppConstants.actionGradient : null);

    final isEnabled = !widget.isLoading && widget.onPressed != null;

    return MouseRegion(
      onEnter: (_) {
        if (isEnabled) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (isEnabled) setState(() => _isHovered = false);
      },
      child: GestureDetector(
        onTapDown: (_) {
          if (isEnabled) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (isEnabled) setState(() => _isPressed = false);
        },
        onTapCancel: () {
          if (isEnabled) setState(() => _isPressed = false);
        },
        onTap: isEnabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _isPressed
              ? 0.96
              : (_isHovered ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeInOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: widget.height,
            decoration: BoxDecoration(
              gradient: effectiveGradient,
              color: widget.solidColor,
              border: widget.solidColor == Colors.transparent
                  ? Border.all(
                      color: _isHovered
                          ? AppConstants.accent
                          : AppConstants.accent.withValues(alpha: 0.8),
                      width: _isHovered ? 2.0 : 1.5,
                    )
                  : null,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: !isEnabled
                  ? []
                  : [
                      BoxShadow(
                        color: (effectiveGradient?.colors.first ??
                                AppConstants.accent)
                            .withValues(alpha: _isHovered ? 0.55 : 0.35),
                        blurRadius: _isHovered ? 16 : 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
