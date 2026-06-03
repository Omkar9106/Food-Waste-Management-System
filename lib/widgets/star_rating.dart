import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StarRating extends StatelessWidget {
  final int rating;
  final int maxRating;
  final double size;
  final Color? color;
  final bool interactive;
  final Function(int)? onRatingChanged;

  const StarRating({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 24,
    this.color,
    this.interactive = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? AppTheme.primaryOrange;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        return GestureDetector(
          onTap: interactive && onRatingChanged != null
              ? () => onRatingChanged!(index + 1)
              : null,
          child: Icon(
            index < rating ? Icons.star_rounded : Icons.star_border_rounded,
            size: size,
            color: index < rating ? starColor : Colors.grey.shade300,
          ),
        );
      }),
    );
  }
}

class RatingDisplay extends StatelessWidget {
  final double averageRating;
  final int totalRatings;
  final double size;

  const RatingDisplay({
    super.key,
    required this.averageRating,
    required this.totalRatings,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StarRating(
          rating: averageRating.round(),
          size: size,
          color: AppTheme.primaryOrange,
        ),
        const SizedBox(width: 6),
        Text(
          averageRating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($totalRatings)',
          style: TextStyle(
            fontSize: size - 2,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
