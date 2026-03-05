## Description
Create `AppSemanticColors` ThemeExtension with brightness-aware surface/ink/border/grid tokens. Wire it into `AppTheme.buildTheme`, add a context accessor, update `AppGridBackground` adaptive mode to use semantic grid tokens, and fix global highlight/overlay whites.


**Size:** M
**Files:**
- `lib/core/ui/extensions/app_semantic_colors.dart` (new) — ThemeExtension definition (matches existing `extensions/` directory)
- `lib/core/ui/app_theme.dart` — register extension, add context accessor, fix `highlightColor` from `Colors.white` to `colorScheme.onSurface`-derived
- `lib/core/ui/widgets/app_grid_background.dart` — update adaptive mode to read from `AppSemanticColors` grid tokens (gridLine, gridBackground, gridGlow) instead of raw `ColorScheme`
- `test/core/ui/extensions/app_semantic_colors_test.dart` (new) — contrast validation
- `test/helpers/contrast_ratio.dart` (new) — WCAG contrast ratio helper (shared by all subsequent tasks)
- `test/core/ui/widgets/app_grid_background_test.dart` — update adaptive mode assertions to use semantic tokens instead of raw ColorScheme

## Approach
- Follow existing `KitColorsExtension` pattern at `kit_colors.dart:4-408` for structure
- Semantic tokens to include: `surface`, `surfaceElevated`, `ink`, `inkSubtle`, `border`, `borderSubtle`, `gridLine`, `gridBackground`, `gridGlow`
- Light mode: derive from `ColorScheme` light values (dark ink on light surface)
- Dark mode: map to existing `KitColors` dark palette equivalents for visual continuity
- Add `context.semanticColors` accessor following pattern at `app_theme.dart:231-253`
- Must implement `copyWith` and `lerp` for animated theme transitions
- Contrast helper: use `Color.computeLuminance()` (built-in WCAG relative luminance)
- Update `AppGridBackground` adaptive mode to prefer `AppSemanticColors` grid tokens
- Fix `highlightColor: Colors.white.withValues(alpha: .1)` in `app_theme.dart:157` — derive from `colorScheme.onSurface` to avoid washed-out highlights on light surfaces
- `DarkThemeScope` (Task 2) uses `AppTheme.buildTheme(Brightness.dark)` — once `AppSemanticColors` is registered here in `buildTheme`, `DarkThemeScope` automatically includes it with no code changes needed

## Key context
- `Color.computeLuminance()` already implements WCAG 2.0 relative luminance formula — no need for manual sRGB linearization
- WCAG AA: 4.5:1 for normal text, 3.0:1 for large text (18pt+ or 14pt+ bold)
- `AppTheme.buildTheme` at line 35 accepts `Brightness` — semantic colors should derive from this parameter
- The contrast helper in `test/helpers/contrast_ratio.dart` will be reused by all subsequent migration tasks (5-9) — establish the canonical testing pattern here
- File path uses `lib/core/ui/extensions/` (existing directory) not `lib/core/ui/theme/` (does not exist)

## Acceptance
- [ ] `AppSemanticColors` ThemeExtension exists at `lib/core/ui/extensions/app_semantic_colors.dart`
- [ ] Includes surface, ink, border, and grid token families
- [ ] Registered in `AppTheme.buildTheme` for both `Brightness.light` and `Brightness.dark`
- [ ] `context.semanticColors` accessor works
- [ ] `copyWith` and `lerp` implemented correctly
- [ ] Light mode: ink-on-surface contrast ratio >= 4.5:1 (WCAG AA)
- [ ] Dark mode: ink-on-surface contrast ratio >= 4.5:1 (WCAG AA)
- [ ] Light mode: gridLine-on-gridBackground contrast >= 1.5:1
- [ ] Dark mode: values visually consistent with current `whiteXX` equivalents
- [ ] `AppGridBackground` adaptive mode reads from `AppSemanticColors` grid tokens
- [ ] `highlightColor` in `app_theme.dart` derived from `colorScheme.onSurface` (not `Colors.white`)
- [ ] Contrast ratio helper exists at `test/helpers/contrast_ratio.dart`
- [ ] Test: contrast ratio helper validates WCAG thresholds
- [ ] Test: both brightness variants pass minimum contrast assertions

## Done summary
Created AppSemanticColors ThemeExtension with brightness-aware surface/ink/border/grid tokens. Registered in AppTheme.buildTheme with context.semanticColors accessor. Updated AppGridBackground adaptive mode to use semantic grid tokens. Fixed highlightColor. Added alpha-aware WCAG contrast ratio helper with tests.
## Evidence
- Commits: cab2a65, 2cff324, 992ba2f
- Tests: flutter analyze, flutter test
- PRs: