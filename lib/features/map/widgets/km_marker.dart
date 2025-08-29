import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class KmMarker extends StatelessWidget {
  final String label;

  const KmMarker({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Halo ring for better visibility (same as waypoint markers)
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.warningAmber.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
        ),
        // Core marker (same style as waypoint markers but different color)
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.warningAmber,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.textInverse,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textInverse,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

