# fn-68-phase-33-fix-supabaseseedsql-test-data Phase 3.3: Fix supabase/seed.sql (test data)

## Overview
Fix `supabase/seed.sql` to be compatible with the new seed migration (Phase 3.2) which inserts 57 protocols. The current seed.sql uses explicit IDs and stale enum values that will collide/fail.

## Scope
Edit `supabase/seed.sql` only.

## Approach (from plan_update_protocol_domain_and_db.md Phase 3.3)

1. **Remove explicit IDs** from protocol INSERTs — stop using `OVERRIDING SYSTEM VALUE` with fixed IDs 1..13. Let the DB assign identity values, matching the approach used by the seed migration in 3.2. This avoids PK collisions when `supabase db reset` runs migrations (which insert 57 protocols) before seed.sql (which inserts 13 test protocols).

2. **Resolve citation FKs by name:** replace `protocol_id = <literal int>` with `protocol_id = (SELECT id FROM public.protocols WHERE name = '...')` in research_citations INSERTs.

3. **Add `description` column** to INSERT statement — use placeholder descriptions for 13 test protocols.

4. **Fix stale category values:** `coldTherapy` → `coldExposure`, `supplementation` → `supplements`, `mindfulness` → `mind`

5. **Fix stale evidence levels:** `strong` → `singleRct`, `moderate` → `observational`, `proven` → `multipleRcts`, `preliminary` → `expertConsensus`

6. **Fix JSONB key:** `duration_seconds` → `durationSeconds` in all target objects

## Quick commands
- `flutter analyze`
- `flutter test`

## Acceptance
- [ ] No `OVERRIDING SYSTEM VALUE` in seed.sql
- [ ] No hardcoded protocol IDs in seed.sql
- [ ] Citation FKs resolved via subquery `(SELECT id FROM public.protocols WHERE name = ...)`
- [ ] `description` column present in all protocol INSERTs
- [ ] Category values match Dart enums: coldExposure, supplements, mind
- [ ] Evidence levels match Dart enums: singleRct, observational, multipleRcts, expertConsensus
- [ ] JSONB uses `durationSeconds` (camelCase)
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes

## References
- `supabase/seed.sql` — file to edit
- `supabase/migrations/20260221200000_seed_protocols.sql` — seed migration pattern to follow
- `lib/features/protocol/domain/enums/category.dart` — Dart category enum
- `lib/features/protocol/domain/enums/evidence_level.dart` — Dart evidence level enum
- `lib/features/protocol/data/dtos/target_dto.dart` line 21 — JSONB key format
- `plan_update_protocol_domain_and_db.md` Phase 3.3
