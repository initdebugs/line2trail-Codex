import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class MapControlRail extends StatelessWidget {
  final VoidCallback onLocate;
  final VoidCallback onLayers;

  const MapControlRail({
    super.key,
    required this.onLocate,
    required this.onLayers,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SquareButton(icon: Icons.my_location, onTap: onLocate),
        const SizedBox(height: 10),
        _SquareButton(icon: Icons.layers, onTap: onLayers),
      ],
    );
  }
}

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SquareButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.mapControlBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: AppColors.mapControlShadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Icon(icon, color: AppColors.textPrimary, size: 22),
        ),
      ),
    );
  }
}

