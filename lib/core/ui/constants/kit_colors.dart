import 'package:flutter/material.dart';

@immutable
class KitColorsExtension extends ThemeExtension<KitColorsExtension> {
  // Red Colors
  final Color red50;
  final Color red100;
  final Color red200;
  final Color red300;
  final Color red400;
  final Color red500;
  final Color red600;
  final Color red700;
  final Color red800;
  final Color red900;
  final Color red950;

  // Yellow Colors
  final Color yellow50;
  final Color yellow100;
  final Color yellow200;
  final Color yellow300;
  final Color yellow400;
  final Color yellow500;
  final Color yellow600;
  final Color yellow700;
  final Color yellow800;
  final Color yellow900;
  final Color yellow950;

  // Green Colors
  final Color green50;
  final Color green100;
  final Color green200;
  final Color green300;
  final Color green400;
  final Color green500;
  final Color green600;
  final Color green700;
  final Color green800;
  final Color green900;
  final Color green950;

  // Neutral Colors
  final Color neutral50;
  final Color neutral100;
  final Color neutral200;
  final Color neutral300;
  final Color neutral400;
  final Color neutral500;
  final Color neutral600;
  final Color neutral700;
  final Color neutral800;
  final Color neutral900;
  final Color neutral950;

  // Brand Colors
  final Color brandSky;
  final Color brandDark;
  final Color panel;
  final Color background;

  // Semantic Colors
  final Color success;
  final Color successLight;
  final Color warning;
  final Color info;

  // Evidence Level Colors
  final Color evidenceStrong;
  final Color evidenceModerate;
  final Color evidenceWeak;

  // White Opacity Scale
  final Color white90;
  final Color white80;
  final Color white70;
  final Color white60;
  final Color white50;
  final Color white40;
  final Color white30;
  final Color white20;
  final Color white10;
  final Color white05;
  final Color white02;

  const KitColorsExtension({
    // Red Colors
    this.red50 = KitColors.red50,
    this.red100 = KitColors.red100,
    this.red200 = KitColors.red200,
    this.red300 = KitColors.red300,
    this.red400 = KitColors.red400,
    this.red500 = KitColors.red500,
    this.red600 = KitColors.red600,
    this.red700 = KitColors.red700,
    this.red800 = KitColors.red800,
    this.red900 = KitColors.red900,
    this.red950 = KitColors.red950,
    // Yellow Colors
    this.yellow50 = KitColors.yellow50,
    this.yellow100 = KitColors.yellow100,
    this.yellow200 = KitColors.yellow200,
    this.yellow300 = KitColors.yellow300,
    this.yellow400 = KitColors.yellow400,
    this.yellow500 = KitColors.yellow500,
    this.yellow600 = KitColors.yellow600,
    this.yellow700 = KitColors.yellow700,
    this.yellow800 = KitColors.yellow800,
    this.yellow900 = KitColors.yellow900,
    this.yellow950 = KitColors.yellow950,
    // Green Colors
    this.green50 = KitColors.green50,
    this.green100 = KitColors.green100,
    this.green200 = KitColors.green200,
    this.green300 = KitColors.green300,
    this.green400 = KitColors.green400,
    this.green500 = KitColors.green500,
    this.green600 = KitColors.green600,
    this.green700 = KitColors.green700,
    this.green800 = KitColors.green800,
    this.green900 = KitColors.green900,
    this.green950 = KitColors.green950,
    // Neutral Colors
    this.neutral50 = KitColors.neutral50,
    this.neutral100 = KitColors.neutral100,
    this.neutral200 = KitColors.neutral200,
    this.neutral300 = KitColors.neutral300,
    this.neutral400 = KitColors.neutral400,
    this.neutral500 = KitColors.neutral500,
    this.neutral600 = KitColors.neutral600,
    this.neutral700 = KitColors.neutral700,
    this.neutral800 = KitColors.neutral800,
    this.neutral900 = KitColors.neutral900,
    this.neutral950 = KitColors.neutral950,
    // Brand Colors
    this.brandSky = KitColors.brandSky,
    this.brandDark = KitColors.brandDark,
    this.panel = KitColors.panel,
    this.background = KitColors.background,
    // Semantic Colors
    this.success = KitColors.success,
    this.successLight = KitColors.successLight,
    this.warning = KitColors.warning,
    this.info = KitColors.info,
    // Evidence Level Colors
    this.evidenceStrong = KitColors.evidenceStrong,
    this.evidenceModerate = KitColors.evidenceModerate,
    this.evidenceWeak = KitColors.evidenceWeak,
    // White Opacity Scale
    this.white90 = KitColors.white90,
    this.white80 = KitColors.white80,
    this.white70 = KitColors.white70,
    this.white60 = KitColors.white60,
    this.white50 = KitColors.white50,
    this.white40 = KitColors.white40,
    this.white30 = KitColors.white30,
    this.white20 = KitColors.white20,
    this.white10 = KitColors.white10,
    this.white05 = KitColors.white05,
    this.white02 = KitColors.white02,
  });

