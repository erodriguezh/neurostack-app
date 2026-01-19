# fn-4-l4f Phase 5.3: Update Progress to read combined sessions

## Overview

Update `ProgressViewModel` to read sessions from `SessionLocalDataSource` (combined synced + pending) instead of only from remote. This enables offline-first behavior where pending sessions appear immediately in the progress grid.

## Scope

**File to modify:** `lib/progress/progress_view_model.dart`

**Current behavior:** `_loadWeek()` at line ~96 fetches sessions only from remote via `SessionRepository`.

**Target behavior:**
1. Inject `SessionLocalDataSource` as dependency
2. On load: if online, fetch remote sessions and upsert to local cache
3. Read week sessions from `SessionLocalDataSource.listSessions()` (combined synced + pending)
4. Remote sync is best-effort — progress screen renders even if server unavailable

## Approach

Follow the pattern established in `HomeViewModel._loadCards()` (Phase 4.4):
- Fetch remote when online → upsert to local
- Read from local (combined) for display
- Handle errors gracefully

## Quick commands
- `flutter analyze`
- `flutter test test/progress/`

## Acceptance
- [ ] `SessionLocalDataSource` injected into `ProgressViewModel`
- [ ] `_loadWeek()` fetches remote + upserts when online
- [ ] Progress grid shows combined synced + pending sessions
- [ ] Offline mode still works (reads from local cache)
- [ ] Tests updated/added for new behavior

## References
- `plan_log_session_modal.md` Phase 5.3
- `lib/home/home_view_model.dart` (Phase 4.4 pattern)
- `lib/features/session/data/data_sources/session_local_data_source.dart`
