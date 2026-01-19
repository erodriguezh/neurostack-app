# fn-1-cl3.5 Create SessionLocalDataSource (Phase 2.2)

## Description
TBD

## Acceptance
- [ ] Create `SessionLocalDataSource` in `lib/features/session/data/data_sources/session_local_data_source.dart`
- [ ] Follow patterns from `CachedUserStore` and `CachedWeekProgressStore`
- [ ] Implement `savePendingSession(PendingSession)` method
- [ ] Implement `getPendingSessions(userId)` returning `List<PendingSession>`
- [ ] Implement `removePendingSession(userId, localId)` method
- [ ] Implement `upsertSyncedSessions(userId, List<Session>)` method
- [ ] Implement `listSessions(userId, {from?, to?})` for combined synced + pending
- [ ] Use storage keys: `pending_sessions_$userId`, `synced_sessions_$userId`
- [ ] Add unit tests covering round-trip, corrupt JSON handling, merge logic, date filtering
- [ ] Tests pass with `flutter test`
- [ ] `flutter analyze` passes


## Done summary
- **What changed**:
  - Created `SessionLocalDataSource` for offline-first session persistence
  - Implements pending sessions queue (save/get/remove) and synced sessions cache (upsert)
  - Combined listing with date filtering and descending sort by completedAt
  - Graceful corrupt data handling: clears cache on parse failure, skips invalid entries
  
- **Why**:
  - Enables offline session logging (pending queue for sync later)
  - Provides local cache for synced sessions to reduce network calls
  - Supports multi-user safety with user-scoped storage keys
  
- **Verification**:
  - 28 unit tests passing (round-trip, corrupt JSON, merge logic, date filtering)
  - `flutter analyze` passes with no issues
## Evidence
- Commits: a0ed3f83118a3ea4cf6889e0bb44ec27540ce9b0
- Tests: flutter test test/features/session/data/data_sources/session_local_data_source_test.dart
- PRs: