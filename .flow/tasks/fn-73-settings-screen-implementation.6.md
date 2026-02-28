# fn-73-settings-screen-implementation.6 Phase 2.1: Add tab coordination and subscription awareness to SettingsViewModel

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
Refactored SettingsViewModel with EntitlementListenerMixin for live subscription awareness, tab coordination via HomeBottomTabCoordinator, navigation methods (goToPaywall, goToContact, openSubscriptionManagement), and injectable url_launcher. Delivered ahead of schedule: ContactView placeholder, /settings/contact route registration, url_launcher dependency, and SettingsView tab-screen shell with HomeBottomNav. Added 14 unit tests covering isPremium computation, entitlement updates, navigation, tab coordination, platform-specific URL launching, and dispose safety.
## Evidence
- Commits: 0afebba, 6daca1a, f5055b3, 64e57b8, 229c78d, f9dcd9a
- Tests: flutter analyze, flutter test
- PRs: