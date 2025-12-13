import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A widget that renders a subtle grid background with radial fade masking.
///
/// The grid consists of lines at [gridSpacing] intervals (default 40px),
/// rendered in [lineColor], with a radial gradient mask that fades the
/// grid toward the edges.
class SplashGridBackground extends StatelessWidget {
  const SplashGridBackground({
    super.key,
    required this.lineColor,
    this.gridSpacing = 40.0,
  });

  /// Color of the grid lines (typically white with very low opacity).
  final Color lineColor;

  /// Spacing between grid lines in logical pixels.
  final double gridSpacing;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _GridPainter(
          lineColor: lineColor,
          spacing: gridSpacing,
        ),
        size: Size.infinite,
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
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.spacing != spacing;
  }
}
