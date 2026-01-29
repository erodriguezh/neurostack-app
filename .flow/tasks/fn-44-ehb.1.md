# fn-44-ehb.1 Inject RevenueCatService into AuthService and integrate identify/logout calls

## Description

This is Phase 4.2 of the RevenueCat Paywall Integration plan (`plan_paywall_modal.md`).

Phase 4.1 (StartupViewModel) is already done - RevenueCat is initialized before Auth.init() runs.

### Goal

Update AuthService to call RevenueCat identify/logout when users authenticate/sign out.

### Requirements

1. **Add `RevenueCatService` as constructor parameter** to `AuthService`
2. **In `_rehydrateFromSession()`**: After successful user bootstrap, call `identify(data.user.id)`
3. **In `logout()`**: Call `_revenueCatService.logout()` before clearing local state
4. **Update DI registration** in `locator_config.dart` to inject `RevenueCatService`

### Files to Modify

- `lib/features/auth/data/auth_service.dart`
- `lib/config/locator_config.dart`

### Notes from Plan

- RevenueCatService.identify() is designed to be non-fatal - it logs and returns on any failure
- RevenueCatService.logout() is also best-effort - app sign-out should not be blocked
- Phase 4.3 (Update DI Registration) is included in this task

## Acceptance

- [ ] AuthService constructor takes RevenueCatService
- [ ] identify() called after successful user bootstrap in _rehydrateFromSession
- [ ] logout() called before signOut in logout()
- [ ] DI registration updated
- [ ] `flutter analyze` passes
- [ ] Existing auth tests pass (update mocks if needed)

## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
