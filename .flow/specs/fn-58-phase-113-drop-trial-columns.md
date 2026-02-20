# fn-58-phase-113-drop-trial-columns Phase 11.3: Drop Trial Columns

## Overview
Drop the legacy trial columns from the `users` table. RevenueCat is now the source of truth for trial state.

## Prerequisites (all verified done)
- Phase 11.1: pg_cron jobs removed
- Phase 11.2: `handle_new_user()` trigger no longer references trial columns
- Phase 10.4: `UserDto` no longer serializes `trial_ends_at`

## Scope
Create a Supabase migration that drops:
- `trial_ends_at`
- `trial_expired_at`
- `trial_period`

Use `DROP COLUMN IF EXISTS` for idempotency.

## Quick commands
- `flutter analyze`
- `flutter test`

## Acceptance
- [ ] Migration applied via Supabase MCP
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
- [ ] Plan updated to mark Phase 11.3 as done
