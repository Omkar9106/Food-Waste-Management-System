import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/donation_service.dart';
import '../services/rating_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../main.dart';
import '../widgets/expiry_badge.dart';
import '../widgets/star_rating.dart';
import '../widgets/notification_dialog.dart';

class DonorDashboard extends StatefulWidget {
  const DonorDashboard({super.key});

  @override
  State<DonorDashboard> createState() => _DonorDashboardState();
}

class _DonorDashboardState extends State<DonorDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  String donorName = 'Donor';
  String userEmail = '';
  String donorLocation = 'Greenfields Community, Sector 45';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final email = await StorageService.getUserEmail();
    if (mounted && email != null) {
      setState(() {
        userEmail = email;
        // Generate a friendly name from email if name is not explicitly saved
        final namePart = email.split('@')[0];
        donorName = namePart[0].toUpperCase() + namePart.substring(1);
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C1810), Color(0xFF4A3728), Color(0xFF6B4423)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 20,
            ),
            child: FadeTransition(
              opacity: _fadeController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top App Bar with Gradient Header
                  _buildGradientHeader(),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const SizedBox(height: 20),

                    // 2. Donor Info Card
                    _buildDonorInfoCard(),

                    const SizedBox(height: 24),

                    // Section Title: Stats Overview
                    _buildSectionHeader('Stats Overview', null),
                    const SizedBox(height: 12),

                    // 3. Stats Row (4 Compact Cards)
                    _buildStatsRow(isWideScreen),

                    const SizedBox(height: 24),

                    // Section Title: Quick Actions
                    _buildSectionHeader('Quick Actions', null),
                    const SizedBox(height: 12),

                    // 4. Main Action Grid (4 Large Cards)
                    _buildActionGrid(context, isWideScreen),

                    const SizedBox(height: 28),

                    // Section Title: Recent Donations
                    _buildSectionHeader('Recent Donations', () {
                      Navigator.pushNamed(context, '/donations_list');
                    }),
                    const SizedBox(height: 12),

                    // 5. Recent Donations Section with Progress Chips
                    _buildRecentDonationsList(),

                    const SizedBox(height: 28),

                    // Section Title: Requests from NGOs
                    _buildSectionHeader('Requests from NGOs', null),
                    const SizedBox(height: 12),

                    // 6. NGO Requests Section
                    _buildNgoRequestsList(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    ));
  }

  // --- 1. Top App Bar with Gradient Header ---
  Widget _buildGradientHeader() {
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 600;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC8860A), Color(0xFFF5A623)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          size.width * 0.05,
          size.height * 0.03,
          size.width * 0.05,
          size.height * 0.04,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xCCFFFFFF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Good Morning, $donorName',
                  style: TextStyle(
                    fontSize: isWideScreen ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                StreamBuilder<int>(
                  stream: NotificationService.getUnreadCount(AuthService.currentUser?.uid ?? ''),
                  builder: (context, snapshot) {
                    final unreadCount = snapshot.data ?? 0;

                    return Stack(
                      children: [
                        Container(
                          width: isWideScreen ? 40 : 36,
                          height: isWideScreen ? 40 : 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            onPressed: () {
                              final userId = AuthService.currentUser?.uid ?? '';
                              debugPrint('🔔 [DonorDashboard] Notification bell pressed with userId: "$userId"');
                              showDialog(
                                context: context,
                                builder: (context) => NotificationDialog(),
                              ).then((_) {
                                debugPrint('🔔 [DonorDashboard] Notification dialog closed');
                                setState(() {}); // Refresh to update badge
                              });
                            },
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                              child: Text(
                                unreadCount > 9 ? '9+' : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: _showLogoutDialog,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. Donor Info Card ---
  Widget _buildDonorInfoCard() {
    final donorId = AuthService.currentUser?.uid ?? '';

    return Transform.translate(
      offset: const Offset(0, -18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Avatar with initials
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A623),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF5A623).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    donorName.substring(0, donorName.length > 1 ? 2 : 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Text Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          donorName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E2723),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Small Status chip/badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified, size: 12, color: Colors.white),
                              const SizedBox(width: 2),
                              const Text(
                                'Verified',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            userEmail.isNotEmpty ? userEmail : 'donor@example.com',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    StreamBuilder<Map<String, dynamic>>(
                      stream: RatingService.getUserRatingStats(donorId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox.shrink();
                        }
                        final stats = snapshot.data!;
                        final averageRating = stats['averageRating'] as double? ?? 0.0;
                        final totalRatings = stats['totalRatings'] as int? ?? 0;

                        if (totalRatings == 0) {
                          return const SizedBox.shrink();
                        }

                        return RatingDisplay(
                          averageRating: averageRating,
                          totalRatings: totalRatings,
                          size: 14,
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            donorLocation,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 3. Stats Row (4 Compact Cards) ---
  Widget _buildStatsRow(bool isWideScreen) {
    final user = AuthService.currentUser;
    final donorId = user?.uid ?? '';

    return StreamBuilder<Map<String, dynamic>>(
      stream: DonationService.donorStatsStream(donorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading stats'));
        }

        final statsData = snapshot.data ?? {
          'totalDonations': 0,
          'totalFoodSaved': 0,
          'ngosHelped': 0,
          'rewardPoints': 0,
        };

        final totalDonations = statsData['totalDonations'] as int;
        final totalFoodSaved = statsData['totalFoodSaved'] as int;
        final ngosHelped = statsData['ngosHelped'] as int;
        final rewardPoints = statsData['rewardPoints'] as int;

        // 4 Stat definitions
        final stats = [
          {'value': '$totalDonations', 'label': 'Donations', 'icon': Icons.favorite_rounded, 'color': const Color(0xFF800020)},
          {'value': '$totalFoodSaved kg', 'label': 'Saved Food', 'icon': Icons.eco_rounded, 'color': const Color(0xFFC9A227)},
          {'value': '$ngosHelped', 'label': 'NGOs Helped', 'icon': Icons.handshake_rounded, 'color': const Color(0xFF1E3A5F)},
          {'value': '$rewardPoints', 'label': 'Reward Points', 'icon': Icons.stars_rounded, 'color': const Color(0xFFD4A574)},
        ];

        if (isWideScreen) {
          return Row(
            children: stats.map((stat) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: _buildSingleStatCard(
                  stat['value'] as String,
                  stat['label'] as String,
                  stat['icon'] as IconData,
                  stat['color'] as Color,
                ),
              ),
            )).toList(),
          );
        } else {
          // 2x2 grid for standard mobile portrait
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              final stat = stats[index];
              return _buildSingleStatCard(
                stat['value'] as String,
                stat['label'] as String,
                stat['icon'] as IconData,
                stat['color'] as Color,
              );
            },
          );
        }
      },
    );
  }

  Widget _buildSingleStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          // Value & Label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E2723),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. Main Action Grid (4 Large Cards) ---
  Widget _buildActionGrid(BuildContext context, bool isWideScreen) {
    final actions = [
      {
        'title': 'Add Food',
        'desc': 'Donate surplus food items',
        'icon': Icons.add_circle_outline_rounded,
        'color': const Color(0xFFC9A227),
        'route': '/add_food',
        'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
      },
      {
        'title': 'My Donations',
        'desc': 'View your donation history',
        'icon': Icons.volunteer_activism_rounded,
        'color': const Color(0xFF8B4513),
        'route': '/donations_list',
        'image': 'https://images.unsplash.com/photo-1488459716781-31db52582fe9?w=400',
      },
      {
        'title': 'Requests',
        'desc': 'Respond to NGO food requests',
        'icon': Icons.handshake_outlined,
        'color': const Color(0xFF1E3A5F),
        'route': '/ngo_requests',
        'image': 'https://images.unsplash.com/photo-1509099836639-18ba1795216d?w=400',
      },
      {
        'title': 'Analytics',
        'desc': 'View donation statistics',
        'icon': Icons.bar_chart_rounded,
        'color': const Color(0xFF059669),
        'route': '/analytics',
        'image': 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=400',
      },
    ];

    // Use GridView for mobile (2x2), horizontal scroll for wide screens
    if (isWideScreen) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(actions.length, (index) {
            final act = actions[index];
            return Padding(
              padding: EdgeInsets.only(right: index < actions.length - 1 ? 16 : 0),
              child: SizedBox(
                width: 160,
                height: 160,
                child: _buildActionCard(act, index),
              ),
            );
          }),
        ),
      );
    } else {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          return _buildActionCard(actions[index], index);
        },
      );
    }
  }

  Widget _buildActionCard(Map<String, dynamic> act, int index) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.pushNamed(context, act['route'] as String);
          if (act['route'] == '/add_food' && result == true && mounted) {
            setState(() {});
          }
        },
        splashColor: Colors.white.withOpacity(0.3),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (act['color'] as Color).withOpacity(0.8),
                (act['color'] as Color),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Background image with dark overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    image: DecorationImage(
                      image: NetworkImage(act['image'] as String),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.4),
                        BlendMode.darken,
                      ),
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon in white circle
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: Icon(
                        act['icon'] as IconData,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    // Title and subtitle
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          act['title'] as String,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          act['desc'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 5. Recent Donations Section with Chips ---
  Widget _buildRecentDonationsList() {
    final donorId = AuthService.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: DonationService.donorDonationsStream(donorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 180,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text('Unable to load donations. Please try again.'),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Icon(Icons.restaurant_menu_rounded, size: 48, color: const Color(0xFFC9A227)),
                const SizedBox(height: 16),
                const Text(
                  'No donations yet.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first food donation and it will appear here instantly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        }

        final items = docs.take(3).toList();
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++)
                Column(
                  children: [
                    _buildDonationRowItem(
                      name: DonationService.readName(items[i].data()),
                      qty: '${items[i].data()['quantity'] ?? 0} kg/units',
                      status: items[i].data()['status'] as String? ?? 'Pending',
                      statusColor: _statusColor(items[i].data()['status'] as String? ?? 'Pending'),
                      time: _timeAgo(items[i].data()['createdAt'] as Timestamp?),
                      expiryTime: (items[i].data()['expiryTime'] as Timestamp?)?.toDate(),
                    ),
                    if (i < items.length - 1)
                      Divider(height: 1, color: Colors.grey.shade100, indent: 16, endIndent: 16),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const Color(0xFF8B4513);
      case 'ready for pickup':
        return const Color(0xFF1E3A5F);
      case 'pending':
      default:
        return const Color(0xFFC9A227);
    }
  }

  String _timeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final date = timestamp.toDate();
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours} hr ago';
    return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
  }

  Widget _buildDonationRowItem({
    required String name,
    required String qty,
    required String status,
    required Color statusColor,
    required String time,
    DateTime? expiryTime,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          // Left Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5E6D3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.restaurant_rounded,
              color: const Color(0xFF8B4513),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          // Title and Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E2723),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Quantity: $qty • $time',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status and Expiry Badges
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              if (expiryTime != null) ...[
                const SizedBox(height: 4),
                ExpiryBadge(
                  expiryTime: expiryTime,
                  showCountdown: true,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // --- Section Header Helper ---
  Widget _buildSectionHeader(String title, VoidCallback? onTrailingTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3E2723),
          ),
        ),
        if (onTrailingTap != null)
          TextButton(
            onPressed: onTrailingTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'See All',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Color(0xFF8B4513),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // --- 6. NGO Requests Section ---
  Widget _buildNgoRequestsList() {
    final donorId = AuthService.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: DonationService.donorRequestsStream(donorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 180,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text('Unable to load requests.'),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Icon(Icons.mail_outline_rounded, size: 48, color: const Color(0xFFC9A227)),
                const SizedBox(height: 16),
                const Text(
                  'No requests yet.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'NGOs will request your donations here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        }

        final items = DonationService.sortByCreatedAt(docs).take(3).toList();
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++)
                Column(
                  children: [
                    _buildRequestRowItem(
                      requestId: items[i].id,
                      donationId: items[i].data()['donationId']?.toString() ?? '',
                      name: DonationService.readName(items[i].data()),
                      quantity: DonationService.parseQuantity(
                            items[i].data()['quantity'],
                          ) ??
                          0,
                      location: items[i].data()['location']?.toString() ?? '',
                      donorEmail: items[i].data()['donorEmail']?.toString() ?? '',
                      ngoEmail: items[i].data()['ngoEmail']?.toString() ?? 'Unknown',
                      status: items[i].data()['status']?.toString() ?? 'Pending',
                      createdAt: items[i].data()['createdAt'] as Timestamp?,
                      statusColor: _statusColor(
                        items[i].data()['status']?.toString() ?? 'Pending',
                      ),
                    ),
                    if (i < items.length - 1)
                      Divider(height: 1, color: Colors.grey.shade100, indent: 16, endIndent: 16),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestRowItem({
    required String requestId,
    required String donationId,
    required String name,
    required int quantity,
    required String location,
    required String donorEmail,
    required String ngoEmail,
    required String status,
    required Timestamp? createdAt,
    required Color statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5E6D3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.mail_rounded,
                  color: Color(0xFF8B4513),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E2723),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NGO: $ngoEmail • $quantity kg/units',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (location.isNotEmpty)
                      Text(
                        location,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (status == 'Pending')
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      _handleRequestAction(requestId, donationId, value),
                  itemBuilder: (BuildContext context) => const [
                    PopupMenuItem(
                      value: 'approve',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 18, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Approve'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'reject',
                      child: Row(
                        children: [
                          Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Reject'),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleRequestAction(
    String requestId,
    String donationId,
    String action,
  ) async {
    try {
      if (action == 'approve') {
        if (donationId.isEmpty) {
          throw Exception('Missing donation reference on this request.');
        }
        await DonationService.approveRequest(
          requestId: requestId,
          donationId: donationId,
        );
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request approved!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (action == 'reject') {
        await DonationService.rejectRequest(requestId: requestId);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request rejected.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                navigator.pop();
                await authState.logout();
                navigator.pushNamedAndRemoveUntil('/login', (route) => false);
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}

