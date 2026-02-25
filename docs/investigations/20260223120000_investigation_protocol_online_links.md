# Investigation: Protocol Online Link Pointers

## Summary
Documentation that explicitly points to protocol sources online is sparse in `app/docs`. The clearest “where can I find the protocols?” links live in the root research memo, while app-facing docs mostly point to `protocols.json` and seed SQL where the citation URLs are stored.

## Symptoms
- User needs pointers in documentation to find protocol sources online.
- App docs reference protocol seed data but do not list external URLs directly.

## Investigation Log

### 2026-02-23 - Root research memo (explicit external links)
**Hypothesis:** A documentation file explicitly links to online protocol sources.
**Findings:** The root research memo includes explicit external URLs (Reddit “Where can I find the protocols?” thread, Huberman PDF, HubermanLab site, newsletter).
**Evidence:** `docs/Claude-BDNF cognitive enhancement iOS app opportunities.md` lines 540–590 show explicit URLs including `https://www.reddit.com/r/HubermanLab/comments/pb89dp/where_can_i_find_the_protocols/` and the HubermanLab PDF link; lines 590–620 include the HubermanLab site and newsletter URLs.
**Conclusion:** Confirmed — the only clear “find protocols online” pointers are in this root research memo.

### 2026-02-23 - Protocol citation URL source in seed data
**Hypothesis:** The canonical protocol source file (`protocols.json`) stores external URLs.
**Findings:** `protocols.json` includes `research_citations[].url` fields with DOI links and other external URLs.
**Evidence:** `app/protocols.json` lines 18–33 show `url` fields such as `https://doi.org/10.1007/s004210050065` and `https://doi.org/10.1080/00365510701516350`.
**Conclusion:** Confirmed — external URLs are embedded in the seed data.

### 2026-02-23 - App spec points to where URLs live (but no direct URLs)
**Hypothesis:** App documentation directly links to online protocols.
**Findings:** The protocol seed spec describes `protocols.json` and includes `doi`/`url` fields, but does not link to external sites itself.
**Evidence:** `app/docs/specs/20260220120000_spec_protocol_description_and_seed.md` lines 26–40 list citation fields including `doi` and `url`.
**Conclusion:** Partially confirmed — docs point to where URLs live, not the URLs themselves.

### 2026-02-23 - Seed migration materializes URLs into DB
**Hypothesis:** Seed SQL contains the external URLs for protocols.
**Findings:** The generated migration inserts citation URLs (mostly DOI links).
**Evidence:** `app/supabase/migrations/20260221200000_seed_protocols.sql` lines 820–845 show DOI URLs inserted into `research_citations`.
**Conclusion:** Confirmed — URLs are persisted via migration, but this is not user-facing documentation.

### 2026-02-23 - Legacy seed.sql contains direct journal URLs
**Hypothesis:** Existing seed.sql has explicit external links.
**Findings:** `seed.sql` includes journal URLs (JAMA, Hindawi) in research citations.
**Evidence:** `app/supabase/seed.sql` lines 98–110 show URLs like `https://jamanetwork.com/...` and `https://www.hindawi.com/...`.
**Conclusion:** Confirmed — URLs present, but again in seed data rather than docs.

### 2026-02-23 - Docs index & glossary indicate where to look (no URLs)
**Hypothesis:** App docs index provides protocol source links.
**Findings:** `app/docs/README.md` links to the protocol seed spec and plan but no external URLs. Glossary defines research citations as DOI/Link backed but no URLs.
**Evidence:** `app/docs/README.md` lines 58–70 (spec link); `app/docs/ubiquitous-language.md` lines 70–90 (Research Citation definition).
**Conclusion:** Eliminated for explicit URLs; confirmed only for internal pointers.

### 2026-02-23 - Git history
**Hypothesis:** Recent commits reference protocol source links.
**Findings:** Git log could not be retrieved (tool reported no VCS repository in loaded roots).
**Evidence:** `mcp__RepoPrompt__git` log failed with “No VCS repository found in loaded roots.”
**Conclusion:** Needs manual git verification outside this environment if required.

## Root Cause
App documentation does not maintain a single, explicit “protocol sources online” page. External URLs live primarily in data artifacts (`protocols.json`, seed SQL), while the only explicit online protocol discovery links are in a root research memo outside the app docs index.

## Recommendations
1. Add a short, maintained doc (e.g., `app/docs/protocol_sources.md`) that explicitly states where online sources live (`protocols.json` → citations URL/DOI) and link to it from `app/docs/README.md`.
2. Decide whether the Huberman-oriented external links in the root research memo are canonical; if yes, curate them into the new doc with clear intent and disclaimers.

## Preventive Measures
- Require new protocol sources to include `url` fields in `protocols.json` and update the “Protocol Sources” doc alongside any seed updates.
