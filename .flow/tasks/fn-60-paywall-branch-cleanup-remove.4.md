# fn-60-paywall-branch-cleanup-remove.4 Extract shared ViewModel utilities and relocate HomeBottomTab

## Description
Extract shared ViewModel utility methods that are duplicated across Home, Library, and Progress ViewModels. Also relocate `HomeBottomTab` and `HomeBottomTabCoordinator` to a shared location.

**Size:** M
**Files:**
- `lib/home/home_view_model.dart`
- `lib/library/library_view_model.dart`
- `lib/progress/progress_view_model.dart`
- `lib/home/home_state.dart` (remove `HomeBottomTab` from here)
- `lib/library/library_state.dart` (update import)
- `lib/core/utils/auth_helpers.dart` (NEW — shared auth resolution utility)
- `lib/core/models/home_bottom_tab.dart` (NEW — relocated enum)
- `lib/home/home_bottom_tab_coordinator.dart` (update import)

## What to extract

### `_resolveUserId()` → standalone function or extension
Identical in 3 ViewModels. Depends only on `AuthService.authState`. Extract to `lib/core/utils/auth_helpers.dart`:

```dart
String? resolveUserId(ValueListenable<AuthState> authState) { ... }
```

Or as an extension on `AuthService`.

### `_resolveCachedUser()` → shared utility (Library + Progress only)
Both check `_cachedUser`, then `AuthenticatedOffline`, then `CachedUserStore`. Extract as a utility function that takes the dependencies as parameters.

### Snapshot user-scoping helper (HomeViewModel only)
The pattern `rawSnapshot != null && rawSnapshot.isForUser(user.id) ? rawSnapshot : null` appears twice in HomeViewModel (L556-560, L663-667). Extract to a private helper `_scopedSnapshot(User user)`.

### `_failureMessage()` → shared utility (Home + Library only)
Near-identical in Home (L734) and Library (L614), both return `String`. Progress uses a different signature (returns `DomainFailure`) so it stays as-is.

### `HomeBottomTab` → `lib/core/models/home_bottom_tab.dart`
Currently defined in `home_state.dart` but imported by Library and Progress, creating a cross-module dependency. Move to shared location. Update `HomeBottomTabCoordinator` import accordingly.

## Approach

- Create `lib/core/utils/auth_helpers.dart` for `resolveUserId` and `resolveCachedUser`
- These are pure functions taking explicit parameters (not mixins) — keeps ProgressVM compatible without scope creep
- Move `HomeBottomTab` enum and update ~8 import sites
- Do NOT migrate ProgressViewModel to use entitlement/connectivity mixins (out of scope)

## Key context

- ProgressViewModel does NOT use `EntitlementListenerMixin` or `ConnectivityListenerMixin` — only manual connectivity listener
- The `_failureMessage` in Progress returns `DomainFailure` not `String` — different signature, leave it alone
- `HomeBottomTabCoordinator` at `lib/home/home_bottom_tab_coordinator.dart` must update its import after the enum moves
## Acceptance
- [ ] `resolveUserId()` extracted to shared utility — no copies in VMs
- [ ] `resolveCachedUser()` extracted to shared utility — no copies in Library/Progress VMs
- [ ] Snapshot-scoping helper extracted in HomeViewModel (no inline repetition)
- [ ] `_failureMessage()` extracted for Home + Library (Progress keeps its own variant)
- [ ] `HomeBottomTab` relocated from `home_state.dart` to `lib/core/models/`
- [ ] All imports updated (~8 files)
- [ ] `flutter test test/home/ test/library/ test/progress/` passes
- [ ] `flutter analyze` passes
## Done summary
Extracted shared ViewModel utilities (resolveUserId, resolveCachedUser, failureMessage) to core, relocated HomeBottomTab enum to lib/core/models/, and added _scopedSnapshot helper in HomeViewModel to eliminate inline duplication.
## Evidence
- Commits: e309c6b3c67f43e292c1d10fb2afb7c4056899da
- Tests: flutter test test/home/ test/library/ test/progress/, flutter analyze
- PRs: