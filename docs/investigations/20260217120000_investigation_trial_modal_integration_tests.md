# Investigation: TrialExpiredModal and TrialReminderAlert Not Found in Integration Tests

## Summary

Three integration tests in `paywall_flow_test.dart` fail because `HomeViewModel._loadHome()` can't load the user from the repository — the `MockDataSourceAbstraction` only stubs `.auth` but not `.from('users')`, causing `UserRepository.getById()` to throw and `_loadHome()` to enter error state before ever reaching the modal trigger logic.

## Symptoms

- `trialExpiration_trialExpires_showsExpiredModal` (line 215): Expected `TrialExpiredModal`, found 0
- `trialExpiration_premiumExpires_showsExpiredModal` (line 246): Expected `TrialExpiredModal`, found 0
- `trialReminder_within24h_showsReminderAlert` (line 346): Expected `TrialReminderAlert`, found 0
- 13 other tests pass (all either check service state directly or expect `findsNothing`)

## Investigation Log

### Phase 1: Trace the widget display chain

**Hypothesis:** The widgets exist but the conditions to show them aren't being met.

**Findings:** Traced the full chain:
1. `pumpToHomeWithUser()` → lands on `HomeView`
2. `HomeView.initState()` → `HomeViewModel.init()` → `_loadHome(showLoading: true)`
3. `_loadHome()` calls `_userRepository.getById(userId)`
4. `UserRepositoryImpl.getById()` → `UserRemoteDataSource.getUser(id)` → `_dataSource.from('users').select().eq('id', id).single()`
5. `_dataSource` is `MockDataSourceAbstraction` — only `.auth` is stubbed, not `.from()`
6. Mocktail throws `MissingStubError` on unstubbed `.from('users')` call
7. `UserRepositoryImpl` catches the exception → returns `Left(DomainFailure('User.UnexpectedError', ...))`
8. `_loadHome()` sees `userResult.isLeft()` → calls `_setError(message)` → **returns early**
9. `_maybeTriggerExpiredModal()` is **never reached**
10. `HomeViewState.status = HomeStatus.error`, `showTrialExpiredModal = false`, `showTrialReminder = false`

**Evidence:**
- `lib/home/home_view_model.dart:348-353` — `_loadHome` early-return on user load failure
- `lib/features/user/data/repositories/user_repository_impl.dart:23-41` — catch-all returns Left
- `lib/features/user/data/data_sources/user_remote_data_source.dart:21-27` — calls `_dataSource.from('users')`
- `integration_test/mocks/mock_data_sources.dart:1-7` — mock only extends Mock, no stubs for `.from()`
- `integration_test/utils/auth_helpers.dart:94` — only `.auth` is stubbed

**Conclusion:** Root cause CONFIRMED.

### Phase 2: Why do other tests pass?

**Hypothesis:** Other tests should also fail if `_loadHome` fails for all.

**Findings:** All passing tests fall into two categories:
1. Tests that check service state directly (purchase flow, entitlement changes, lifecycle) — don't verify UI widgets
2. Tests that expect `findsNothing` (activeTrialUser, premiumUser, moreThan24h, throttled) — pass because error state also shows nothing

No test that expects a widget to BE PRESENT (`findsOneWidget`) passes. The 3 failing tests are exactly the 3 that expect a widget to appear.

**Evidence:** Cross-referenced all 16 test assertions against their expect statements.

**Conclusion:** CONFIRMED — `_loadHome` fails silently for ALL `pumpToHomeWithUser` tests, but only the 3 that expect positive widget presence fail.

### Phase 3: Understanding why auth works but home loading fails

**Hypothesis:** Auth flow uses `FakeUserBootstrapService` to bypass repository, but `_loadHome` makes a separate repository call.

**Findings:**
- Auth: `AuthService._handleSession()` → `_userBootstrapService.rehydrateFromRemote(userId: ...)` → `FakeUserBootstrapService` returns user directly
- Home: `HomeViewModel._loadHome()` → `_userRepository.getById(userId)` → goes through real `UserRepositoryImpl` → real `UserRemoteDataSource` → `MockDataSourceAbstraction.from('users')` → FAILS

The auth flow is properly faked, but the home view model's own repository call is not.

**Evidence:**
- `lib/features/auth/data/auth_service.dart:216-219` — uses `_userBootstrapService.rehydrateFromRemote`
- `integration_test/mocks/fake_services.dart:32-50` — `FakeUserBootstrapService` returns user directly
- `lib/home/home_view_model.dart:345-348` — `_userRepository.getById(userId)` separate call

**Conclusion:** CONFIRMED.

## Root Cause

`HomeViewModel._loadHome()` calls `_userRepository.getById(userId)` which routes through the real `UserRepositoryImpl → UserRemoteDataSource → MockDataSourceAbstraction.from('users')`. The `MockDataSourceAbstraction` (Mocktail mock) only has `.auth` stubbed — calling the unstubbed `.from('users')` throws `MissingStubError`, which the repository catches and converts to a `Left(DomainFailure)`. This causes `_loadHome()` to enter error state and return before reaching `_maybeTriggerExpiredModal()`, so the trial expired modal and trial reminder alert are never shown.

## Fix

Created `FakeUserRepository` and wired it into the test infrastructure:

1. **New file:** `integration_test/mocks/fake_user_repository.dart` — implements `UserRepository` returning a fixed user
2. **Modified:** `integration_test/utils/test_app.dart` — added `UserRepository?` parameter to `buildTestModules` and `createTestApp`
3. **Modified:** `integration_test/utils/auth_helpers.dart` — `pumpToHomeWithUser` now accepts optional `UserRepository` and defaults to `FakeUserRepository(user)`

This allows `_loadHome()` to successfully load the user, reach `_maybeTriggerExpiredModal()`, and show the expected widgets.

## Preventive Measures

1. **Test infrastructure review:** When adding new integration tests that exercise full UI flows, ensure all repository dependencies have proper fakes — not just the auth-related ones.
2. **Add a negative assertion:** The `_loadHome` error case should log or expose the error so integration tests can detect silent failures (e.g., assert `HomeStatus.populated` or `HomeStatus.empty` before checking for specific widgets).
3. **Consider adding a `FakeProtocolRepository`:** If future tests involve users with active protocols, the `ProtocolRepository` will face the same `MockDataSourceAbstraction.from()` issue.
