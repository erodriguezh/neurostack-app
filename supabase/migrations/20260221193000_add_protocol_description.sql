-- ============================================================================
-- Add description column to protocols + fix stale column comments
-- ============================================================================
-- This migration:
-- 1. Adds a `description` text column to public.protocols
-- 2. Fixes stale COMMENT ON COLUMN for category, evidence_level, and target
-- 3. Adds a COMMENT ON COLUMN for the new description column
--
-- Task: fn-66-phase-31-schema-migration-add.1
-- ============================================================================

-- Add description column (idempotent)
ALTER TABLE public.protocols
  ADD COLUMN IF NOT EXISTS description text NOT NULL DEFAULT '';

-- Fix stale category comment: was "exercise, heatTherapy, coldTherapy, supplementation, etc."
-- Actual Dart enum values: exercise, heatTherapy, coldExposure, nutrition, supplements, mind, sleep
COMMENT ON COLUMN public.protocols.category IS
  'Enum stored as text: exercise, heatTherapy, coldExposure, nutrition, supplements, mind, sleep';

-- Fix stale evidence_level comment: was "preliminary, moderate, strong, proven"
-- Actual Dart enum values: multipleRcts, singleRct, observational, expertConsensus
COMMENT ON COLUMN public.protocols.evidence_level IS
  'Enum stored as text: multipleRcts, singleRct, observational, expertConsensus';

-- Fix stale target comment: top-level keys use camelCase (durationSeconds),
-- but nested frequency keys use snake_case (min_per_week, max_per_week) per @JsonKey.
-- Actual TargetDto fields: frequency (object), durationSeconds (int?), intensity (String?)
COMMENT ON COLUMN public.protocols.target IS
  'JSONB structure: { "frequency": { "min_per_week": int, "max_per_week": int }, '
  '"durationSeconds": int | null, "intensity": "string" | null }. '
  'Top-level keys use camelCase; nested frequency keys use snake_case per @JsonKey overrides.';

-- Add comment for new description column
COMMENT ON COLUMN public.protocols.description IS
  'Free-text protocol description. Max 2000 chars enforced at domain level. '
  'Defaults to empty string for backward compatibility with existing rows.';
