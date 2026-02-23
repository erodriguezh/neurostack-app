## Description
Add a Supabase migration that tightens the `description` column on `public.protocols`:
1. Add a CHECK constraint ensuring `description` is non-empty (after trim) — matches the domain VO invariant in `ProtocolDescription.create()`
2. Drop the `DEFAULT ''` which contradicts the domain invariant

This resolves the critical issue: the migration at `20260221193000` added `NOT NULL DEFAULT ''` for backward compatibility, but `ProtocolDescription.create('')` rejects empty strings. The seed migration `20260221200000` already populated all 57 protocols with descriptions.

**Size:** S
**Files:**
- `supabase/migrations/YYYYMMDDHHMMSS_tighten_protocol_description.sql` (NEW)
- `docs/specs/20260220120000_spec_protocol_description_and_seed.md` (add rationale note for DEFAULT '' design decision)

## Approach

- New migration (timestamp after `20260221200000`) with:
  1. Safety check: `DO $$ BEGIN IF EXISTS (SELECT 1 FROM public.protocols WHERE trim(description) = '' OR description IS NULL) THEN RAISE EXCEPTION 'Cannot add CHECK: rows with empty description exist'; END IF; END $$;`
  2. Guard constraint creation for idempotency (Postgres has no `ADD CONSTRAINT IF NOT EXISTS`):
     ```sql
     DO $$ BEGIN
       IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'protocols_description_not_empty') THEN
         ALTER TABLE public.protocols ADD CONSTRAINT protocols_description_not_empty CHECK (length(trim(description)) > 0);
       END IF;
     END $$;
     ```
  3. `ALTER TABLE public.protocols ALTER COLUMN description DROP DEFAULT;`
- The idempotency guard ensures `supabase db reset` can re-apply without error
- Match the domain VO validation exactly: `trim(input).isEmpty` → `length(trim(description)) > 0`

## Key context

- Migration `20260221193000` added column: `description text NOT NULL DEFAULT ''`
- Migration `20260221200000` upserted all 57 protocols with real descriptions via ON CONFLICT
- `supabase/seed.sql` test data also provides descriptions for all 13 test protocols
- Domain VO at `protocol_description.dart:28-40` rejects empty strings and strings > 2000 chars (not 500 — the max-length is 2000 per `ProtocolDescription.maxLength` and `ProtocolFailures.descriptionTooLong`)
- Consider also adding `CHECK (length(trim(description)) <= 2000)` to match the VO max-length constraint — but only if explicitly required

## Acceptance
- [ ] New migration file exists with CHECK constraint `length(trim(description)) > 0`
- [ ] Constraint creation is idempotent (guarded with `IF NOT EXISTS` on `pg_constraint`)
- [ ] DEFAULT '' is dropped from `description` column
- [ ] Safety pre-check prevents migration from running if empty descriptions exist
- [ ] `supabase db reset` succeeds locally (if Supabase CLI available) — migration re-applies cleanly
- [ ] Spec file updated with rationale for the DEFAULT '' → CHECK transition
- [ ] No changes to Dart code (pure SQL migration)
