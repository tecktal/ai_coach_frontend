import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../../core/theme/app_theme.dart';

class HeroScore extends StatelessWidget {
  final double score;
  final String date;
  final String title;

  const HeroScore({
    super.key,
    required this.score,
    required this.date,
    required this.title,
  });

  String _getQualitativeLabel(double score) {
    if (score >= 4.0) return 'Excellent';
    if (score >= 3.0) return 'Good';
    if (score >= 2.0) return 'Developing';
    return 'Needs Focus';
  }

  @override
  Widget build(BuildContext context) {
    final label = _getQualitativeLabel(score);
    final color = AppTheme.getScoreColorDouble(score);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textMain,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            date,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSub,
            ),
          ),
          const SizedBox(height: 24),
          // Ring shows progress visually but no number inside
          CircularPercentIndicator(
            radius: 80.0,
            lineWidth: 16.0,
            animation: true,
            percent: (score / 5.0).clamp(0.0, 1.0),
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  score >= 3.0 ? Icons.check_circle_outline : Icons.trending_up,
                  color: color,
                  size: 28,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.0,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: Colors.grey.shade100,
            progressColor: color,
          ),
        ],
      ),
    );
  }
}
