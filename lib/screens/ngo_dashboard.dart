import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/rating_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../main.dart';
import '../widgets/star_rating.dart';
import '../widgets/notification_dialog.dart';

class NgoDashboard extends StatefulWidget {
  const NgoDashboard({super.key});

  @override
  State<NgoDashboard> createState() => _NgoDashboardState();
}

class _NgoDashboardState extends State<NgoDashboard> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _fadeController;
  String userEmail = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final email = await StorageService.getUserEmail();
    if (mounted) {
      setState(() {
        userEmail = email ?? 'NGO';
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
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
              left: size.width * 0.05,
              right: size.width * 0.05,
              top: 18,
              bottom: MediaQuery.of(context).padding.bottom + 18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildSummaryCard(),
                const SizedBox(height: 24),
                _buildSectionHeader('Quick Actions', 'Stay on top of NGO operations'),
                const SizedBox(height: 16),
                _buildActionGrid(context),
                const SizedBox(height: 24),
                _buildInfoBanner(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final size = MediaQuery.of(context).size;
    
    return FadeTransition(
      opacity: _fadeController,
      child: Container(
        padding: EdgeInsets.all(size.width * 0.04),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF5E6D3), Color(0xFFF7D08A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: size.width * 0.15,
              height: size.width * 0.15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.handshake_rounded,
                size: size.width * 0.08,
                color: const Color(0xFF6B4423),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NGO Portal',
                    style: TextStyle(
                      fontSize: size.width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2C1810),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Streamline requests, track pickups, and manage food access.',
                    style: TextStyle(
                      fontSize: size.width * 0.035,
                      color: const Color(0xFF4A3728),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Hi, ${userEmail.split('@').first.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C1810),
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<Map<String, dynamic>>(
                    stream: RatingService.getUserRatingStats(AuthService.currentUser?.uid ?? ''),
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
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF6B4423),
                  size: 22,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/ngo_profile');
                },
              ),
            ),
            const SizedBox(width: 12),
            StreamBuilder<int>(
              stream: NotificationService.getUnreadCount(AuthService.currentUser?.uid ?? ''),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;

                return Stack(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Color(0xFF6B4423),
                          size: 24,
                        ),
                        onPressed: () {
                          final userId = AuthService.currentUser?.uid ?? '';
                          debugPrint('🔔 [NgoDashboard] Notification bell pressed with userId: "$userId"');
                          showDialog(
                            context: context,
                            builder: (context) => NotificationDialog(),
                          ).then((_) {
                            debugPrint('🔔 [NgoDashboard] Notification dialog closed');
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFF6B4423),
                  size: 22,
                ),
                onPressed: _showLogoutDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Live overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C1810),
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Track your NGO activities and impact in real-time.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF4A3728),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    final actions = [
      {
        'icon': Icons.restaurant_menu_rounded,
        'title': 'Available Food',
        'description': 'Browse available meals',
        'color': const Color(0xFF8B4513),
        'route': '/available_food',
        'imageUrl': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
      },
      {
        'icon': Icons.assignment_turned_in_rounded,
        'title': 'My Requests',
        'description': 'Manage pickup requests',
        'color': const Color(0xFF1E3A5F),
        'route': '/my_requests',
        'imageUrl': 'https://images.unsplash.com/photo-1488459716781-31db52582fe9?w=400',
      },
      {
        'icon': Icons.local_shipping_rounded,
        'title': 'Pickup Status',
        'description': 'Track delivery progress',
        'color': const Color(0xFF047857),
        'route': '/pickup_status',
        'imageUrl': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400',
      },
    ];

    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 600;

    // Use GridView for mobile (2x2), horizontal scroll for wide screens
    if (isWideScreen) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(actions.length, (index) {
            final action = actions[index];
            return Padding(
              padding: EdgeInsets.only(right: index < actions.length - 1 ? 16 : 0),
              child: SizedBox(
                width: 150,
                height: 150,
                child: _buildActionCard(
                  icon: action['icon'] as IconData,
                  title: action['title'] as String,
                  description: action['description'] as String,
                  color: action['color'] as Color,
                  imageUrl: action['imageUrl'] as String,
                  onTap: () {
                    Navigator.pushNamed(context, action['route'] as String);
                  },
                  delay: index * 80,
                ),
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
          final action = actions[index];
          return _buildActionCard(
            icon: action['icon'] as IconData,
            title: action['title'] as String,
            description: action['description'] as String,
            color: action['color'] as Color,
            imageUrl: action['imageUrl'] as String,
            onTap: () {
              Navigator.pushNamed(context, action['route'] as String);
            },
            delay: index * 80,
          );
        },
      );
    }
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: const [
          Icon(
            Icons.lightbulb_outline,
            color: Color(0xFFF8F0D8),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Make the most of your NGO portal: respond quickly, stay organized, and help more communities.',
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required String imageUrl,
    required VoidCallback onTap,
    required int delay,
  }) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1)
          .animate(CurvedAnimation(
            parent: _animationController,
            curve: Interval(delay / 500, 1.0, curve: Curves.easeOut),
          )),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0)
            .animate(CurvedAnimation(
              parent: _animationController,
              curve: Interval(delay / 500, 1.0, curve: Curves.easeOut),
            )),
        child: GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(color: Colors.grey.shade300);
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: color.withOpacity(0.8));
                      },
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.45),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              icon,
                              size: 40,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
