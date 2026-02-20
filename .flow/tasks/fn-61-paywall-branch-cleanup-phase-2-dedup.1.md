# fn-61-paywall-branch-cleanup-phase-2-dedup.1 Mechanical cleanup: dead code, dependency fix, doc deprecation

## Description
Mechanical cleanup pass: remove dead code, fix a dependency placement error, update stale doc comments, and deprecate obsolete specification documents.

**Size:** M
**Files:**
- `lib/paywall/data/revenuecat_service.dart` (remove commented-out code block)
- `lib/features/user/domain/enums/subscription_status.dart` (fix INV-U3 doc comment)
- `pubspec.yaml` (move mocktail to dev_dependencies)
- `docs/specs/20260122150000_spec_trial_expiration_cronjob.md` (add DEPRECATED header)
- `docs/investigations/20260122180000_investigation_trial_expiration_race_condition.md` (add DEPRECATED header)
- `docs/best_practices/design/screen-functional-specifications.md` (fix INV-U3 references)

## Approach

1. **Remove commented-out platform key code** at `lib/paywall/data/revenuecat_service.dart:138-152`. Replace the 12-line commented-out block with a single-line comment: `// When per-platform keys are needed, update env.json with REVENUECAT_IOS_KEY / REVENUECAT_ANDROID_KEY / REVENUECAT_MACOS_KEY and add Platform checks here.`

2. **Fix ALL stale INV-U3 references repo-wide.** Run `rg INV-U3 lib/ docs/` and, for every match:
   - Either annotate it with `(DEPRECATED)` if it refers to the old concept, or
   - Remove/update it if it's no longer relevant, or
   - Leave it only if it is in `docs/ubiquitous-language.md` where it is already marked as deprecated by design.

   At minimum, this includes:
   - `lib/features/user/domain/enums/subscription_status.dart:5`
   - `docs/best_practices/design/screen-functional-specifications.md` (lines ~162, 169)

3. **Move mocktail to dev_dependencies** in `pubspec.yaml`. Currently at line ~63 in `dependencies`. Verify with `rg "import.*mocktail" lib/` that zero production files use it before moving. Run `flutter pub get` after the move.

4. **Add DEPRECATED headers** to:
   - `docs/specs/20260122150000_spec_trial_expiration_cronjob.md` — replaced by RevenueCat webhook (Phase 9); pg_cron removed (Phase 11.1)
   - `docs/investigations/20260122180000_investigation_trial_expiration_race_condition.md` — resolved by RevenueCat event-driven architecture + client-side transition detection

5. **Run `dart fix --apply --code=unused_import`** to clean any stale imports. **Note:** This is a repo-wide operation. If Tasks 2 and 3 are running in parallel on separate branches, defer this step until after those tasks have merged to minimize conflicts.

6. **Verify no orphaned generated files.** Run `dart run build_runner clean && dart run build_runner build --delete-conflicting-outputs`. **Note:** Like step 5, this is a repo-wide operation — defer if parallel tasks are in flight. Then explicitly check for orphans:
   ```bash
   # Find any .freezed.dart or .g.dart without a matching source .dart
   for f in $(find lib test -name '*.freezed.dart' -o -name '*.g.dart'); do
     base="${f%.freezed.dart}"
     base="${base%.g.dart}"
     [[ -f "${base}.dart" ]] || echo "ORPHAN: $f"
   done
   ```
   Delete any orphaned files found.

7. **Run `flutter analyze` + `flutter test`** as validation gate.

## Key context

- Do NOT touch `lib/paywall/data/revenuecat_client_factory.dart` or the conditional import chain
- The one remaining TODO at `subscription_status_resolver.dart:189` is intentional forward-looking guidance — do NOT remove it
- Steps 5 and 6 (`dart fix` + `build_runner`) are repo-wide and should ideally run after Tasks 2 and 3 have merged to avoid merge conflicts

## Acceptance
- [ ] Commented-out platform key block removed from `revenuecat_service.dart` (replaced with 1-line comment)
- [ ] `rg INV-U3 lib/ docs/` — every match either has `(DEPRECATED)` annotation or is in `ubiquitous-language.md` where it is already marked
- [ ] `mocktail` moved from `dependencies` to `dev_dependencies` in `pubspec.yaml`
- [ ] `dart fix --apply --code=unused_import` run (no remaining unused imports)
- [ ] Orphan check script run — no `.freezed.dart` / `.g.dart` files without matching source `.dart`
- [ ] DEPRECATED header added to `docs/specs/20260122150000_spec_trial_expiration_cronjob.md`
- [ ] DEPRECATED header added to `docs/investigations/20260122180000_investigation_trial_expiration_race_condition.md`
- [ ] `flutter analyze` reports 0 issues
- [ ] `flutter test` all pass
## Done summary
Mechanical cleanup: removed 12-line commented-out platform key block from revenuecat_service.dart (replaced with 1-line comment), moved mocktail from dependencies to dev_dependencies, annotated all stale INV-U3 references with DEPRECATED across lib/ and docs/, and added DEPRECATED headers to obsolete trial expiration cronjob spec and race condition investigation docs.
## Evidence
- Commits: d5167e54915ffab3f18b79b445f483a7560237d8
- Tests: flutter analyze, flutter test, dart fix --apply --code=unused_import, orphan check (find lib test -name *.freezed.dart / *.g.dart)
- PRs: