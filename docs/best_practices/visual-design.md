# Visual Design System Rules

## Purpose

Visual design tokens, theming, and screen specification standards.

## Design Token Architecture

All visual values must reference tokens. Never hardcode colors, spacing, or typography.

### Token Hierarchy

```
Foundation Tokens (raw values)
    ↓
Semantic Tokens (purpose-based)
    ↓
Component Tokens (widget-specific)
```

### File Structure

```
lib/core/ui/
├── constants/
│   ├── app_colors.dart       # ColorScheme + semantic colors
│   ├── app_spacing.dart      # Spacing scale (8px grid)
│   ├── app_typography.dart   # TextTheme + custom styles
│   ├── app_shapes.dart       # Border radii
│   └── app_durations.dart    # Animation timing
├── theme/
│   ├── app_theme.dart        # ThemeData assembly
│   └── theme_extensions.dart # Custom ThemeExtension classes
└── widgets/
    └── ...                   # Reusable design system widgets
```

---

## Color System

### Seed-Based Generation (Material 3)

```dart
// app_colors.dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  // Seed color - single source of truth
  static const Color seedColor = Color(0xFF0D9488); // Teal

  // Generated schemes
  static final ColorScheme lightScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
  );

  static final ColorScheme darkScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.dark,
  );

  // Semantic colors (app-specific, not in Material)
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // NeuroStack brand colors
  static const Color brandSky = Color(0xFF38BDF8);
  static const Color background = Color(0xFF030303);
  static const Color panel = Color(0xFF050505);

  // Evidence level colors (domain-specific)
  static const Color evidenceStrong = Color(0xFF10B981);   // Multiple RCTs - emerald-400
  static const Color evidenceModerate = Color(0xFF38BDF8); // Single RCT - brand-sky
  static const Color evidenceWeak = Color(0x80FFFFFF);     // Observational/Expert - white/50

  // Trial status
  static const Color trialWarning = Color(0xFFFBBF24);     // Amber-400 - trial expiration
}
```

### Usage in Widgets

```dart
// ✅ Correct - reference ColorScheme
Container(
  color: Theme.of(context).colorScheme.primaryContainer,
)

// ✅ Correct - semantic color for app-specific meaning
Icon(Icons.check, color: AppColors.success)

// ❌ Wrong - hardcoded color
Container(color: Color(0xFF0D9488))

// ❌ Wrong - hardcoded opacity
Container(color: Colors.black.withOpacity(0.5))
```

---

## Spacing System

### 8px Grid Scale

```dart
// app_spacing.dart
abstract final class AppSpacing {
  static const double xs = 4;   // Micro adjustments
  static const double sm = 8;   // Inline spacing
  static const double md = 16;  // Card padding, list gaps
  static const double lg = 24;  // Section spacing
  static const double xl = 32;  // Screen margins
  static const double xxl = 48; // Large separators

  // Screen edge insets
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: lg,
  );

  // Card internal padding
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
}
```

### Usage

```dart
// ✅ Correct
Padding(padding: EdgeInsets.all(AppSpacing.md))
SizedBox(height: AppSpacing.lg)
Gap(AppSpacing.sm) // if using gap package

// ❌ Wrong - magic numbers
Padding(padding: EdgeInsets.all(16))
SizedBox(height: 24)
```

---

## Typography System

### TextTheme Mapping

```dart
// app_typography.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  static TextTheme textTheme(ColorScheme colorScheme) {
    return TextTheme(
      // Display - hero numbers, large promotional
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: colorScheme.onSurface,
      ),

      // Headline - screen titles
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),

      // Title - card titles, section headers
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
      ),

      // Body - main content
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: colorScheme.onSurfaceVariant,
      ),

      // Label - buttons, chips, badges
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
```

### Usage

```dart
// ✅ Correct - semantic style from theme
Text('Screen Title', style: Theme.of(context).textTheme.headlineMedium)
Text('Card title', style: Theme.of(context).textTheme.titleLarge)
Text('Body text', style: Theme.of(context).textTheme.bodyMedium)

// ✅ Correct - override specific property
Text(
  'Custom',
  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
    color: AppColors.success,
  ),
)

// ❌ Wrong - hardcoded TextStyle
Text('Title', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
```

---

## Shape System

### Border Radius Tokens

```dart
// app_shapes.dart
abstract final class AppShapes {
  static const double none = 0;
  static const double extraSmall = 4;
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double extraLarge = 28;

  // Common BorderRadius instances
  static final BorderRadius smallRadius = BorderRadius.circular(small);
  static final BorderRadius mediumRadius = BorderRadius.circular(medium);
  static final BorderRadius largeRadius = BorderRadius.circular(large);
  static final BorderRadius fullRadius = BorderRadius.circular(999);
}
```

