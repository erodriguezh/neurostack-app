import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';

/// Controls how [AppGridBackground] resolves its fill, line, and glow colors.
///
/// - [legacyDark]: Fixed dark palette from [KitColorsExtension]. Current
///   default -- no visual change from pre-migration behavior.
/// - [adaptive]: Brightness-aware palette derived from [ColorScheme].
///   Fill uses `ColorScheme.surface`, lines use `ColorScheme.outlineVariant`,
///   and glow uses `ColorScheme.primary` with low alpha.
///
/// See `docs/best_practices/design/brightness_theming.md` for the full policy.
enum AppGridBackgroundMode {
  /// Fixed dark palette -- uses kitColors.background / white02 / brandSky.
  legacyDark,

  /// Brightness-aware -- resolves from the ambient [ColorScheme].
  adaptive,
}

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
///
/// By default, [mode] is [AppGridBackgroundMode.legacyDark] which preserves
/// the original fixed-dark behavior. Pass [AppGridBackgroundMode.adaptive] to
/// resolve colors from the ambient [ColorScheme] (brightness-aware).
///
/// Explicit [lineColor], [glowColor], and [fillColor] overrides take priority
/// over both modes.
class AppGridBackground extends StatelessWidget {
  const AppGridBackground({
    super.key,
    required this.child,
    this.mode = AppGridBackgroundMode.legacyDark,
    this.showTopGlow = false,
    this.fillColor,
    this.glowColor,
    this.lineColor,
    this.gridSpacing = 40.0,
  });

  final Widget child;

  /// How fill / line / glow colors are resolved. Defaults to [legacyDark].
  final AppGridBackgroundMode mode;

  /// Whether to show the radial glow at the top of the screen.
  final bool showTopGlow;

  /// Explicit fill color override. When null, resolved from [mode].
  final Color? fillColor;

  /// Explicit glow color override. When null, resolved from [mode].
  final Color? glowColor;

  /// Explicit line color override. When null, resolved from [mode].
  final Color? lineColor;

  /// Spacing between grid lines in logical pixels.
  final double gridSpacing;

  @override
  Widget build(BuildContext context) {
    final Color effectiveFill;
    final Color effectiveLine;
    final Color effectiveGlow;

    switch (mode) {
      case AppGridBackgroundMode.legacyDark:
        final kitColors = context.kitColors;
        effectiveFill = fillColor ?? kitColors.background;
        effectiveLine = lineColor ?? kitColors.white02;
        effectiveGlow =
            glowColor ?? kitColors.brandSky.withValues(alpha: 0.05);
      case AppGridBackgroundMode.adaptive:
        final colorScheme = Theme.of(context).colorScheme;
        effectiveFill = fillColor ?? colorScheme.surface;
        effectiveLine = lineColor ?? colorScheme.outlineVariant;
        effectiveGlow =
            glowColor ?? colorScheme.primary.withValues(alpha: 0.05);
    }

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: effectiveFill),
          GridPattern(lineColor: effectiveLine, spacing: gridSpacing),
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
                        effectiveGlow,
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
