# fn-15-u8i.1 Add CachedUserStore dependency to HomeViewModel (Phase 4.1)

## Description
Add `CachedUserStore` as a dependency to `HomeViewModel` so that `handleUseFreeTier()` can update the user cache when transitioning to free tier.

## Files to Modify
- `lib/home/home_view_model.dart`

## Implementation

### Constructor change:
```dart
HomeViewModel({
  // ... existing params ...
  CachedUserStore? cachedUserStore,
}) : // ... existing assignments ...
     _cachedUserStore = cachedUserStore;

final CachedUserStore? _cachedUserStore;
```

### Import to add:
```dart
import 'package:neurostack/features/auth/data/cached_user_store.dart';
```

## Acceptance
- [ ] `CachedUserStore` is an optional parameter in the constructor
- [ ] Private field `_cachedUserStore` stores the dependency
- [ ] Import is added for `CachedUserStore`
- [ ] No regressions in existing functionality

## Done summary
Added CachedUserStore as an optional dependency to HomeViewModel constructor with private field _cachedUserStore, enabling future use in handleUseFreeTier() for cache updates during free tier transitions.
## Evidence
- Commits: d84fea8e475e9140b758e951996b24be10dc4eb5
- Tests: flutter test, flutter analyze
- PRs: