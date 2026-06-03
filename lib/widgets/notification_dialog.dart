import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class NotificationDialog extends StatelessWidget {
  const NotificationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.currentUser?.uid ?? '';
    debugPrint('🔔 [NotificationDialog] Building dialog with userId: "$userId"');

    // Mark all notifications as read when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (userId.isNotEmpty) {
        NotificationService.markAllAsRead(userId);
      } else {
        debugPrint('⚠️ [NotificationDialog] Skipping markAllAsRead due to empty userId');
      }
    });

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryOrange, AppTheme.primaryOrange.withOpacity(0.8)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await NotificationService.markAllAsRead(userId);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text(
                      'Mark all read',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Notifications list
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: NotificationService.getUserNotifications(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryOrange),
                    );
                  }

                  if (snapshot.hasError) {
                    debugPrint('❌ [NotificationDialog] Stream error: ${snapshot.error}');
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  final notifications = snapshot.data?.docs ?? [];

                  if (userId.isEmpty) {
                    debugPrint('⚠️ [NotificationDialog] Showing not logged in state');
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login_rounded, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Please log in to view notifications',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  if (notifications.isEmpty) {
                    debugPrint('🔔 [NotificationDialog] No notifications found');
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No notifications',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final doc = notifications[index];
                      final notification = doc.data();
                      final isRead = notification['isRead'] as bool? ?? false;
                      final title = notification['title'] as String? ?? '';
                      final message = notification['message'] as String? ?? '';
                      final createdAt = notification['createdAt'] as Timestamp?;
                      final type = notification['type'] as String? ?? 'info';

                      return _buildNotificationCard(
                        context,
                        doc.id,
                        title,
                        message,
                        createdAt,
                        isRead,
                        type,
                        userId,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    String notificationId,
    String title,
    String message,
    Timestamp? createdAt,
    bool isRead,
    String type,
    String userId,
  ) {
    final icon = _getNotificationIcon(type);
    final iconColor = _getNotificationColor(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? Colors.grey.shade200 : AppTheme.primaryOrange.withOpacity(0.3),
          width: isRead ? 1 : 2,
        ),
        boxShadow: isRead
            ? null
            : [
                BoxShadow(
                  color: AppTheme.primaryOrange.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (createdAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(createdAt.toDate()),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'request':
        return Icons.request_quote_rounded;
      case 'pickup':
        return Icons.local_shipping_rounded;
      case 'rating':
        return Icons.star_rounded;
      case 'approval':
        return Icons.check_circle_rounded;
      case 'info':
      default:
        return Icons.info_rounded;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'request':
        return AppTheme.primaryOrange;
      case 'pickup':
        return Colors.blue;
      case 'rating':
        return Colors.amber;
      case 'approval':
        return AppTheme.primaryGreen;
      case 'info':
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
