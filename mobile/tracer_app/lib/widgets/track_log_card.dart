import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/track_log.dart';
import '../utils/helpers.dart';

class TrackLogCard extends StatelessWidget {
  final TrackLog log;
  final int index;

  const TrackLogCard({super.key, required this.log, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.cardBg,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppConstants.success.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: AppConstants.dangerGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Hit #$index',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              Icon(Icons.location_on, color: AppConstants.danger, size: 14),
              const SizedBox(width: 4),
              Text(
                log.locationDisplay,
                style: const TextStyle(
                    color: AppConstants.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _row(Icons.language, 'IP Address', Helpers.maskIp(log.ipAddress)),
          _row(Icons.phone_android, 'Device', log.deviceType ?? 'Unknown'),
          _row(Icons.web, 'Browser', log.browser ?? 'Unknown'),
          _row(Icons.computer, 'OS', log.os ?? 'Unknown'),
          _row(Icons.access_time, 'Clicked At', Helpers.formatDate(log.clickedAt)),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppConstants.accent),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style:
                const TextStyle(color: AppConstants.textSecondary, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: AppConstants.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
