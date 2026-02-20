# fn-57-phase-112-update-handle-new-user-before.1 Create migration to update handle_new_user() trigger removing trial columns from INSERT

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
Created Supabase migration (20260213200443_update_handle_new_user_no_trial) that updates the handle_new_user() trigger to remove trial_period and trial_ends_at from the INSERT statement, leaving only id, subscription_status, protocol_ids, onboarding_completed, and created_at. This unblocks Phase 11.3 (dropping the trial columns).
## Evidence
- Commits: 650d320c61b53b173a46ad80bece9efca0aa4f55
- Tests: flutter analyze, flutter test
- PRs: