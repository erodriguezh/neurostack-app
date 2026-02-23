## Description
Two small fixes in the seed/generator area:

**A) Fix misleading comment** in `tool/generate_seed_sql.dart` at L84-85. The comment says "use only the keys the DTO expects" but the code is a passthrough from `protocols.json` — it does not reference the DTO at all. Correct the comment to describe the actual behavior.

**B) Convert citation inserts** in `supabase/seed.sql` from scalar subquery pattern to `INSERT...SELECT...WHERE` pattern. Currently 22 citations use `(SELECT id FROM protocols WHERE ...)` inside `VALUES`, which returns NULL if the protocol is missing (causing FK violation). The `INSERT...SELECT...WHERE` pattern silently inserts zero rows instead.

**Scope note:** Only `supabase/seed.sql` is being changed. The generated migration (`20260221200000_seed_protocols.sql`) still uses scalar subqueries and is explicitly out of scope — the generator always runs citations after protocols exist.

**Size:** M
**Files:**
- `tool/generate_seed_sql.dart` (L84-85 comment fix only)
- `supabase/seed.sql` (L97-240 — restructure citation inserts)

## Approach

- **Comment fix**: Change L84-85 from "use only the keys the DTO expects" to something like "passthrough from protocols.json — expected shape: { frequency: { min_per_week, max_per_week }, durationSeconds?, intensity? }"
- **seed.sql**: Convert each citation INSERT from scalar subquery in VALUES to `INSERT INTO ... SELECT ... FROM protocols WHERE ...` pattern
- This is a **different failure mode**: silent skip (zero rows) vs. FK violation. Acceptable for test seed data.

## Key context

- `supabase/seed.sql` currently has a single multi-row INSERT block for citations (L97-240). The restructure requires splitting into individual INSERT...SELECT statements (one per citation).
- fn-68 already fixed seed.sql with `ON CONFLICT DO NOTHING` for protocols; this task extends resilience to citations.
- The `ON CONFLICT DO NOTHING` on citations (if present) should be preserved.

## Acceptance
- [ ] Comment at `tool/generate_seed_sql.dart:84-85` accurately describes passthrough from protocols.json
- [ ] No `(SELECT id FROM public.protocols WHERE` inside `VALUES(` in `supabase/seed.sql` (grep returns 0 hits)
- [ ] All citation inserts in `supabase/seed.sql` use `INSERT INTO ... SELECT ... FROM protocols WHERE ...` pattern
- [ ] Citation count unchanged (same 22 citations inserted when all protocols exist)
- [ ] Generated migration (`20260221200000_seed_protocols.sql`) is NOT modified (out of scope)
- [ ] `supabase db reset` succeeds locally (if Supabase CLI available)
- [ ] `flutter analyze` clean
