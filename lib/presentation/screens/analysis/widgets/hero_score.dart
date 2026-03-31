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

  @override
  Widget build(BuildContext context) {
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
          CircularPercentIndicator(
            radius: 80.0,
            lineWidth: 16.0,
            animation: true,
            percent: score / 5.0,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  score.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 48.0,
                    color: AppTheme.textMain,
                  ),
                ),
                const Text(
                  'Overall Score',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12.0,
                    color: AppTheme.textSub,
                  ),
                ),
              ],
            ),
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: Colors.grey.shade100,
            progressColor: AppTheme.getScoreColorDouble(score),
          ),
        ],
      ),
    );
  }
}
