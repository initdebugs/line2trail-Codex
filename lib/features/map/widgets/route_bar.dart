import 'package:flutter/material.dart';
import '../../../core/constants/activity_types.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/animated_tap_button.dart';
import 'activity_mode_chip.dart';

class RouteBar extends StatefulWidget {
  final ActivityType selectedActivity;
  final ValueChanged<ActivityType> onActivityChanged;
  final bool isDrawing;
  final VoidCallback onToggleDraw;
  final VoidCallback? onSave;
  final bool hasRoute;
  final VoidCallback? onRoundtrip;
  final bool isRoundtripMode;
  final VoidCallback? onCancelRoundtrip;

  const RouteBar({
    super.key,
    required this.selectedActivity,
    required this.onActivityChanged,
    required this.isDrawing,
    required this.onToggleDraw,
    this.onSave,
    this.hasRoute = false,
    this.onRoundtrip,
    this.isRoundtripMode = false,
    this.onCancelRoundtrip,
  });

  @override
  State<RouteBar> createState() => _RouteBarState();
}

class _RouteBarState extends State<RouteBar> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    // Initialize animation state to match initial drawing state
    if (widget.isDrawing) {
      _flipController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(RouteBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Sync animation with drawing state whenever it changes
    if (oldWidget.isDrawing != widget.isDrawing) {
      if (widget.isDrawing) {
        _flipController.forward();
      } else {
        _flipController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isRoundtripMode) {
      // Roundtrip generator mode - prominent layout with animation
      return SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.trailGreen.withValues(alpha: 0.9),
                AppColors.trailGreen.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.trailGreen.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main instruction with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.touch_app,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selecteer Startpunt',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Tik op de kaart om je rondrit te starten',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Action button
              _CancelRoundtripButton(
                onPressed: widget.onCancelRoundtrip!,
              ),
            ],
          ),
        ),
      );
    }

    // Normal mode with animation
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
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
        child: Row(
          children: [
            // Activity selector (when not drawing and no route)
            if (!widget.isDrawing && !widget.hasRoute)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActivityModeChip(
                  selected: widget.selectedActivity,
                  onChanged: widget.onActivityChanged,
                  disabled: widget.hasRoute,
                ),
              ),
            // Draw/Stop button (primary action) with flip animation
            Expanded(
              child: AnimatedBuilder(
                animation: _flipAnimation,
                builder: (context, child) {
                  final angle = _flipAnimation.value * 3.14159; // π radians = 180°
                  final transform = Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // perspective
                    ..rotateY(angle);

                  return Transform(
                    transform: transform,
                    alignment: Alignment.center,
                    child: _flipAnimation.value < 0.5
                        ? _PrimaryActionButton(
                            isDrawing: false,
                            onPressed: widget.onToggleDraw,
                          )
                        : Transform(
                            transform: Matrix4.identity()..rotateY(3.14159),
                            alignment: Alignment.center,
                            child: _PrimaryActionButton(
                              isDrawing: true,
                              onPressed: widget.onToggleDraw,
                            ),
                          ),
                  );
                },
              ),
            ),
            // Roundtrip button (only when not drawing and no route)
            if (!widget.isDrawing && !widget.hasRoute && widget.onRoundtrip != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _RoundtripButton(
                  onPressed: widget.onRoundtrip!,
                ),
              ),
            // Save button (when route exists)
            if (widget.hasRoute && widget.onSave != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _SaveButton(
                  onPressed: widget.onSave!,
                  showText: !widget.isDrawing && !widget.hasRoute,
                ),
              ),
          ],
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
                  isDrawing ? 'Stop' : 'Tekenen',
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

class _RoundtripButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _RoundtripButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTapButton(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.pathBlue, AppColors.pathBlue.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.pathBlue.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.swap_horiz_rounded,
            color: Colors.white,
            size: 20,
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
      return AnimatedTapButton(
        onTap: onPressed,
        child: Container(
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
                  'Opslaan',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.trailGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Show as compact icon-only button
      return AnimatedTapButton(
        onTap: onPressed,
        child: Container(
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
          child: Center(
            child: Icon(
              Icons.bookmark_add_outlined,
              color: AppColors.trailGreen,
              size: 18,
            ),
          ),
        ),
      );
    }
  }
}

class _CancelRoundtripButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CancelRoundtripButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTapButton(
      onTap: onPressed,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Annuleer',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
