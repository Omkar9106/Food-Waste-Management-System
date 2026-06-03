import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/donation_service.dart';
import '../theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    final donorId = AuthService.currentUser?.uid ?? '';
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 380;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Donation Analytics',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryGreen,
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildOverviewCards(donorId, isSmallScreen),
              const SizedBox(height: 24),
              _buildRequestStats(donorId, isSmallScreen),
              const SizedBox(height: 24),
              _buildMonthlyStats(donorId, isSmallScreen),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards(String donorId, bool isSmallScreen) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: DonationService.donorDonationsStream(donorId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
        }

        final donations = snapshot.data!.docs;
        int totalDonations = donations.length;
        int totalQuantity = 0;

        for (var doc in donations) {
          final quantity = (doc.data()['quantity'] as num?)?.toInt() ?? 0;
          totalQuantity += quantity;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.volunteer_activism_rounded,
                    title: 'Total Donations',
                    value: totalDonations.toString(),
                    color: AppTheme.primaryGreen,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.scale_rounded,
                    title: 'Total Quantity',
                    value: '$totalQuantity kg',
                    color: AppTheme.primaryOrange,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildRequestStats(String donorId, bool isSmallScreen) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: DonationService.donorRequestsStream(donorId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
        }

        final requests = snapshot.data!.docs;
        int approved = 0;
        int rejected = 0;
        int pending = 0;

        for (var doc in requests) {
          final status = doc.data()['status']?.toString().toLowerCase() ?? '';
          if (status == 'approved') {
            approved++;
          } else if (status == 'rejected') {
            rejected++;
          } else {
            pending++;
          }
        }

        final total = approved + rejected + pending;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Request Status',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Container(
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
                children: [
                  _buildProgressBar(
                    label: 'Approved',
                    value: approved,
                    total: total,
                    color: AppTheme.primaryGreen,
                  ),
                  const SizedBox(height: 12),
                  _buildProgressBar(
                    label: 'Pending',
                    value: pending,
                    total: total,
                    color: AppTheme.primaryOrange,
                  ),
                  const SizedBox(height: 12),
                  _buildProgressBar(
                    label: 'Rejected',
                    value: rejected,
                    total: total,
                    color: AppTheme.error,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMonthlyStats(String donorId, bool isSmallScreen) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: DonationService.donorDonationsStream(donorId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
        }

        final donations = snapshot.data!.docs;
        final monthlyData = <String, int>{};

        for (var doc in donations) {
          final timestamp = doc.data()['createdAt'] as Timestamp?;
          if (timestamp != null) {
            final date = timestamp.toDate();
            final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
            monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + 1;
          }
        }

        final sortedMonths = monthlyData.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Donations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            if (sortedMonths.isEmpty)
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
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
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.bar_chart_rounded, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No data yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
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
                  children: [
                    ...sortedMonths.map((entry) {
                      final maxValue = sortedMonths.map((e) => e.value).reduce((a, b) => a > b ? a : b);
                      final percentage = maxValue > 0 ? (entry.value / maxValue) * 100 : 0;
                      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                      final parts = entry.key.split('-');
                      final monthLabel = parts.length >= 2 ? monthNames[int.parse(parts[1]) - 1] : entry.key;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$monthLabel ${parts[0]}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  '${entry.value} donations',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isSmallScreen,
  }) {
    return Container(
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar({
    required String label,
    required int value,
    required int total,
    required Color color,
  }) {
    final percentage = total > 0 ? (value / total) * 100 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              '$value (${percentage.toStringAsFixed(0)}%)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
          ),
        ),
      ],
    );
  }
}
