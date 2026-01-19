# fn-2-8il.1 Update HomeViewModel to use SessionLocalDataSource for combined sessions

## Description
Update `HomeViewModel` to read sessions from `SessionLocalDataSource` (combined synced + pending) instead of only remote, enabling offline-first session display.

From `plan_log_session_modal.md` Phase 4.4:
- **File:** `lib/home/home_view_model.dart`
- **Current:** `_loadCards()` fetches from remote
- **Change:**
  - Inject `SessionLocalDataSource`
  - On load: if online, fetch remote + upsert to local cache
  - Read `loggedToday` from local combined sessions (synced + pending)

## Implementation details

1. Add `SessionLocalDataSource` parameter to `HomeViewModel` constructor
2. In `_loadCards()`:
   - If online: fetch sessions from remote, upsert to local via `upsertSyncedSessions()`
   - Read today's sessions from `SessionLocalDataSource.listSessions()` with date filter
   - Use combined list to determine `loggedToday` status for each protocol card

## Acceptance
- [ ] HomeViewModel accepts SessionLocalDataSource dependency
- [ ] _loadCards() reads from local combined sessions
- [ ] When online, remote sessions are fetched and cached
- [ ] `flutter analyze` passes
- [ ] Tests pass

## Done summary
Updated HomeViewModel to use SessionLocalDataSource for offline-first session display. When online, remote sessions are fetched and cached locally; the UI always reads from combined local sessions (synced + pending). Remote sync is best-effort to ensure resilience when server is unavailable.

### Refactoring (post-review)
- Added `startOfDay`/`endOfDay` extensions to `DateTimeWeekExtension` with UTC preservation
- Updated `weekStart`/`weekEnd` to preserve UTC and use consistent precision
- DST-safe `endOfDay`: uses calendar-based next day (DateTime constructor) instead of 24h addition
- Replaced `debugPrint` with `Logger` in HomeViewModel for consistent logging infrastructure
- Added 4 unit tests for UTC preservation in date extensions

## Evidence
- Commits: cff265a, fc041e2, f0f7d89, aa4a3c4, ee31a61
- Tests: flutter analyze, flutter test
- Review: RepoPrompt impl review → SHIP
- PRs: