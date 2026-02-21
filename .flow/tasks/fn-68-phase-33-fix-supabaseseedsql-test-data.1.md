# fn-68-phase-33-fix-supabaseseedsql-test-data.1 Fix supabase/seed.sql: remove explicit IDs, resolve FKs by name, add description, fix enums and JSONB keys

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
Updated supabase/seed.sql to be compatible with the new schema and seed migration: removed explicit protocol IDs and OVERRIDING SYSTEM VALUE, resolved citation FKs via case-insensitive name subqueries, added description column, fixed stale category/evidence enums to match Dart domain enums, fixed JSONB key to camelCase durationSeconds, and added ON CONFLICT DO NOTHING for collision safety.
## Evidence
- Commits: c13c7fdf68a1a1a5adcd2ab199b5a86200e99c60, 78c334c468276178682680c275056d7a6330e306
- Tests: flutter analyze, flutter test
- PRs: