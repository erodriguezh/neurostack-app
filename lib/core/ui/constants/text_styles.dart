import 'package:flutter/material.dart';

@immutable
class CustomTextStyles extends ThemeExtension<CustomTextStyles> {
  /// 12 - Caption
  final TextStyle xs;

  /// 14 - Body
  final TextStyle sm;

  /// 16 - Body Large / Standard
  final TextStyle standard;

  /// 18 - Card titles (H3)
  final TextStyle lg;

  /// 20
  final TextStyle xl;

  /// 24
  final TextStyle xxl;

  /// 32 - Legacy, prefer h1 for screen titles
  final TextStyle xxxl;

  /// 28 - Section headers (H2), serif
  final TextStyle h2;

  /// 32 - Screen titles, serif italic
  final TextStyle h1;

  /// 11 - Mono/technical labels, uppercase
  final TextStyle mono;

  const CustomTextStyles({
    this.xs = const TextStyle(fontSize: 12.0, fontWeight: FontWeight.w400),
    this.sm = const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w300),
    this.standard = const TextStyle(
      fontSize: 16.0,
      fontWeight: FontWeight.w400,
    ),
    this.lg = const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
    this.xl = const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400),
    this.xxl = const TextStyle(fontSize: 24.0, fontWeight: FontWeight.w600),
    this.xxxl = const TextStyle(fontSize: 32.0, fontWeight: FontWeight.w600),
    this.h2 = const TextStyle(
      fontSize: 28.0,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.5,
    ),
    this.h1 = const TextStyle(
      fontSize: 32.0,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
      letterSpacing: -0.8,
    ),
    this.mono = const TextStyle(
      fontSize: 11.0,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.5,
    ),
  });

  @override
  CustomTextStyles copyWith({
    TextStyle? xs,
    TextStyle? sm,
    TextStyle? standard,
    TextStyle? lg,
    TextStyle? xl,
    TextStyle? xxl,
    TextStyle? xxxl,
    TextStyle? h2,
    TextStyle? h1,
    TextStyle? mono,
  }) {
    return CustomTextStyles(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      standard: standard ?? this.standard,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      xxxl: xxxl ?? this.xxxl,
      h2: h2 ?? this.h2,
      h1: h1 ?? this.h1,
      mono: mono ?? this.mono,
    );
  }

  @override
  CustomTextStyles lerp(ThemeExtension<CustomTextStyles>? other, double t) {
    if (other is! CustomTextStyles) return this;
    return CustomTextStyles(
      xs: TextStyle.lerp(xs, other.xs, t)!,
      sm: TextStyle.lerp(sm, other.sm, t)!,
      standard: TextStyle.lerp(standard, other.standard, t)!,
      lg: TextStyle.lerp(lg, other.lg, t)!,
      xl: TextStyle.lerp(xl, other.xl, t)!,
      xxl: TextStyle.lerp(xxl, other.xxl, t)!,
      xxxl: TextStyle.lerp(xxxl, other.xxxl, t)!,
      h2: TextStyle.lerp(h2, other.h2, t)!,
      h1: TextStyle.lerp(h1, other.h1, t)!,
      mono: TextStyle.lerp(mono, other.mono, t)!,
    );
  }
}
