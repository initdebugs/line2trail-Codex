import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class RouteTools extends StatelessWidget {
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;
  final VoidCallback onMore;
  final bool showWaypoints;
  final VoidCallback onToggleWaypoints;

  const RouteTools({
    super.key,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
    required this.onMore,
    required this.showWaypoints,
    required this.onToggleWaypoints,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkCard
              : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Tool(icon: Icons.undo, label: 'Ongedaan', onTap: onUndo),
            _Tool(icon: Icons.redo, label: 'Opnieuw', onTap: onRedo),
            _Tool(
              icon: showWaypoints ? Icons.location_on : Icons.location_off,
              label: showWaypoints ? 'Tonen' : 'Verbergen',
              onTap: onToggleWaypoints,
              activeColor: showWaypoints ? AppColors.pathBlue : AppColors.textPrimary,
            ),
            _Tool(icon: Icons.clear_all, label: 'Wissen', onTap: onClear),
            _Tool(icon: Icons.more_horiz, label: 'Meer', onTap: onMore),
          ],
        ),
      ),
    );
  }
}

class _Tool extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? activeColor;

  const _Tool({
    required this.icon,
    required this.label,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
