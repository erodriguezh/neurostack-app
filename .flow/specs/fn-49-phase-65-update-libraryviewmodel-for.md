# Phase 6.5: Update LibraryViewModel for RevenueCat

## Goal
Update LibraryViewModel to use SubscriptionStatusResolver and RevenueCatService for protocol locking, replacing direct user.subscriptionStatus checks.

## Plan Reference
See `plan_paywall_modal.md` Phase 6.5.

## Requirements
- Constructor inject `SubscriptionStatusResolver` and `RevenueCatService`
- Use `_resolver.resolveEffectiveStatus()` for protocol locking instead of raw `user.subscriptionStatus`
- Listen to `_revenueCatService.entitlementSnapshot` for real-time updates
- Update DI registration in `locator_config.dart`
- Follow existing patterns from Phase 6.1 (HomeViewModel update)

## Key Files
- `lib/library/library_view_model.dart` - Main file to update
- `lib/config/locator_config.dart` - DI registration
- `lib/paywall/domain/subscription_status_resolver.dart` - Resolver to inject
- `lib/paywall/data/revenuecat_service.dart` - Service to inject

## After Implementation
- Run `flutter analyze`
- Run `flutter test`
- Propose any refactoring/simplification opportunities before moving on
