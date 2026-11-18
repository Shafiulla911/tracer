import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/scammer.dart';
import '../widgets/threat_badge.dart';

class ScammerCard extends StatefulWidget {
  final Scammer scammer;
  final VoidCallback? onTap;
  final bool compact;

  const ScammerCard({
    super.key,
    required this.scammer,
    this.onTap,
    this.compact = false,
  });

  @override
  State<ScammerCard> createState() => _ScammerCardState();
}

class _ScammerCardState extends State<ScammerCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  String get _initials {
    final name = widget.scammer.name ?? widget.scammer.phoneNumber ?? '??';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  Color get _avatarColor {
    final count = widget.scammer.reportedCount;
    if (count >= 10) return AppConstants.danger;
    if (count >= 5)  return const Color(0xFFF97316);
    if (count >= 2)  return AppConstants.warning;
    return AppConstants.success;
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.scammer.reportedCount;
    final glow = _isHovered ? AppConstants.danger : AppConstants.accent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit:  (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown:   (_) => setState(() => _isPressed = true),
        onTapUp:     (_) => setState(() => _isPressed = false),
        onTapCancel: ()  => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.975 : (_isHovered ? 1.012 : 1.0),
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppConstants.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isHovered
                    ? AppConstants.danger.withValues(alpha: 0.55)
                    : AppConstants.divider,
                width: _isHovered ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: _isHovered ? 0.18 : 0.0),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Cyber Avatar
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              _avatarColor.withValues(alpha: 0.25),
                              _avatarColor.withValues(alpha: 0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: _avatarColor.withValues(alpha: 0.45),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _avatarColor.withValues(alpha: 0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _initials,
                            style: TextStyle(
                              color: _avatarColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.scammer.name?.isNotEmpty == true
                                  ? widget.scammer.name!
                                  : widget.scammer.phoneNumber ?? 'Unknown',
                              style: const TextStyle(
                                color: AppConstants.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            ThreatBadge.fromCount(count, mini: true),
                          ],
                        ),
                      ),
                      // Report count pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppConstants.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: AppConstants.danger.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '$count ${count == 1 ? "report" : "reports"}',
                          style: const TextStyle(
                            color: AppConstants.danger,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Threat severity bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: (count.clamp(0, 15) / 15).toDouble(),
                      minHeight: 3,
                      backgroundColor: AppConstants.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(_avatarColor),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Info rows
                  if (widget.scammer.phoneNumber?.isNotEmpty == true)
                    _infoRow(Icons.phone_rounded, 'Phone', widget.scammer.phoneNumber!),
                  if (widget.scammer.upiId?.isNotEmpty == true)
                    _infoRow(Icons.account_balance_wallet_rounded, 'UPI', widget.scammer.upiId!),

                  if (!widget.compact)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          const Text(
                            'VIEW FORENSIC DOSSIER',
                            style: TextStyle(
                              color: AppConstants.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 13, color: AppConstants.accent),
                        ],
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppConstants.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 13, color: AppConstants.accent),
          ),
          const SizedBox(width: 9),
          Text(
            '$label  ',
            style: const TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppConstants.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
