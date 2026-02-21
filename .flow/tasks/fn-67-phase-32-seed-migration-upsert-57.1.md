# fn-67-phase-32-seed-migration-upsert-57.1 Create generate_seed_sql.dart script and seed migration SQL

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
Created tool/generate_seed_sql.dart Dart script and supabase/migrations/20260221200000_seed_protocols.sql migration that upserts all 57 protocols and 76 citations from protocols.json with case-insensitive ON CONFLICT, dollar-quoted SQL literals, SHA-256 audit checksum, and portable shasum/sha256sum fallback.
## Evidence
- Commits: 4a6c7d72a42f5e3bfee361cda22e5eb8c8c2cdd5, 8ef9ce0a90faa2ddaca7c14f0f2dbb2b6259a81e, c0972616854fc96e73e12a63b24821451cb5515c
- Tests: flutter analyze, flutter test
- PRs: