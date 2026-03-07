import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neurostack/core/ui/constants/border_radius.dart';
import 'package:neurostack/core/ui/constants/breakpoints.dart';
import 'package:neurostack/core/ui/constants/curves.dart';
import 'package:neurostack/core/ui/constants/durations.dart';
import 'package:neurostack/core/ui/constants/kit_colors.dart';
import 'package:neurostack/core/ui/constants/shadows.dart';
import 'package:neurostack/core/ui/constants/spacing.dart';
import 'package:neurostack/core/ui/constants/text_styles.dart';
import 'package:neurostack/core/ui/extensions/app_semantic_colors.dart';

/// AppTheme is a class that builds a theme for the app.
/// By default this will support light and dark mode.
///
/// you can access different theme extensions from the context
///
/// ```dart
/// context.textStyles.standard
/// context.kitColors.neutral50
/// context.borderRadius.md
/// context.spacing.md
/// context.durations.duration200
/// context.shadows.sm
/// ```
///
/// Some are also just instances of the class, so you can access them directly without context:
///
/// ```dart
/// CustomSpacing.instance.md
/// CustomDurations.instance.duration200
/// CustomCurves.spring
/// ```
class AppTheme {
  static ThemeData buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    const textStyles = CustomTextStyles();
    const borderRadius = CustomBorderRadius();
    const breakpoints = CustomBreakpoints();
    const shadows = CustomShadows();
    const kitColors = KitColorsExtension();

    final colorScheme = ColorScheme(
      brightness: brightness,
      // Surface colors
      surface: isDark ? kitColors.background : kitColors.neutral100,
      surfaceContainerLowest: isDark
          ? kitColors.background
          : kitColors.neutral50,
      surfaceContainerLow: isDark
          ? kitColors.brandDark
          : kitColors.neutral100,
      surfaceContainer: isDark ? kitColors.panel : kitColors.neutral200,
      surfaceContainerHigh: isDark
          ? kitColors.neutral800
          : kitColors.neutral300,
      surfaceTint: isDark ? kitColors.background : kitColors.neutral100,
      // Primary colors - use brand sky for dark
      primary: isDark ? kitColors.brandSky : kitColors.neutral950,
      onPrimary: isDark ? kitColors.background : kitColors.neutral50,
      // Secondary
      secondary: isDark ? kitColors.brandSky : kitColors.neutral950,
      onSecondary: isDark ? kitColors.background : kitColors.neutral50,
      // Tertiary - success color
      tertiary: isDark ? kitColors.success : kitColors.green600,
      onTertiary: isDark ? kitColors.background : kitColors.neutral50,
      // Error - warning for dark theme
      error: isDark ? kitColors.warning : Colors.red.shade400,
      onError: kitColors.neutral50,
      // Text colors - use white opacity scale for dark
      onSurface: isDark ? kitColors.white90 : kitColors.neutral950,
      onSurfaceVariant: isDark ? kitColors.white60 : kitColors.neutral600,
      // Border colors
      outline: isDark ? kitColors.white10 : kitColors.neutral300,
      outlineVariant: isDark ? kitColors.white05 : kitColors.neutral200,
    );

    final semanticColors = AppSemanticColors.fromBrightness(
      brightness: brightness,
      colorScheme: colorScheme,
    );

