# Investigation: Long-term plan for brightness-aware AppGridBackground + palette

## Summary
The app currently mixes adaptive typography with fixed dark surfaces, causing light-mode contrast failures. This plan defines a phased migration to brightness-aware surfaces and semantic color usage while preserving intentional dark-first flows.

## Symptoms
- In light system theme, key headers became unreadable on dark backgrounds.
- Many components still encode dark-only assumptions via `kitColors.whiteXX`.

## Investigation Log

### Phase 1 - Root architectural mismatch (confirmed)
**Hypothesis:** Background composition is dark-fixed while text semantics are brightness-adaptive.
**Findings:**
- `AppTheme` provides brightness-adaptive text and color semantics.
- `AppGridBackground` paints a fixed dark base and white-line grid regardless of brightness.
**Evidence:**
- `lib/core/ui/app_theme.dart:35-41` (`isDark` computed; single `KitColorsExtension()` instance)
- `lib/core/ui/app_theme.dart:48-77` (`ColorScheme` branches by brightness)
- `lib/core/ui/app_theme.dart:107-110` (`headlineLarge` = dark text in light mode)
- `lib/core/ui/widgets/app_grid_background.dart:76-77` (always `kitColors.background` + `white02`-based lines)
**Conclusion:** Confirmed; this is the core structural mismatch to solve long-term.

### Phase 2 - Dark-first flow dependency mapping
**Hypothesis:** Several routes intentionally rely on dark visual language and cannot be blindly made adaptive.
**Findings:** Auth/onboarding/offline/paywall all use `AppGridBackground` and white-token styling.
**Evidence:**
- `lib/features/auth/presentation/widgets/auth_background.dart:16-19`
- `lib/features/onboarding/presentation/widgets/onboarding_scaffold.dart:38-40`
- `lib/features/offline/offline_retry_view.dart:45-77`
- `lib/paywall/paywall_view.dart:57-64`
**Conclusion:** Confirmed; migration needs explicit route-level mode support (adaptive vs force-dark).

### Phase 3 - Shared primitive risk inventory
**Hypothesis:** Shared widgets encode dark assumptions and will propagate regressions unless migrated to semantic tokens.
**Findings:** Several core widgets directly use `kitColors.whiteXX` or dark surfaces.
**Evidence:**
- `lib/core/ui/widgets/app_primary_cta.dart:88-105`
- `lib/core/ui/widgets/dismiss_button.dart:24`
- `lib/core/ui/widgets/error_state_view.dart:24-35`
- `lib/core/ui/widgets/home_indicator_pill.dart:28`
- `lib/core/utils/internal_notification/toast/toast_view.dart:116-167` (manual brightness branching)
**Conclusion:** Confirmed; shared primitives should be migrated before broad feature-level cleanup.

### Phase 4 - Scope sizing + test baseline
**Hypothesis:** Migration scope is broad and requires early test tripwires.
**Findings:**
- `kitColors.whiteXX` appears on 214 lines under `lib/`.
- Highest concentration by top-level folder: `features` 86, `library` 38, `core` 31, `home` 26.
- Multiple widget tests are dark-only and won’t catch light-mode contrast regressions.
**Evidence:**
- Search count: `rg "kitColors\.white(90|80|70|60|50|40|30|20|10|05|02)" lib` -> 214 line hits.
- Dark-biased tests:
  - `test/library/widgets/library_protocol_card_test.dart:85`
  - `test/progress/widgets/progress_grid_test.dart:47`
  - `test/paywall/widgets/trial_expired_modal_test.dart:35`
- Light-theme counterexample available:
  - `test/features/auth/presentation/auth_view_test.dart:113`
**Conclusion:** Confirmed; introduce light+dark coverage early before large migration PRs.

## Root Cause
The app currently lacks a strict boundary between semantic adaptive colors and dark-brand tokens. `AppGridBackground` is fixed to dark palette tokens while text and `ColorScheme` are brightness-sensitive, and shared components still rely heavily on dark-only `whiteXX` tokens. This makes light mode fragile and causes contrast regressions.

## Recommended Execution Plan

