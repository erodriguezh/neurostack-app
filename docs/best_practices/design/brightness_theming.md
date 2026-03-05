# Brightness Theming Policy

> How Neurostack routes and widgets choose between dark-only and
> brightness-adaptive color palettes.

## Route Classification

Every route falls into one of two categories:

| Category | Follows system brightness? | Examples |
|---|---|---|
| **Adaptive** | Yes | Home, Library, Progress, Settings, Contact, Log Session (modal) |
| **Dark-first** | No -- always dark | Auth, Onboarding, Offline, Paywall, Splash |

### Adaptive routes

Surfaces, text, borders, and icons resolve from the ambient `ColorScheme` and
`AppSemanticColors` (once available). In light mode, backgrounds are light and
text is dark; in dark mode the inverse.

### Dark-first routes

Wrapped in `DarkThemeScope` (see `lib/core/ui/widgets/dark_theme_scope.dart`
once created). They receive a dark `ThemeData` regardless of the system
setting, so `whiteXX` tokens remain legible.

## Token Usage Rules

### When to use `whiteXX` tokens

Use `kitColors.whiteXX` **only** inside dark-first routes or widgets that are
guaranteed to sit on a dark surface. These tokens are white with fixed alpha;
on a light surface they become invisible or near-invisible.

```dart
// OK -- inside a DarkThemeScope or auth screen
Text('Welcome', style: TextStyle(color: kitColors.white90));
```

### When to use semantic tokens

On adaptive routes, use `ColorScheme` roles or `AppSemanticColors`:

| Need | Token |
|---|---|
| Primary text | `colorScheme.onSurface` |
| Secondary text | `colorScheme.onSurfaceVariant` |
| Surface fill | `colorScheme.surface` |
| Elevated surface | `colorScheme.surfaceContainer` |
| Subtle border | `colorScheme.outlineVariant` |
| Grid fill (adaptive) | `AppGridBackgroundMode.adaptive` resolves from `ColorScheme.surface` |
| Grid lines (adaptive) | `AppGridBackgroundMode.adaptive` resolves from `ColorScheme.outlineVariant` |
| Glow (adaptive) | `AppGridBackgroundMode.adaptive` resolves from `ColorScheme.primary` at 5% alpha |

### Migration path

1. New adaptive widgets should never reference `kitColors.whiteXX`.
2. Existing widgets migrate incrementally (one task per feature area).
3. `AppSemanticColors` (Task 3) will provide higher-level tokens that
   encapsulate the `ColorScheme` lookups above.

## AppGridBackground Modes

`AppGridBackgroundMode` controls how `AppGridBackground` resolves its palette:

- **`legacyDark`** (default) -- Fixed dark palette. Fill =
  `kitColors.background`, lines = `kitColors.white02`, glow =
  `kitColors.brandSky` at 5% alpha. Use on dark-first routes.
- **`adaptive`** -- Brightness-aware. Fill = `ColorScheme.surface`, lines =
  `ColorScheme.outlineVariant`, glow = `ColorScheme.primary` at 5% alpha.
  Use on adaptive routes.

Explicit color overrides (`fillColor`, `lineColor`, `glowColor`) take
priority over both modes.

The radial mask inside `_GridPainter` uses `Colors.white` with
`BlendMode.dstIn` for the circular fade effect. This relies on the alpha
channel, not the RGB values, so it works identically in both brightness modes
and must **not** be brightness-branched.

## Canonical Names

These names are locked for the migration and must not be renamed:

| Artifact | Name | Location |
|---|---|---|
| Background mode enum | `AppGridBackgroundMode` | `lib/core/ui/widgets/app_grid_background.dart` |
| Dark scope widget | `DarkThemeScope` | `lib/core/ui/widgets/dark_theme_scope.dart` |
| Semantic colors extension | `AppSemanticColors` | `lib/core/ui/extensions/app_semantic_colors.dart` |

## References

- Investigation (symptom): `docs/investigations/20260304120000_investigation_invisible_screen_titles.md`
- Investigation (plan): `docs/investigations/20260304133000_investigation_brightness_aware_theming_plan.md`
- Visual design tokens: `docs/best_practices/design/visual-design.md`
- Theme builder: `lib/core/ui/app_theme.dart`
- Color constants: `lib/core/ui/constants/kit_colors.dart`
