import 'package:flutter/material.dart';
import '../../../core/constants/activity_types.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/localization_service.dart';
import '../../../shared/services/fast_roundtrip_service.dart';

class RoundtripGeneratorDialog extends StatefulWidget {
  const RoundtripGeneratorDialog({super.key});

  @override
  State<RoundtripGeneratorDialog> createState() => _RoundtripGeneratorDialogState();
}

class _RoundtripGeneratorDialogState extends State<RoundtripGeneratorDialog> {
  ActivityType _selectedActivity = ActivityType.walking;
  double _selectedDistance = 5.0; // Default 5km
  RoundtripStrategy _selectedStrategy = RoundtripStrategy.balanced;
  final List<double> _distanceOptions = [2.0, 5.0, 10.0, 15.0, 20.0, 25.0, 50.0];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final defaultActivity = SettingsService.getDefaultActivity();
    setState(() {
      _selectedActivity = defaultActivity;
    });
  }

  @override
  Widget build(BuildContext context) {
    final unitsSystem = SettingsService.getUnitsSystem();
    final isMetric = unitsSystem == 'Metric';
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(
          maxWidth: 400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact Header
            Row(
              children: [
                Icon(
                  Icons.refresh,
                  color: AppColors.trailGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Rondrit Generator',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Activity Type Selection - Compact Row Layout
            Row(
              children: [
                Text(
                  'Activiteit:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    children: ActivityType.values.map((activity) {
                      final isSelected = _selectedActivity == activity;
                      return FilterChip(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              activity.icon,
                              size: 14,
                              color: isSelected ? AppColors.trailGreen : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              activity.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? AppColors.trailGreen : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedActivity = activity),
                        backgroundColor: AppColors.surface,
                        selectedColor: AppColors.trailGreen.withValues(alpha: 0.2),
                        side: BorderSide(
                          color: isSelected ? AppColors.trailGreen : AppColors.textSecondary.withValues(alpha: 0.3),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Route Strategy Selection - Compact Dropdown
            Row(
              children: [
                Text(
                  'Route Type:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                    ),
                    child: DropdownButton<RoundtripStrategy>(
                      value: _selectedStrategy,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: RoundtripStrategy.values.map((strategy) {
                        return DropdownMenuItem(
                          value: strategy,
                          child: Text(
                            _getStrategyTitle(strategy),
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedStrategy = value);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Show description for selected strategy
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                _getStrategyDescription(_selectedStrategy),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Distance Selection - Compact Layout
            Row(
              children: [
                Text(
                  'Afstand:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_selectedDistance.toInt()} ${isMetric ? 'km' : 'mi'}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.trailGreen,
                  ),
                ),
                const Spacer(),
                Text(
                  '~${_getEstimatedTime()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _distanceOptions.map((distance) {
                final displayDistance = isMetric ? distance : distance * 0.621371;
                final isSelected = _selectedDistance == distance;
                
                return FilterChip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  label: Text(
                    '${displayDistance.toInt()}${isMetric ? 'k' : 'm'}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedDistance = distance),
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.trailGreen.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.trailGreen : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.trailGreen : AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.textSecondary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Annuleer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop({
                        'activity': _selectedActivity,
                        'distance': _selectedDistance,
                        'strategy': _selectedStrategy,
                      });
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.trailGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Selecteer Startpunt',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getEstimatedTime() {
    final speed = _selectedActivity.averageSpeed;
    final timeHours = _selectedDistance / speed;
    
    if (timeHours < 1.0) {
      return '${(timeHours * 60).round()}min';
    } else {
      final hours = timeHours.floor();
      final minutes = ((timeHours - hours) * 60).round();
      return '${hours}h ${minutes}min';
    }
  }

  String _getStrategyTitle(RoundtripStrategy strategy) {
    switch (strategy) {
      case RoundtripStrategy.scenic:
        return 'Landschappelijk';
      case RoundtripStrategy.direct:
        return 'Direct';
      case RoundtripStrategy.balanced:
        return 'Uitgebalanceerd';
      case RoundtripStrategy.exploration:
        return 'Verkenning';
    }
  }

  String _getStrategyDescription(RoundtripStrategy strategy) {
    switch (strategy) {
      case RoundtripStrategy.scenic:
        return 'Focus op parken, paden en landschappelijke routes';
      case RoundtripStrategy.direct:
        return 'Meest efficiente circulaire route';
      case RoundtripStrategy.balanced:
        return 'Goede mix van efficientie en variatie';
      case RoundtripStrategy.exploration:
        return 'Maximum verkenning van het gebied';
    }
  }
}