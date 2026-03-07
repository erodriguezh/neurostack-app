import 'dart:ui';

/// Composites [foreground] over [background] using standard alpha blending.
///
/// If [foreground] is fully opaque, returns it unchanged.
Color compositedOver(Color foreground, Color background) {
  if (foreground.a == 1.0) return foreground;
  return Color.alphaBlend(foreground, background);
}

/// Computes the WCAG 2.0 contrast ratio of [foreground] rendered on top of
/// [background].
///
/// Semi-transparent foreground colors are composited over the background before
/// computing luminance. Returns a value between 1.0 and 21.0.
///
/// See: https://www.w3.org/WAI/GL/wiki/Contrast_ratio
double contrastRatio(Color foreground, Color background) {
  final fg = compositedOver(foreground, background);

  final luminanceFg = fg.computeLuminance();
  final luminanceBg = background.computeLuminance();

  final lighter =
      luminanceFg > luminanceBg ? luminanceFg : luminanceBg;
  final darker =
      luminanceFg > luminanceBg ? luminanceBg : luminanceFg;

  return (lighter + 0.05) / (darker + 0.05);
}

/// WCAG AA minimum contrast ratio for normal text (< 18pt, or < 14pt bold).
const double wcagAANormalText = 4.5;

/// WCAG AA minimum contrast ratio for large text (>= 18pt, or >= 14pt bold).
const double wcagAALargeText = 3.0;
