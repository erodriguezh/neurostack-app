# fn-33-6ay.1 Create migration for webhook bookkeeping columns

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
Created Supabase migration adding webhook bookkeeping columns (subscription_updated_at, subscription_source, rc_last_event_id) to users table for RevenueCat webhook idempotency and conflict resolution.
## Evidence
- Commits: 89b45c6a9c19686dc6ee8c8964b732ca15e8d02f
- Tests: flutter analyze, flutter test
- PRs: