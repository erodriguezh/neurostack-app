## Description
Extract the duplicated `_pascalCase` function from 4 test files into a shared helper. Update documentation to reflect the new `test/helpers/` directory and fix a known filename mismatch.

**Size:** M
**Files:**
- `test/helpers/string_helpers.dart` (NEW)
- `test/helpers/helpers.dart` (NEW — barrel)
- `test/features/protocol/data/dtos/frequency_dto_test.dart` (remove `_pascalCase` at L120-125)
- `test/features/protocol/data/dtos/research_citation_dto_test.dart` (remove `_pascalCase` at L159-164)
- `test/features/protocol/data/dtos/protocol_dto_test.dart` (remove `_pascalCase` at L186-191)
- `test/features/session/data/dtos/pending_session_dto_test.dart` (remove `_pascalCase` at L292-297)
- `AGENTS.md` line 9 (add `test/helpers/`)
- `docs/best_practices/test/domain/index.md` (add `helpers/` to file structure diagram + fix `result_matchers.dart` → `either_matchers.dart`)
- `docs/best_practices/test/data-layer/data-layer-supabase-testing.md` (add `helpers/` to structure block)

## Approach

- Follow `test/matchers/either_matchers.dart` as precedent for shared test utilities
- Rename from `_pascalCase` (private) to `pascalCase` (public) when extracting
- Barrel file re-exports all helpers: `export 'string_helpers.dart';`
- Each test file replaces the local function with an import of the barrel
- While editing `docs/best_practices/test/domain/index.md`, also fix the known mismatch: `result_matchers.dart` → `either_matchers.dart` (this is the actual filename in the repo)

## Key context

- The 4 test files have identical implementations — pure string transform, no dependencies
- `test/helpers/` does not exist yet; `test/matchers/` and `test/factories/` are the existing shared directories
- AGENTS.md line 9 currently reads: `helpers in test/factories/ + test/matchers/`
- `docs/best_practices/test/domain/index.md` currently references `matchers/result_matchers.dart` but the actual file is `matchers/either_matchers.dart`

## Acceptance
- [ ] `test/helpers/string_helpers.dart` exists with public `pascalCase()` function
- [ ] `test/helpers/helpers.dart` barrel exports `string_helpers.dart`
- [ ] No `_pascalCase` function in any test file (grep returns 0 hits)
- [ ] All 4 test files import from `helpers/helpers.dart`
- [ ] `flutter test` passes
- [ ] AGENTS.md lists `test/helpers/` alongside factories and matchers
- [ ] `docs/best_practices/test/domain/index.md` file structure includes `helpers/` and uses `either_matchers.dart` (not `result_matchers.dart`)
- [ ] `docs/best_practices/test/data-layer/data-layer-supabase-testing.md` project structure includes `helpers/`

## Done summary
Extracted duplicated `_pascalCase` function from 4 test files into a shared public `pascalCase()` helper in `test/helpers/string_helpers.dart` with a barrel export. Updated AGENTS.md and two best-practices docs to reflect the new `test/helpers/` directory and fixed the stale `result_matchers.dart` reference to `either_matchers.dart`.
## Evidence
- Commits: 7371a740c63d59d6efa8584a6ec33a5821bcca79
- Tests: flutter test, flutter analyze
- PRs: