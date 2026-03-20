# fn-78-send-feedback-mailto-via-url-launcher.5 Unit tests for sendFeedback including effective-status regression

## Description
Add unit tests for `sendFeedback()` in `settings_view_model_test.dart`, following the existing `openFeatureRequestBoard` test group as a structural template. Include an effective-status regression test.

**Size:** M
**Files:**
- `test/settings/settings_view_model_test.dart`

## Approach

- Follow the test structure of `openFeatureRequestBoard` group at `settings_view_model_test.dart:268-379`
- Use existing `launchCalls` list to capture `(Uri, LaunchMode)` tuples (`settings_view_model_test.dart:30`)
- Use existing `fakeLaunch` injection via constructor (`settings_view_model_test.dart:33-36`)
- Extend `createViewModel()` factory at `settings_view_model_test.dart:60-72` to accept `PackageInfo` param
- Create `PackageInfo` directly via public constructor (no mock needed): `PackageInfo(appName: 'Neurostack', packageName: 'com.example', version: '1.2.3', buildNumber: '42')`
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
- [ ] Test: no-op when user is unauthenticated (launch not called)
- [ ] Test: no-op when user is `null` (unauthenticated state)
- [ ] All tests pass: `flutter test test/settings/settings_view_model_test.dart`
## Done summary
Duplicate — use task .1 instead
## Evidence
- Commits:
- Tests:
- PRs: