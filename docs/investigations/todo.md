3. Verifier _knownPreExistingDuplicates hard-coded set

The spec asks for a literal-verbatim commit, but this hard-coded set will silently rot if a future epic dedupes the gratitude entry. A small-scope improvement: derive the allowed-duplicate set from git show
HEAD:protocols.json at runtime. Tradeoff: adds a Process.runSync to the dev-tool, breaks "no shell-out" simplicity, and the spec explicitly wants a static gate. Recommend leaving as-is; flagging for
visibility.

4. Verifier _expectedNewNames is task-specific

The script is now hard-coupled to fn-82's three names — once the next "add N protocols" epic ships, the tail-3 sanity assert fires false negatives. Long-term fix: parameterize via a --new-names=... CLI flag
or a .flow/-anchored fixture. Out of scope for fn-82 (spec says verbatim) but worth a follow-up ticket.

Key conclusion:

	•	Keep _knownPreExistingDuplicates static for fn-82.
	•	Do not derive allowed duplicates from git show HEAD:protocols.json in this verifier.
	•	The static set is explicitly required by the Flow task/spec and currently matches both working tree and HEAD.
	•	The real risk is stale exception hygiene after a future dedupe.
	•	Best follow-up: convert the static set to an expected-count map/self-check so stale allowlist entries fail loudly.

Source: @20260508120000_investigation_verifier_known_preexistingduplicates.md

5. Citation doi/url redundancy

Every new citation has doi and a url of https://doi.org/<doi> — pure derivation. The seed pipeline already mirrors this redundancy in the existing 57. Not a fn-82 problem; would be a cross-cutting          
normalization epic. 