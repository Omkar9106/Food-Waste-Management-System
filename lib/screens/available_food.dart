import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/donation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/expiry_badge.dart';

class AvailableFoodScreen extends StatefulWidget {
  const AvailableFoodScreen({super.key});

  @override
  State<AvailableFoodScreen> createState() => _AvailableFoodScreenState();
}

class _AvailableFoodScreenState extends State<AvailableFoodScreen> {
  @override
  Widget build(BuildContext context) {
    final ngoId = AuthService.currentUser?.uid ?? '';
    final ngoEmail = AuthService.currentUser?.email ?? '';
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Available Food',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryOrange,
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
          stream: DonationService.availableDonationsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryOrange),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Error loading donations: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final donations = (snapshot.data?.docs ?? []).where((doc) {
              final status = doc.data()['status']?.toString() ?? '';
              final expiryTime = doc.data()['expiryTime'] as Timestamp?;
              
              // Filter out reserved donations
              if (status == 'Reserved') return false;
              
              // Filter out expired donations
              if (expiryTime != null) {
                final now = DateTime.now();
                final expiry = expiryTime.toDate();
                if (expiry.isBefore(now)) return false;
              }
              
              return true;
            }).toList();
            
            if (donations.isEmpty) {
              return EmptyState(
                icon: Icons.restaurant_rounded,
                title: 'No food available yet',
                subtitle: 'Check back soon for new donations from donors',
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              itemCount: donations.length,
              itemBuilder: (context, index) {
                final donation = donations[index].data();
                final donationId = donations[index].id;
                final donorEmail = donation['donorEmail']?.toString() ?? 'Unknown';
                final name = DonationService.readName(donation);
                final quantity = (donation['quantity'] as num?)?.toInt() ?? 0;
                final location = donation['location']?.toString() ?? 'Unknown';
                final status = donation['status']?.toString() ?? 'Pending';
                final description = donation['description']?.toString() ?? '';
                final donorId = donation['donorId']?.toString() ?? '';
                final expiryTime = donation['expiryTime'] as Timestamp?;

                return Padding(
                  padding: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 300 + index * 60),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 16 : 18,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Donor: $donorEmail',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 11 : 12,
                                          color: const Color(0xFF475569),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 8 : 12,
                                        vertical: isSmallScreen ? 4 : 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 10 : 11,
                                          fontWeight: FontWeight.bold,
                                          color: _statusColor(status),
                                        ),
                                      ),
                                    ),
                                    if (expiryTime != null) ...[
                                      const SizedBox(height: 6),
                                      ExpiryBadge(
                                        expiryTime: expiryTime.toDate(),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoChip(
                                    Icons.scale_rounded,
                                    'Quantity',
                                    '$quantity kg/units',
                                    isSmallScreen,
                                  ),
                                ),
                                SizedBox(width: isSmallScreen ? 8 : 12),
                                Expanded(
                                  child: _buildInfoChip(
                                    Icons.location_on_rounded,
                                    'Location',
                                    location,
                                    isSmallScreen,
                                  ),
                                ),
                              ],
                            ),
                            if (description.isNotEmpty) ...[
                              SizedBox(height: isSmallScreen ? 8 : 12),
                              Text(
                                'Notes:',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 12,
                                  color: const Color(0xFF64748B),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            SizedBox(height: isSmallScreen ? 12 : 16),
                            SizedBox(
                              width: double.infinity,
                              height: isSmallScreen ? 44 : 52,
                              child: ElevatedButton.icon(
                                onPressed: status == 'Reserved'
                                    ? null
                                    : () => _requestFood(
                                          donationId,
                                          ngoId,
                                          ngoEmail,
                                          name,
                                        ),
                                icon: Icon(Icons.favorite_outline_rounded, size: isSmallScreen ? 18 : 20),
                                label: Text(
                                  status == 'Reserved' ? 'Already Reserved' : 'Request Food',
                                  style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryOrange,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey,
                                  padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildInfoChip(IconData icon, String label, String value, [bool isSmallScreen = false]) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: isSmallScreen ? 12 : 14, color: AppTheme.primaryOrange),
              SizedBox(width: isSmallScreen ? 4 : 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 9 : 10,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 2 : 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'reserved':
        return AppTheme.primaryBrown;
      case 'delivered':
        return AppTheme.success;
      case 'pending':
      default:
        return AppTheme.primaryOrange;
    }
  }

  void _requestFood(
    String donationId,
    String ngoId,
    String ngoEmail,
    String name,
  ) async {
    if (ngoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in again to request food.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await DonationService.createFoodRequest(
        donationId: donationId,
        ngoId: ngoId,
        ngoEmail: ngoEmail,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request sent for $name'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