  @override
  ThemeExtension<KitColorsExtension> copyWith({
    // Red Colors
    Color? red50,
    Color? red100,
    Color? red200,
    Color? red300,
    Color? red400,
    Color? red500,
    Color? red600,
    Color? red700,
    Color? red800,
    Color? red900,
    Color? red950,
    // Yellow Colors
    Color? yellow50,
    Color? yellow100,
    Color? yellow200,
    Color? yellow300,
    Color? yellow400,
    Color? yellow500,
    Color? yellow600,
    Color? yellow700,
    Color? yellow800,
    Color? yellow900,
    Color? yellow950,
    // Green Colors
    Color? green50,
    Color? green100,
    Color? green200,
    Color? green300,
    Color? green400,
    Color? green500,
    Color? green600,
    Color? green700,
    Color? green800,
    Color? green900,
    Color? green950,
    // Neutral Colors
    Color? neutral50,
    Color? neutral100,
    Color? neutral200,
    Color? neutral300,
    Color? neutral400,
    Color? neutral500,
    Color? neutral600,
    Color? neutral700,
    Color? neutral800,
    Color? neutral900,
    Color? neutral950,
    // Brand Colors
    Color? brandSky,
    Color? brandDark,
    Color? panel,
    Color? background,
    // Semantic Colors
    Color? success,
    Color? successLight,
    Color? warning,
    Color? info,
    // Evidence Level Colors
    Color? evidenceStrong,
    Color? evidenceModerate,
    Color? evidenceWeak,
    // White Opacity Scale
    Color? white90,
    Color? white80,
    Color? white70,
    Color? white60,
    Color? white50,
    Color? white40,
    Color? white30,
    Color? white20,
    Color? white10,
    Color? white05,
    Color? white02,
  }) {
    return KitColorsExtension(
      // Red Colors
      red50: red50 ?? this.red50,
      red100: red100 ?? this.red100,
      red200: red200 ?? this.red200,
      red300: red300 ?? this.red300,
      red400: red400 ?? this.red400,
      red500: red500 ?? this.red500,
      red600: red600 ?? this.red600,
      red700: red700 ?? this.red700,
      red800: red800 ?? this.red800,
      red900: red900 ?? this.red900,
      red950: red950 ?? this.red950,
      // Yellow Colors
      yellow50: yellow50 ?? this.yellow50,
      yellow100: yellow100 ?? this.yellow100,
      yellow200: yellow200 ?? this.yellow200,
      yellow300: yellow300 ?? this.yellow300,
      yellow400: yellow400 ?? this.yellow400,
      yellow500: yellow500 ?? this.yellow500,
      yellow600: yellow600 ?? this.yellow600,
      yellow700: yellow700 ?? this.yellow700,
      yellow800: yellow800 ?? this.yellow800,
      yellow900: yellow900 ?? this.yellow900,
      yellow950: yellow950 ?? this.yellow950,
      // Green Colors
      green50: green50 ?? this.green50,
      green100: green100 ?? this.green100,
      green200: green200 ?? this.green200,
      green300: green300 ?? this.green300,
      green400: green400 ?? this.green400,
      green500: green500 ?? this.green500,
      green600: green600 ?? this.green600,
      green700: green700 ?? this.green700,
      green800: green800 ?? this.green800,
      green900: green900 ?? this.green900,
      green950: green950 ?? this.green950,
      // Neutral Colors
      neutral50: neutral50 ?? this.neutral50,
      neutral100: neutral100 ?? this.neutral100,
      neutral200: neutral200 ?? this.neutral200,
      neutral300: neutral300 ?? this.neutral300,
      neutral400: neutral400 ?? this.neutral400,
      neutral500: neutral500 ?? this.neutral500,
      neutral600: neutral600 ?? this.neutral600,
      neutral700: neutral700 ?? this.neutral700,
      neutral800: neutral800 ?? this.neutral800,
      neutral900: neutral900 ?? this.neutral900,
      neutral950: neutral950 ?? this.neutral950,
      // Brand Colors
      brandSky: brandSky ?? this.brandSky,
      brandDark: brandDark ?? this.brandDark,
      panel: panel ?? this.panel,
      background: background ?? this.background,
      // Semantic Colors
      success: success ?? this.success,
      successLight: successLight ?? this.successLight,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      // Evidence Level Colors
      evidenceStrong: evidenceStrong ?? this.evidenceStrong,
      evidenceModerate: evidenceModerate ?? this.evidenceModerate,
      evidenceWeak: evidenceWeak ?? this.evidenceWeak,
      // White Opacity Scale
      white90: white90 ?? this.white90,
      white80: white80 ?? this.white80,
      white70: white70 ?? this.white70,
      white60: white60 ?? this.white60,
      white50: white50 ?? this.white50,
      white40: white40 ?? this.white40,
      white30: white30 ?? this.white30,
      white20: white20 ?? this.white20,
      white10: white10 ?? this.white10,
      white05: white05 ?? this.white05,
      white02: white02 ?? this.white02,
    );
  }

