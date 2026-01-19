# fn-1-cl3.6 Create SessionSyncService (Phase 2.3)

## Description
TBD

## Acceptance
- [ ] Create `SessionSyncService` in `lib/features/session/data/session_sync_service.dart`
- [ ] Follow service pattern from `lib/features/auth/data/auth_service.dart`
- [ ] Inject: `SessionLocalDataSource`, `SessionRemoteDataSource`, `ConnectivityService`, auth user source
- [ ] Implement `init()` to attach connectivity listener
- [ ] Implement `sync()` with algorithm: check online + auth → load pending → push each → remove on success
- [ ] Implement `dispose()` to detach listeners
- [ ] Handle errors gracefully (keep in queue for retry)
- [ ] Add unit tests for sync flow, offline handling, error recovery
- [ ] Tests pass with `flutter test`
- [ ] `flutter analyze` passes


## Done summary
Created SessionSyncService for offline-first session sync with connectivity-aware background sync. The service attaches to connectivity changes, checks online status and auth, pushes pending sessions to remote, and removes from queue on success (keeping on failure for retry). Addressed review feedback: fixed duplicate submission risk by removing pending immediately after remote success, made sync() never throw since it's called via unawaited(), and aligned SessionInsertDto timestamp handling with UTC policy.
## Evidence
- Commits: cded96a, 6abe80b, 8ccf6e9
- Tests: flutter test test/features/session/data/services/session_sync_service_test.dart
- PRs: