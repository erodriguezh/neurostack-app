# fn-22-5wl.1 Create expire_trials() function and pg_cron schedule migration

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
Created expire_trials() function and pg_cron schedule migration with security hardening (SET search_path, REVOKE PUBLIC) and idempotent job scheduling.
## Evidence
- Commits: 6ea0fd2, 27180ac, cda35f8
- Tests: flutter analyze
- PRs: