import 'package:flutter/material.dart';

/// Brightness-aware semantic color tokens for adaptive routes.
///
/// This [ThemeExtension] provides surface, ink, border, and grid tokens that
/// resolve differently for light and dark brightness. Registered in
/// [AppTheme.buildTheme] and accessible via `context.semanticColors`.
///
/// Use these tokens on adaptive routes instead of raw `KitColorsExtension`
/// `whiteXX` values, which are designed for dark-first routes only.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.surface,
    required this.surfaceElevated,
    required this.ink,
    required this.inkSubtle,
    required this.border,
    required this.borderSubtle,
    required this.gridLine,
    required this.gridBackground,
    required this.gridGlow,
  });

  /// Creates light-mode semantic colors derived from [colorScheme].
  factory AppSemanticColors.light(ColorScheme colorScheme) {
    return AppSemanticColors(
      surface: colorScheme.surface,
      surfaceElevated: colorScheme.surfaceContainer,
      ink: colorScheme.onSurface,
      inkSubtle: colorScheme.onSurfaceVariant,
      border: colorScheme.outline,
      borderSubtle: colorScheme.outlineVariant,
      // Use onSurfaceVariant with moderate alpha for light-mode grid lines.
      // Alpha 0.35 composited over the light surface meets the 1.5:1 contrast
      // threshold while keeping lines visually subtle.
      gridLine: colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
      gridBackground: colorScheme.surface,
      gridGlow: colorScheme.primary.withValues(alpha: 0.05),
    );
  }

  /// Creates dark-mode semantic colors derived from [colorScheme].
  ///
  /// Dark-mode values map to the existing `KitColors` dark palette equivalents
  /// for visual continuity with the pre-migration dark theme.
  factory AppSemanticColors.dark(ColorScheme colorScheme) {
    return AppSemanticColors(
      surface: colorScheme.surface,
      surfaceElevated: colorScheme.surfaceContainer,
      ink: colorScheme.onSurface,
      inkSubtle: colorScheme.onSurfaceVariant,
      border: colorScheme.outline,
      borderSubtle: colorScheme.outlineVariant,
      gridLine: colorScheme.outlineVariant,
      gridBackground: colorScheme.surface,
      gridGlow: colorScheme.primary.withValues(alpha: 0.05),
    );
  }

  /// Creates the appropriate variant for [brightness].
  factory AppSemanticColors.fromBrightness({
    required Brightness brightness,
    required ColorScheme colorScheme,
  }) {
    return switch (brightness) {
      Brightness.light => AppSemanticColors.light(colorScheme),
      Brightness.dark => AppSemanticColors.dark(colorScheme),
    };
  }

  // -- Surface tokens --

  /// Primary surface color (page backgrounds).
  final Color surface;

  /// Elevated surface (cards, sheets, dialogs).
  final Color surfaceElevated;

  // -- Ink tokens --

  /// Primary text / icon color on surfaces.
  final Color ink;

  /// Subdued text / icon color (secondary labels, captions).
  final Color inkSubtle;

  // -- Border tokens --

  /// Standard border / divider color.
  final Color border;

  /// Subtle border (e.g. card outlines).
  final Color borderSubtle;

  // -- Grid tokens --

  /// Grid line color for [AppGridBackground] adaptive mode.
  final Color gridLine;

  /// Grid fill / background color for [AppGridBackground] adaptive mode.
  final Color gridBackground;

  /// Grid glow color for [AppGridBackground] adaptive mode.
  final Color gridGlow;

  @override
  AppSemanticColors copyWith({
    Color? surface,
    Color? surfaceElevated,
    Color? ink,
    Color? inkSubtle,
    Color? border,
    Color? borderSubtle,
    Color? gridLine,
    Color? gridBackground,
    Color? gridGlow,
  }) {
    return AppSemanticColors(
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      ink: ink ?? this.ink,
      inkSubtle: inkSubtle ?? this.inkSubtle,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      gridLine: gridLine ?? this.gridLine,
      gridBackground: gridBackground ?? this.gridBackground,
      gridGlow: gridGlow ?? this.gridGlow,
    );
  }

  @override
  AppSemanticColors lerp(
    covariant ThemeExtension<AppSemanticColors>? other,
    double t,
  ) {
    if (other is! AppSemanticColors) {
      return this;
    }
    return AppSemanticColors(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSubtle: Color.lerp(inkSubtle, other.inkSubtle, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      gridLine: Color.lerp(gridLine, other.gridLine, t)!,
      gridBackground: Color.lerp(gridBackground, other.gridBackground, t)!,
      gridGlow: Color.lerp(gridGlow, other.gridGlow, t)!,
    );
  }
}
