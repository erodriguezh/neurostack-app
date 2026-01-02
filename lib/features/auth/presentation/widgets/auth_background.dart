import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/startup/widgets/splash_grid_background.dart';

class AuthBackground extends StatelessWidget {
  const AuthBackground({
    super.key,
    required this.child,
    this.showTopGlow = true,
  });

  final Widget child;
  final bool showTopGlow;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: kitColors.background),
          SplashGridBackground(lineColor: kitColors.white02),
          if (showTopGlow)
            IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: double.infinity,
                  height: 260,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 0.8,
                      colors: [
                        kitColors.brandSky.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}
