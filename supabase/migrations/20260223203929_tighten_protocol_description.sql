-- ============================================================================
-- Tighten description constraint: CHECK non-empty + drop DEFAULT ''
-- ============================================================================
-- The migration at 20260221193000 added `description text NOT NULL DEFAULT ''`
-- for backward compatibility with existing rows. The seed migration at
-- 20260221200000 populated all 57 protocols with real descriptions.
--
-- Problem: `DEFAULT ''` contradicts the domain invariant —
-- `ProtocolDescription.create('')` rejects empty strings. Without a CHECK
-- constraint, a raw INSERT could bypass the domain layer and store an empty
-- description.
--
-- This migration:
-- 1. Safety pre-check: aborts if any row has an empty/NULL description
-- 2. Adds CHECK constraint matching the domain VO: length(trim(description)) > 0
-- 3. Drops DEFAULT '' so all INSERT paths must provide an explicit description
--
-- Task: fn-72-refactor-protocol-description-seed.5
-- ============================================================================

-- 1. Safety pre-check: abort if empty descriptions exist
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.protocols
    WHERE trim(description) = '' OR description IS NULL
  ) THEN
    RAISE EXCEPTION 'Cannot add CHECK constraint: rows with empty or NULL description exist in public.protocols';
  END IF;
END $$;

-- 2. Add CHECK constraint (idempotent — guarded because Postgres has no
--    ADD CONSTRAINT IF NOT EXISTS)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'protocols_description_not_empty'
  ) THEN
    ALTER TABLE public.protocols
      ADD CONSTRAINT protocols_description_not_empty
      CHECK (length(trim(description)) > 0);
  END IF;
END $$;

-- 3. Drop the DEFAULT '' — forces explicit description on every INSERT
ALTER TABLE public.protocols ALTER COLUMN description DROP DEFAULT;
