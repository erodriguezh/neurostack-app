## Description
Add `AppGridBackgroundMode` enum and adaptive color resolution to `AppGridBackground`, plus document the brightness theming policy. No call-site changes — existing behavior unchanged via `legacyDark` default.

**Size:** M
**Files:**
- `lib/core/ui/widgets/app_grid_background.dart` — add mode enum + color resolver
- `test/core/ui/widgets/app_grid_background_test.dart` (new) — light/dark behavior tests
- `docs/best_practices/design/brightness_theming.md` (new) — route policy + token rules

## Approach
- Follow existing `_GridPainter` pattern at `app_grid_background.dart:27` — colors already injected via constructor with `shouldRepaint`
- Add `AppGridBackgroundMode { legacyDark, adaptive }` enum (two modes only, no `forceDark`)
- Add `mode` parameter defaulting to `legacyDark`
- In `adaptive` mode: resolve fill from `ColorScheme.surface`, grid lines from `ColorScheme.outlineVariant` (or `onSurface` with low alpha), glow from `ColorScheme.primary` with low alpha
- The radial mask (`Colors.white` with `BlendMode.dstIn`) uses alpha for the fade effect — **keep as-is**; the visibility fix is about fill and line colors, not the mask RGB
- Task 3 will later update adaptive mode to read from `AppSemanticColors` grid tokens once they exist
- Policy doc: document adaptive vs dark-first route classification, canonical names, and when to use `whiteXX` vs semantic tokens

## Key context
- `_GridPainter` uses `BlendMode.dstIn` with a radial gradient for the circular fade — the alpha channel controls the effect, not the RGB values
- On a light background, `white02` grid lines (white at 2% opacity) would be invisible — adaptive mode uses dark-tinted lines derived from `ColorScheme`
- No `AppSemanticColors` exists yet (Task 3) — adaptive mode uses `ColorScheme` directly for now

## Acceptance
- [ ] `AppGridBackgroundMode` enum exists with `legacyDark` and `adaptive` values (two modes only)
- [ ] `AppGridBackground` accepts `mode` parameter, defaults to `legacyDark`
- [ ] Legacy mode: resolved fill == `kitColors.background`, lines == `kitColors.white02` regardless of system brightness
- [ ] Adaptive mode: resolved fill == `ColorScheme.surface`, lines == `ColorScheme.outlineVariant` or `onSurface` with low alpha
- [ ] Adaptive mode: glow color derived from `ColorScheme.primary` with low alpha
- [ ] Radial mask kept as-is (no brightness branching on mask RGB)
- [ ] Test: legacy mode resolves to same dark token values in both brightness modes (property assertions, not pixel comparison)
- [ ] Test: adaptive mode resolves to brightness-aware token values (light fill in light mode, dark fill in dark mode)
- [ ] `docs/best_practices/design/brightness_theming.md` documents route policy, canonical names, and token usage rules

## Done summary
Added AppGridBackgroundMode enum (legacyDark/adaptive) with brightness-aware color resolution to AppGridBackground, 12 widget tests covering both modes, and brightness theming policy documentation.
## Evidence
- Commits: d3d298c, 102c23d, 348e8fd, e42f886
- Tests: flutter analyze, flutter test test/core/ui/widgets/app_grid_background_test.dart, flutter test
- PRs: