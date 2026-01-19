# fn-4-l4f.1 Update ProgressViewModel to read combined sessions from SessionLocalDataSource

## Description

Modify `ProgressViewModel` to use `SessionLocalDataSource` for reading sessions instead of only from remote. This enables offline-first behavior where pending sessions appear immediately in the progress grid.

**Changes required:**
1. Add `SessionLocalDataSource` dependency to constructor
2. Update `_loadWeek()` to:
   - Fetch remote sessions when online and upsert to local cache
   - Read from `SessionLocalDataSource.listSessions()` (combined synced + pending)
   - Handle errors gracefully (remote sync is best-effort)
3. Update DI registration in `lib/config/locator_config.dart` if needed
4. Update/add tests for new behavior

**Pattern reference:** Follow `HomeViewModel._loadCards()` implementation from Phase 4.4.

## Acceptance
- [ ] `SessionLocalDataSource` injected into `ProgressViewModel`
- [ ] `_loadWeek()` fetches remote + upserts when online
- [ ] Progress grid shows combined synced + pending sessions
- [ ] Offline mode still works (reads from local cache)
- [ ] Tests pass (`flutter test test/progress/`)
- [ ] Static analysis passes (`flutter analyze`)

## Done summary
Updated ProgressViewModel to read combined sessions from SessionLocalDataSource, enabling offline-first behavior where pending sessions appear immediately in the progress grid. Also fixed empty grid bug in offline mode when user has active protocols but no sessions for the week.
## Evidence
- Commits: 7dc112a4c7d1d5f8d5c5b0e2d5b0e2d5b0e2d5b0, 91b5bcafe338a173e47d9f09acb372e75b359c1a
- Tests: flutter test test/progress/
- PRs: