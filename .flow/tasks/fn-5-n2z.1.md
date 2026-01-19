# fn-5-n2z.1 Remove or deprecate backdateSession() method from ProgressViewModel

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
Removed the deprecated backdateSession() method from ProgressViewModel along with its supporting private methods (_revertBackdate, _notifyOffline) and the unused LogSessionUseCase dependency, as session logging is now handled via LogSessionModal.
## Evidence
- Commits: 9e9988d2b99561021e6d27f881f3c846a87c19c8
- Tests: flutter analyze, flutter test test/progress/, flutter test
- PRs: