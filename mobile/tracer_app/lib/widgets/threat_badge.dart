import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

enum ThreatSeverity { low, medium, high, critical }

class ThreatBadge extends StatelessWidget {
  final String label;
  final ThreatSeverity severity;
  final bool mini;

  const ThreatBadge({
    super.key,
    required this.label,
    this.severity = ThreatSeverity.medium,
    this.mini = false,
  });

  factory ThreatBadge.fromCount(int count, {bool mini = false}) {
    ThreatSeverity sev;
    String lbl;
    if (count >= 10) {
      sev = ThreatSeverity.critical;
      lbl = 'CRITICAL';
    } else if (count >= 5) {
      sev = ThreatSeverity.high;
      lbl = 'HIGH';
    } else if (count >= 2) {
      sev = ThreatSeverity.medium;
      lbl = 'ELEVATED';
    } else {
      sev = ThreatSeverity.low;
      lbl = 'MONITORED';
    }
    return ThreatBadge(label: lbl, severity: sev, mini: mini);
  }

  Color get _color {
    switch (severity) {
      case ThreatSeverity.critical:
        return AppConstants.danger;
      case ThreatSeverity.high:
        return const Color(0xFFF97316);
      case ThreatSeverity.medium:
        return AppConstants.warning;
      case ThreatSeverity.low:
        return AppConstants.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: mini ? 7 : 10,
        vertical: mini ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: c.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: mini ? 5 : 6,
            height: mini ? 5 : 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c,
              boxShadow: [
                BoxShadow(color: c.withValues(alpha: 0.7), blurRadius: 4),
              ],
            ),
          ),
          SizedBox(width: mini ? 4 : 6),
          Text(
            label,
            style: TextStyle(
              color: c,
              fontSize: mini ? 9 : 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

