# Send Feedback mailto via url_launcher

## Overview

Replace the no-op Wiredash placeholder on the Settings "Send Feedback" tile with a `mailto:` link that opens the device email client pre-filled with diagnostic context (app version, platform, effective subscription tier).

**Spec:** `docs/specs/20260227120000_spec_settings_screen.md` — §Send Feedback (mailto)

## Scope

**In scope:**
- Add `package_info_plus` as a direct dependency (currently transitive via `userorient_flutter`)
- Thread `PackageInfo` through the full startup/DI path (same pattern as `SharedPreferences`)
- Implement `sendFeedback()` on `SettingsViewModel` using existing launch/auth/subscription patterns
- Build mailto URI with correct encoding (`Uri.encodeComponent` + `query:`, not `queryParameters:`)
- Wire the callback in `SettingsView`
- Update existing tests to accommodate new constructor parameters
- Clean up all stale Wiredash references in code and docs
- Unit tests including effective-status regression test

**Out of scope:**
- In-app fallback UI when no email client is configured (fire-and-forget per spec)
- Web-specific platform detection (uses `defaultTargetPlatform.name` consistently)
- Debounce on tile tap (consistent with existing tiles)

## Approach

### DI/Bootstrap
Thread `PackageInfo` through `main()` → `_AppLifecycleObserver` → `StartupView` → `StartupViewModel` → `buildModules()`, mirroring the `SharedPreferences` pattern exactly. Register as non-lazy singleton so it survives `locator.reset()` + `retryInitialization()` cycles. Verification: `buildModules` receives `PackageInfo` as a parameter (same structural guarantee as `SharedPreferences`).

### mailto URI Construction
Use `Uri(scheme: 'mailto', path: '...', query: encodeQueryParameters({...}))` with a helper that uses `Uri.encodeComponent()` per value. This avoids the Dart `queryParameters` bug that encodes spaces as `+` (Dart SDK #43838). The helper follows the pattern from the official url_launcher README.

### ViewModel Method
`sendFeedback()` combines two existing patterns:
- Auth extraction + effective status resolution from `openFeatureRequestBoard()` (`settings_view_model.dart:114-131`)
- URI launch with `LaunchMode` from `openSubscriptionManagement()` (`settings_view_model.dart:138-158`)

## Quick commands

```bash
# Run tests
flutter test test/settings/settings_view_model_test.dart

# Analyze
flutter analyze

# Full test suite
flutter test
```

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| `Uri(queryParameters:)` encodes spaces as `+`, breaking mail clients | Use `query:` with manual `Uri.encodeComponent()` — documented in url_launcher README |
| Settings spec says `Uri.encodeFull` but that's incorrect for query params | Update spec to say `Uri.encodeComponent` during doc cleanup |
| `PackageInfo.fromPlatform()` could theoretically fail in `main()` | Extremely unlikely (battle-tested plugin); consistent with `SharedPreferences` pattern which also runs in `main()` without fallback |
| `defaultTargetPlatform.name` reports simulated platform on web (e.g., `android`) | Acceptable — consistent behavior, low priority for support triage |
| New constructor param breaks existing tests | Task 1 includes mechanical test updates to keep suite green |

## Acceptance

- [ ] Tapping "Send Feedback" opens device email client with pre-filled `to`, `subject`, and `body`
- [ ] Email `to` is `feedback@getneurostack.app`
- [ ] Email `subject` is `NeuroStack Feedback`
- [ ] Email `body` contains app version+build, platform name, and effective subscription tier
- [ ] Spaces in mailto URI are encoded as `%20` (not `+`)
- [ ] No-op when `AuthState` is `Unauthenticated`
- [ ] `PackageInfo` survives `retryInitialization()` cycles (verified by `buildModules` parameter pattern, same as `SharedPreferences`)
- [ ] Existing tests updated and passing after constructor changes
- [ ] All stale Wiredash references removed from code and docs (historical replacement notes preserved)
- [ ] Unit tests pass including effective-status regression test
- [ ] `flutter analyze` clean

## References

- Plan: `plan_send_feedback_mailto.md`
- Spec: `docs/specs/20260227120000_spec_settings_screen.md` lines 89-116
- Dart SDK #43838: `Uri.toString()` encodes spaces as `+` for mailto
- url_launcher README: canonical `encodeQueryParameters` helper
- Existing patterns: `openFeatureRequestBoard()` at `settings_view_model.dart:114-131`, `openSubscriptionManagement()` at `settings_view_model.dart:138-158`
