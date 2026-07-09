---
status: accepted
date: 2026-06-21
---

# Passwordless email one-time code instead of magic link

## Context

Magic-link **Sign-In** never worked in production: every attempt failed with `otp_expired` and no **User** ever completed a Sign-In (`last_sign_in_at` null; two `flow_state` rows total). The investigation (`docs/investigations/20260621120000_investigation_magic_link_otp_expired.md`) traced this to the PKCE magic-link architecture — email security scanners / Gmail prefetch the one-time link and consume the token before the User clicks, and the PKCE code exchange requires the original device's `code_verifier`, which a prefetcher or cross-context click does not have.

## Decision

Sign-In uses a **passwordless email One-Time Code** that the User types into the app and the app verifies in-process. The clickable magic link is removed entirely — **not** kept as a fallback. Email confirmations are disabled, so one code email serves both first and returning Sign-In.

## Considered options

- **Fix the magic link** (token_hash template + a prefetch-defeating landing page + an in-app deep-link verify handler). Rejected: still fragile across in-app browsers, desktop clicks, and unverified app-links, and adds more moving parts (deployed template + native deep links + a hosted landing page) — each a failure point, for a flow with zero successful sign-ins to preserve.
- **Both** (code primary, link fallback). Rejected: doubles the surface to build, test, and deploy and re-introduces the fragile path.

## Consequences

- A typed code is marginally less slick than tapping a link, but the link flow demonstrably never worked.
- The native universal-link config (iOS entitlements, Android intent-filter) is deliberately **kept** — harmless and reusable for future deep-linking — even though Sign-In no longer needs it.
- A resend issues a new code and invalidates the previous one (single token slot); the UI must make "use the latest code" clear.
- Email still flows through Supabase's built-in (rate-limited, non-production) email service; moving to transactional SMTP is a separate future decision.
