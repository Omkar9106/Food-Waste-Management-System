import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/donation_service.dart';
import '../services/rating_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class PickupStatusScreen extends StatefulWidget {
  const PickupStatusScreen({super.key});

  @override
  State<PickupStatusScreen> createState() => _PickupStatusScreenState();
}

class _PickupStatusScreenState extends State<PickupStatusScreen> {
  final Set<String> _updatingIds = {};

  final List<String> _statusTimeline = [
    'Request Sent',
    'Approved',
    'On The Way',
    'Picked Up',
    'Completed',
  ];

  @override
  Widget build(BuildContext context) {
    final ngoId = AuthService.currentUser?.uid ?? '';
    final ngoEmail = AuthService.currentUser?.email ?? '';
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 380;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Pickup Status',
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
        child: StreamBuilder(
          stream: DonationService.ngoRequestsStream(ngoId),
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
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final activePickups = DonationService.sortByCreatedAt(
              (snapshot.data?.docs ?? []).where((doc) {
                final request = doc.data();
                final status = request['status']?.toString() ?? '';
                final pickupStatus = request['pickupStatus']?.toString() ?? '';
                return status == 'Approved' && pickupStatus != 'Delivered';
              }).toList(),
            );

            if (activePickups.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No active pickups',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              itemCount: activePickups.length,
              itemBuilder: (context, index) {
                final doc = activePickups[index];
                final request = doc.data();
                final requestId = doc.id;

                final name = DonationService.readName(request);
                final quantity = DonationService.parseQuantity(request['quantity']) ?? 0;
                final location = request['location']?.toString() ?? '';
                final donorEmail = request['donorEmail']?.toString() ?? '';
                final donorId = request['donorId']?.toString() ?? '';
                final pickupStatus = request['pickupStatus']?.toString() ?? 'Scheduled';
                final createdAt = request['createdAt'] as Timestamp?;
                final updatedAt = request['updatedAt'] as Timestamp?;
                final progress = DonationService.pickupProgress(pickupStatus);
                final nextStatus = DonationService.nextPickupStatus(pickupStatus);
                final statusColor = _pickupColor(pickupStatus);
                final isUpdating = _updatingIds.contains(requestId);
                final currentStepIndex = _getCurrentStepIndex(pickupStatus);

                return Padding(
                  padding: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
                  child: Container(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with name and status badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 18 : 20,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Quantity: $quantity kg/units',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 13 : 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 10 : 12,
                                vertical: isSmallScreen ? 6 : 8,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getStatusIcon(pickupStatus),
                                    size: isSmallScreen ? 14 : 16,
                                    color: statusColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    pickupStatus,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 11 : 12,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Info chips
                        _buildInfoChip(Icons.location_on_rounded, 'Location', location, isSmallScreen),
                        const SizedBox(height: 8),
                        _buildInfoChip(Icons.person_rounded, 'Donor', donorEmail, isSmallScreen),
                        const SizedBox(height: 8),
                        _buildInfoChip(Icons.business_rounded, 'NGO', ngoEmail, isSmallScreen),
                        
                        if (createdAt != null || updatedAt != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (createdAt != null) ...[
                                Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  'Created: ${_formatDate(createdAt.toDate())}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                ),
                              ],
                              if (createdAt != null && updatedAt != null) const SizedBox(width: 12),
                              if (updatedAt != null) ...[
                                Icon(Icons.update_rounded, size: 14, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  'Updated: ${_formatDate(updatedAt.toDate())}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                ),
                              ],
                            ],
                          ),
                        ],
                        
                        const SizedBox(height: 20),
                        
                        // Status Timeline
                        _buildStatusTimeline(currentStepIndex, statusColor, isSmallScreen),
                        
                        const SizedBox(height: 20),
                        
                        // Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                            minHeight: 8,
                          ),
                        ),
                        
                        if (nextStatus != null) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isUpdating
                                  ? null
                                  : () => _advancePickup(requestId, nextStatus, donorId, donorEmail),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryOrange,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isUpdating
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Mark as $nextStatus',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 14 : 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
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

  Widget _buildInfoChip(IconData icon, String label, String value, bool isSmallScreen) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: isSmallScreen ? 16 : 18, color: AppTheme.primaryOrange),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 11,
                  color: Colors.grey.shade500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTimeline(int currentStepIndex, Color statusColor, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status Timeline',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_statusTimeline.length, (index) {
          final isCompleted = index < currentStepIndex;
          final isCurrent = index == currentStepIndex;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                // Step indicator
                Container(
                  width: isSmallScreen ? 28 : 32,
                  height: isSmallScreen ? 28 : 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted || isCurrent ? statusColor : Colors.grey.shade300,
                    border: Border.all(
                      color: isCompleted || isCurrent ? statusColor : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(Icons.check_rounded, size: isSmallScreen ? 14 : 16, color: Colors.white)
                        : isCurrent
                            ? Icon(Icons.circle_rounded, size: isSmallScreen ? 8 : 10, color: Colors.white)
                            : Icon(Icons.circle_outlined, size: isSmallScreen ? 14 : 16, color: Colors.grey.shade400),
                  ),
                ),
                const SizedBox(width: 12),
                // Step label
                Expanded(
                  child: Text(
                    _statusTimeline[index],
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted || isCurrent ? const Color(0xFF0F172A) : Colors.grey.shade400,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  int _getCurrentStepIndex(String pickupStatus) {
    switch (pickupStatus) {
      case 'Pending Approval':
        return 0;
      case 'Scheduled':
      case 'Approved':
        return 1;
      case 'Out for Delivery':
        return 2;
      case 'Picked Up':
        return 3;
      case 'Delivered':
      case 'Completed':
        return 4;
      default:
        return 0;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending Approval':
        return Icons.pending_rounded;
      case 'Scheduled':
      case 'Approved':
        return Icons.event_available_rounded;
      case 'Out for Delivery':
        return Icons.local_shipping_rounded;
      case 'Picked Up':
        return Icons.inventory_2_rounded;
      case 'Delivered':
      case 'Completed':
        return Icons.check_circle_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _advancePickup(String requestId, String nextStatus, String donorId, String donorEmail) async {
    // Show confirmation if marking as completed
    if (nextStatus == 'Delivered' || nextStatus == 'Completed') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Pickup Completion'),
          content: const Text('Are you sure you want to mark this pickup as completed?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    setState(() => _updatingIds.add(requestId));
    try {
      await DonationService.updatePickupStatus(
        requestId: requestId,
        pickupStatus: nextStatus,
      );

      // Create notification for donor
      await NotificationService.createNotification(
        userId: donorId,
        title: 'Pickup Status Updated',
        message: 'Your pickup status has been updated to: $nextStatus',
        requestId: requestId,
        type: 'pickup',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $nextStatus'),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Prompt for rating after completion
        if (nextStatus == 'Delivered' || nextStatus == 'Completed') {
          _showRatingPrompt(requestId, donorId, donorEmail);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingIds.remove(requestId));
    }
  }

  void _showRatingPrompt(String requestId, String donorId, String donorEmail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Your Experience'),
        content: const Text('Would you like to rate the donor for this pickup?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/submit_rating',
                arguments: {
                  'requestId': requestId,
                  'toUserId': donorId,
                  'toUserRole': 'Donor',
                  'toUserName': donorEmail,
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rate Now'),
          ),
        ],
      ),
    );
  }

  Color _pickupColor(String status) {
    switch (status) {
      case 'Pending Approval':
        return Colors.grey;
      case 'Scheduled':
      case 'Approved':
        return AppTheme.primaryOrange;
      case 'Out for Delivery':
        return Colors.blue;
      case 'Picked Up':
        return AppTheme.primaryGreen;
      case 'Delivered':
      case 'Completed':
        return const Color(0xFF047857);
      default:
        return Colors.grey;
    }
  }
}
