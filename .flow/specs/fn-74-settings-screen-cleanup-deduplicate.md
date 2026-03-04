# Settings Screen Cleanup: Deduplicate, Remove Stubs, Extract Shared Widgets

## Overview

Post-implementation cleanup of the settings screen branch (`feature/settings-screen`). The branch introduced ~715 lines across 6 new files in `lib/settings/`. During rapid feature implementation, several patterns were copy-pasted from other tab screens rather than extracted to shared code, stub callbacks were wired for features that don't exist yet, and minor inconsistencies crept in. This epic addresses all of these before the branch merges to master.

## Scope

**In scope:**
- Remove 3 stub tiles (Send Feedback, Rate the App, Feature Request) that are wired to `() {}`
- Merge duplicate `ValueListenableBuilder<bool>` blocks in `settings_view.dart`
- Fix GestureDetector → InkWell inconsistency on SettingsUpgradeBanner
- Extract home indicator pill (duplicated in 4 tab screens) to shared widget
- Consolidate screen header text style by updating `CustomTextStyles.h1.letterSpacing` to `-0.8` and using `headlineLarge` directly
- Fix misleading/stale doc comments (including support section tile count)
- Update docs: README dead reference, plan outdated info, settings spec tile definitions, README prompt descriptor

**Out of scope:**
- Retrofitting `PremiumAwareViewModelMixin` onto Home/Library ViewModels (separate epic)
- Adding widget tests for settings widgets (separate scope)
- Creating a `ContactViewModel` (acceptable for a single-back-button page per existing precedent in `progress_view.dart`)
- Changing mixin contracts (EntitlementListenerMixin / PremiumAwareViewModelMixin)

## Decisions

1. **letterSpacing: -0.8 is canonical.** Four screens use `-0.8` inline; `CustomTextStyles.h1` uses `-0.5`. Update the `h1` token to `-0.8` to match the screens, then replace all inline `copyWith(letterSpacing: -0.8)` with direct `headlineLarge` usage from the theme. This keeps color/font in the `TextTheme` pipeline (set in `app_theme.dart`) and avoids baking colors into `CustomTextStyles`.

## Quick commands

```bash
flutter analyze
flutter test
flutter test test/settings/
```

## Acceptance

- [ ] `flutter analyze` passes with zero issues
- [ ] `flutter test` passes (all existing tests green)
- [ ] No `() {}` stub callbacks remain in settings code
- [ ] Home indicator pill exists as a single shared widget, used by all 4 tab screens
- [ ] `CustomTextStyles.h1.letterSpacing == -0.8`; no inline `letterSpacing: -0.8` remains in tab title headers
- [ ] SettingsUpgradeBanner uses InkWell with press feedback (not GestureDetector)
- [ ] Only one `ValueListenableBuilder<bool>` for `isPremium` in settings_view.dart
- [ ] `docs/README.md` has no dead file references
- [ ] `docs/specs/20260227120000_spec_settings_screen.md` tile definitions updated (3 stubs removed)
- [ ] No stale doc comments (ContactView, banner, support section tile count)

## References

- Settings spec: `docs/specs/20260227120000_spec_settings_screen.md`
- Settings plan: `plan_settings_screen.md`
- Prior cleanup patterns: fn-60 (paywall cleanup phase 1), fn-61 (paywall cleanup phase 2)
- Mixin contracts: `lib/core/abstractions/entitlement_listener_mixin.dart`, `lib/core/abstractions/premium_aware_view_model_mixin.dart`
- Shared widget precedent: `lib/core/ui/widgets/staggered_fade_in.dart`, `lib/core/ui/widgets/error_state_view.dart` (extracted in fn-60.3)
- Theme pipeline: `lib/core/ui/app_theme.dart` (color/font applied via `TextTheme`), `lib/core/ui/constants/text_styles.dart` (structural tokens only)
