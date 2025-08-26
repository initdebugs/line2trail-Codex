import 'package:flutter/material.dart';
import '../../../core/constants/activity_types.dart';
import '../../../core/theme/app_colors.dart';
import 'activity_mode_chip.dart';

class RouteBar extends StatefulWidget {
  final ActivityType selectedActivity;
  final ValueChanged<ActivityType> onActivityChanged;
  final bool isDrawing;
  final VoidCallback onToggleDraw;
  final VoidCallback? onSave;
  final bool hasRoute;

  const RouteBar({
    super.key,
    required this.selectedActivity,
    required this.onActivityChanged,
    required this.isDrawing,
    required this.onToggleDraw,
    this.onSave,
    this.hasRoute = false,
  });

  @override
  State<RouteBar> createState() => _RouteBarState();
}

class _RouteBarState extends State<RouteBar> with TickerProviderStateMixin {
  late AnimationController _activityModeController;
  late AnimationController _saveButtonController;
  late Animation<double> _activityModeAnimation;
  late Animation<double> _saveButtonAnimation;

  @override
  void initState() {
    super.initState();
    _activityModeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _saveButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _activityModeAnimation = CurvedAnimation(
      parent: _activityModeController,
      curve: Curves.easeInOut,
    );
    _saveButtonAnimation = CurvedAnimation(
      parent: _saveButtonController,
      curve: Curves.easeInOut,
    );

    // Initial state
    if (!widget.isDrawing) {
      _activityModeController.value = 1.0;
      _saveButtonController.value = 0.0;
    } else {
      _activityModeController.value = 0.0;
      _saveButtonController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(RouteBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Animate based on drawing state
    if (widget.isDrawing && !oldWidget.isDrawing) {
      // Started drawing - hide activity mode, show save button
      _activityModeController.reverse();
      _saveButtonController.forward();
    } else if (!widget.isDrawing && oldWidget.isDrawing) {
      // Stopped drawing - show activity mode, hide save button if no route
      _activityModeController.forward();
      if (!widget.hasRoute) {
        _saveButtonController.reverse();
      }
    }
    
    // Handle save button based on route existence
    if (widget.hasRoute && widget.onSave != null) {
      _saveButtonController.forward();
    } else if (!widget.isDrawing) {
      _saveButtonController.reverse();
    }
  }

  @override
  void dispose() {
    _activityModeController.dispose();
    _saveButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkCard
              : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([_activityModeAnimation, _saveButtonAnimation]),
          builder: (context, child) {
            return Row(
              children: [
                // Activity selector (animated)
                if (_activityModeAnimation.value > 0.01)
                  SizeTransition(
                    sizeFactor: _activityModeAnimation,
                    axis: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: FadeTransition(
                        opacity: _activityModeAnimation,
                        child: ActivityModeChip(
                          selected: widget.selectedActivity,
                          onChanged: widget.onActivityChanged,
                        ),
                      ),
                    ),
                  ),
                // Draw/Stop button (primary action)
                Expanded(
                  flex: 2,
                  child: _PrimaryActionButton(
                    isDrawing: widget.isDrawing,
                    onPressed: widget.onToggleDraw,
                  ),
                ),
                // Save button (animated)
                if (_saveButtonAnimation.value > 0.01)
                  SizeTransition(
                    sizeFactor: _saveButtonAnimation,
                    axis: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FadeTransition(
                        opacity: _saveButtonAnimation,
                        child: _SaveButton(
                          onPressed: widget.onSave!,
                          showText: _activityModeAnimation.value < 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final bool isDrawing;
  final VoidCallback onPressed;

  const _PrimaryActionButton({required this.isDrawing, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDrawing 
              ? [AppColors.summitOrange, AppColors.summitOrangeDark]
              : [AppColors.trailGreen, AppColors.trailGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: (isDrawing ? AppColors.summitOrange : AppColors.trailGreen).withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(22),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isDrawing ? Icons.stop_circle_outlined : Icons.create_outlined,
                  color: AppColors.textInverse,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  isDrawing ? 'Stop' : 'Draw',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool showText;

  const _SaveButton({
    required this.onPressed,
    required this.showText,
  });

  @override
  Widget build(BuildContext context) {
    if (showText) {
      // Show as expanded button with text
      return Container(
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : AppColors.background,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.trailGreen.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bookmark_add_outlined,
                    color: AppColors.trailGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Save',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.trailGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      // Show as compact icon-only button
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : AppColors.background,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.trailGreen.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(22),
            child: Center(
              child: Icon(
                Icons.bookmark_add_outlined,
                color: AppColors.trailGreen,
                size: 18,
              ),
            ),
          ),
        ),
      );
    }
  }
}
