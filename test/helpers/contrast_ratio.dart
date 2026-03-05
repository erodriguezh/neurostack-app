import 'dart:ui';

/// Computes the WCAG 2.0 contrast ratio between two colors.
///
/// Returns a value between 1.0 (identical luminance) and 21.0 (black on white).
/// Uses [Color.computeLuminance] which implements the WCAG 2.0 relative
/// luminance formula with proper sRGB linearization.
///
/// See: https://www.w3.org/WAI/GL/wiki/Contrast_ratio
double contrastRatio(Color a, Color b) {
  final luminanceA = a.computeLuminance();
  final luminanceB = b.computeLuminance();

  final lighter =
      luminanceA > luminanceB ? luminanceA : luminanceB;
  final darker =
      luminanceA > luminanceB ? luminanceB : luminanceA;

  return (lighter + 0.05) / (darker + 0.05);
}

/// WCAG AA minimum contrast ratio for normal text (< 18pt, or < 14pt bold).
const double wcagAANormalText = 4.5;

/// WCAG AA minimum contrast ratio for large text (>= 18pt, or >= 14pt bold).
const double wcagAALargeText = 3.0;
