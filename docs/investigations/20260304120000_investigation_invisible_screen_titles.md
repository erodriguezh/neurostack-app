# Investigation: Screen titles not visible

## Summary
Screen title text became effectively invisible on major tab screens when the app runs in light system theme. The regression was introduced on **March 4, 2026** in commit `c48e436`, which replaced explicit white title colors with `textTheme.headlineLarge` while those screens still render on an always-dark `AppGridBackground`.

## Symptoms
- Home, Library, Progress, Settings, and Contact screen titles appear missing.
- Issue is systemic across multiple routes, not isolated to one screen.

## Investigation Log

### Phase 1 - Initial theme/background mismatch hypothesis
**Hypothesis:** Title color is derived from theme brightness, but screen backgrounds are fixed dark.
**Findings:**
- `headlineLarge` color is dark in light mode and white in dark mode.
- `AppGridBackground` always paints dark `kitColors.background`.
**Evidence:**
- `lib/core/ui/app_theme.dart:107-110` (`headlineLarge` uses `isDark ? white90 : neutral950`)
- `lib/core/ui/widgets/app_grid_background.dart:76` (`ColoredBox(color: kitColors.background)`)
- `lib/core/ui/constants/kit_colors.dart:463` (`neutral950 = #0A0A0A`), `:469` (`background = #030303`)
- Contrast check (`#0A0A0A` on `#030303`) ≈ **1.04:1** (effectively unreadable)
**Conclusion:** Confirmed.

### Phase 2 - Scope and affected screens
**Hypothesis:** All broken titles are screens using both `AppGridBackground` and raw `headlineLarge`.
**Findings:** Same pattern appears in all reported screens.
**Evidence:**
- Wrapping with dark background:
  - `lib/home/home_view.dart:78`
  - `lib/library/library_view.dart:76`
  - `lib/progress/progress_view.dart:88`
  - `lib/settings/settings_view.dart:56`
  - `lib/settings/contact_view.dart:17`
- Title style using raw `headlineLarge`:
  - `lib/home/widgets/home_header.dart:18`
  - `lib/library/library_view.dart:190`
  - `lib/progress/progress_view.dart:180`
  - `lib/settings/settings_view.dart:79`
  - `lib/settings/contact_view.dart:40`
- Route exposure:
  - `lib/config/route_config.dart:17-45` (`/`, `/library`, `/week`, `/settings`, `/settings/contact`)
**Conclusion:** Confirmed systemic impact on primary tab/title screens.

### Phase 3 - Regression origin via git history
**Hypothesis:** A recent refactor removed explicit white title overrides.
**Findings:** Commit `c48e436` (Wed **March 4, 2026**, 09:43:35 +0100) changed these title styles to raw `headlineLarge`.
**Evidence:**
- `git show c48e436` patch:
  - Replaced `headlineLarge?.copyWith(... color: kitColors.white90 ...)` with `headlineLarge` in:
    - `lib/home/widgets/home_header.dart`
    - `lib/library/library_view.dart`
    - `lib/progress/progress_view.dart`
    - `lib/settings/settings_view.dart`
    - `lib/settings/contact_view.dart`
- `git blame` confirms exact changed title style lines in those files now point to `c48e436`.
**Conclusion:** Confirmed regression introduction point.

### Phase 4 - Eliminated hypotheses
**Hypothesis:** This is an AppBar title rendering bug.
**Findings:** Primary affected screens do not rely on `AppBar(title: ...)`; they use custom `Text` headers.
**Evidence:**
- `rg "AppBar\(|title:\s*Text\(" lib` only surfaced dialog/sheet titles, not the affected top-level screens.
**Conclusion:** Eliminated as primary cause.

**Hypothesis:** All `AppGridBackground` screens are affected equally.
**Findings:** Not all are broken because some explicitly force light text colors.
**Evidence:**
- Safe explicit override examples:
  - `lib/features/auth/presentation/auth_view.dart:112-114`
  - `lib/features/auth/presentation/check_email_view.dart:129-132`
  - `lib/features/offline/offline_retry_view.dart:65-67`
- `lib/paywall/paywall_view.dart:57-65` has no title text to hide.
**Conclusion:** Partially true; only screens using raw theme header colors are affected.

## Root Cause
A design inconsistency exists between theme and background:
1. `MaterialApp.router` defines `theme` and `darkTheme` but does not set `themeMode` (`lib/startup/startup_view.dart:51-58`), so runtime theme can be light (inference: default behavior is system mode).
2. In light mode, `headlineLarge` becomes near-black (`neutral950`) (`lib/core/ui/app_theme.dart:107-110`).
3. Affected screens are rendered on a fixed dark `AppGridBackground` (`lib/core/ui/widgets/app_grid_background.dart:76`).
4. Commit `c48e436` on March 4, 2026 removed per-screen white overrides and switched to raw `headlineLarge`, exposing the contrast bug globally on those screens.

## Recommendations
1. **Safest short-term fix:** set `themeMode: ThemeMode.dark` in `lib/startup/startup_view.dart` to align app runtime with dark-only background assumptions.
2. **Best long-term fix:** make `AppGridBackground` and related token usage brightness-aware (or adopt a true light palette for `KitColorsExtension`) so light mode is coherent.
3. If immediate patching is needed without theme policy change, restore explicit white header color on affected titles (same files listed above), but treat as temporary.

## Preventive Measures
- Add a UI test/screenshot test that runs key routes in both light and dark themes and verifies title contrast/visibility.
- Add lint/review rule: avoid using raw theme text color over fixed custom surfaces unless contrast is explicitly verified.
- Document theme policy clearly (dark-only vs full light/dark) to prevent mixed assumptions in refactors.
