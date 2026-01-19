# fn-3-8ne.1 Replace backdate sheet with LogSessionModal (Phase 5.1)

## Description
Replace the existing backdate session sheet in ProgressView with the new LogSessionModal.

## File
`lib/progress/progress_view.dart`

## Current State
`lib/progress/progress_view.dart` — `_showBackdateSheet()` method uses `BackdateSessionSheet`

## Changes Required

1. **Resolve Protocol from cached store**
   - Get the Protocol object from `CachedProtocolStore` using the protocolId from the cell
   - Handle case where protocol might not be found (show error toast)

2. **Call `showLogSessionModal()` with cell's date**
   - Import `log_session_modal.dart`
   - Replace `_showBackdateSheet()` implementation to call `showLogSessionModal()`
   - Pass the cell's date as `initialDate`
   - Pass the resolved Protocol

3. **Handle `onSessionLogged` callback**
   - Call `_viewModel.onSessionLogged(session)` (to be added in Phase 5.2, for now use refresh)
   - Trigger grid refresh after session logged

## Dependencies
- `showLogSessionModal()` from `lib/features/session/presentation/log_session_modal.dart`
- `CachedProtocolStore` from `lib/features/protocol/data/cached_protocol_store.dart`

## Pattern Reference
- Current implementation: `lib/progress/widgets/backdate_session_sheet.dart`
- Modal entry: `lib/features/session/presentation/log_session_modal.dart`

## Acceptance
- [ ] Tapping a cell opens LogSessionModal instead of BackdateSessionSheet
- [ ] Protocol is correctly resolved from cache
- [ ] Cell's date is passed as initialDate to modal
- [ ] Session logged callback triggers grid refresh
- [ ] No compilation errors

## Done summary
- Task completed
## Evidence
- Commits:
- Tests:
- PRs: