# fn-74-settings-screen-cleanup-deduplicate.1 Clean up settings view: remove stubs, merge builders, fix banner interaction

## Description
Clean up the settings module code: remove no-op stub tiles, consolidate duplicate ValueListenableBuilder usage, and fix the GestureDetector/InkWell inconsistency on the upgrade banner.

**Size:** M
**Files:**
- `lib/settings/settings_view.dart`
- `lib/settings/widgets/settings_upgrade_banner.dart`
- `lib/settings/widgets/settings_support_section.dart`
- `lib/settings/contact_view.dart`

## Approach

### 1. Remove 3 stub tiles

The tiles "Send Feedback" (`LucideIcons.messageSquare`), "Rate the App" (`LucideIcons.star`), and "Feature Request" (`LucideIcons.lightbulb`) at `lib/settings/settings_view.dart:114-116` are wired to `() {}`. Remove them:
- Remove the 3 `onXxxTap` callback parameters from `SettingsSupportSection` constructor at `lib/settings/widgets/settings_support_section.dart`
- Remove the corresponding `_TileEntry` items from the tile list at `settings_support_section.dart:~L80-100`
- Remove the 3 `() {}` callbacks from the `SettingsSupportSection(...)` call in `settings_view.dart`
- Update `SettingsSupportSection` file-level docstring (currently says "five settings tiles") to reflect 2 tiles
- The section will have: "Contact Us" (always visible) + "Cancel Subscription" (premium only)

### 2. Merge duplicate ValueListenableBuilder blocks

`settings_view.dart` has two `ValueListenableBuilder<bool>` blocks (lines ~90-101 and ~106-122) both listening to `_viewModel.isPremium`. Merge into a single `ValueListenableBuilder` that wraps a `SliverMainAxisGroup` containing both sliver children (banner + support section). This is the canonical approach for grouping slivers under a single builder. Fallback if `SliverMainAxisGroup` is not available: move the `ValueListenableBuilder` up to build the `slivers:` list, or use `SliverToBoxAdapter(child: Column(...))` to combine both sections.

The merged builder should also fix StaggeredFadeIn indices for premium users: when the banner is hidden (`isPremium == true`), the support section should use `index: 0` instead of `index: 1` to avoid an unnecessary entrance delay.

### 3. Switch SettingsUpgradeBanner to InkWell

`settings_upgrade_banner.dart:32` uses `GestureDetector` with no press feedback. Switch to the canonical `Material`/`InkWell` pattern matching `SettingsTile` at `lib/settings/widgets/settings_tile.dart:49`:
- Use `Material(color: Colors.transparent)` as ink host
- Use `InkWell` with `borderRadius: BorderRadius.circular(24)` to clip splash correctly over the decorated surface
- Check if `SettingsTile` uses `splashFactory: NoSplash.splashFactory` and match that interaction style
- Ensure the ink renders on top of (not behind) the decorated container — prefer `Ink(decoration: ...)` pattern or keep `Container` decoration if `Material(type: MaterialType.transparency)` allows it

### 4. Fix stale doc comments

- `contact_view.dart:8` — remove "placeholder until Phase 4" comment (Phase 4 is done)
- `settings_upgrade_banner.dart:11` — fix "Hidden when isPremium is true" doc (the widget itself doesn't check isPremium; the parent does via ValueListenableBuilder)
- `settings_support_section.dart` — update file docstring to reflect 2 tiles instead of 5

## Acceptance
- [ ] No `() {}` stub callbacks in settings code
- [ ] `SettingsSupportSection` constructor takes only `onContactTap`, `onCancelSubscriptionTap`, `isPremium` (no feedback/rate/feature callbacks)
- [ ] Renders **Contact Us** always; renders **Cancel Subscription** only when `isPremium == true`; no other tiles exist
- [ ] Single `ValueListenableBuilder<bool>` for `isPremium` in `settings_view.dart`
- [ ] StaggeredFadeIn index for support section is `0` when `isPremium` (banner hidden), `1` when not premium
- [ ] `SettingsUpgradeBanner` uses `Material` + `InkWell` with visible press feedback (not GestureDetector)
- [ ] No stale doc comments: ContactView "placeholder" removed, banner doc accurate, support section tile count correct
- [ ] `flutter analyze` passes
- [ ] `flutter test test/settings/` passes
## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
