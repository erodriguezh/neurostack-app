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
`AppSemanticColors`. In light mode, backgrounds are light and
text is dark; in dark mode the inverse.

### Dark-first routes

Wrapped in `DarkThemeScope` (see `lib/core/ui/widgets/dark_theme_scope.dart`
). They receive a dark `ThemeData` regardless of the system
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
| Grid fill (adaptive) | `AppGridBackgroundMode.adaptive` resolves from `semanticColors.gridBackground` |
| Grid lines (adaptive) | `AppGridBackgroundMode.adaptive` resolves from `semanticColors.gridLine` |
| Glow (adaptive) | `AppGridBackgroundMode.adaptive` resolves from `semanticColors.gridGlow` |

### Migration results (March 6, 2026)

1. Adaptive routes now use `AppGridBackgroundMode.adaptive`.
2. Dark-first routes are scoped by `DarkThemeScope`.
3. `AppSemanticColors` is implemented and registered in `AppTheme`.
4. Adaptive surfaces should now be considered `whiteXX`-free by policy.

## CI Guard (adaptive `whiteXX` enforcement)

CI enforces the adaptive policy via:

- Script: `tool/ci/check_adaptive_white_tokens.sh`
- Workflow step: `.github/workflows/test.yaml` (`Guard adaptive whiteXX usage`)

### Denylist (blocked from `kitColors.whiteXX`)

- `lib/home/`
- `lib/library/`
- `lib/progress/`
- `lib/settings/`
- `lib/core/ui/widgets/*.dart` (except `dark_theme_scope.dart` and `app_grid_background.dart`)

### Allowlist (dark-first, intentionally excluded)

- `lib/features/auth/`
- `lib/features/onboarding/`
- `lib/features/offline/` (legacy location)
- `lib/offline/` (current location)
- `lib/paywall/`
- `lib/startup/`

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
