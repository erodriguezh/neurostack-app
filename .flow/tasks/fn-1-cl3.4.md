# fn-1-cl3.4 Create PendingSessionDto (Phase 2.1)

## Description
TBD

## Acceptance

- [ ] Create `lib/features/session/data/dtos/pending_session_dto.dart`
- [ ] Follow pattern from `session_insert_dto.dart` (freezed + json_serializable)
- [ ] Include all PendingSession fields: localId, userId, draft (flattened fields: protocolId, completedAt, durationSeconds, notes), createdAt, retryCount
- [ ] Add `toDomain()` method to convert to PendingSession entity
- [ ] Add `fromDomain()` factory to create from PendingSession entity
- [ ] Run build_runner to generate .g.dart and .freezed.dart files
- [ ] Add unit tests for round-trip serialization
- [ ] Tests pass: `flutter test`
- [ ] Analyze passes: `flutter analyze`


## Done summary
- Created PendingSessionDto with freezed/json_serializable for SharedPreferences storage
- Added SessionDraft.reconstitute() factory to bypass validation on load from persistence
- Added PendingSessionDtoFactory for test data generation

Why:
- Enables offline-first persistence of pending sessions (Phase 2.1)
- Round-trip serialization preserves all entity data with flattened SessionDraft fields

Verification:
- flutter analyze: No issues found
- flutter test test/features/session/data/dtos/pending_session_dto_test.dart: 23/23 pass
- flutter test test/domain/session/: All 76 session tests pass
## Evidence
- Commits: 23050a012a39d11c0e1fa560e008bbd28f10f57a
- Tests: flutter test test/features/session/data/dtos/pending_session_dto_test.dart
- PRs: