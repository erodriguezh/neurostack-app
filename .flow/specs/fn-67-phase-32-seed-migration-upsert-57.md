# fn-67-phase-32-seed-migration-upsert-57 Phase 3.2: Seed migration — upsert 57 protocols + 76 citations

## Overview
Generate a Supabase migration SQL file that upserts all 57 protocols and their 76 citations from `protocols.json` into the database. Also create a Dart helper script that reads `protocols.json` and outputs the migration SQL.

## Scope
1. **`tool/generate_seed_sql.dart`** — Dart script that reads `protocols.json` and outputs migration SQL to stdout
2. **`supabase/migrations/YYYYMMDDHHMMSS_seed_protocols.sql`** — Generated migration file

## Approach
- Add case-insensitive unique index: `CREATE UNIQUE INDEX IF NOT EXISTS protocols_name_unique ON public.protocols (lower(name))`
- For each of 57 protocols: `INSERT INTO public.protocols (name, description, target, category, evidence_level) VALUES (...) ON CONFLICT ((lower(name))) DO UPDATE SET description=EXCLUDED.description, target=EXCLUDED.target, category=EXCLUDED.category, evidence_level=EXCLUDED.evidence_level`
- For citations: `DELETE FROM public.research_citations WHERE protocol_id = (SELECT id FROM public.protocols WHERE name = ...)` then re-insert
- Use `durationSeconds` (camelCase) in target JSONB — matches `lib/features/protocol/data/dtos/target_dto.dart`
- Strip `verification_status`, `verification_note`, `source_models` from JSON data
- Use explicit `null` for missing DOI values; use dollar-quoted strings (`$desc$...$desc$`) for safe SQL literals
- Include SHA-256 checksum of `protocols.json` as comment in generated SQL for audit trail
- Script is run manually; output is committed

## Quick commands
- `dart run tool/generate_seed_sql.dart > supabase/migrations/YYYYMMDDHHMMSS_seed_protocols.sql`
- `flutter analyze`
- `flutter test`

## Acceptance
- [ ] `tool/generate_seed_sql.dart` exists and runs without errors
- [ ] Generated SQL includes case-insensitive unique index
- [ ] All 57 protocols upserted with ON CONFLICT clause
- [ ] All citations deleted and re-inserted per protocol
- [ ] Target JSONB uses camelCase keys (`durationSeconds`)
- [ ] `verification_status`, `verification_note`, `source_models` stripped
- [ ] SHA-256 checksum of `protocols.json` in SQL comment
- [ ] Dollar-quoted strings used for safe SQL literals
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes

## References
- `protocols.json` — source data
- `supabase/seed.sql` — existing seed pattern
- `lib/features/protocol/data/dtos/target_dto.dart` — target JSONB format
- `plan_update_protocol_domain_and_db.md` Phase 3.2
