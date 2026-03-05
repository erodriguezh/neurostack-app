## Description
Migrate core shared primitives from `kitColors.whiteXX` to `AppSemanticColors`/`ColorScheme` tokens. These widgets are used across both adaptive and dark-first routes, so they must read from the ambient theme (which `DarkThemeScope` controls for dark-first contexts).

**Size:** M
**Files:**
- `lib/core/ui/widgets/app_primary_cta.dart` — replace `white05`, `white30`, `white10` (lines 89-104)
- `lib/core/ui/widgets/dismiss_button.dart` — replace `white60` (line 24)
- `lib/core/ui/widgets/error_state_view.dart` — replace `white60`, `white40` (lines 25, 33)
- `lib/core/ui/widgets/home_indicator_pill.dart` — replace `white90.withValues(alpha: 0.3)` (line 28)
- `lib/core/utils/internal_notification/toast/toast_view.dart` — remove ad-hoc `isDark` branching (lines 116-145), use semantic tokens instead
- Tests: add/update widget tests for all above in light+dark

## Approach
- Replace `kitColors.whiteXX` with `context.semanticColors.inkSubtle`, `.border`, `.surface`, etc. as appropriate
- Toast already has `isDark` branching — simplify by using semantic tokens that handle brightness automatically
- Each widget should be testable in both `Brightness.light` and `Brightness.dark` using `AppTheme.buildTheme(brightness)`
- These shared widgets work correctly in dark-first routes because `DarkThemeScope` sets the ambient theme to dark, so `context.semanticColors` returns dark values
- Use shared contrast helper from `test/helpers/contrast_ratio.dart` (Task 3)

## Key context
- `home_indicator_pill.dart` was recently extracted by fn-74 to `lib/core/ui/widgets/`
- `app_primary_cta.dart` disabled state uses `white05` background + `white30` text — semantic equivalents: `semanticColors.surface` + `semanticColors.inkSubtle`

## Acceptance
- [ ] `app_primary_cta.dart` uses no `whiteXX` tokens
- [ ] `dismiss_button.dart` uses no `whiteXX` tokens
- [ ] `error_state_view.dart` uses no `whiteXX` tokens
- [ ] `home_indicator_pill.dart` uses no `whiteXX` tokens
- [ ] `toast_view.dart` uses semantic tokens instead of manual `isDark` branching
- [ ] All 5 widgets readable in light mode (ink-on-surface contrast >= 3.0:1)
- [ ] All 5 widgets visually unchanged in dark mode (no regression)
- [ ] Tests: each widget tested in both Brightness.light and Brightness.dark

## Done summary
Migrated 5 core shared widgets (app_primary_cta, dismiss_button, error_state_view, home_indicator_pill, toast_view) from kitColors.whiteXX tokens to AppSemanticColors semantic tokens. Removed isDark branching in toast_view. Added 36 widget tests covering both light and dark brightness modes with WCAG contrast assertions and source-grep guards.
## Evidence
- Commits: 6b1b50ad, 677fc90, 1954631
- Tests: flutter analyze, flutter test (684 passed)
- PRs: