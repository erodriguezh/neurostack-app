# fn-49-phase-65-update-libraryviewmodel-for.1 Update LibraryViewModel to use SubscriptionStatusResolver and RevenueCatService

## Description
Update LibraryViewModel to constructor-inject SubscriptionStatusResolver and RevenueCatService, replacing direct user.subscriptionStatus checks with resolver.resolveEffectiveStatus(). Listen to entitlementSnapshot for real-time UI updates. Update DI registration. Follow HomeViewModel (Phase 6.1) patterns.

## Acceptance
- [ ] LibraryViewModel constructor injects SubscriptionStatusResolver and RevenueCatService
- [ ] Protocol locking uses resolver.resolveEffectiveStatus() instead of raw user.subscriptionStatus
- [ ] Listens to revenueCatService.entitlementSnapshot for real-time updates
- [ ] DI registration updated in locator_config.dart
- [ ] flutter analyze passes
- [ ] flutter test passes

## Done summary
Updated LibraryViewModel to use SubscriptionStatusResolver and RevenueCatService for protocol locking, replacing user.getEffectiveStatus() with resolver.resolveEffectiveStatus(). Added entitlement snapshot listener for real-time UI updates.
## Evidence
- Commits: 0c7e5e9, 7222fd6
- Tests: flutter analyze, flutter test
- PRs: