# Plan: Send Feedback (mailto via url_launcher)

Replaces the no-op Wiredash placeholder with a `mailto:` link that opens the device email client with diagnostic context.

**Spec:** [`docs/specs/20260227120000_spec_settings_screen.md`](docs/specs/20260227120000_spec_settings_screen.md) — §Send Feedback (mailto)

---

## Phase 1 — Add `package_info_plus` dependency & bootstrap

- Add `package_info_plus` to `pubspec.yaml` (line ~68, after `in_app_review`)
  - Source: `pubspec.yaml:68`
- Resolve `PackageInfo.fromPlatform()` in `main()` alongside `SharedPreferences.getInstance()`
  - Source: `lib/main.dart`
- Thread `PackageInfo` through the full startup path, mirroring `SharedPreferences`:
  - `main()` → `StartupView` → `StartupViewModel` → `buildModules()`
  - Source: `lib/startup/startup_view.dart` (pass `PackageInfo` to `StartupViewModel`)
  - Source: `lib/startup/startup_view_model.dart` (accept and forward to `buildModules`)
- Extend `buildModules()` signature to accept `PackageInfo` as a required parameter
  - Register the pre-resolved `PackageInfo` instance as a non-lazy singleton (matches `SharedPreferences` pattern)
  - Source: `lib/config/locator_config.dart:59` (`buildModules` signature)
  - This ensures `PackageInfo` survives `locator.reset()` + `retryInitialization()` cycles
- Run `flutter pub get`

## Phase 2 — Add `sendFeedback()` to `SettingsViewModel`

- Accept `PackageInfo` as a required constructor parameter
  - Source: `lib/settings/settings_view_model.dart:24-44` (constructor)
- Add `sendFeedback()` async method following `openSubscriptionManagement()` pattern (line 138-158):
  - Resolve **effective** subscription status via `_resolver.resolveEffectiveStatus()` — same pattern as `openFeatureRequestBoard()` (line 114-131)
  - Extract user from `_authService.authState.value` using the existing `switch` pattern (line 116-120)
  - Build mailto URI with manual query encoding to avoid mail-client issues:
    - Use `Uri.encodeComponent()` for `subject` and `body` values
    - Construct URI with `query:` parameter (not `queryParameters:`) to control encoding precisely
    - `to`: `feedback@getneurostack.app`
    - `subject`: `NeuroStack Feedback`
    - `body`: `App Version: ${packageInfo.version}+${packageInfo.buildNumber}\nPlatform: ${defaultTargetPlatform.name}\nSubscription: ${effectiveStatus.name}`
  - Launch via `_launch(uri, mode: mode)` with try-catch (fire-and-forget, no fallback)
  - Use same `LaunchMode` logic: `LaunchMode.externalApplication` native, `LaunchMode.platformDefault` web

## Phase 3 — Wire callback in `SettingsView`

- Replace `onFeedbackTap: () {}, // TODO: Wiredash` with `onFeedbackTap: _viewModel.sendFeedback`
  - Source: `lib/settings/settings_view.dart:108`
- Pass `PackageInfo` from locator to `SettingsViewModel` constructor
  - Source: `lib/settings/settings_view.dart:32-39` (ViewModel instantiation)

## Phase 4 — Clean up stale Wiredash references

- Remove all stale Wiredash doc comments from `settings_support_section.dart`:
  - `onFeedbackTap` placeholder comment (line ~31)
  - Any other Wiredash references in the widget's doc comments
  - Source: `lib/settings/widgets/settings_support_section.dart`
- Update `docs/best_practices/design/screen-prompts/11-settings-screen.md`:
  - Replace Wiredash placeholder description with mailto behavior
- Update `docs/specs/20260315140000_spec_userorient_integration.md`:
  - Remove/update out-of-scope reference to "Send Feedback pending Wiredash"
- Update `docs/specs/202603162012_spec_rate_app_integration.md`:
  - Remove/update out-of-scope reference to "Send Feedback pending Wiredash"
- Fix encoding reference in `docs/specs/20260227120000_spec_settings_screen.md`:
  - Change `Uri.encodeFull` → `Uri.encodeComponent` at line ~107
  - Preserve the historical struck-through `~~Wiredash integration~~` replacement note (design decision record)

## Phase 5 — Tests

- **Unit test `sendFeedback()`** in `test/settings/settings_view_model_test.dart`:
  - Verify mailto URI contains `feedback@getneurostack.app`
  - Verify subject is `NeuroStack Feedback`
  - Verify body contains app version, platform name, and **effective** subscription status name
  - **Effective-status regression test**: set up a user with DB-level `free` status but a RevenueCat entitlement snapshot that resolves to a paid tier; assert the email body contains the resolved paid tier (not `free`)
  - Verify `_launch` is called with `LaunchMode.externalApplication` (native test environment; web branch not exercised in unit tests — acceptable since `kIsWeb` is a compile-time constant)
  - Verify no-op when user is unauthenticated (same guard as `openFeatureRequestBoard`)
  - Use injected `launch` parameter for testability (existing pattern, line 32/42)
  - Use injected `PackageInfo` for testability (constructor accepts concrete instance)

## Phase 6 — Verify docs index

- Verify `docs/README.md` already contains the Send Feedback plan link (believed already present — no edit needed unless missing)

---

## Files touched (summary)

| File | Change |
|------|--------|
| `pubspec.yaml` | Add `package_info_plus` |
| `lib/main.dart` | Resolve `PackageInfo.fromPlatform()` at startup |
| `lib/startup/startup_view.dart` | Thread `PackageInfo` to `StartupViewModel` |
| `lib/startup/startup_view_model.dart` | Accept `PackageInfo`, forward to `buildModules` |
| `lib/config/locator_config.dart` | Extend `buildModules` signature, register `PackageInfo` non-lazy singleton |
| `lib/settings/settings_view_model.dart` | Add `PackageInfo` param + `sendFeedback()` method |
| `lib/settings/settings_view.dart` | Wire `sendFeedback`, pass `PackageInfo` |
| `lib/settings/widgets/settings_support_section.dart` | Remove all stale Wiredash doc comments |
| `docs/best_practices/design/screen-prompts/11-settings-screen.md` | Update Send Feedback from Wiredash placeholder to mailto |
| `docs/specs/20260315140000_spec_userorient_integration.md` | Remove stale Wiredash out-of-scope reference |
| `docs/specs/202603162012_spec_rate_app_integration.md` | Remove stale Wiredash out-of-scope reference |
| `docs/specs/20260227120000_spec_settings_screen.md` | Fix `Uri.encodeFull` → `Uri.encodeComponent`; preserve historical Wiredash note |
| `test/settings/settings_view_model_test.dart` | Add/extend tests for `sendFeedback()` incl. effective-status regression |
