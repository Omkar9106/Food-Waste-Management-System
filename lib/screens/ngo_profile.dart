import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/rating_service.dart';
import '../theme/app_theme.dart';
import '../widgets/star_rating.dart';

class NgoProfile extends StatefulWidget {
  const NgoProfile({super.key});

  @override
  State<NgoProfile> createState() => _NgoProfileState();
}

class _NgoProfileState extends State<NgoProfile> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = AuthService.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      // Try to get NGO name from Firestore
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data();
          final name = data?['name'] as String?;
          if (name != null) {
            _nameController.text = name;
          }
        }
      } catch (e) {
        debugPrint('Error loading profile: $e');
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = AuthService.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': 'NGO',
          'updatedAt': Timestamp.now(),
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
          setState(() => _isEditing = false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating profile: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final userId = user?.uid ?? '';

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
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'NGO Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Profile Card
                _buildProfileCard(userId),
                const SizedBox(height: 24),

                // Stats Cards
                _buildStatsRow(userId),
                const SizedBox(height: 24),

                // Rating Card
                _buildRatingCard(userId),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(String userId) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryOrange.withOpacity(0.2),
                  AppTheme.primaryOrange.withOpacity(0.1),
                ],
              ),
            ),
            child: const Icon(
              Icons.business_rounded,
              size: 50,
              color: AppTheme.primaryOrange,
            ),
          ),
          const SizedBox(height: 20),

          // Name
          if (_isEditing)
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'NGO Name',
                labelStyle: TextStyle(color: Colors.grey.shade600),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            )
          else
            Text(
              _nameController.text.isEmpty ? 'NGO Name' : _nameController.text,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          const SizedBox(height: 8),

          // Email
          if (_isEditing)
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.grey.shade600),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            )
          else
            Text(
              _emailController.text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          const SizedBox(height: 20),

          // Edit/Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isEditing ? _saveProfile : () => setState(() => _isEditing = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isEditing ? 'Save Changes' : 'Edit Profile',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('ngoId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange));
        }

        final requests = snapshot.data?.docs ?? [];
        int totalRequests = requests.length;
        int completedPickups = 0;

        for (var doc in requests) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['pickupStatus'] as String? ?? '';
          if (status == 'Completed' || status == 'Delivered') {
            completedPickups++;
          }
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                value: '$totalRequests',
                label: 'Requests Sent',
                icon: Icons.send_rounded,
                color: const Color(0xFF8B4513),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                value: '$completedPickups',
                label: 'Pickups Completed',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF047857),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(String userId) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          const Text(
            'NGO Rating',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<Map<String, dynamic>>(
            stream: RatingService.getUserRatingStats(userId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange));
              }

              final stats = snapshot.data!;
              final averageRating = stats['averageRating'] as double? ?? 0.0;
              final totalRatings = stats['totalRatings'] as int? ?? 0;

              if (totalRatings == 0) {
                return Column(
                  children: [
                    const Icon(
                      Icons.star_border_rounded,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No ratings yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  RatingDisplay(
                    averageRating: averageRating,
                    totalRatings: totalRatings,
                    size: 32,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$totalRatings ${totalRatings == 1 ? 'rating' : 'ratings'} received',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