### Workstreams
1. **Policy + invariants**: define adaptive surfaces vs intentional dark-first surfaces in docs.
2. **Background architecture**: add `AppGridBackground` variants (`adaptive`, `forceDark`, legacy default during migration).
3. **Dark-first scope**: add a local dark theme scope wrapper for auth/onboarding/offline/paywall.
4. **Semantic tokens**: introduce semantic surface/ink/border tokens derived from `ColorScheme`.
5. **Component migration**: shared primitives first, then feature widgets by domain.
6. **Testing hardening**: add light+dark tripwires and targeted goldens.

### First 3 PRs (exact)

#### PR1 — `AppGridBackground` capabilities only (no behavior changes)
- Files:
  - `lib/core/ui/widgets/app_grid_background.dart`
  - `test/core/ui/widgets/app_grid_background_test.dart` (new)
- Include:
  - Introduce variant API (`legacyDark` default, plus `adaptive` and `forceDark`).
  - Implement adaptive fill/line derivation from theme semantics.
- Exclude:
  - No call-site migrations.
  - No palette/token changes.
- Acceptance:
  - Existing visuals unchanged by default.
  - New tests validate legacy vs adaptive behavior in light/dark themes.
- Rollback:
  - Revert PR cleanly; no call sites depend on new API.

#### PR2 — Fix high-exposure tab routes with adaptive mode + contrast tests
- Files:
  - `lib/home/home_view.dart`
  - `lib/library/library_view.dart`
  - `lib/progress/progress_view.dart`
  - `lib/settings/settings_view.dart`
  - `lib/settings/contact_view.dart`
  - `lib/core/ui/widgets/home_indicator_pill.dart`
  - `test/theming/tab_screen_header_contrast_test.dart` (new)
- Include:
  - Opt tab/contact routes into `AppGridBackground` adaptive variant.
  - Make contact chevron and home indicator use semantic adaptive colors.
  - Add light+dark header contrast assertions.
- Exclude:
  - Do not migrate auth/onboarding/offline/paywall yet.
- Acceptance:
  - Titles visible in both light and dark themes.
  - Added tests fail if text/background contrast regresses.
- Rollback:
  - Revert only call-site opt-ins; keep PR1 infrastructure.

#### PR3 — Preserve intentional dark-first routes
- Files:
  - `lib/core/ui/widgets/dark_first_theme_scope.dart` (new)
  - `lib/features/auth/presentation/widgets/auth_background.dart`
  - `lib/features/onboarding/presentation/widgets/onboarding_scaffold.dart`
  - `lib/features/offline/offline_retry_view.dart`
  - `lib/paywall/paywall_view.dart`
  - `test/theming/dark_first_routes_scope_test.dart` (new)
- Include:
  - Add local dark theme scope wrapper.
  - Apply wrapper to dark-first routes so they remain intentionally dark under light system theme.
- Exclude:
  - No semantic token migration yet.
- Acceptance:
  - Dark-first flows remain visually stable in both system theme settings.
- Rollback:
  - Revert wrapper usage route-by-route if regressions appear.

### Post-PR3 roadmap
4. Add semantic token extension (e.g. `app_semantic_colors.dart`) and wire in `AppTheme`.
5. Migrate shared primitives (`app_primary_cta`, `dismiss_button`, `error_state_view`, `toast_view`, nav/pill components).
6. Migrate feature surfaces in order: Home → Library → Progress → Settings.
7. Reduce adaptive-surface `whiteXX` usage toward near-zero; keep brand accents (`brandSky`, semantic status colors).

## Preventive Measures
- Add a permanent light+dark visual smoke suite for top routes.
- Add reviewer rule: semantic text/surface/border colors must come from `ColorScheme` or semantic extension on adaptive surfaces.
- Track residual `whiteXX` usage with periodic grep in CI or PR checklist.

## Resolution

This investigation is resolved by Flow epic
`fn-75-brightness-aware-theming-migration`, including:

- Route policy split (`adaptive` vs `dark-first`)
- `DarkThemeScope` containment for dark-first routes
- `AppSemanticColors` migration for adaptive surfaces
- CI enforcement against new adaptive `kitColors.whiteXX` usage

Policy reference:
`docs/best_practices/design/brightness_theming.md`.
