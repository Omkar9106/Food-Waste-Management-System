import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/donation_service.dart';

/// Donor view: NGO requests for this donor's donations.
class NgoRequestsScreen extends StatefulWidget {
  const NgoRequestsScreen({super.key});

  @override
  State<NgoRequestsScreen> createState() => _NgoRequestsScreenState();
}

class _NgoRequestsScreenState extends State<NgoRequestsScreen> {
  @override
  Widget build(BuildContext context) {
    final donorId = AuthService.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'NGO Requests',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFC9A227),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C1810), Color(0xFF4A3728), Color(0xFF6B4423)],
          ),
        ),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: DonationService.donorRequestsStream(donorId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFC9A227)),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            final requests = DonationService.sortByCreatedAt(
              snapshot.data?.docs ?? [],
            );

            if (requests.isEmpty) {
              return const Center(
                child: Text(
                  'No NGO requests yet.',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final doc = requests[index];
                final request = doc.data();
                final requestId = doc.id;
                final donationId = request['donationId']?.toString() ?? '';

                final name = DonationService.readName(request);
                final quantity = DonationService.parseQuantity(request['quantity']) ?? 0;
                final location = request['location']?.toString() ?? '';
                final donorEmail = request['donorEmail']?.toString() ?? '';
                final ngoEmail = request['ngoEmail']?.toString() ?? 'Unknown NGO';
                final status = request['status']?.toString() ?? 'Pending';

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _statusChip(status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('NGO: $ngoEmail', style: _subtitleStyle),
                        const SizedBox(height: 4),
                        Text('Quantity: $quantity kg/units', style: _subtitleStyle),
                        if (location.isNotEmpty)
                          Text('Location: $location', style: _subtitleStyle),
                        if (donorEmail.isNotEmpty)
                          Text('Donor: $donorEmail', style: _subtitleStyle),
                        if (status == 'Pending') ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _approve(
                                    context,
                                    requestId,
                                    donationId,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF047857),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Approve'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _reject(context, requestId),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                  ),
                                  child: const Text('Reject'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  static const _subtitleStyle = TextStyle(
    fontSize: 13,
    color: Color(0xFF475569),
  );

  Widget _statusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        color = const Color(0xFF047857);
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = const Color(0xFFC9A227);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Future<void> _approve(
    BuildContext context,
    String requestId,
    String donationId,
  ) async {
    if (donationId.isEmpty) return;
    try {
      await DonationService.approveRequest(
        requestId: requestId,
        donationId: donationId,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request approved'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _reject(BuildContext context, String requestId) async {
    try {
      await DonationService.rejectRequest(requestId: requestId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
