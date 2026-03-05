## Description
Flip all adaptive routes from `AppGridBackground` `legacyDark` mode to `adaptive` mode. This is the "big switch" — all widget migrations must be complete before this task.

**Size:** M
**Files:**
- `lib/home/home_view.dart` — set `mode: AppGridBackgroundMode.adaptive`
- `lib/library/library_view.dart` — set `mode: AppGridBackgroundMode.adaptive`
- `lib/progress/progress_view.dart` — set `mode: AppGridBackgroundMode.adaptive`
- `lib/settings/settings_view.dart` — set `mode: AppGridBackgroundMode.adaptive`
- `lib/settings/contact_view.dart` — set `mode: AppGridBackgroundMode.adaptive`
- `test/theming/adaptive_routes_contrast_test.dart` (new) — light+dark route contrast tests

## Approach
- Each route change is a one-line `mode:` parameter addition — minimal diff per file
- Adaptive mode was introduced in Task 1 (using `ColorScheme`) and updated in Task 3 to resolve from `AppSemanticColors` grid tokens — by this point it is fully semantic-backed
- All child widgets already use semantic tokens (Tasks 4-9) — flipping the background is the final step
- Add comprehensive contrast tests: render each tab route in both brightness modes, assert title text contrast >= 4.5:1
- Use shared contrast helper from `test/helpers/contrast_ratio.dart` (Task 3)

## Key context
- **Rollback**: revert only these 5 route changes back to `legacyDark` — all infrastructure and widget migrations remain safe
- `home_bottom_nav.dart` is shared across all 4 tab routes — already migrated in Task 5

## Acceptance
- [ ] All 5 adaptive routes use `AppGridBackgroundMode.adaptive`
- [ ] Light mode: background is light-colored on all adaptive routes
- [ ] Dark mode: background matches current dark appearance (no regression)
- [ ] Title text visible in both modes on all adaptive routes
- [ ] Grid lines visible in both modes on all adaptive routes
- [ ] Test: each tab route contrast >= 4.5:1 for title text in both modes
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
