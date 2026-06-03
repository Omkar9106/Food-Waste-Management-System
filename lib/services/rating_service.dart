import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class RatingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> submitRating({
    required String requestId,
    required String fromUserId,
    required String toUserId,
    required String fromUserRole,
    required String toUserRole,
    required int rating,
    String? feedback,
  }) async {
    try {
      await _firestore.collection('ratings').add({
        'requestId': requestId,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'fromUserRole': fromUserRole,
        'toUserRole': toUserRole,
        'rating': rating,
        'feedback': feedback ?? '',
        'createdAt': Timestamp.now(),
      });

      debugPrint('✅ [RatingService] Rating submitted successfully');
    } on FirebaseException catch (e) {
      debugPrint('❌ [RatingService] Error submitting rating: ${e.code} ${e.message}');
      rethrow;
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserRatings(String userId) {
    return _firestore
        .collection('ratings')
        .where('toUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Stream<Map<String, dynamic>> getUserRatingStats(String userId) {
    return _firestore
        .collection('ratings')
        .where('toUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalRatings': 0,
        };
      }

      double totalRating = 0;
      for (var doc in snapshot.docs) {
        final rating = doc.data()['rating'] as int? ?? 0;
        totalRating += rating;
      }

      final averageRating = totalRating / snapshot.docs.length;

      return {
        'averageRating': averageRating,
        'totalRatings': snapshot.docs.length,
      };
    });
  }

  static Future<bool> hasRated(String requestId, String fromUserId) async {
    try {
      final snapshot = await _firestore
          .collection('ratings')
          .where('requestId', isEqualTo: requestId)
          .where('fromUserId', isEqualTo: fromUserId)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ [RatingService] Error checking rating status: $e');
      return false;
    }
  }

  static Stream<bool> hasRatedStream(String requestId, String fromUserId) {
    return _firestore
        .collection('ratings')
        .where('requestId', isEqualTo: requestId)
        .where('fromUserId', isEqualTo: fromUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }
}
