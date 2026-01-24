# fn-21-wbj.1 Implement migration: trial_expiration_columns.sql

## Description
Create Supabase migration to add trial expiration columns, CHECK constraint, partial index, backfill existing users, and update the auth trigger.

**Source:** `plan_trial_expiration_cron_job.md` - Phase 6.1

### Schema changes:
1. Add CHECK constraint for `subscription_status`:
   ```sql
   ALTER TABLE public.users
   ADD CONSTRAINT chk_subscription_status
   CHECK (subscription_status IN ('trial', 'free', 'premiumMonthly', 'premiumAnnual', 'expired', 'grace'));
   ```

2. Update comment to match:
   ```sql
   COMMENT ON COLUMN public.users.subscription_status IS
     'Enum stored as text: trial, free, premiumMonthly, premiumAnnual, expired, grace';
   ```

3. Add `trial_ends_at timestamptz NULL` column to `public.users`

4. Add `trial_expired_at timestamptz NULL` column to `public.users` (audit timestamp for cron processing)

5. Add partial index for cron query performance:
   ```sql
   CREATE INDEX idx_users_trial_expiration
   ON public.users (trial_ends_at)
   WHERE subscription_status = 'trial' AND trial_expired_at IS NULL;
   ```

### Backfill existing users:
```sql
UPDATE public.users
SET trial_ends_at = (trial_period->>'start_date')::timestamptz + INTERVAL '7 days'
WHERE trial_period IS NOT NULL
  AND trial_ends_at IS NULL;
```

### Update auth trigger:
Modify `handle_new_user()` to compute `trial_ends_at` on signup:
```sql
trial_ends_at = new.created_at + INTERVAL '7 days'
```

## References
- `supabase/migrations/20251204192228_initial_schema.sql:103-110` (users table)
- `supabase/migrations/20251230160000_auth_trigger_and_rls.sql:5-28` (existing trigger)
- `supabase/migrations/20251230160000_auth_trigger_and_rls.sql:21` (trial_period JSONB structure)

## Acceptance
- [ ] Migration file created with timestamp naming convention
- [ ] CHECK constraint added for subscription_status enum values
- [ ] trial_ends_at and trial_expired_at columns added
- [ ] Partial index created for efficient cron queries
- [ ] Existing users backfilled with computed trial_ends_at
- [ ] handle_new_user() trigger updated to set trial_ends_at on new signups

## Done summary
Created Supabase migration adding trial expiration columns (trial_ends_at, trial_expired_at), CHECK constraint for subscription_status enum values (with NOT VALID + VALIDATE pattern), partial index for cron query performance, backfill for existing users, and updated handle_new_user() trigger to set trial_ends_at on signup.
## Evidence
- Commits: cbd076d, 4e95d75a59c5e5c0ec00061af737589dd0e107fc
- Tests:
- PRs: