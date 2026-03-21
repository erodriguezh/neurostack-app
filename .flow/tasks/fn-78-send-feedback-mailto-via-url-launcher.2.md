# fn-78-send-feedback-mailto-via-url-launcher.2 Unit tests for sendFeedback including effective-status regression

## Description
Add unit tests for `sendFeedback()` in `settings_view_model_test.dart`, following the existing `openFeatureRequestBoard` test group as a structural template. Include an effective-status regression test.

**Size:** M
**Files:**
- `test/settings/settings_view_model_test.dart`

## Approach

- Follow the test structure of `openFeatureRequestBoard` group at `settings_view_model_test.dart:277-388`
- Use existing `launchCalls` list to capture `(Uri, LaunchMode)` tuples (`settings_view_model_test.dart:31`)
- Use existing `fakeLaunch` injection via constructor (`settings_view_model_test.dart:34-37`)
- `createViewModel()` factory at `settings_view_model_test.dart:61-79` already accepts optional `PackageInfo` param (done in task .1) — no extension needed
- Create `PackageInfo` directly via public constructor (no mock needed): `PackageInfo(appName: 'NeuroStack', packageName: 'app.getneurostack', version: '1.2.3', buildNumber: '42')`
<!-- Updated by plan-sync: fn-78-send-feedback-mailto-via-url-launcher.1 already extended createViewModel with PackageInfo; line numbers shifted -->
- Use `UserFactory` and `EntitlementSnapshotFactory` from `test/factories/`

## Key context

- Assert URI structurally: `scheme == 'mailto'`, `path == 'feedback@getneurostack.app'`, decode and verify exact `subject` and `body` values
- Assert spaces encoded as `%20` not `+` (catch Dart SDK #43838 regression)
- Effective-status regression test: DB-level `free` user + RC snapshot resolving to `premiumMonthly` → body must contain `premiumMonthly` not `free`
## Acceptance
- [ ] Test: mailto URI has scheme `mailto` and path `feedback@getneurostack.app`
- [ ] Test: subject is `NeuroStack Feedback`
- [ ] Test: body contains app version (`1.2.3+42`), platform name, subscription status
- [ ] Test: spaces in URI encoded as `%20` not `+`
- [ ] Test: effective-status regression — DB `free` + RC `premiumMonthly` snapshot → body contains `premiumMonthly`
- [ ] Test: `_launch` called with `LaunchMode.externalApplication`
- [ ] Test: no-op when `AuthState` is `Unauthenticated` (launch not called)
- [ ] All tests pass: `flutter test test/settings/settings_view_model_test.dart`
## Done summary
Added 8 unit tests for `sendFeedback()` in `settings_view_model_test.dart`:
1. mailto URI structure (scheme, path, subject, body with version/platform/subscription)
2. `%20` encoding regression (Dart SDK #43838)
3. Effective-status regression (DB `free` + RC `premiumMonthly` → body shows `premiumMonthly`)
4. `LaunchMode.externalApplication` assertion
5. Unauthenticated no-op (launch not called)
6. `AuthenticatedOffline` support
7. Stale snapshot for different user falls back to DB status
8. Launcher failure (try/catch) completes normally
## Evidence
- Commits: 5840d9d
- Tests: flutter test test/settings/settings_view_model_test.dart — 28 pass (8 new)
- PRs: