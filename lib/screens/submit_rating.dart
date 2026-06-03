import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/rating_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/star_rating.dart';

class SubmitRatingScreen extends StatefulWidget {
  const SubmitRatingScreen({super.key});

  @override
  State<SubmitRatingScreen> createState() => _SubmitRatingScreenState();
}

class _SubmitRatingScreenState extends State<SubmitRatingScreen> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  late String _requestId;
  late String _toUserId;
  late String _toUserRole;
  late String _toUserName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _requestId = args['requestId'] ?? '';
      _toUserId = args['toUserId'] ?? '';
      _toUserRole = args['toUserRole'] ?? '';
      _toUserName = args['toUserName'] ?? '';
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final user = AuthService.currentUser;
    if (user == null) return;

    final fromUserRole = await _getUserRole();

    try {
      await RatingService.submitRating(
        requestId: _requestId,
        fromUserId: user.uid,
        toUserId: _toUserId,
        fromUserRole: fromUserRole,
        toUserRole: _toUserRole,
        rating: _rating,
        feedback: _feedbackController.text.trim(),
      );

      // Create notification for the rated user
      await NotificationService.createNotification(
        userId: _toUserId,
        title: 'New Rating Received',
        message: 'You received a $_rating-star rating!',
        requestId: _requestId,
        type: 'rating',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating submitted successfully!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting rating: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<String> _getUserRole() async {
    // This should come from StorageService or AuthService
    // For now, we'll determine based on the toUserRole
    return _toUserRole == 'NGO' ? 'Donor' : 'NGO';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 380;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Submit Rating',
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildRatingCard(isSmallScreen),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingCard(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryOrange.withOpacity(0.2),
                  AppTheme.primaryOrange.withOpacity(0.1),
                ],
              ),
            ),
            child: Icon(
              _toUserRole == 'NGO' ? Icons.business_rounded : Icons.person_rounded,
              size: 40,
              color: AppTheme.primaryOrange,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Rate $_toUserRole',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _toUserName,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          
          // Star rating
          StarRating(
            rating: _rating,
            interactive: true,
            onRatingChanged: (rating) {
              setState(() {
                _rating = rating;
              });
            },
            size: isSmallScreen ? 36 : 48,
          ),
          const SizedBox(height: 8),
          Text(
            _getRatingText(_rating),
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          
          // Feedback text field
          TextField(
            controller: _feedbackController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Add optional feedback (optional)',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.all(isSmallScreen ? 14 : 16),
            ),
          ),
          const SizedBox(height: 24),
          
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitRating,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Submit Rating',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap to rate';
    }
  }
}
