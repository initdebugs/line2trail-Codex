import 'package:flutter/material.dart';

/// A wrapper widget that adds a scale animation when tapped
class AnimatedTapButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleAmount;
  final Duration duration;

  const AnimatedTapButton({
    super.key,
    required this.child,
    this.onTap,
    this.scaleAmount = 0.95,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<AnimatedTapButton> createState() => _AnimatedTapButtonState();
}

class _AnimatedTapButtonState extends State<AnimatedTapButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleAmount,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onTapDown(TapDownDetails details) async {
    await _controller.forward();
  }

  Future<void> _onTapUp(TapUpDetails details) async {
    await _controller.reverse();
    widget.onTap?.call();
  }

  Future<void> _onTapCancel() async {
    await _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
