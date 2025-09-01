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
    final screenHeight = MediaQuery.of(context).size.height;
    final maxDialogHeight = screenHeight * 0.8;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: maxDialogHeight,
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
            const SizedBox(height: 16),

            // Scrollable content area
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Activity Type Selection
                    Text(
                      'Activiteit Type',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Horizontal activity selector
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: ActivityType.values.length,
                        itemBuilder: (context, index) {
                          final activity = ActivityType.values[index];
                          final isSelected = _selectedActivity == activity;
                          
                          return Padding(
                            padding: EdgeInsets.only(right: index < ActivityType.values.length - 1 ? 8 : 0),
                            child: FilterChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    activity.icon,
                                    size: 16,
                                    color: isSelected ? AppColors.trailGreen : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    activity.displayName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected ? AppColors.trailGreen : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedActivity = activity),
                              backgroundColor: AppColors.surface,
                              selectedColor: AppColors.trailGreen.withValues(alpha: 0.2),
                              checkmarkColor: AppColors.trailGreen,
                              side: BorderSide(
                                color: isSelected ? AppColors.trailGreen : AppColors.textSecondary.withValues(alpha: 0.3),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Route Strategy Selection
                    Text(
                      'Route Type',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          for (final strategy in RoundtripStrategy.values)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: RadioListTile<RoundtripStrategy>(
                                value: strategy,
                                groupValue: _selectedStrategy,
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _selectedStrategy = value);
                                  }
                                },
                                title: Text(
                                  _getStrategyTitle(strategy),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  _getStrategyDescription(strategy),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                activeColor: AppColors.trailGreen,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Distance Selection
                    Text(
                      'Gewenste Afstand',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_selectedDistance.toInt()} ${isMetric ? 'km' : 'mi'}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.trailGreen,
                                ),
                              ),
                              Text(
                                '~${_getEstimatedTime()}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
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
                                  style: const TextStyle(fontSize: 12),
                                ),
                                selected: isSelected,
                                onSelected: (_) => setState(() => _selectedDistance = distance),
                                backgroundColor: AppColors.surface,
                                selectedColor: AppColors.trailGreen.withValues(alpha: 0.2),
                                checkmarkColor: AppColors.trailGreen,
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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