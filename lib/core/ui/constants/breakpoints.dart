import 'package:flutter/material.dart';
import 'dart:ui'; // For lerpDouble

/// A ThemeExtension for defining custom breakpoint values (screen widths),
/// inspired by Tailwind CSS.
@immutable
class CustomBreakpoints extends ThemeExtension<CustomBreakpoints> {
  /// 640 - Compact/Medium boundary
  /// Below this: single-pane layouts, bottom navigation
  final double sm;

  /// 768 - Medium/Expanded boundary
  /// Above this: navigation rail becomes viable, two-pane layouts
  final double md;

  /// 1024 - Medium/Expanded boundary
  /// Navigation rail becomes viable, two-pane layouts
  final double lg;

  /// 1280 - Expanded/Large boundary
  /// Above this: navigation drawer, multi-pane layouts
  final double xl;

  /// 1536 - Large/ExtraLarge boundary
  /// Above this: max-width containers recommended, 4K displays
  final double xxl;

  const CustomBreakpoints({
    this.sm = 640.0,
    this.md = 768.0,
    this.lg = 1024.0,
    this.xl = 1280.0,
    this.xxl = 1536.0,
  });

  @override
  CustomBreakpoints copyWith({
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
  }) {
    return CustomBreakpoints(
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
    );
  }

  @override
  CustomBreakpoints lerp(ThemeExtension<CustomBreakpoints>? other, double t) {
    if (other is! CustomBreakpoints) return this;
    return CustomBreakpoints(
      sm: lerpDouble(sm, other.sm, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xl: lerpDouble(xl, other.xl, t)!,
      xxl: lerpDouble(xxl, other.xxl, t)!,
    );
  }
}
