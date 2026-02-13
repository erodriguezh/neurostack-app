# fn-56-phase-111-remove-pg-cron-job.1 Create migration to remove expire_trials cron jobs and function

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
Created migration to remove the two pg_cron trial expiration jobs (neurostack-expire-trials-morning, neurostack-expire-trials-evening) and drop the expire_trials() function. RevenueCat now manages trial expiration. Applied to remote Supabase via MCP.
## Evidence
- Commits: 3438fd6d5c79b075e293921018385c24fecd5c49
- Tests: flutter analyze, flutter test
- PRs: