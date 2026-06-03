import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ExpiryBadge extends StatelessWidget {
  final DateTime expiryTime;
  final bool showCountdown;

  const ExpiryBadge({
    super.key,
    required this.expiryTime,
    this.showCountdown = false,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final difference = expiryTime.difference(now);
    final isExpired = difference.isNegative;
    final isWarning = !isExpired && difference.inHours < 24;

    Color badgeColor;
    String label;
    IconData icon;

    if (isExpired) {
      badgeColor = AppTheme.error;
      label = 'Expired';
      icon = Icons.cancel_rounded;
    } else if (isWarning) {
      badgeColor = AppTheme.warning;
      label = 'Expiring Soon';
      icon = Icons.warning_rounded;
    } else {
      badgeColor = AppTheme.primaryGreen;
      label = 'Fresh';
      icon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: badgeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: badgeColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (showCountdown && !isExpired) ...[
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 14,
              color: badgeColor.withOpacity(0.3),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDuration(difference),
              style: TextStyle(
                color: badgeColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}
