import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class DrawStatsPanel extends StatelessWidget {
  final String distance;
  final String time;
  final bool isLoading;

  const DrawStatsPanel({
    super.key,
    required this.distance,
    required this.time,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkCard
            : AppColors.card).withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: AppColors.outline.withOpacity(0.3), 
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Metric(label: 'Distance', value: distance, icon: Icons.straighten),
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: AppColors.outline.withOpacity(0.5),
          ),
          _Metric(label: 'Time', value: time, icon: Icons.schedule_outlined),
          if (isLoading) ...[
            Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: AppColors.outline.withOpacity(0.5),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.trailGreen),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Snapping',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _Metric({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AppColors.textSecondary,
      fontSize: 10,
      letterSpacing: 0.5,
    );
    final valueStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 15,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              size: 14, 
              color: AppColors.trailGreen,
            ),
            const SizedBox(width: 4),
            Text(value, style: valueStyle),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: labelStyle),
      ],
    );
  }
}

