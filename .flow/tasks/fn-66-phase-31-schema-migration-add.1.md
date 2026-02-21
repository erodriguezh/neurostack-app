# fn-66-phase-31-schema-migration-add.1 Implement schema migration: add description column + fix stale comments

## Description

Create a new Supabase migration file that:
1. Adds a `description text NOT NULL DEFAULT ''` column to `public.protocols`
2. Fixes stale `COMMENT ON COLUMN` for `category`, `evidence_level`, and `target`
3. Adds a `COMMENT ON COLUMN` for the new `description` column

### Details from plan (Phase 3.1)

- **New file:** `supabase/migrations/YYYYMMDDHHMMSS_add_protocol_description.sql`
- `ALTER TABLE public.protocols ADD COLUMN IF NOT EXISTS description text NOT NULL DEFAULT ''`
- Fix stale `COMMENT ON COLUMN public.protocols.category` → list actual enum values (exercise, heatTherapy, coldExposure, nutrition, supplements, mind, sleep)
- Fix stale `COMMENT ON COLUMN public.protocols.evidence_level` → list actual enum values (multipleRcts, singleRct, observational, expertConsensus)
- Fix stale `COMMENT ON COLUMN public.protocols.target` → note JSONB keys use camelCase (`durationSeconds`, `intensity`, `frequency`)
- Add `COMMENT ON COLUMN public.protocols.description`
- Cite: existing comments at `supabase/migrations/20251204192228_initial_schema.sql` lines 33-37

## Acceptance
- [ ] Migration file created with proper timestamp naming
- [ ] ALTER TABLE adds description column with NOT NULL DEFAULT ''
- [ ] Stale category comment fixed with actual enum values
- [ ] Stale evidence_level comment fixed with actual enum values
- [ ] Stale target comment fixed to note camelCase JSONB keys
- [ ] New description column comment added
- [ ] Migration is idempotent (uses IF NOT EXISTS)

## Done summary
Created Supabase migration 20260221193000_add_protocol_description.sql that adds a description text NOT NULL DEFAULT '' column to public.protocols, fixes stale COMMENT ON COLUMN for category (actual enum values), evidence_level (actual enum values), and target (correct JSONB key casing including snake_case nested frequency keys), and adds a comment for the new description column.
## Evidence
- Commits: ba54cea9497b6aa706f1cc952510c8d1595709d0
- Tests: flutter analyze, flutter test
- PRs: