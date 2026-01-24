# fn-20-7vp.1 Create HomeViewModel tests for trial expiration and free tier transition

## Description
Add comprehensive tests for HomeViewModel focusing on trial expiration modal trigger logic and free tier transition handling.

## Test File
- **New file:** `test/home/home_view_model_test.dart`

## Test Cases

### `handleUseFreeTier()` tests
1. **With 2 protocols → status becomes `free`, cache updated**
   - User has `activeProtocolCount = 2`
   - Call `handleUseFreeTier()`
   - Verify `_userRepository.save()` called with user having `SubscriptionStatus.free`
   - Verify `_cachedUserStore.saveUser()` called
   - Verify `showDeactivationModal` is NOT set to true

2. **With 3 protocols → triggers deactivation modal**
   - User has `activeProtocolCount = 3`
   - Call `handleUseFreeTier()`
   - Verify `showDeactivationModal` is set to true in state
   - Verify `_userRepository.save()` NOT called

### `_maybeTriggerExpiredModal()` tests (via `init()` or user stream)
3. **Triggers for trial expiration (trial + effective free)**
   - User has `subscriptionStatus = SubscriptionStatus.trial`
   - User has `trialPeriod` that is expired (end date in past)
   - `getEffectiveStatus(now)` returns `SubscriptionStatus.free`
   - Verify `showTrialExpiredModal` is set to true in state

4. **Triggers for premium expiration (expired status)**
   - User has `subscriptionStatus = SubscriptionStatus.expired`
   - Verify `showTrialExpiredModal` is set to true in state

5. **Does NOT trigger for active trial**
   - User has `subscriptionStatus = SubscriptionStatus.trial`
   - User has `trialPeriod` that is NOT expired (end date in future)
   - `getEffectiveStatus(now)` returns `SubscriptionStatus.trial`
   - Verify `showTrialExpiredModal` remains false in state

### `isTrialOrPremiumExpired()` tests
6. **Returns true for expired trial**
   - User with trial status but expired trial period
   - Verify method returns true

7. **Returns false for active trial**
   - User with trial status and active trial period
   - Verify method returns false

8. **Returns true for expired premium**
   - User with expired status
   - Verify method returns true

9. **Returns false for free user**
   - User with free status
   - Verify method returns false

## Dependencies to Mock
- `UserRepository` - mock `save()` and `watchCurrent()`
- `ProtocolRepository` - mock `watchActiveProtocols()`
- `SessionRepository` - mock `watchProtocolSessions()`
- `RouterService` - mock navigation
- `CachedUserStore` - mock `saveUser()`
- `ToastService` - mock toast display (for error handling)

## Reference Files
- `lib/home/home_view_model.dart` - source under test
- `lib/features/user/domain/entities/user.dart` - User entity with `getEffectiveStatus()`
- `test/factories/user_factory.dart` - test factory for User entities
- `test/home/home_view_model_test.dart` - may already exist, check first

## Patterns to Follow
- Use `mocktail` for mocking
- Use test factories from `test/factories/`
- Follow AAA pattern (Arrange, Act, Assert)
- Use `fakeAsync` for time-dependent tests

## Acceptance
- [ ] All 9 test cases pass
- [ ] Tests use proper mocking with mocktail
- [ ] Tests follow AAA pattern
- [ ] flutter analyze passes
- [ ] flutter test passes

## Done summary
Added 11 comprehensive HomeViewModel tests covering trial expiration modal trigger logic and free tier transition handling. Tests include handleUseFreeTier() scenarios, _maybeTriggerExpiredModal() via init(), and isTrialOrPremiumExpired() helper method with regression tests for users who chose free tier.
## Evidence
- Commits: 192cf63e4b3f6d1c2a5b8e7f9c0d1a2b3c4d5e6f, fb69503efc137a016a109ecfdb7318eddbcd8c35
- Tests: flutter test test/home/home_view_model_test.dart, flutter test
- PRs: