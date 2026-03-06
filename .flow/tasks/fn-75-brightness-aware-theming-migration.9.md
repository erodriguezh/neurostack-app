## Description
Migrate session-related views and modal/dialog presentations from `kitColors.whiteXX` to semantic tokens. This task covers `log_session_view.dart` (26+ whiteXX usages, 3rd heaviest file) and modal theme inheritance for dark-first dialogs.

**Size:** M (borderline L due to `log_session_view.dart` density, but single-file focus)
**Files:**
- `lib/features/session/presentation/views/log_session_view.dart` — replace 26+ whiteXX usages
- `lib/features/session/presentation/log_session_modal.dart` — fix hardcoded dark `barrierColor` (line 68)
- `lib/paywall/widgets/trial_expired_modal.dart` — wrap content in `DarkThemeScope` (7 whiteXX usages, dark-first modal)
- `test/features/session/presentation/log_session_brightness_test.dart` (new)

## Approach
- `log_session_view.dart` is shown as a modal from home and library views — it inherits the app-level theme (adaptive), so it needs semantic tokens
- `log_session_modal.dart` has `barrierColor: const Color(0xCC030303)` — replace with `ColorScheme.scrim` or brightness-derived equivalent
- `trial_expired_modal.dart` is a `showDialog` from paywall (dark-first route) — wrap its builder content in `DarkThemeScope` so it stays dark regardless of system theme
- **Date picker**: `_showDatePicker` in `log_session_view.dart` currently hard-forces dark surface via `colorScheme.copyWith(surface: kitColors.panel, onSurface: kitColors.white90)`. Since `LogSessionView` is adaptive, make the date picker adaptive too — derive `surface`/`onSurface` from `context.semanticColors` or `Theme.of(context).colorScheme` based on current brightness. Remove the forced-dark override.
- Use shared contrast helper from `test/helpers/contrast_ratio.dart` (Task 3)

## Key context
- `showModalBottomSheet`/`showDialog` create new Route objects inheriting Navigator theme, NOT local Theme overrides — this is why `trial_expired_modal` needs explicit `DarkThemeScope` wrapping
- `log_session_view.dart` is the 3rd heaviest whiteXX file in the codebase — systematic mapping required
- The date picker override will produce a dark picker inside a light modal if not migrated — visual inconsistency

## Acceptance
- [x] No `whiteXX` usage in `log_session_view.dart` for legibility tokens
- [x] `log_session_modal.dart` barrier color derived from theme (not hardcoded)
- [x] `trial_expired_modal.dart` stays dark under light system theme (wrapped in DarkThemeScope)
- [x] Log session modal readable in both light and dark modes
- [x] Date picker uses adaptive colors (no forced-dark surface/onSurface override) — picker appearance matches system brightness
- [x] Test: log session view rendered in both Brightness.light and Brightness.dark
- [x] Existing `trial_expired_modal_test.dart` still passes

## Done summary
Migrated session and modal widgets to semantic tokens: replaced 26+ kitColors.whiteXX usages in log_session_view.dart with semantic/colorScheme equivalents, derived log_session_modal.dart barrier color from colorScheme.scrim, wrapped trial_expired_modal.dart in DarkThemeScope, removed forced-dark date picker override, and added brightness tests for both light/dark modes.

## Evidence
- Commits: 008b189, 3280167
- Tests: flutter test (35 tests pass), flutter analyze (no issues)
