import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    String? requestId,
    String? type,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'requestId': requestId,
        'type': type ?? 'info',
        'isRead': false,
        'createdAt': Timestamp.now(),
      });

      debugPrint('✅ [NotificationService] Notification created successfully');
    } on FirebaseException catch (e) {
      debugPrint('❌ [NotificationService] Error creating notification: ${e.code} ${e.message}');
      rethrow;
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserNotifications(String userId) {
    debugPrint('🔔 [NotificationService] getUserNotifications called with userId: "$userId"');
    
    if (userId.isEmpty) {
      debugPrint('⚠️ [NotificationService] Empty userId provided, returning empty stream');
      return const Stream.empty();
    }
    
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error, stackTrace) {
      debugPrint('❌ [NotificationService] Error in getUserNotifications stream: $error');
      debugPrint('Stack trace: $stackTrace');
    });
  }

  static Stream<int> getUnreadCount(String userId) {
    debugPrint('🔔 [NotificationService] getUnreadCount called with userId: "$userId"');
    
    if (userId.isEmpty) {
      debugPrint('⚠️ [NotificationService] Empty userId provided, returning 0 unread count');
      return Stream.value(0);
    }
    
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error, stackTrace) {
      debugPrint('❌ [NotificationService] Error in getUnreadCount stream: $error');
      debugPrint('Stack trace: $stackTrace');
      return 0;
    });
  }

  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });

      debugPrint('✅ [NotificationService] Notification marked as read');
    } on FirebaseException catch (e) {
      debugPrint('❌ [NotificationService] Error marking notification as read: ${e.code} ${e.message}');
      rethrow;
    }
  }

  static Future<void> markAllAsRead(String userId) async {
    debugPrint('🔔 [NotificationService] markAllAsRead called with userId: "$userId"');
    
    if (userId.isEmpty) {
      debugPrint('⚠️ [NotificationService] Empty userId provided, skipping markAllAsRead');
      return;
    }
    
    try {
      final unreadDocs = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      debugPrint('✅ [NotificationService] All notifications marked as read');
    } on FirebaseException catch (e) {
      debugPrint('❌ [NotificationService] Error marking all as read: ${e.code} ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ [NotificationService] Unexpected error marking all as read: $e');
      rethrow;
    }
  }

  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      debugPrint('✅ [NotificationService] Notification deleted');
    } on FirebaseException catch (e) {
      debugPrint('❌ [NotificationService] Error deleting notification: ${e.code} ${e.message}');
      rethrow;
    }
  }
}
