# Paywall Branch Cleanup

## Overview

Refactor and clean up the `feature/paywall-modal` branch after 100+ commits across 12 implementation phases. The branch accumulated significant duplicate code across ViewModels, dead code from iterative development, and scattered test mock declarations.

**Scope:** Internal refactoring only — no user-visible changes, no new features, no behavioral changes.

## Stakeholders

- **End users:** No visible changes
- **Developers:** Cleaner architecture, shared utilities, fewer duplicate mocks
- **Operations:** No changes

## Key Findings (from research)

### Duplicate Code
1. `_resolveUserId()` — identical in Home, Library, Progress ViewModels
2. `_resolveCachedUser()` — identical in Library and Progress ViewModels
3. `_failureMessage()` — near-identical in 3 ViewModels (Home/Library return String, Progress returns DomainFailure)
4. `_StaggeredFadeIn` widget — character-for-character identical in Home and Library views
5. `_ErrorState` widget — identical in Home, Library, and Progress views
6. Mixin wiring boilerplate — identical in Home and Library
7. Snapshot user-scoping pattern — repeated inline twice in HomeViewModel

### Dead Code
1. Legacy `isResolved()`/`markResolved()` on `TrialExpirationDecisionStore` — never called from production
2. `isSubscriptionExpirationResolved()`/`markSubscriptionExpirationResolved()` — never called from production
3. `ExpirationDecision` enum — only used by dead methods
4. `User.upgradeToPremium()` — never called from production
5. `User.updateSubscriptionStatus()` — never called from production
6. `TrialStartedEvent` + `SubscriptionUpgradedEvent` — never raised from production

### Test Duplication
1. Two independent `FakeRevenueCatClient` — unit test (inline) vs integration test (extracted)
2. Mock classes redeclared in 3+ test files each (MockNotifyService, MockRouterService, MockAuthService, etc.)

## Scope Decisions

| Item | Decision | Rationale |
|------|----------|-----------|
| ProgressViewModel mixin alignment | OUT of scope | Scope creep — Progress has no paywall/entitlement logic |
| `goToPaywall()` consolidation | OUT of scope | Home and Library serve different purposes (Home awaits paywall dismissal for retry loop; Library is fire-and-forget) |
| `onAddProtocol`/`onBrowseLibrary` merge | OUT of scope | Semantically different intents, same implementation today but may diverge |
| `_failureMessage` extraction | IN scope (Home + Library only) | Progress uses a different signature returning DomainFailure |
| Web stub (`revenuecat_client_stub.dart`) | NOT dead code | Serves web platform — explicitly keep |
| Orphaned SharedPreferences keys | Leave as harmless orphaned data | No migration needed |

## Quick commands

```bash
flutter analyze
flutter test
flutter test test/paywall/
flutter test test/home/
flutter test test/library/
flutter test test/progress/
```

## Acceptance

- [ ] `flutter analyze` passes with zero warnings
- [ ] `flutter test` passes (all existing + updated tests green)
- [ ] No duplicate `_resolveUserId()` across ViewModels
- [ ] No duplicate `_ErrorState` or `_StaggeredFadeIn` widgets across views
- [ ] Dead code removed from TrialExpirationDecisionStore (legacy + unused new methods)
- [ ] Dead domain methods removed from User entity
- [ ] Dead domain events removed (TrialStartedEvent, SubscriptionUpgradedEvent)
- [ ] Shared mocks extracted to `test/mocks/` (no duplicate Mock class declarations)
- [ ] `HomeBottomTab` lives in a shared location (not imported from home_state.dart by Library/Progress)
