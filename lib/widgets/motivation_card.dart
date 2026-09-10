import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../data/motivational_quotes.dart';
import '../theme/app_theme.dart';

/// A small daily-motivation banner. Deterministic per day (same quote all
/// day, changes tomorrow) rather than random-per-open, so it doesn't feel
/// like the app is being repetitive/noisy on every launch.
class MotivationCard extends StatelessWidget {
  const MotivationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final quote = quoteOfTheDay();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppColors.general.withValues(alpha: 0.14),
            AppColors.trading.withValues(alpha: 0.14),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💬', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              quote,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.15, end: 0, curve: Curves.easeOut);
  }
}
