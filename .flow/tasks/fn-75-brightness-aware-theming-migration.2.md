## Description
Create `DarkThemeScope` widget that forces a subtree to dark theme. Wrap all dark-first routes (auth, onboarding, offline, paywall, splash) so they remain visually dark regardless of system brightness.

**Size:** M
**Files:**
- `lib/core/ui/widgets/dark_theme_scope.dart` (new) — scope widget
- `lib/features/auth/presentation/widgets/auth_background.dart` — wrap in scope
- `lib/features/onboarding/presentation/widgets/onboarding_scaffold.dart` — wrap in scope
- `lib/features/offline/offline_retry_view.dart` — wrap in scope
- `lib/paywall/paywall_view.dart` — wrap in scope
- `lib/startup/splash_screen.dart` — wrap in scope
- `test/theming/dark_first_scope_test.dart` (new) — verify scope behavior

## Approach
- `DarkThemeScope` wraps child in `Theme(data: AppTheme.buildTheme(Brightness.dark), child: child)`
- **No manual extension re-registration needed**: `AppTheme.buildTheme(Brightness.dark)` returns a complete `ThemeData` with all registered extensions. This means when Task 3 adds `AppSemanticColors` to `buildTheme`, `DarkThemeScope` automatically includes it — no `DarkThemeScope` update required.
- Use `Theme.of(context).brightness` inside descendants (NOT `MediaQuery.platformBrightness`) to check brightness
- Auth route: add scope at `AuthBackground` level
- Onboarding: add scope at `OnboardingScaffold` level
- Offline/paywall/splash: wrap at view level

## Key context
- `showModalBottomSheet`/`showDialog` do NOT inherit local Theme overrides — they inherit from Navigator. Dark-first modals (e.g., `trial_expired_modal.dart`) will need their content wrapped in `DarkThemeScope` individually (handled in Task 9)
- Splash uses `GridPattern` directly (not `AppGridBackground`) + `beam.frag` shader — the shader renders absolute colors, scope ensures surrounding widgets stay dark

## Acceptance
- [x] `DarkThemeScope` widget exists in `lib/core/ui/widgets/dark_theme_scope.dart`
- [x] Implementation uses `Theme(data: AppTheme.buildTheme(Brightness.dark), child: child)` — no manual extension list
- [x] All ThemeExtensions accessible under `DarkThemeScope` (KitColors, CustomTextStyles, CustomBorderRadius, CustomShadows)
- [x] Auth routes visually identical in light and dark system themes
- [x] Onboarding routes visually identical in light and dark system themes
- [x] Offline route visually identical in light and dark system themes
- [x] Paywall route visually identical in light and dark system themes
- [x] Splash screen visually identical in light and dark system themes
- [x] Test: `Theme.of(context).brightness` returns `Brightness.dark` inside `DarkThemeScope` regardless of system theme
- [x] Test: `context.kitColors` accessible (not null) inside scope

## Done summary
Created DarkThemeScope widget using AppTheme.buildTheme(Brightness.dark) and wrapped all dark-first routes (auth, onboarding, offline, paywall, splash) to ensure they remain visually dark regardless of system brightness. Added 4 tests verifying brightness forcing and ThemeExtension accessibility.
## Evidence
- Commits: 3be129e6b5985bf1a64ce2d9206c1add09a4cca7
- Tests: flutter analyze, flutter test test/theming/dark_first_scope_test.dart, flutter test
- PRs: