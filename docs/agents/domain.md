# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- **`docs/ubiquitous-language.md`** — the canonical glossary for this repo. Covers monetization terms (Free Tier, Premium Trial, Subscription Status, Protocol Limit), core domain terms (Protocol, Session, etc.), and other domain language. This file plays the role that `CONTEXT.md` plays in other repos — treat it as the authoritative source for terminology.
- **`docs/adr/`** — does not exist yet. When ADRs appear here in the future, read the ones that touch the area you're about to work in.

If `docs/adr/` does not exist, **proceed silently**. Don't flag its absence; don't suggest creating it upfront. The producer skill (`/grill-with-docs`) creates ADRs lazily when decisions actually get resolved.

## File structure

This is a **single-context** repo (one Flutter app, no monorepo split):

```
/
├── docs/
│   ├── ubiquitous-language.md   ← canonical glossary (acts as CONTEXT.md)
│   ├── adr/                     ← does not exist yet; will appear over time
│   └── specs/                   ← spec documents
├── lib/                         ← app code (feature-first)
└── test/
```

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in `docs/ubiquitous-language.md`. Don't drift to synonyms the glossary explicitly avoids.

If the concept you need isn't in the glossary yet, that's a signal — either you're inventing language the project doesn't use (reconsider) or there's a real gap (note it for `/grill-with-docs`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0007 — but worth reopening because…_
