import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';

class HomeStatusDot extends StatefulWidget {
  const HomeStatusDot({super.key, required this.active});

  final bool active;

  @override
  State<HomeStatusDot> createState() => _HomeStatusDotState();
}

class _HomeStatusDotState extends State<HomeStatusDot> {
  int _pulseTick = 0;

  @override
  void didUpdateWidget(HomeStatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) {
      setState(() {
        _pulseTick += 1;
      });
    }
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
          _buildDot(dotColor),
          if (widget.active)
            TweenAnimationBuilder<double>(
              key: ValueKey(_pulseTick),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 3),
              curve: Curves.easeOut,
              onEnd: () {
                if (!mounted || !widget.active) {
                  return;
                }
                setState(() {
                  _pulseTick += 1;
                });
              },
              builder: (context, t, child) {
                final opacity = 0.4 * (1 - t);
                final scale = 1.0 + (2.2 - 1.0) * t;

                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                );
              },
              child: _buildDot(dotColor),
            ),
        ],
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