---

## Animation System

### Duration Tokens

```dart
// app_durations.dart
abstract final class AppDurations {
  // Short - micro interactions
  static const Duration short1 = Duration(milliseconds: 50);
  static const Duration short2 = Duration(milliseconds: 100);
  static const Duration short3 = Duration(milliseconds: 150);
  static const Duration short4 = Duration(milliseconds: 200);

  // Medium - standard transitions
  static const Duration medium1 = Duration(milliseconds: 250);
  static const Duration medium2 = Duration(milliseconds: 300);
  static const Duration medium3 = Duration(milliseconds: 350);
  static const Duration medium4 = Duration(milliseconds: 400);

  // Long - complex animations
  static const Duration long1 = Duration(milliseconds: 450);
  static const Duration long2 = Duration(milliseconds: 500);
}

abstract final class AppCurves {
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);
  static const Curve standard = Curves.easeInOut;
}
```

### Usage

```dart
// ✅ Correct
AnimatedContainer(
  duration: AppDurations.medium2,
  curve: AppCurves.emphasized,
)

// ❌ Wrong
AnimatedContainer(
  duration: Duration(milliseconds: 300),
  curve: Curves.easeInOut,
)
```

---

## Theme Assembly

```dart
// app_theme.dart
import 'package:flutter/material.dart';

ThemeData appLightTheme() {
  final colorScheme = AppColors.lightScheme;

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: AppTypography.textTheme(colorScheme),

    // Component themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(64, 40),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: AppShapes.fullRadius,
        ),
      ),
    ),

    cardTheme: CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: AppShapes.mediumRadius,
      ),
      margin: EdgeInsets.zero,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      border: OutlineInputBorder(
        borderRadius: AppShapes.smallRadius,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
    ),
  );
}

ThemeData appDarkTheme() {
  final colorScheme = AppColors.darkScheme;
  // ... same structure with darkScheme
}
```

---

## Screen Specification Format

When specifying a screen's visual design, use this structure:

### Required Sections

```markdown
## [Screen Name]

### Layout
- Container: [surface/surfaceContainer/etc]
- Padding: [AppSpacing token]
- Structure: [Column/Row/Stack arrangement]

### Components
| Element | Style | Color | Spacing |
|---------|-------|-------|---------|
| Title | headlineMedium | onSurface | bottom: lg |
| Subtitle | bodyMedium | onSurfaceVariant | bottom: md |
| Card | elevated | surfaceContainerLow | padding: md |

### States
| State | Visual Change |
|-------|---------------|
| Loading | Skeleton with surfaceContainerHighest |
| Empty | Illustration + bodyMedium message |
| Error | errorContainer background, error text |

### Animations
| Trigger | Duration | Curve |
|---------|----------|-------|
| Enter | medium2 | emphasizedDecelerate |
| State change | short4 | standard |
```

---

## Accessibility Requirements

### Contrast Ratios
- Body text: 4.5:1 minimum (WCAG AA)
- Large text (18sp+): 3:1 minimum
- Verify with `Theme.of(context).colorScheme` - Material 3 handles this

### Touch Targets
- Minimum: 48x48 logical pixels
- Use `minimumSize` in button styles

```dart
// ✅ Correct - enforces minimum
ElevatedButton.styleFrom(
  minimumSize: const Size(48, 48),
)

// ❌ Risk - could be too small
SizedBox(
  width: 32,
  height: 32,
  child: IconButton(...),
)
```

### Focus Indicators
- Material 3 handles focus states automatically
- Don't override `overlayColor` without providing focus state

---

## Quick Reference

| Category | Token Class | Example |
|----------|-------------|---------|
| Colors | `AppColors` | `AppColors.success` |
| Spacing | `AppSpacing` | `AppSpacing.md` (16) |
| Typography | `Theme.of(context).textTheme` | `.headlineMedium` |
| Shapes | `AppShapes` | `AppShapes.mediumRadius` |
| Durations | `AppDurations` | `AppDurations.medium2` |
| Curves | `AppCurves` | `AppCurves.emphasized` |

---

## Checklist Before PR

- [ ] No hardcoded colors (use ColorScheme or AppColors)
- [ ] No magic numbers for spacing (use AppSpacing)
- [ ] No inline TextStyle (use textTheme with copyWith if needed)
- [ ] Animations use AppDurations and AppCurves
- [ ] Touch targets are 48x48 minimum
- [ ] Dark mode tested (ColorScheme handles most cases)
