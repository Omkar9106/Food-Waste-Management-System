import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DonationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Stream<QuerySnapshot<Map<String, dynamic>>> availableDonationsStream() {
    return _firestore
        .collection('donations')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> donorDonationsStream(
    String donorId,
  ) {
    if (donorId.isEmpty) {
      return Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return _firestore
        .collection('donations')
        .where('donorId', isEqualTo: donorId)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> donorRequestsStream(
    String donorId,
  ) {
    if (donorId.isEmpty) {
      return Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return _firestore
        .collection('requests')
        .where('donorId', isEqualTo: donorId)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> ngoRequestsStream(
    String ngoId,
  ) {
    if (ngoId.isEmpty) {
      return Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return _firestore
        .collection('requests')
        .where('ngoId', isEqualTo: ngoId)
        .snapshots();
  }

  static Stream<Map<String, dynamic>> donorStatsStream(String donorId) {
    if (donorId.isEmpty) {
      return Stream.value({
        'totalDonations': 0,
        'totalFoodSaved': 0,
        'ngosHelped': 0,
        'rewardPoints': 0,
      });
    }

    return _firestore
        .collection('donations')
        .where('donorId', isEqualTo: donorId)
        .snapshots()
        .map((snapshot) {
      int totalDonations = snapshot.docs.length;
      int totalFoodSaved = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalFoodSaved += parseQuantity(data['quantity']) ?? 0;
      }

      return {
        'totalDonations': totalDonations,
        'totalFoodSaved': totalFoodSaved,
        'ngosHelped': 0,
        'rewardPoints': totalDonations * 10,
      };
    });
  }

  static Future<void> addDonation({
    required String donorId,
    required String donorEmail,
    required String name,
    required int quantity,
    required String location,
    required String status,
    String description = '',
    double? latitude,
    double? longitude,
    DateTime? expiryTime,
  }) async {
    try {
      final donationData = {
        'donorId': donorId,
        'donorEmail': donorEmail,
        'name': name.trim(),
        'quantity': quantity,
        'location': location.trim(),
        'status': status,
        'description': description.trim(),
        'createdAt': Timestamp.now(),
      };

      if (latitude != null && longitude != null) {
        donationData['latitude'] = latitude;
        donationData['longitude'] = longitude;
      }

      if (expiryTime != null) {
        donationData['expiryTime'] = Timestamp.fromDate(expiryTime);
      }

      await _firestore.collection('donations').add(donationData);
    } on FirebaseException catch (e) {
      debugPrint('❌ [DonationService] addDonation: ${e.code} ${e.message}');
      rethrow;
    }
  }

  /// Loads donation from Firestore and saves a full copy on the request document.
  static Future<void> createFoodRequest({
    required String donationId,
    required String ngoId,
    required String ngoEmail,
  }) async {
    final donation = await getDonationDetails(donationId);
    if (donation == null) {
      throw Exception('Donation not found. It may have been removed.');
    }

    final donorId = donation['donorId']?.toString() ?? '';
    if (donorId.isEmpty) {
      throw Exception('Donation is missing donor information.');
    }

    final requestData = {
      'donationId': donationId,
      'donorId': donorId,
      'ngoId': ngoId,
      'ngoEmail': ngoEmail,
      'name': donation['name']?.toString() ?? '',
      'quantity': parseQuantity(donation['quantity']) ?? 0,
      'location': donation['location']?.toString() ?? '',
      'donorEmail': donation['donorEmail']?.toString() ?? '',
      'status': 'Pending',
      'pickupStatus': 'Pending Approval',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };

    await _firestore.collection('requests').add(requestData);
  }

  static Future<void> approveRequest({
    required String requestId,
    required String donationId,
  }) async {
    await _firestore.collection('requests').doc(requestId).update({
      'status': 'Approved',
      'pickupStatus': 'Scheduled',
      'updatedAt': Timestamp.now(),
    });

    await _firestore.collection('donations').doc(donationId).update({
      'status': 'Reserved',
      'updatedAt': Timestamp.now(),
    });
  }

  static Future<void> rejectRequest({required String requestId}) async {
    await _firestore.collection('requests').doc(requestId).update({
      'status': 'Rejected',
      'updatedAt': Timestamp.now(),
    });
  }

  static Future<Map<String, dynamic>?> getDonationDetails(String donationId) async {
    try {
      final doc = await _firestore.collection('donations').doc(donationId).get();
      return doc.data();
    } catch (e) {
      debugPrint('❌ [DonationService] getDonationDetails: $e');
      return null;
    }
  }

  static Future<void> updatePickupStatus({
    required String requestId,
    required String pickupStatus,
  }) async {
    await _firestore.collection('requests').doc(requestId).update({
      'pickupStatus': pickupStatus,
      'updatedAt': Timestamp.now(),
    });

    if (pickupStatus == 'Delivered') {
      final requestDoc =
          await _firestore.collection('requests').doc(requestId).get();
      final donationId = requestDoc.data()?['donationId']?.toString();
      if (donationId != null && donationId.isNotEmpty) {
        await _firestore.collection('donations').doc(donationId).update({
          'status': 'Delivered',
          'updatedAt': Timestamp.now(),
        });
      }
    }
  }

  /// Food title from a request or donation map (field is always [name]).
  static String readName(Map<String, dynamic> data) {
    final value = data['name']?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
    return 'Food Item';
  }

  static int? parseQuantity(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static List<QueryDocumentSnapshot<Map<String, dynamic>>> sortByCreatedAt(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final sorted = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(docs);
    sorted.sort((a, b) {
      final aTime = a.data()['createdAt'] as Timestamp?;
      final bTime = b.data()['createdAt'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return bTime.compareTo(aTime);
    });
    return sorted;
  }

  static String timeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final difference = DateTime.now().difference(timestamp.toDate());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours} hr ago';
    return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
  }

  static double pickupProgress(String? pickupStatus) {
    switch (pickupStatus) {
      case 'Scheduled':
        return 0.25;
      case 'Picked Up':
        return 0.5;
      case 'Out for Delivery':
        return 0.75;
      case 'Delivered':
        return 1.0;
      default:
        return 0.0;
    }
  }

  static String? nextPickupStatus(String? current) {
    switch (current) {
      case 'Scheduled':
        return 'Picked Up';
      case 'Picked Up':
        return 'Out for Delivery';
      case 'Out for Delivery':
        return 'Delivered';
      default:
        return null;
    }
  }
}
