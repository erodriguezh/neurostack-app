import 'package:flutter/material.dart';

/// A ThemeExtension for defining custom box shadow values, inspired by Tailwind CSS.
@immutable
class CustomShadows extends ThemeExtension<CustomShadows> {
  final List<BoxShadow> sm;
  final List<BoxShadow> md;
  final List<BoxShadow> lg;
  final List<BoxShadow> xl;
  final List<BoxShadow> xxl;

  /// Brand sky glow - hover states, subtle emphasis
  final List<BoxShadow> skyGlow;

  /// Brand sky strong glow - primary CTAs, active states
  final List<BoxShadow> skyGlowStrong;

  /// Amber glow - trial expiration warning
  final List<BoxShadow> amberGlow;

  /// Icon glow - selected checkboxes, badges
  final List<BoxShadow> iconGlow;

  // Using common rgba shadow colors from Tailwind defaults
  // You might want to tweak these based on your specific theme colors
  static const _colorBase = Color.fromRGBO(0, 0, 0, 0.1);
  static const _colorMd = Color.fromRGBO(0, 0, 0, 0.1);
  static const _colorMdAlt = Color.fromRGBO(0, 0, 0, 0.06);
  static const _colorLg = Color.fromRGBO(0, 0, 0, 0.1);
  static const _colorLgAlt = Color.fromRGBO(0, 0, 0, 0.05);
  static const _colorXl = Color.fromRGBO(0, 0, 0, 0.1);
  static const _colorXlAlt = Color.fromRGBO(0, 0, 0, 0.05);
  static const _color2xl = Color.fromRGBO(0, 0, 0, 0.25);

  // Glow colors
  static const _colorSkyGlow = Color(0x1A38BDF8); // rgba(56,189,248,0.1)
  static const _colorSkyGlowStrong = Color(0x4D38BDF8); // rgba(56,189,248,0.3)
  static const _colorAmberGlow = Color(0x33FBBF24); // rgba(251,191,36,0.2)

  const CustomShadows({
    this.sm = const [
      BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: _colorBase),
    ],
    this.md = const [
      BoxShadow(
        offset: Offset(0, 4),
        blurRadius: 6,
        spreadRadius: -1,
        color: _colorMd,
      ),
      BoxShadow(
        offset: Offset(0, 2),
        blurRadius: 4,
        spreadRadius: -1,
        color: _colorMdAlt,
      ),
    ],
    this.lg = const [
      BoxShadow(
        offset: Offset(0, 10),
        blurRadius: 15,
        spreadRadius: -3,
        color: _colorLg,
      ),
      BoxShadow(
        offset: Offset(0, 4),
        blurRadius: 6,
        spreadRadius: -2,
        color: _colorLgAlt,
      ),
    ],
    this.xl = const [
      BoxShadow(
        offset: Offset(0, 20),
        blurRadius: 25,
        spreadRadius: -5,
        color: _colorXl,
      ),
      BoxShadow(
        offset: Offset(0, 10),
        blurRadius: 10,
        spreadRadius: -5,
        color: _colorXlAlt,
      ),
    ],
    this.xxl = const [
      BoxShadow(
        offset: Offset(0, 25),
        blurRadius: 50,
        spreadRadius: -12,
        color: _color2xl,
      ),
    ],
    this.skyGlow = const [
      BoxShadow(
        offset: Offset.zero,
        blurRadius: 20,
        color: _colorSkyGlow,
      ),
    ],
    this.skyGlowStrong = const [
      BoxShadow(
        offset: Offset.zero,
        blurRadius: 25,
        color: _colorSkyGlowStrong,
      ),
    ],
    this.amberGlow = const [
      BoxShadow(
        offset: Offset.zero,
        blurRadius: 25,
        color: _colorAmberGlow,
      ),
    ],
    this.iconGlow = const [
      BoxShadow(
        offset: Offset.zero,
        blurRadius: 10,
        color: _colorSkyGlowStrong,
      ),
    ],
  });

  @override
  CustomShadows copyWith({
    List<BoxShadow>? sm,
    List<BoxShadow>? md,
    List<BoxShadow>? lg,
    List<BoxShadow>? xl,
    List<BoxShadow>? xxl,
    List<BoxShadow>? skyGlow,
    List<BoxShadow>? skyGlowStrong,
    List<BoxShadow>? amberGlow,
    List<BoxShadow>? iconGlow,
  }) {
    return CustomShadows(
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      skyGlow: skyGlow ?? this.skyGlow,
      skyGlowStrong: skyGlowStrong ?? this.skyGlowStrong,
      amberGlow: amberGlow ?? this.amberGlow,
      iconGlow: iconGlow ?? this.iconGlow,
    );
  }

  @override
  CustomShadows lerp(ThemeExtension<CustomShadows>? other, double t) {
    if (other is! CustomShadows) return this;
    return CustomShadows(
      sm: BoxShadow.lerpList(sm, other.sm, t) ?? sm,
      md: BoxShadow.lerpList(md, other.md, t) ?? md,
      lg: BoxShadow.lerpList(lg, other.lg, t) ?? lg,
      xl: BoxShadow.lerpList(xl, other.xl, t) ?? xl,
      xxl: BoxShadow.lerpList(xxl, other.xxl, t) ?? xxl,
      skyGlow: BoxShadow.lerpList(skyGlow, other.skyGlow, t) ?? skyGlow,
      skyGlowStrong:
          BoxShadow.lerpList(skyGlowStrong, other.skyGlowStrong, t) ??
          skyGlowStrong,
      amberGlow: BoxShadow.lerpList(amberGlow, other.amberGlow, t) ?? amberGlow,
      iconGlow: BoxShadow.lerpList(iconGlow, other.iconGlow, t) ?? iconGlow,
    );
  }
}