  @override
  ThemeExtension<KitColorsExtension> lerp(
    covariant ThemeExtension<KitColorsExtension>? other,
    double t,
  ) {
    if (other is! KitColorsExtension) {
      return this;
    }
    return KitColorsExtension(
      // Red Colors
      red50: Color.lerp(red50, other.red50, t)!,
      red100: Color.lerp(red100, other.red100, t)!,
      red200: Color.lerp(red200, other.red200, t)!,
      red300: Color.lerp(red300, other.red300, t)!,
      red400: Color.lerp(red400, other.red400, t)!,
      red500: Color.lerp(red500, other.red500, t)!,
      red600: Color.lerp(red600, other.red600, t)!,
      red700: Color.lerp(red700, other.red700, t)!,
      red800: Color.lerp(red800, other.red800, t)!,
      red900: Color.lerp(red900, other.red900, t)!,
      red950: Color.lerp(red950, other.red950, t)!,
      // Yellow Colors
      yellow50: Color.lerp(yellow50, other.yellow50, t)!,
      yellow100: Color.lerp(yellow100, other.yellow100, t)!,
      yellow200: Color.lerp(yellow200, other.yellow200, t)!,
      yellow300: Color.lerp(yellow300, other.yellow300, t)!,
      yellow400: Color.lerp(yellow400, other.yellow400, t)!,
      yellow500: Color.lerp(yellow500, other.yellow500, t)!,
      yellow600: Color.lerp(yellow600, other.yellow600, t)!,
      yellow700: Color.lerp(yellow700, other.yellow700, t)!,
      yellow800: Color.lerp(yellow800, other.yellow800, t)!,
      yellow900: Color.lerp(yellow900, other.yellow900, t)!,
      yellow950: Color.lerp(yellow950, other.yellow950, t)!,
      // Green Colors
      green50: Color.lerp(green50, other.green50, t)!,
      green100: Color.lerp(green100, other.green100, t)!,
      green200: Color.lerp(green200, other.green200, t)!,
      green300: Color.lerp(green300, other.green300, t)!,
      green400: Color.lerp(green400, other.green400, t)!,
      green500: Color.lerp(green500, other.green500, t)!,
      green600: Color.lerp(green600, other.green600, t)!,
      green700: Color.lerp(green700, other.green700, t)!,
      green800: Color.lerp(green800, other.green800, t)!,
      green900: Color.lerp(green900, other.green900, t)!,
      green950: Color.lerp(green950, other.green950, t)!,
      // Neutral Colors
      neutral50: Color.lerp(neutral50, other.neutral50, t)!,
      neutral100: Color.lerp(neutral100, other.neutral100, t)!,
      neutral200: Color.lerp(neutral200, other.neutral200, t)!,
      neutral300: Color.lerp(neutral300, other.neutral300, t)!,
      neutral400: Color.lerp(neutral400, other.neutral400, t)!,
      neutral500: Color.lerp(neutral500, other.neutral500, t)!,
      neutral600: Color.lerp(neutral600, other.neutral600, t)!,
      neutral700: Color.lerp(neutral700, other.neutral700, t)!,
      neutral800: Color.lerp(neutral800, other.neutral800, t)!,
      neutral900: Color.lerp(neutral900, other.neutral900, t)!,
      neutral950: Color.lerp(neutral950, other.neutral950, t)!,
      // Brand Colors
      brandSky: Color.lerp(brandSky, other.brandSky, t)!,
      brandDark: Color.lerp(brandDark, other.brandDark, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      background: Color.lerp(background, other.background, t)!,
      // Semantic Colors
      success: Color.lerp(success, other.success, t)!,
      successLight: Color.lerp(successLight, other.successLight, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      // Evidence Level Colors
      evidenceStrong: Color.lerp(evidenceStrong, other.evidenceStrong, t)!,
      evidenceModerate: Color.lerp(
        evidenceModerate,
        other.evidenceModerate,
        t,
      )!,
      evidenceWeak: Color.lerp(evidenceWeak, other.evidenceWeak, t)!,
      // White Opacity Scale
      white90: Color.lerp(white90, other.white90, t)!,
      white80: Color.lerp(white80, other.white80, t)!,
      white70: Color.lerp(white70, other.white70, t)!,
      white60: Color.lerp(white60, other.white60, t)!,
      white50: Color.lerp(white50, other.white50, t)!,
      white40: Color.lerp(white40, other.white40, t)!,
      white30: Color.lerp(white30, other.white30, t)!,
      white20: Color.lerp(white20, other.white20, t)!,
      white10: Color.lerp(white10, other.white10, t)!,
      white05: Color.lerp(white05, other.white05, t)!,
      white02: Color.lerp(white02, other.white02, t)!,
    );
  }
}

class KitColors {
  const KitColors._(); // Private constructor to prevent instantiation

  // Red Colors
  static const red50 = Color(0xFFFEF2F2);
  static const red100 = Color(0xFFFEE2E2);
  static const red200 = Color(0xFFFECACA);
  static const red300 = Color(0xFFFCA5A5);
  static const red400 = Color(0xFFF87171);
  static const red500 = Color(0xFFEF4444);
  static const red600 = Color(0xFFDC2626);
  static const red700 = Color(0xFFB91C1C);
  static const red800 = Color(0xFF991B1B);
  static const red900 = Color(0xFF7F1D1D);
  static const red950 = Color(0xFF450A0A);

  // Yellow Colors
  static const yellow50 = Color(0xFFFEFCE8);
  static const yellow100 = Color(0xFFFEF9C3);
  static const yellow200 = Color(0xFFFEF08A);
  static const yellow300 = Color(0xFFFDE047);
  static const yellow400 = Color(0xFFFACC15);
  static const yellow500 = Color(0xFFEAB308);
  static const yellow600 = Color(0xFFCA8A04);
  static const yellow700 = Color(0xFFA16207);
  static const yellow800 = Color(0xFF854D0E);
  static const yellow900 = Color(0xFF713F12);
  static const yellow950 = Color(0xFF422006);

  // Green Colors
  static const green50 = Color(0xFFF0FDF4);
  static const green100 = Color(0xFFDCFCE7);
  static const green200 = Color(0xFFBBF7D0);
  static const green300 = Color(0xFF86EFAC);
  static const green400 = Color(0xFF4ADE80);
  static const green500 = Color(0xFF22C55E);
  static const green600 = Color(0xFF16A34A);
  static const green700 = Color(0xFF15803D);
  static const green800 = Color(0xFF166534);
  static const green900 = Color(0xFF14532D);
  static const green950 = Color(0xFF052E16);

  // Neutral Colors
  static const neutral50 = Color(0xFFFAFAFA);
  static const neutral100 = Color(0xFFF5F5F5);
  static const neutral200 = Color(0xFFE5E5E5);
  static const neutral300 = Color(0xFFD4D4D4);
  static const neutral400 = Color(0xFFA3A3A3);
  static const neutral500 = Color(0xFF737373);
  static const neutral600 = Color(0xFF525252);
  static const neutral700 = Color(0xFF404040);
  static const neutral800 = Color(0xFF262626);
  static const neutral900 = Color(0xFF171717);
  static const neutral950 = Color(0xFF0A0A0A);

  // Brand Colors
  static const brandSky = Color(0xFF38BDF8);
  static const brandDark = Color(0xFF050505);
  static const panel = Color(0xFF0F110E);
  static const background = Color(0xFF030303);

  // Semantic Colors
  static const success = Color(0xFF10B981); // Emerald-500
  static const successLight = Color(0xFF34D399); // Emerald-400
  static const warning = Color(0xFFFBBF24); // Amber-400
  static const info = Color(0xFF3B82F6); // Blue-500

  // Evidence Level Colors
  static const evidenceStrong = Color(0xFF34D399); // Emerald-400
  static const evidenceModerate = Color(0xFF38BDF8); // Brand Sky
  static const evidenceWeak = Color(0x80FFFFFF); // white/50

  // White Opacity Scale
  static const white90 = Color(0xE6FFFFFF); // 0.9 - Headlines
  static const white80 = Color(0xCCFFFFFF); // 0.8 - Body text light
  static const white70 = Color(0xB3FFFFFF); // 0.7 - Subheadings
  static const white60 = Color(0x99FFFFFF); // 0.6 - Secondary text
  static const white50 = Color(0x80FFFFFF); // 0.5 - Tertiary text
  static const white40 = Color(0x66FFFFFF); // 0.4 - Muted labels
  static const white30 = Color(0x4DFFFFFF); // 0.3 - Disabled
  static const white20 = Color(0x33FFFFFF); // 0.2 - Subtle elements
  static const white10 = Color(0x1AFFFFFF); // 0.1 - Borders, dividers
  static const white05 = Color(0x0DFFFFFF); // 0.05 - Subtle backgrounds
  static const white02 = Color(0x05FFFFFF); // 0.02 - Card fills
}
