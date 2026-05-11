---
satisfies: [R1, R2, R3, R4, R6, R7]
---

## Description

Append three new protocol entries to `protocols.json` (preserving the existing 57 content-identical, **append-only**), regenerate the **full-reseed** seed migration via `tool/generate_seed_sql.dart` (matching the established fn-67 convention — the new migration upserts all 60 protocols, not just the 3 new ones), commit a new manual dev-tool script `tool/verify_protocols_json.dart` that validates the catalog against domain VOs + uniqueness + shape parity + BMD scope lock, and verify prefix-identity (first 57 protocol upsert blocks in the new migration are content-identical to the prior canonical migration).

The three entries:
1. **Daily Sub-Maximal Calisthenics for Functional Preservation** — `category: exercise`, `evidence_level: expertConsensus` *(downgraded from `observational` per epic Decision context: Yang 2019 measures push-up capacity → CVD events, which is mechanism/marker context, not direct evidence on the protocol's claimed "functional preservation" outcome; per exact-outcome rule, all 3 citations are mechanism/context → step 6 → `expertConsensus`)*
2. **Delayed Morning Caffeine for Sustained Daytime Alertness** — `category: mind`, `evidence_level: expertConsensus`
3. **Vitamin D3 with K2 (MK-7) for Bone Density Maintenance** — `category: supplements`, `evidence_level: singleRct` *(citations: Knapen 2013 = K2 RCT BMD anchor; Bischoff-Ferrari 2012 NEJM = D3 pooled analysis on fracture prevention (supporting, related but not exact-outcome); Geleijnse 2004 = K2 cohort cardiovascular (off-scope, breadth context). Manson 2019 (VITAL) and Martineau 2017 BMJ are intentionally NOT cited.)*

See the parent epic spec for the canonical Evidence-level convention (Option B with exact-outcome precedence) and the Pre-existing duplicate acknowledgment.

**Size:** M
**Files:**
- `protocols.json` (modify — append 3 entries; **append-only**, single permissible touch is the trailing comma after the prior 57th entry's closing `}`)
- `supabase/migrations/<UTC-timestamp>_seed_protocols_add3.sql` (new file — full reseed, generated, do not hand-edit)
- `tool/verify_protocols_json.dart` (new file — **COMMITTED** as a manual dev-tool, no underscore prefix; runs ad-hoc via `dart run`, not part of `flutter test` or any CI test target)

## Approach

**Order of operations:**

0. **Bootstrap a clean working tree** before any of the steps below:
   ```bash
   flutter pub get   # required so the verification script's package: imports resolve
   ```
   Disable editor format-on-save / line-ending normalization for `protocols.json` before editing.

   **Baseline-duplicate snapshot** (before any edit, to lock the allowed pre-existing duplicates the script's `_knownPreExistingDuplicates` constant must match):
   ```bash
   python3 -c '
   import json
   from collections import Counter
   d = json.load(open("protocols.json"))
   c = Counter(p["name"].lower() for p in d)
   dups = sorted(n for n, k in c.items() if k > 1)
   print("BASELINE_DUPLICATES:", dups if dups else "(none)")
   ' | tee /tmp/fn-82-baseline-dups.txt
   ```
   Expected today: `BASELINE_DUPLICATES: ['structured gratitude journaling for well-being']`. If the actual baseline contains MORE collisions, **halt** and update the script's `_knownPreExistingDuplicates` constant accordingly (or escalate).

1. **Append-only edit of `protocols.json`.** Insert the 3 new objects immediately before the closing `]`.

   **Required fields** (consumed by `tool/generate_seed_sql.dart` and the static gates): `name`, `description`, `target.frequency.{min_per_week,max_per_week}`, `target.durationSeconds`, `target.intensity`, `category`, `evidence_level`, `research_citations[]` with `authors/year/title/journal/doi/url`.

   **Shape-parity fields** (NOT consumed by the generator but enforced by the verifier on the new entries for stylistic consistency): `research_citations[].verification_status` = `"verified"`, `research_citations[].verification_note` = non-empty string, top-level `source_models` = non-empty list of strings (e.g., `["protocols2.md community research"]`).

   The **only permissible touch to the existing 57th entry** is the trailing comma after its closing `}`.

   **Do not run any reformatter** — no `dart format`, no `jq`, no editor auto-format.

   **R1 deterministic gate (deep-equal prefix identity check, robust to whitespace drift):**
   ```bash
   [[ "$(tail -c 1 protocols.json | xxd -p)" == "0a" ]] || { echo "FAIL R1: protocols.json must end with newline (LF)"; exit 1; }

   # Deep-equal check: parse both versions of protocols.json, assert the first
   # 57 entries are content-identical (key/value-deep-equal). Whitespace,
   # key-ordering, etc. are normalized away by JSON parsing.
   python3 <<'PY'
   import json, sys, subprocess
   with open("protocols.json") as f:
     current = json.load(f)
   prior = json.loads(subprocess.check_output(["git", "show", "HEAD:protocols.json"]))
   if len(current) != len(prior) + 3:
     print(f"FAIL R1: expected {len(prior)+3} entries, got {len(current)}")
     sys.exit(1)
   for i, (a, b) in enumerate(zip(prior, current[:len(prior)])):
     if a != b:
       print(f"FAIL R1: entry [{i}] changed:")
       print(f"  prior:   {json.dumps(a)[:200]}")
       print(f"  current: {json.dumps(b)[:200]}")
       sys.exit(1)
   print(f"R1 deep-equal: OK ({len(prior)} prior entries content-identical; {len(current)-len(prior)} new entries appended)")
   PY
   ```
   This replaces the brittle hunk-counting heuristic with a deterministic JSON-content equality check.

2. **Defense-in-depth dollar-quote pre-flight** (the generator auto-handles collisions at `tool/generate_seed_sql.dart:228-236`):
   ```bash
   python3 -c '
   import re, json
   d = json.load(open("protocols.json"))
   bad = [p["name"] for p in d if any(re.search(r"\$\w+\$", str(v))
     for v in (p.get("name",""), p.get("description",""), (p.get("target") or {}).get("intensity","")))]
   print("\n".join(bad) if bad else "OK")
   '
   ```
   Output must be `OK`.

3. **Create and commit `tool/verify_protocols_json.dart`** (a manual dev-tool, NOT a test target — runs ad-hoc via `dart run`). Calls all five protocol VO constructors, performs uniqueness preflight, shape-parity checks, BMD scope-lock check, and DOI/URL gates. Type-guarded extraction (no unchecked `as` casts), accumulates errors per-entry. New-entry detection is by index (`i >= data.length - 3` per R1 append-only); tail-3 sanity asserts symmetric set equality (catches both unexpected and missing).

   Canonical implementation (commit verbatim):

   ```dart
   // ignore_for_file: avoid_print, avoid_dynamic_calls
   /// Manual dev-tool: validates protocols.json against domain VO invariants,
   /// uniqueness, shape parity, and (for the 3 fn-82 new entries) DOI/URL +
   /// BMD scope-lock for D3+K2.
   ///
   /// This is NOT a test target. It is a dev-tool invoked manually via:
   ///   dart run tool/verify_protocols_json.dart
   ///
   /// Exit 0 on green, non-zero with per-entry diagnostics on any failure.
   import 'dart:convert';
   import 'dart:io';
   import 'package:neurostack/features/protocol/domain/value_objects/protocol_name.dart';
   import 'package:neurostack/features/protocol/domain/value_objects/protocol_description.dart';
   import 'package:neurostack/features/protocol/domain/value_objects/frequency.dart';
   import 'package:neurostack/features/protocol/domain/value_objects/target.dart';
   import 'package:neurostack/features/protocol/domain/value_objects/research_citation.dart';
   import 'package:neurostack/features/protocol/domain/enums/category.dart';
   import 'package:neurostack/features/protocol/domain/enums/evidence_level.dart';

   /// Strict DOI+URL+shape-parity gate applies to the LAST 3 entries (per R1
   /// append-only contract). Hard-coded names are asserted as a sanity check.
   const _expectedNewNames = <String>{
     'Daily Sub-Maximal Calisthenics for Functional Preservation',
     'Delayed Morning Caffeine for Sustained Daytime Alertness',
     'Vitamin D3 with K2 (MK-7) for Bone Density Maintenance',
   };

   /// The D3+K2 protocol's name; its description must contain "BMD" or
   /// "bone mineral density" to lock the exact-outcome alignment with Knapen 2013.
   const _d3K2Name = 'Vitamin D3 with K2 (MK-7) for Bone Density Maintenance';

   /// Pre-existing duplicate that is INTENTIONALLY preserved (R1 append-only).
   /// Listed by lower(name); the script allows exactly one collision pair.
   const _knownPreExistingDuplicates = <String>{
     'structured gratitude journaling for well-being',
   };

   final _doiRe = RegExp(r'^10\.[0-9]{4,9}/.+');
   final _bmdRe = RegExp(r'\b(BMD|bone mineral density)\b', caseSensitive: false);

   bool _isAbsoluteHttpUrl(String? url) {
     if (url == null || url.trim().isEmpty) return false;
     final u = Uri.tryParse(url);
     if (u == null) return false;
     if (!u.hasScheme) return false;
     if (u.scheme != 'http' && u.scheme != 'https') return false;
     if (u.host.isEmpty) return false;
     return true;
   }

   void main() {
     // CWD guard: this dev-tool must run from the repo root (where pubspec.yaml lives)
     // so relative paths resolve. Friendlier than a raw FileSystemException.
     if (!File('pubspec.yaml').existsSync() || !File('protocols.json').existsSync()) {
       stderr.writeln(
         'FAIL: dev-tool must be run from repo root.\n'
         '  Expected pubspec.yaml + protocols.json in the current directory.\n'
         '  Try: cd <repo-root> && dart run tool/verify_protocols_json.dart',
       );
       exit(1);
     }
     final rawDecoded = jsonDecode(File('protocols.json').readAsStringSync());
     if (rawDecoded is! List<dynamic>) {
       stderr.writeln('FAIL: protocols.json root is not a JSON array');
       exit(1);
     }
     final List<dynamic> data = rawDecoded;
     var errors = 0;
     void err(String msg) {
       errors++;
       stderr.writeln('FAIL $msg');
     }

     // Uniqueness preflight (tolerates _knownPreExistingDuplicates only).
     final nameCounts = <String, int>{};
     for (final entry in data) {
       if (entry is Map && entry['name'] is String) {
         final lower = (entry['name'] as String).toLowerCase();
         nameCounts[lower] = (nameCounts[lower] ?? 0) + 1;
       }
     }
     for (final e in nameCounts.entries) {
       if (e.value > 1) {
         if (_knownPreExistingDuplicates.contains(e.key) && e.value == 2) {
           // Tolerated.
         } else {
           err('uniqueness: lower(name) "${e.key}" appears ${e.value} times '
               '(only known pre-existing duplicates allowed)');
         }
       }
     }

     // Tail-3 sanity (symmetric, verbose with indices on mismatch).
     if (data.length < 3) {
       err('expected ≥3 entries; got ${data.length}');
     } else {
       final tailEntries = <MapEntry<int, String>>[];
       for (var i = data.length - 3; i < data.length; i++) {
         final entry = data[i];
         final name = (entry is Map && entry['name'] is String)
             ? entry['name'] as String
             : '<entry $i: name missing>';
         tailEntries.add(MapEntry(i, name));
       }
       final tailNames = tailEntries.map((e) => e.value).toSet();
       if (tailNames.length != 3 || !tailNames.containsAll(_expectedNewNames)) {
         final unexpected = tailNames.difference(_expectedNewNames);
         final missing = _expectedNewNames.difference(tailNames);
         err('last-3 mismatch: tail entries=${tailEntries.map((e) => "[${e.key}]=${e.value}").join(", ")}; '
             'unexpected=$unexpected missing=$missing. '
             'Update _expectedNewNames if rename was intentional.');
       }
     }

     // Per-entry validation.
     for (var i = 0; i < data.length; i++) {
       final entry = data[i];
       if (entry is! Map) {
         err('entry[$i]: not a JSON object (got ${entry.runtimeType})');
         continue;
       }
       final name = (entry['name'] is String) ? entry['name'] as String : '<entry $i: name missing>';
       final isNew = i >= data.length - 3;

       if (entry['name'] is String) {
         ProtocolName.create(entry['name'] as String).fold(
           (failure) => err('ProtocolName ($name): ${failure.code} — ${failure.message}'),
           (_) {},
         );
       } else {
         err('ProtocolName ($name): missing or wrong type');
       }

       if (entry['description'] is String) {
         final desc = entry['description'] as String;
         ProtocolDescription.create(desc).fold(
           (failure) => err('ProtocolDescription ($name): ${failure.code} — ${failure.message}'),
           (_) {},
         );
         // BMD scope-lock check for the D3+K2 entry.
         if (name == _d3K2Name && !_bmdRe.hasMatch(desc)) {
           err('BMD scope-lock ($name): description must contain "BMD" or "bone mineral density" '
               'to keep exact-outcome aligned with Knapen 2013 RCT anchor.');
         }
       } else {
         err('ProtocolDescription ($name): missing or wrong type');
       }

       if (entry['category'] is String) {
         try {
           Category.values.byName(entry['category'] as String);
         } catch (_) {
           err('Category ($name): ${entry['category']}');
         }
       } else {
         err('Category ($name): missing or wrong type');
       }
       if (entry['evidence_level'] is String) {
         try {
           EvidenceLevel.values.byName(entry['evidence_level'] as String);
         } catch (_) {
           err('EvidenceLevel ($name): ${entry['evidence_level']}');
         }
       } else {
         err('EvidenceLevel ($name): missing or wrong type');
       }

       // Frequency + Target (VOs 3 + 4).
       final target = entry['target'];
       if (target is! Map) {
         err('target ($name): missing or wrong type');
       } else {
         final freqRaw = target['frequency'];
         Frequency? freqVo;
         if (freqRaw is! Map) {
           err('target.frequency ($name): missing or wrong type');
         } else {
           final minPerWeek = freqRaw['min_per_week'];
           final maxPerWeek = freqRaw['max_per_week'];
           if (minPerWeek is! int) {
             err('target.frequency.min_per_week ($name): $minPerWeek (must be int)');
           } else if (maxPerWeek is! int) {
             err('target.frequency.max_per_week ($name): $maxPerWeek (must be int)');
           } else {
             Frequency.create(minPerWeek: minPerWeek, maxPerWeek: maxPerWeek).fold(
               (failure) => err('Frequency.create ($name): ${failure.code} — ${failure.message}'),
               (vo) => freqVo = vo,
             );
           }
         }

         if (freqVo != null) {
           final durationSeconds = target['durationSeconds'];
           Duration? duration;
           if (durationSeconds is int) {
             if (durationSeconds < 0) {
               err('target.durationSeconds ($name): $durationSeconds (negative)');
             } else {
               duration = Duration(seconds: durationSeconds);
             }
           } else if (durationSeconds != null) {
             err('target.durationSeconds ($name): wrong type ($durationSeconds)');
           }

           final intensityRaw = target['intensity'];
           String? intensity;
           if (intensityRaw is String) {
             intensity = intensityRaw;
           } else if (intensityRaw != null) {
             err('target.intensity ($name): wrong type');
           }

           Target.create(frequency: freqVo!, duration: duration, intensity: intensity).fold(
             (failure) => err('Target.create ($name): ${failure.code} — ${failure.message}'),
             (_) {},
           );

           if (isNew) {
             if (durationSeconds is! int || durationSeconds < 1) {
               err('target.durationSeconds (new $name): $durationSeconds (require int ≥1)');
             }
             if (intensity == null || intensity.trim().isEmpty) {
               err('target.intensity (new $name): empty/missing (require non-empty string)');
             }
           }
         }
       }

       // ResearchCitation (VO 5) + INV-P1 + DOI/URL gates.
       final citationsRaw = entry['research_citations'];
       final citations = (citationsRaw is List) ? citationsRaw : const [];
       if (citationsRaw is! List) {
         err('research_citations ($name): missing or wrong type');
       }
       if (citations.isEmpty) {
         err('INV-P1 ($name): zero citations');
       }

       for (final c in citations) {
         if (c is! Map) {
           err('citation ($name): not a JSON object');
           continue;
         }
         final authors = (c['authors'] is String) ? c['authors'] as String : null;
         final year = (c['year'] is int) ? c['year'] as int : null;
         final title = (c['title'] is String) ? c['title'] as String : null;
         final journal = (c['journal'] is String) ? c['journal'] as String : null;
         final doi = (c['doi'] is String) ? c['doi'] as String : null;
         final url = (c['url'] is String) ? c['url'] as String : null;

         if (authors == null || year == null || title == null || journal == null) {
           err('citation field type ($name): authors=${c['authors']}, year=${c['year']}, '
               'title=${c['title']}, journal=${c['journal']}');
           continue;
         }

         ResearchCitation.create(
           authors: authors, year: year, title: title, journal: journal, doi: doi, url: url,
         ).fold(
           (failure) => err('ResearchCitation.create ($name): ${failure.code} — ${failure.message}'),
           (_) {},
         );

         if (isNew) {
           if (doi == null || !_doiRe.hasMatch(doi)) {
             err('R7-strict ($name): bad/missing DOI on new entry: $doi');
           }
           if (!_isAbsoluteHttpUrl(url)) {
             err('R2-url ($name): bad/missing URL on new entry: $url');
           }
           // Shape-parity for new entries: verification_status + verification_note.
           final vs = c['verification_status'];
           final vn = c['verification_note'];
           if (vs is! String || vs.trim().isEmpty) {
             err('shape-parity ($name): citation.verification_status missing/empty');
           }
           if (vn is! String || vn.trim().isEmpty) {
             err('shape-parity ($name): citation.verification_note missing/empty');
           }
         } else {
           if (doi != null && !_doiRe.hasMatch(doi)) {
             err('R7-format (legacy $name): malformed DOI: $doi');
           }
           if (url != null && url.trim().isNotEmpty && !_isAbsoluteHttpUrl(url)) {
             err('R2-url (legacy $name): malformed URL: $url');
           }
         }
       }

       // Shape-parity: source_models on new entries.
       if (isNew) {
         final sm = entry['source_models'];
         if (sm is! List || sm.isEmpty || sm.any((e) => e is! String || (e).trim().isEmpty)) {
           err('shape-parity ($name): source_models must be non-empty list of non-empty strings');
         }
       }
     }

     if (errors > 0) {
       stderr.writeln('$errors invariant violation(s)');
       exit(1);
     }
     print('OK ${data.length} entries valid');
   }
   ```

   Run: `dart run tool/verify_protocols_json.dart` — must exit 0 and print `OK 60 entries valid`. **The file IS committed** (no underscore prefix; this is a manual dev-tool, not a test target).

4. **Run the generator (full reseed):** `dart run tool/generate_seed_sql.dart > supabase/migrations/$(date -u +%Y%m%d%H%M%S)_seed_protocols_add3.sql`. The generator emits one upsert per array entry (so 60 protocol upserts in the new file, NOT just 3 — this is a full reseed per the established fn-67 convention).

5. **Static SQL gates** (env-independent, all required) — counts derived from `protocols.json`:
   ```bash
   MIG=$(ls -t supabase/migrations/*_seed_protocols_add3.sql | head -1)
   EXPECTED_PROTOCOLS=$(python3 -c 'import json; print(len(json.load(open("protocols.json"))))')
   EXPECTED_CITATIONS=$(python3 -c 'import json; print(sum(len(p.get("research_citations",[])) for p in json.load(open("protocols.json"))))')

   ACTUAL_PROTOCOLS=$(grep -c '^INSERT INTO public.protocols ' "$MIG")
   ACTUAL_DELETES=$(grep -c '^DELETE FROM public.research_citations' "$MIG")
   ACTUAL_CITATIONS=$(grep -c '^INSERT INTO public.research_citations ' "$MIG")

   [[ "$ACTUAL_PROTOCOLS" -eq "$EXPECTED_PROTOCOLS" ]] || { echo "FAIL: protocol count $ACTUAL_PROTOCOLS != $EXPECTED_PROTOCOLS"; exit 1; }
   [[ "$ACTUAL_DELETES" -eq "$EXPECTED_PROTOCOLS" ]] || { echo "FAIL: citation delete count $ACTUAL_DELETES != $EXPECTED_PROTOCOLS"; exit 1; }
   [[ "$ACTUAL_CITATIONS" -eq "$EXPECTED_CITATIONS" ]] || { echo "FAIL: citation insert count $ACTUAL_CITATIONS != $EXPECTED_CITATIONS"; exit 1; }
   grep -q 'CREATE UNIQUE INDEX IF NOT EXISTS protocols_name_unique' "$MIG" || { echo "FAIL: unique index"; exit 1; }

   # Cross-platform SHA-256 (matches generator's portability fallback)
   if command -v python3 >/dev/null 2>&1; then
     EXPECTED_SHA=$(python3 -c 'import hashlib; print(hashlib.sha256(open("protocols.json","rb").read()).hexdigest())')
   elif command -v shasum >/dev/null 2>&1; then
     EXPECTED_SHA=$(shasum -a 256 protocols.json | awk '{print $1}')
   elif command -v sha256sum >/dev/null 2>&1; then
     EXPECTED_SHA=$(sha256sum protocols.json | awk '{print $1}')
   else
     echo "FAIL: no SHA-256 tool available"; exit 1
   fi
   ACTUAL_SHA=$(grep -E '^-- SHA-256\(protocols.json\):' "$MIG" | awk '{print $3}')
   [[ "$EXPECTED_SHA" == "$ACTUAL_SHA" ]] || { echo "FAIL: SHA mismatch"; exit 1; }
   echo "Static SQL gates: OK ($EXPECTED_PROTOCOLS protocols / $EXPECTED_CITATIONS citations / SHA matches)"
   ```

   **Dollar-quote VALUES tripwire (best-effort grep + manual audit backstop):**
   ```bash
   # Best-effort regression tripwire — fails on any single-quoted string literal
   # inside a VALUES block. Manual audit is authoritative if grep is inconclusive.
   if awk '/INSERT INTO public\.(protocols|research_citations) /,/;[[:space:]]*$/' "$MIG" \
        | grep -vE '^[[:space:]]*--' \
        | grep -E "[[:space:]]'[^']*'" >/dev/null; then
     echo "TRIPWIRE: single-quoted string literal inside VALUES block — manually audit before continuing"
     exit 1
   fi
   ```

   **Manual audit (authoritative):** Open the migration and visually confirm the first new protocol's `INSERT INTO public.protocols ... VALUES (...)` block uses dollar-quoted tags throughout.

   **Prefix-identity check (R4.7 — catches generator regressions on existing rows; requires `python3` on PATH; if Python is unavailable in your environment, escalate or skip — the R1 deep-equal gate already covers most regression modes):**
   ```bash
   # Extract the per-protocol upsert blocks from both migrations; for the
   # first 57 protocols, both should produce content-identical SQL (modulo
   # header / SHA / timestamp comment lines, which we strip).
   PRIOR_MIG="supabase/migrations/20260221200000_seed_protocols.sql"
   python3 <<'PY'
   import re, sys

   def extract_protocol_blocks(path):
       """Yield (protocol_name, block_text) for each protocol upsert in the file."""
       blocks = []
       current = []
       in_block = False
       name = None
       name_re = re.compile(r"^\s*\$n\$([^$]+)\$n\$")
       with open(path) as f:
           for line in f:
               if line.startswith('INSERT INTO public.protocols '):
                   if in_block and name is not None:
                       blocks.append((name, ''.join(current)))
                   in_block = True
                   current = [line]
                   name = None
               elif in_block:
                   current.append(line)
                   if name is None:
                       m = name_re.match(line)
                       if m:
                           name = m.group(1)
                   if line.startswith('  evidence_level = EXCLUDED.evidence_level'):
                       blocks.append((name, ''.join(current)))
                       in_block = False
                       current = []
                       name = None
       if in_block and name is not None:
           blocks.append((name, ''.join(current)))
       return blocks

   prior = extract_protocol_blocks(sys.argv[1])
   new = extract_protocol_blocks(sys.argv[2])
   if len(new) < len(prior):
       print(f"FAIL: new migration has fewer protocol blocks ({len(new)}) than prior ({len(prior)})")
       sys.exit(1)
   for i, (a, b) in enumerate(zip(prior, new[:len(prior)])):
       if a != b:
           print(f"FAIL: prefix-identity mismatch at block [{i}] ({a[0]}):")
           print(f"  prior:   {a[1][:200]}")
           print(f"  new:     {b[1][:200]}")
           sys.exit(1)
   print(f"R4.7 prefix-identity: OK (first {len(prior)} protocol blocks content-identical to prior migration)")
   PY "$PRIOR_MIG" "$MIG"
   ```
   This catches: (a) generator emit-logic regressions (would cause first 57 blocks to differ), (b) accidental edits to existing entries in `protocols.json` that escaped the R1 deep-equal check.

6. **Optional dynamic check** (only if Supabase CLI + Docker available locally; CI not required). **Do NOT use total table counts** — `seed.sql` adds test protocols. Assert by name set:
   ```bash
   supabase db reset && supabase db push && supabase db push
   psql "$SUPABASE_DB_URL" <<'SQL'
   SELECT COUNT(*) AS new_protocols FROM public.protocols
     WHERE lower(name) IN (
       lower('Daily Sub-Maximal Calisthenics for Functional Preservation'),
       lower('Delayed Morning Caffeine for Sustained Daytime Alertness'),
       lower('Vitamin D3 with K2 (MK-7) for Bone Density Maintenance')
     );  -- expect 3
   SELECT COUNT(*) AS new_citations FROM public.research_citations c
     JOIN public.protocols p ON p.id = c.protocol_id
     WHERE lower(p.name) IN (
       lower('Daily Sub-Maximal Calisthenics for Functional Preservation'),
       lower('Delayed Morning Caffeine for Sustained Daytime Alertness'),
       lower('Vitamin D3 with K2 (MK-7) for Bone Density Maintenance')
     );  -- expect 9
   SQL
   ```

7. **Existing test suite + analyze:** `flutter test test/domain/protocol/ test/features/protocol/data/dtos/` and `flutter analyze` — both must pass unchanged. (Since the verifier script is committed under `tool/` and uses `// ignore_for_file: avoid_print`, `flutter analyze` should be clean; if any new analyzer warning appears on the script itself, fix it before commit.)

**Naming constraint (INV-P3):** the chosen names above are vetted against `lib/features/protocol/domain/value_objects/protocol_name.dart:31-67` regexes. Re-check if names are revised. The verification script catches any regression on this; rename also forces `_expectedNewNames` to be updated or the script fails loudly.

**Description shape:** mechanism + measurable expected outcomes, ≤2000 chars after trim. Match the prose style of existing entries. **Researcher-name discipline:** strip "Dr. <Name>" attributions from `protocols2.md` source draft.

**Causal-language discipline (per-protocol):**
- **Calisthenics (Yang 2019, Schoenfeld 2019/2016 — all mechanism/marker context, none on the exact "functional preservation" outcome):** Description MUST NOT make causal claims ("reduces cardiovascular risk", "prevents heart attacks"). Yang is associational on push-up capacity → CVD events. Frame the daily-practice rationale as expert/mechanistic extrapolation. Evidence_level is `expertConsensus` per the exact-outcome rule.
- **Caffeine delay (Lovallo / Urry — mechanism RCTs/reviews on cortisol+caffeine, no protocol-level RCT):** Description MUST NOT claim "RCT-proven to improve afternoon alertness". Frame as "mechanism-supported / expert-consensus protocol". **Citation year for Urry & Landolt:** use `2015` (print-year).
- **D3+K2 (scope = bone density only, anchored by Knapen 2013 BMD RCT):** Description MUST contain "bone mineral density" or "BMD" (verifier checks this) to lock the exact-outcome alignment with Knapen. Bischoff-Ferrari is supporting context (D3 + fracture pooled analysis) — clearly labeled as related-but-not-exact-endpoint. Geleijnse is breadth context (K2 + cardiovascular cohort, off-scope). MUST NOT claim cardiovascular benefit (VITAL was null and is not cited). MUST NOT claim ARI/immune benefit (Martineau is not cited). MUST NOT claim a combined-stack RCT exists.

**Citation year corrections (verified 2026-05-06 via DOI metadata):**
- Schoenfeld BJ et al. — DOI `10.1007/s40279-016-0543-8` is *Sports Medicine* Vol 46 Issue 11, **published 2016**. Use `year: 2016`.
- Urry E, Landolt HP — DOI `10.1007/7854_2014_274` is *Curr Top Behav Neurosci* book series volume, **print 2015**. Use `year: 2015`.

## Investigation targets

**Required** (read before coding):
- `protocols.json:1-100` — first 2 entries; mirror the exact shape (note: `target.frequency.{min_per_week,max_per_week}`, `target.durationSeconds`, `target.intensity`, citation `verification_status/verification_note`, top-level `source_models`)
- `tool/generate_seed_sql.dart:18-38,67-106,108-165,200-222,228-236` — generator + cross-platform sha + dollar-quote auto-fallback
- `supabase/migrations/20260221200000_seed_protocols.sql:9,15-27,819-832` — unique index, exemplar upsert, citation pattern (this is the reference for the prefix-identity check)
- `lib/features/protocol/domain/value_objects/{protocol_name,protocol_description,frequency,target,research_citation}.dart` — all return `Either<DomainFailure, T>`; verifier MUST `fold()` each
- `lib/core/failures/domain_failure.dart` — `DomainFailure.{code, message}`

**Optional**:
- `lib/features/protocol/domain/entities/protocol.dart:59-72` — INV-P1 (script does not call `Protocol.create`; INV-P1 is structural)
- `lib/features/protocol/data/dtos/target_dto.dart` — TargetDto JSON keys
- `test/factories/protocol_factory.dart` — pattern reference

## Key context

- **Dev-tool, not a test:** `tool/verify_protocols_json.dart` is committed and run manually via `dart run`. It is NOT registered as a test target, NOT invoked by `flutter test`, and NOT part of CI. The boundary "no committed regression test" referred to test-suite targets; a manual `tool/` script is consistent with that boundary and matches the precedent of `tool/generate_seed_sql.dart`.
- **Full reseed migration:** the new migration is a full reseed (60 INSERT-upserts), not a delta. This matches fn-67's established convention. Idempotency is guaranteed by `ON CONFLICT (lower(name)) DO UPDATE`. Prefix-identity check (R4.7) catches any generator regression on the first 57 blocks.
- **All 9 citation DOIs** are pre-verified to format and resolve. CI gate is offline regex; live curl is best-effort.
- **`durationSeconds`** for new entries: 600 / 5400 / 60 (calisthenics 10 min / caffeine delay 90 min / supplements 60s — matching existing supplement convention; 30s would render as "0 min").
- **Either/fpdart pattern:** All five VO `create()` return `Either<DomainFailure, T>`. Script MUST `fold(left, right)`; logging uses `failure.code` + `failure.message`.
- **Pre-existing duplicate** "structured gratitude journaling for well-being" remains; preserved per R1; verifier tolerates exactly this collision pair.

## Acceptance

- [ ] `flutter pub get` was run before the verifier script and the generator
- [ ] Baseline-duplicate snapshot (Step 0) shows exactly `['structured gratitude journaling for well-being']`; if more, task halted and `_knownPreExistingDuplicates` updated to match before proceeding
- [ ] `protocols.json` contains exactly 60 array entries (was 57)
- [ ] `protocols.json` ends with a newline (`tail -c 1` is `0a`)
- [ ] **R1 deep-equal gate**: Python check confirms the first 57 entries (parsed JSON) are content-identical to `HEAD:protocols.json`; new entries appended at end; whitespace differences ignored by JSON parsing
- [ ] Each new entry has all **required** fields: `name`, `description`, `target.frequency.{min_per_week,max_per_week}`, `target.durationSeconds`, `target.intensity`, `category`, `evidence_level`, `research_citations[]`
- [ ] Each new entry has all **shape-parity** fields: `source_models` (non-empty list of non-empty strings), `research_citations[].verification_status` (non-empty string, `"verified"`), `research_citations[].verification_note` (non-empty string)
- [ ] Each new entry's `name` is ≤100 chars, no INV-P3 researcher-name patterns
- [ ] Each new entry's `description` is non-empty after trim, ≤2000 chars, follows causal-language discipline
- [ ] **D3+K2 entry's description contains "bone mineral density" or "BMD"** (verifier checks this for the BMD scope-lock)
- [ ] Each new entry's `target.frequency.{min,max}_per_week` are ints with `min≥1` and `max≥min`; `target.durationSeconds` is int ≥1; `target.intensity` is non-empty string
- [ ] `category` and `evidence_level` are valid enum identifiers — calisthenics=`exercise`/`expertConsensus`, caffeine=`mind`/`expertConsensus`, D3+K2=`supplements`/`singleRct`
- [ ] **Caffeine entry has `category: mind`** (deliberate per Catalog grouping rule; do NOT change to `sleep` during implementation — see done-summary FYI)
- [ ] **Uniqueness preflight**: only the known pre-existing collision pair is tolerated; no new collisions
- [ ] Every citation on the 3 new entries: non-null `doi` matching `^10\.[0-9]{4,9}/.+`, non-null `url` satisfying `_isAbsoluteHttpUrl`, non-empty `verification_status` and `verification_note`
- [ ] Every citation universally: non-empty `authors`, `title`, `journal`, int `year` ∈ `[1900, currentYear+1]` (enforced by `ResearchCitation.create`)
- [ ] Defense-in-depth dollar-quote pre-flight (scanning `name`, `description`, `target.intensity`) returns `OK`
- [ ] **Verification dev-tool** (`tool/verify_protocols_json.dart`) exits 0 with `OK 60 entries valid`; calls all five VO constructors with `fold()` + `failure.{code,message}`; uses type-guarded extraction; detects new entries by index; symmetric tail-3 sanity assertion; uniqueness preflight; shape-parity (source_models + verification_*) gate; BMD scope-lock check
- [ ] **Verification dev-tool IS committed** at `tool/verify_protocols_json.dart` (no underscore prefix; `git ls-files` confirms it is tracked)
- [ ] `dart run tool/generate_seed_sql.dart` produces `supabase/migrations/<UTC-timestamp>_seed_protocols_add3.sql` (full reseed, 60 upserts)
- [ ] Static SQL gates pass: protocol-INSERT count == `EXPECTED_PROTOCOLS` (derived from JSON), citation-DELETE count == `EXPECTED_PROTOCOLS`, citation-INSERT count == `EXPECTED_CITATIONS` (derived from JSON), unique-index DDL present, **SHA-256 audit comment matches** (cross-platform fallback). Expected today: 60 / 60 / 85 / hash.
- [ ] Dollar-quote VALUES tripwire passes (best-effort grep) + manual audit of first new protocol's INSERT block confirms dollar-quoting throughout
- [ ] **R4.7 prefix-identity gate**: first 57 protocol upsert blocks in the new migration are content-identical to the corresponding blocks in `supabase/migrations/20260221200000_seed_protocols.sql` (catches generator regressions and any stealth edit to existing entries)
- [ ] (Optional, env-permitting) After `supabase db reset && supabase db push && supabase db push`: name-set query returns 3 new protocol rows and 9 new citation rows
- [ ] `flutter test test/domain/protocol/ test/features/protocol/data/dtos/` passes unchanged
- [ ] `flutter analyze` is clean (no new warnings — including on the committed `tool/verify_protocols_json.dart`)

## Done summary
# fn-82.1 — Append 3 protocols + regenerate seed migration

## Result

Catalog expanded from 57 → 60 protocols. Implementation is a pure data delta plus tooling — no domain/DTO/schema changes.

## What shipped

- `protocols.json` — appended 3 entries (Daily Sub-Maximal Calisthenics for Functional Preservation; Delayed Morning Caffeine for Sustained Daytime Alertness; Vitamin D3 with K2 (MK-7) for Bone Density Maintenance). The prior 57 entries are content-identical to HEAD via JSON deep-equal (R1 deterministic gate).
- `tool/verify_protocols_json.dart` — new committed manual dev-tool (NOT a test target; runs ad-hoc via `dart run`). Validates all 60 entries via the five domain VO `fold()` calls + enum lookups + uniqueness preflight + tail-3 sanity + DOI/URL gates on the new 3 + BMD scope-lock for D3+K2.
- `supabase/migrations/20260508124758_seed_protocols_add3.sql` — new full-reseed migration (matches fn-67 convention), 60 protocol upserts + 85 citation inserts. Prefix-identity verified: first 57 protocol-upsert blocks content-identical to `20260221200000_seed_protocols.sql`.
- `notes_citation_url_normalization.md` — loose follow-up note (root) flagging the cross-cutting DOI/URL redundancy and the pre-existing duplicate as a future epic. No implementation in fn-82.

## FYIs (required per spec)

- **Caffeine delay appears under the Mind category (🧘 icon) by design** — see epic Decision context for rationale (alertness/arousal regulation extension of the `mind` bucket per the canonical Catalog grouping rule). Icon mismatch is an accepted product taxonomy trade-off, not a bug. Reviewers should not "fix" the category.
- **The pre-existing duplicate "Structured Gratitude Journaling for Well-Being" remains in `protocols.json`** — preserved per R1 append-only; deferred to a follow-up dedupe epic. The DB has 59 distinct protocols after upsert, not 60.
- **`tool/verify_protocols_json.dart` is committed as a manual dev-tool, not a test target.** It is NOT invoked by `flutter test` or any CI test job; run it manually via `dart run` when auditing the catalog.
- **The new migration is a full reseed (60 upserts), not a delta migration.** Matches fn-67 convention. Prefix-identity check (R4.7) confirms the first 57 blocks are content-identical to the prior canonical migration.

## User-driven refactors during implementation

- Replaced en-/em-dashes with regular hyphens throughout the 3 new entries (descriptions, intensities, verification_notes) per user direction.
- Tightened the D3+K2 description (dropped "around 5,000 IU" hedging, simplified prose).
- Added `notes_citation_url_normalization.md` as a follow-up plan for a separate epic (DOI/URL redundancy + gratitude duplicate dedupe).

## Quality gates

- `flutter analyze` — clean, no warnings (including on the new dev-tool after adding `library;` directive to suppress dangling-doc-comment).
- `flutter test test/domain/protocol/ test/features/protocol/data/dtos/` — 105 tests pass.
- `dart run tool/verify_protocols_json.dart` — `OK 60 entries valid`.
- R1 deep-equal: 57 prior entries content-identical; 3 appended.
- Static SQL gates: 60 protocol INSERTs / 60 citation DELETEs / 85 citation INSERTs / SHA-256 audit-line matches.
- Dollar-quote VALUES tripwire: passes.
- Manual audit of first new protocol's INSERT block: dollar-quoting throughout, no single-quoted SQL literals.
- R4.7 prefix-identity: first 57 protocol-upsert blocks content-identical.
- RepoPrompt impl-review: `<verdict>SHIP</verdict>` (no introduced findings; all R-IDs met or deferred to .2).

## Out-of-scope (deferred to fn-82.2 or follow-up epic)

- R5 (doc count references update) — assigned to fn-82.2.
- Optional dynamic Supabase apply check — env not available locally; static gates cover the regression surface.
- Citation URL/DOI normalization + gratitude duplicate dedupe — see `notes_citation_url_normalization.md`.
## Evidence
- Commits:
- Tests:
- PRs: