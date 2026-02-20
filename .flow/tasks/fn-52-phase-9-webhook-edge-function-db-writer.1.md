# fn-52-phase-9-webhook-edge-function-db-writer.1 Create apply_revenuecat_event() SECURITY DEFINER RPC migration (Phase 9.1.1)

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
Created apply_revenuecat_event() SECURITY DEFINER RPC migration for webhook subscription status updates. The function enforces monotonicity (timestamp-based), idempotency (event_id dedup), NULL argument guards, status validation aligned with DB CHECK constraint, and is restricted to service_role only.
## Evidence
- Commits: a3da6c3, 3313510, 4ce49d8
- Tests: flutter analyze, flutter test
- PRs: