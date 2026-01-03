import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';

/// A standalone grid pattern widget - just the painting, no wrapper.
///
/// Use this directly when you need to compose the grid with other layers.
/// Use [AppGridBackground] when you want the full background with optional glow.
class GridPattern extends StatelessWidget {
  const GridPattern({
    super.key,
    required this.lineColor,
    this.spacing = 40.0,
  });

  /// Color of the grid lines (typically white with very low opacity).
  final Color lineColor;

  /// Spacing between grid lines in logical pixels.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _GridPainter(
          lineColor: lineColor,
          spacing: spacing,
        ),
        size: Size.infinite,
      ),
    );
  }
}

/// A reusable grid background with optional top glow effect.
///
/// Used by auth, startup, and onboarding screens for consistent branding.
/// For just the grid without the wrapper, use [GridPattern].
class AppGridBackground extends StatelessWidget {
  const AppGridBackground({
    super.key,
    required this.child,
    this.showTopGlow = false,
    this.glowColor,
    this.lineColor,
    this.gridSpacing = 40.0,
  });

  final Widget child;

  /// Whether to show the radial glow at the top of the screen.
  final bool showTopGlow;

  /// Color of the top glow (defaults to brandSky at 5% opacity).
  final Color? glowColor;

  /// Color of the grid lines (defaults to white02 from theme).
  final Color? lineColor;

  /// Spacing between grid lines in logical pixels.
  final double gridSpacing;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final effectiveLineColor = lineColor ?? kitColors.white02;
    final effectiveGlowColor =
        glowColor ?? kitColors.brandSky.withValues(alpha: 0.05);

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: kitColors.background),
          GridPattern(lineColor: effectiveLineColor, spacing: gridSpacing),
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
                        effectiveGlowColor,
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

class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.lineColor,
    required this.spacing,
  });

  final Color lineColor;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Save layer for masking
    final rect = Offset.zero & size;
    canvas.saveLayer(rect, Paint());

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Apply radial gradient mask
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.longestSide * 0.7;

    final gradient = ui.Gradient.radial(
      center,
      radius,
      [
        Colors.white,
        Colors.white,
        Colors.transparent,
      ],
      [0.0, 0.5, 1.0],
    );

    final maskPaint = Paint()
      ..shader = gradient
      ..blendMode = BlendMode.dstIn;

    canvas.drawRect(rect, maskPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor || oldDelegate.spacing != spacing;
  }
}
