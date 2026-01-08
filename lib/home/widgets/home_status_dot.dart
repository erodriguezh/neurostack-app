import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';

class HomeStatusDot extends StatefulWidget {
  const HomeStatusDot({super.key, required this.active});

  final bool active;

  @override
  State<HomeStatusDot> createState() => _HomeStatusDotState();
}

class _HomeStatusDotState extends State<HomeStatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    if (widget.active) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(HomeStatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    }
    if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final dotColor = widget.active ? kitColors.success : kitColors.white20;

    return SizedBox(
      width: 16,
      height: 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
            ),
          ),
          if (widget.active)
            FadeTransition(
              opacity: Tween<double>(begin: 0.4, end: 0.0).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeOut),
              ),
              child: ScaleTransition(
                scale: Tween<double>(begin: 1, end: 2.2).animate(
                  CurvedAnimation(parent: _controller, curve: Curves.easeOut),
                ),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