    return ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
      scaffoldBackgroundColor: isDark
          ? kitColors.background
          : kitColors.neutral100,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? kitColors.white90 : kitColors.neutral950,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? kitColors.white10 : kitColors.neutral200,
      ),
      textTheme: TextTheme(
        // Display - hero numbers (Newsreader italic)
        displayLarge: GoogleFonts.newsreader(
          textStyle: textStyles.h1,
          color: isDark ? kitColors.white90 : kitColors.neutral950,
        ),
        // Headlines (Newsreader)
        headlineLarge: GoogleFonts.newsreader(
          textStyle: textStyles.h1,
          color: isDark ? kitColors.white90 : kitColors.neutral950,
        ),
        headlineMedium: GoogleFonts.newsreader(
          textStyle: textStyles.h2,
          color: isDark ? kitColors.white90 : kitColors.neutral950,
        ),
        // Titles (Inter)
        titleLarge: GoogleFonts.inter(
          textStyle: textStyles.lg,
          color: isDark ? kitColors.white90 : kitColors.neutral950,
        ),
        titleMedium: GoogleFonts.inter(
          textStyle: textStyles.standard,
          color: isDark ? kitColors.white90 : kitColors.neutral950,
        ),
        // Body (Inter)
        bodyLarge: GoogleFonts.inter(
          textStyle: textStyles.standard,
          color: isDark ? kitColors.white80 : kitColors.neutral950,
        ),
        bodyMedium: GoogleFonts.inter(
          textStyle: textStyles.sm,
          color: isDark ? kitColors.white70 : kitColors.neutral700,
        ),
        bodySmall: GoogleFonts.inter(
          textStyle: textStyles.xs,
          color: isDark ? kitColors.white60 : kitColors.neutral600,
        ),
        // Labels (Inter)
        labelLarge: GoogleFonts.inter(
          textStyle: textStyles.sm,
          color: isDark ? kitColors.white70 : kitColors.neutral950,
        ),
        labelMedium: GoogleFonts.inter(
          textStyle: textStyles.xs,
          color: isDark ? kitColors.white40 : kitColors.neutral500,
        ),
        labelSmall: GoogleFonts.robotoMono(
          textStyle: textStyles.mono,
          color: isDark ? kitColors.white40 : kitColors.neutral500,
        ),
      ),
      iconTheme: IconThemeData(
        color: isDark ? kitColors.white40 : kitColors.neutral950,
      ),
      extensions: [
        textStyles,
        borderRadius,
        breakpoints,
        shadows,
        kitColors,
        semanticColors,
      ],
      useMaterial3: true,
      splashFactory: NoSplash.splashFactory,
      highlightColor: colorScheme.onSurface.withValues(alpha: .1),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: GoogleFonts.inter(
          textStyle: textStyles.standard,
          color: isDark ? kitColors.white80 : kitColors.neutral950,
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
            isDark ? kitColors.panel : kitColors.neutral100,
          ),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: isDark ? kitColors.panel : kitColors.neutral100,
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: isDark ? kitColors.white10 : kitColors.neutral200,
            ),
            borderRadius: borderRadius.md,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: isDark ? kitColors.white10 : kitColors.neutral200,
            ),
            borderRadius: borderRadius.md,
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: isDark ? kitColors.brandSky : kitColors.neutral400,
              width: 2,
            ),
            borderRadius: borderRadius.md,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: CustomSpacing.instance.md,
            vertical: CustomSpacing.instance.sm,
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? kitColors.panel : kitColors.neutral100,
        textStyle: GoogleFonts.inter(
          textStyle: textStyles.standard,
          color: isDark ? kitColors.white80 : kitColors.neutral950,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: borderRadius.full),
          minimumSize: const Size(64, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(9999)),
          ),
          side: BorderSide(
            color: isDark ? kitColors.white10 : kitColors.neutral200,
          ),
          minimumSize: const Size(64, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: borderRadius.full),
          minimumSize: const Size(64, 48),
        ),
      ),
    );
  }
}

extension ThemeDataX on BuildContext {
  ThemeData get theme => Theme.of(this);

  CustomTextStyles get textStyles =>
      Theme.of(this).extension<CustomTextStyles>()!;

  KitColorsExtension get kitColors =>
      Theme.of(this).extension<KitColorsExtension>()!;

  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>()!;

  CustomBorderRadius get borderRadius =>
      Theme.of(this).extension<CustomBorderRadius>()!;

  CustomBreakpoints get breakpoints =>
      Theme.of(this).extension<CustomBreakpoints>()!;

  CustomCurves get curves => CustomCurves.instance;

  CustomDurations get durations => CustomDurations.instance;

  CustomSpacing get spacing => CustomSpacing.instance;

  CustomShadows get shadows => Theme.of(this).extension<CustomShadows>()!;
}
