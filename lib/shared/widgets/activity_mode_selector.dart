import 'package:flutter/material.dart';
import '../../core/constants/activity_types.dart';
import '../../core/theme/app_colors.dart';

class ActivityModeSelector extends StatefulWidget {
  final ActivityType selectedActivity;
  final ValueChanged<ActivityType> onActivityChanged;

  const ActivityModeSelector({
    super.key,
    required this.selectedActivity,
    required this.onActivityChanged,
  });

  @override
  State<ActivityModeSelector> createState() => _ActivityModeSelectorState();
}

class _ActivityModeSelectorState extends State<ActivityModeSelector> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ActivityType.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final activity = ActivityType.values[index];
          final isSelected = activity == widget.selectedActivity;

          return ActivityChip(
            activity: activity,
            isSelected: isSelected,
            onTap: () => widget.onActivityChanged(activity),
          );
        },
      ),
    );
  }
}

class ActivityChip extends StatelessWidget {
  final ActivityType activity;
  final bool isSelected;
  final VoidCallback onTap;

  const ActivityChip({
    super.key,
    required this.activity,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.trailGreen : AppColors.trailGreenSurface,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? null
              : Border.all(
                  color: AppColors.trailGreen.withValues(alpha: 0.3),
                  width: 1,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              activity.icon,
              size: 16,
              color: isSelected ? AppColors.textInverse : AppColors.trailGreen,
            ),
            const SizedBox(width: 6),
            Text(
              activity.displayName,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? AppColors.textInverse
                        : AppColors.trailGreen,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}