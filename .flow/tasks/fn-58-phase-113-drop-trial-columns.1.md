# fn-58-phase-113-drop-trial-columns.1 Create migration to drop trial_ends_at, trial_expired_at, trial_period columns

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
Created and applied a Supabase migration to drop the legacy trial columns (trial_ends_at, trial_expired_at, trial_period) and their partial index (idx_users_trial_expiration) from the public.users table. Updated plan to mark Phase 11.3 as done.
## Evidence
- Commits: ab80ca94ea39748398eb89b8bc6eac834761224a
- Tests: flutter analyze, flutter test
- PRs: