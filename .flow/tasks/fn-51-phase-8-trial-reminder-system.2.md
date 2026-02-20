# fn-51-phase-8-trial-reminder-system.2 Wire RevenueCat refresh on app resume (Phase 8.4)

## Description

When the app returns to foreground (resumed), refresh the RevenueCat entitlement snapshot. This catches subscription changes made outside the app (e.g., user upgraded/cancelled via App Store settings).

The existing `AppLifecycleService` exposes a `lifecycle` ValueNotifier. The `RevenueCatService.refreshEntitlement()` method is safe for lifecycle callbacks (swallows all exceptions).

Wire lifecycle listener: when `AppLifecycleState.resumed` fires, call `RevenueCatService.refreshEntitlement()`.

Approach: Add a lifecycle listener in `AppLifecycleService` (constructor-inject RevenueCatService). The service already owns lifecycle state so this is the natural place.

### Key files
- Modified: `lib/core/utils/app_lifecycle_service.dart`
- Modified: `lib/config/locator_config.dart` (update DI for new dependency)
- Modified: `lib/startup/startup_view_model.dart` (if DI wiring affected)

## Acceptance
- [x] AppLifecycleService listens for `AppLifecycleState.resumed` and calls `RevenueCatService.refreshEntitlement()`
- [x] Constructor injection of RevenueCatService into AppLifecycleService
- [x] DI registration updated
- [x] Existing tests pass
- [x] `flutter analyze` passes
- [x] `flutter test` passes

## Done summary
- Task completed
## Evidence
- Commits: 4f16829
- Tests: flutter analyze, flutter test
- PRs: