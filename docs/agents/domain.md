# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- **`GLOSSARY.md`** at the repo root — the canonical glossary for this repo. Covers monetization terms (Free Tier, Premium Trial, Subscription Status, Protocol Limit), core domain terms (Protocol, Session, etc.), and other domain language. Treat it as the authoritative source for terminology.
- **`docs/adr/`** — read ADRs that touch the area you're about to work in.

If any of these files don't exist, **proceed silently**. Don't flag their absence; don't suggest creating them upfront. The producer skill (`/grill-with-docs`) creates ADRs lazily when decisions actually get resolved.

## File structure

This is a **single-context** repo (one Flutter app, no monorepo split):

```
/
├── GLOSSARY.md                  ← canonical glossary
├── docs/
│   ├── adr/                     ← architecture decision records
│   └── specs/                   ← spec documents
├── lib/                         ← app code (feature-first)
└── test/
```

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in `GLOSSARY.md`. Don't drift to synonyms the glossary explicitly avoids.

If the concept you need isn't in the glossary yet, that's a signal — either you're inventing language the project doesn't use (reconsider) or there's a real gap (note it for `/grill-with-docs`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0007 — but worth reopening because…_
