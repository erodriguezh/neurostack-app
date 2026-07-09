# Investigation: Magic link fails immediately with `otp_expired`

## Summary
User signed in with email `taishogun@gmail.com`, received the magic-link email, and on
clicking the link sees a raw Supabase JSON error:
`{"code":403,"error_code":"otp_expired","msg":"Email link is invalid or has expired"}`.
No errors appear in the app logs. The error is produced **server-side by Supabase's
`/auth/v1/verify` endpoint, before any redirect back to the app** — which is exactly why
the Flutter app logs nothing. Root cause is in Supabase auth (deployed template / token
lifecycle / redirect allow-list), not in app Dart code.

## Symptoms
- Click magic link → browser shows raw JSON `403 otp_expired` (not the app, not the website).
- "Email link is invalid or has expired".
- No app-side errors logged.
- Account email: `taishogun@gmail.com` (Gmail — relevant to link prefetch).

## Background / Prior Research
External facts gathered via web/source research (GoTrue source + Supabase docs/issues):

1. **A new magic-link request invalidates the previous link (single token slot).** GoTrue stores
   the active magic-link token in the user's `recovery_token`/`recovery_sent_at` (existing confirmed
   users) or `confirmation_token` (unconfirmed). Verifying `type=email`/`magiclink` looks the token
   up by that slot, so a *resend* overwrites the slot and the **earlier emailed link then fails with
   `otp_expired`**. Magic links are one-time use, default 1h expiry, throttle ~60s.
   Sources: GoTrue `internal/api/verify.go`, `internal/models/user.go`;
   https://supabase.com/docs/guides/auth/auth-email-passwordless

2. **Email security scanners prefetch links and consume the one-time token.** Supabase explicitly
   documents that mail clients/security tools auto-open URLs; with a consuming `{{ .ConfirmationURL }}`
   link this burns the OTP before the user clicks → `403` / `otp_expired`. `taishogun@gmail.com` is
   Gmail. Sources: https://supabase.com/docs/guides/troubleshooting/otp-verification-failures-token-has-expired-or-otp_expired-errors-5ee4d0 ;
   https://github.com/supabase/auth/issues/713

3. **Raw JSON vs redirect — important discriminator.** A plain `{{ .ConfirmationURL }}` **GET**
   link-click that fails does NOT show raw JSON: `verifyGet` catches the error and issues a `303`
   redirect to the allowed `redirect_to` (or falls back to Site URL) with `error`/`error_code`/
   `error_description` params. Raw JSON `{"code":403,"error_code":"otp_expired",...}` is the
   **`POST /auth/v1/verify` (`verifyOtp`) response shape** — i.e. it surfaces when a page/app calls
   `verifyOtp({token_hash, type})` and dumps the error, OR the user lands directly on an API verify
   call. A disallowed `redirect_to` alone does NOT cause raw JSON (it falls back to Site URL).
   Sources: GoTrue `internal/api/verify.go` (`verifyGet`/`verifyPost`, `GetReferrer`);
   https://supabase.com/docs/guides/auth/redirect-urls

**Implication:** Because the user saw **raw JSON**, the failing step is a `verifyOtp`/POST-style
verification (a token_hash confirm page or client-side verify), not a bare `{{ .ConfirmationURL }}`
GET redirect. This is consistent with the repo's token_hash template *intent* — but the token was
already expired/consumed/superseded by the time verify ran.

## Investigator Findings

**DB evidence gathered 2026-06-21 via Supabase MCP.** Linked project confirmed
`etzzkjskpdpltmuioakg` ("neurostack"), GoTrue `v2.184.0` (`supabase/.temp/linked-project.json`,
`.temp/gotrue-version`). The three queries below were executed (dashboard-only items remain — see end).

### 1. `auth.users` — account state (CONFIRMED user, never signed in)
```sql
SELECT id,email,confirmation_sent_at,recovery_sent_at,last_sign_in_at,email_confirmed_at
  FROM auth.users WHERE email='taishogun@gmail.com';
```
| field | value |
|---|---|
| id | `1f93b4a9-935f-45e2-ab46-746b5a4f82f6` |
| confirmation_sent_at | 2026-06-21 06:32:03 UTC |
| email_confirmed_at | 2026-06-21 06:32:33 UTC |
| recovery_sent_at | 2026-06-21 18:30:00 UTC |
| last_sign_in_at | **null** |

- Account **is confirmed** (~30s after signup). A confirmed user's magic-link token therefore lives
  in the `recovery_token` slot → `recovery_sent_at = 18:30` is the active/latest magic link.
  Confirms Background note #1.
- **`last_sign_in_at = null`** → user has **never** completed a sign-in; every magic-link attempt failed.

### 2. `auth.audit_log_entries` — EMPTY (no data to read)
```sql
SELECT created_at,payload->>'action' AS action,payload->>'type' AS type
  FROM auth.audit_log_entries
  WHERE payload->>'actor_username'='taishogun@gmail.com'
  ORDER BY created_at DESC LIMIT 30;
```
Returned `[]`. Diagnostic `count(*)` over the whole table = **0 rows** (oldest/newest null) — the
audit log has been purged by retention. The request count/timeline cannot be reconstructed here;
`flow_state` + `users` are the evidence instead.

### 3. `auth.flow_state` — PKCE flow (SMOKING GUN)
```sql
SELECT id,auth_code,code_challenge_method,authentication_method,created_at,updated_at
  FROM auth.flow_state ORDER BY created_at DESC LIMIT 20;
```
Only **2 rows exist in the entire table**:

| auth method | code_challenge_method | created (UTC) | updated (UTC) |
|---|---|---|---|
| magiclink | **s256** | 18:30:00 | 18:30:44 (+44s) |
| email/signup | s256 | 06:32:03 | 06:32:33 |

**Deductions:**
- **PKCE flow confirmed (`s256`).** The Flutter SDK initiated `signInWithOtp` as PKCE, so
  completing sign-in requires a **`?code=` param → `exchangeCodeForSession`**. The repo email
  template instead emits `?token_hash={{ .TokenHash }}&type=email` (no `code`) → a genuine
  flow/param mismatch: a PKCE deep-link handler landing on `/auth/callback` gets no `code` to
  exchange. **Hardens Root Cause #3.**
- **+44s touch** on the magic-link flow_state (created 18:30:00, updated 18:30:44) = the verify
  endpoint was hit ~44s after send — far inside the 1h expiry, so timing-out is not the cause.
  Consistent with **Gmail/security-scanner prefetch consuming the one-time token** (Root Cause #2);
  the user's later click then hit an already-consumed token → raw `403 otp_expired`.
- **Single magic-link request this session** (one magiclink flow_state; `recovery_sent_at` matches
  it; signup at 06:32 and retry at 18:30 are ~12h apart). No same-session double-request →
  **Root Cause #1 (resend supersede) downweighted for this instance.**

### Still requires the dashboard (not in the DB)
- **Auth > Email Templates** — which Magic Link template is actually *deployed* (`{{ .ConfirmationURL }}` vs the repo's token_hash).
- **Auth > Providers > Email** — `mailer_otp_exp` (hosted OTP expiry).
- **Auth > URL Configuration** — Site URL + redirect allow-list, incl. the `?env=dev` gap (#4).

## Investigation Log

### App-side auth flow (CONFIRMED via code)
**Files:**
- `lib/features/auth/presentation/auth_view.dart:358-361` — `Supabase.instance.client.auth.signInWithOtp(email, emailRedirectTo: widget.redirectUrl)`.
- `lib/features/auth/presentation/auth_view.dart:151-156` — `_redirectUrl()` returns
  `https://getneurostack.app/auth/callback` (prod) or `.../auth/callback?env=dev` (dev).
- `lib/features/auth/presentation/check_email_view_model.dart:46-67,120-125` — `resendMagicLink()`
  calls `signInWithOtp` again with the same redirect. **A resend issues a new token.**
- `lib/features/auth/presentation/auth_callback_view.dart` — pure UI spinner ("Finishing sign-in…");
  the actual code→session exchange happens elsewhere (supabase_auth_ui / deep-link handler). The
  callback view is never reached when verify fails server-side ⇒ explains empty app logs.

**Conclusion:** App correctly calls `signInWithOtp`. The failure is upstream of the app.

### Deep-link / PKCE code-exchange path (CONFIRMED MISSING — new 2026-06-21)
**Evidence:**
- `lib/core/utils/data_source/data_source_init.dart:28-37` — `Supabase.initialize(url, anonKey)`
  passes **no `authOptions`** ⇒ supabase_flutter v2 defaults apply: **`authFlowType: pkce`**
  (matches `flow_state.code_challenge_method = s256`) and `detectSessionInUri: true`.
- **No app code calls `exchangeCodeForSession`, `getSessionFromUrl`, or `verifyOtp`** anywhere
  (repo-wide search: only `onAuthStateChange` listeners + test mocks). `lib/core/utils/deep_link/`
  is **empty**. The app relies entirely on supabase_flutter's automatic deep-link detection.
- Universal/App Links ARE configured: `ios/Runner/Runner.entitlements:7`
  `applinks:getneurostack.app`; `android/.../AndroidManifest.xml:34-38`
  `<intent-filter android:autoVerify="true"> ... https getneurostack.app` (no path filter → all
  paths on the host open the app).
- `pubspec.yaml:58-59` — `supabase_flutter: ^2.10.3`, `supabase_auth_ui: ^0.5.5`.

**Intended (default-template) flow on mobile:** email link → browser → `supabase.co/auth/v1/verify`
→ `303` → `getneurostack.app/auth/callback?code=<auth_code>` → universal link opens the app →
supabase_flutter auto-detects `?code=` → `exchangeCodeForSession` (needs the **on-device
`code_verifier`**) → `signedIn`.

**Why it breaks:** PKCE requires the `?code=` exchange to run on the SAME device that called
`signInWithOtp` (it holds the `code_verifier`). The default `{{ .ConfirmationURL }}` link runs the
**token-consuming `GET /verify` in the browser/scanner first**. When a Gmail/security prefetcher (or
any non-app context) hits verify, it consumes the one-time token and generates the `auth_code` — but
that code is delivered to a bot/browser with no `code_verifier`, so the exchange never completes
(**`flow_state` row never deleted; `last_sign_in_at` null**). The user's later click then finds the
token already consumed → **`otp_expired`**.

### Deployed template — DEDUCED from DB evidence (default `{{ .ConfirmationURL }}`, NOT the repo file)
The `flow_state` `auth_code`/PKCE row was **created and updated at Supabase verify time** (18:30:00 →
18:30:44). A `token_hash` link (the repo's `magic-link.html`) points at `getneurostack.app`, never
at `supabase.co/auth/v1/verify`, and so could **never** trigger PKCE `auth_code` generation in
`flow_state`. Therefore the **hosted project is still serving the default `{{ .ConfirmationURL }}`
magic-link template** — the repo's (broken, nested-path) token_hash template was never deployed.
This converts Root Cause #3 from "suspected" to **confirmed by inference** (dashboard view still
nice-to-have but no longer load-bearing).

### Magic-link email template (SUSPECT)
**File:** `supabase/auth/email/magic-link.html`
```html
<a href="{{ .RedirectTo }}/auth/confirm?token_hash={{ .TokenHash }}&type=email">Log In</a>
```
**Problem:** `{{ .RedirectTo }}` already equals the full `emailRedirectTo`
(`https://getneurostack.app/auth/callback`). So this template renders a **malformed nested
path**: `https://getneurostack.app/auth/callback/auth/confirm?token_hash=...&type=email`.
This template pattern is copied from Supabase's SSR guide, where `{{ .RedirectTo }}` is the
site root — not an `/auth/callback` URL. As written it cannot work.

Because the user actually saw the **raw Supabase verify JSON** (`*.supabase.co/auth/v1/verify`),
the *deployed* template is almost certainly NOT this token_hash file but the **default
`{{ .ConfirmationURL }}`** template (which points at `/auth/v1/verify`). i.e. `config.toml`'s
template was likely never pushed, or was pushed and is broken. **Needs DB/dashboard confirmation.**

### Local Supabase config (`supabase/config.toml`) — NOTE: local, may differ from hosted project
**Evidence:**
- `site_url = "https://getneurostack.app"` (line 148)
- `additional_redirect_urls = ["https://getneurostack.app/auth/callback"]` (line 150)
  — **does NOT include the dev variant `https://getneurostack.app/auth/callback?env=dev`**.
  A `redirect_to` not on the allow-list can make GoTrue refuse to redirect and return the raw
  JSON error instead of a friendly redirect. (Hypothesis — confirm with explore #2.)
- `otp_expiry = 3600` (line 215) — 1h locally; **hosted dashboard value unknown**.
- `[auth.rate_limit] email_sent = 2` per hour (line 180) — only 2 magic emails/hour.
- `[auth.email.template.magic_link] content_path = ./supabase/auth/email/magic-link.html` (line 174-176).

### Git history
- `supabase/auth/` has a single commit `ed8c497 "pre auth setting"` — template added once, never iterated.

## Root Cause (updated 2026-06-21 with DB evidence; template/OTP/URL config still dashboard-pending)
> **DB evidence update (2026-06-21):** `auth.flow_state` shows a **PKCE flow (`s256`)** while the
> repo template emits `token_hash` (no `code`) → **#3 hardened**. The magic-link flow_state was
> touched **+44s** after send (well inside expiry) → prefetch consumption → **#2 supported**. Only
> one magic-link request this session (`recovery_sent_at` matches the single magiclink flow_state)
> → **#1 downweighted**. `last_sign_in_at` is null (never signed in). See Investigator Findings.

**Confirmed chain (high confidence).** The hosted project serves the **default
`{{ .ConfirmationURL }}` magic-link template** (deduced: PKCE `auth_code` was generated in
`flow_state` at verify time — only the verify-routing template can do that). The app uses the
**default PKCE flow** (`data_source_init.dart` passes no `authOptions`) with **no custom
deep-link / code-exchange handler** (`deep_link/` empty; no `exchangeCodeForSession`/`verifyOtp`
in code) — it relies solely on supabase_flutter auto-detection of `?code=`. PKCE requires the
`?code=` exchange to run on the **same device** that requested the link. Because the default link
runs a **token-consuming `GET /auth/v1/verify` in the browser/scanner first**, an email
prefetcher (Gmail/security scanner — `taishogun@gmail.com` is Gmail) consumed the single-use
token ~44s after send and generated an `auth_code` that was delivered to a context with no
`code_verifier`; the on-device exchange never ran (`flow_state` never deleted, `last_sign_in_at`
null), and the user's later click hit the already-consumed token → **`otp_expired`**.

Contributing triggers, ranked after DB evidence:

1. **Email prefetch/scanning consumes the one-time token (PRIMARY).** Verify hit +44s after send,
   well inside expiry; flow_state never exchanged. Classic prefetch-breaks-PKCE-magic-link.
2. **Architecture mismatch: PKCE magic link with no robust exchange/verify handler (PRIMARY).**
   Default `{{ .ConfirmationURL }}` + browser verify + on-device-only `code_verifier` + zero
   `verifyOtp`/`exchangeCodeForSession` handling makes sign-in fragile even without a scanner
   (any in-app browser / desktop click / unvalidated app-link breaks it).
3. **Deployed template is the default, not the repo's token_hash file (CONFIRMED by inference).**
   The repo `magic-link.html` is also broken (nested `/auth/callback/auth/confirm` path) and was
   never deployed.
4. **Superseded token (DOWNWEIGHTED).** Only one magic-link request this session
   (`recovery_sent_at` matches the single magiclink `flow_state`); not the cause this instance,
   but the app's `resendMagicLink` makes it a latent footgun.
5. **Redirect allow-list gap (dev, MINOR).** `?env=dev` not allow-listed (`config.toml:150`);
   affects graceful error redirect, not the core failure.

## Recommendations (prioritized)

### A. Strongest fix — switch to a 6-digit OTP code flow (scanner-proof, deep-link-proof)
The most robust option for a Flutter mobile app: keep `signInWithOtp(email:)` but verify with the
**emailed code** instead of a clickable link.
- Email template: send `{{ .Token }}` (the 6-digit code) instead of a link.
- App: on the existing "check email" screen, add a code field → call
  `Supabase.instance.client.auth.verifyOTP(email: email, token: code, type: OtpType.email)`.
- Eliminates prefetch consumption, the on-device `code_verifier` constraint, and universal-link
  fragility entirely. No `/auth/callback` round-trip needed.

### B. If keeping the magic *link* — make verification scanner-resistant and actually wired
1. **Fix + deploy the template.** The default `{{ .ConfirmationURL }}` is prefetch-vulnerable; the
   repo token_hash file is broken (nested `/auth/callback/auth/confirm`). Use a token_hash link
   whose base is a **real landing page**, e.g.
   `{{ .SiteURL }}/auth/confirm?token_hash={{ .TokenHash }}&type=email`, and a page that requires
   an explicit **button click** before verifying (defeats prefetch).
2. **Wire an actual handler.** Add a deep-link handler (the empty `lib/core/utils/deep_link/`) that,
   on inbound `/auth/confirm`, calls `verifyOTP(type: OtpType.email, tokenHash: <hash>)`
   (token_hash verify is NOT `code_verifier`-bound → works cross-context). Today nothing calls
   `verifyOtp`/`exchangeCodeForSession`.
3. **Confirm `config.toml` is pushed** (`supabase config push`) so repo == hosted (currently the
   hosted template is the default, not the repo file).

### C. Regardless of A or B
4. Add the dev redirect (`https://getneurostack.app/auth/callback?env=dev`, or a wildcard) to
   `additional_redirect_urls` (`config.toml:150`) **and** the hosted dashboard allow-list.
5. Guard `resendMagicLink` (latent token-supersede footgun) — make it unmistakable that a resend
   invalidates the prior email's link.
6. (Optional dashboard verification, no longer load-bearing) Auth > Email Templates (deployed
   template), Auth > Providers > Email (`mailer_otp_exp`), Auth > URL Configuration (allow-list).

## Preventive Measures
- Keep email templates in repo AND verify they're deployed (CI check or `config push` in deploy).
- Add an integration/e2e check that the rendered magic link resolves to a 2xx verify page.
- Log the inbound `/auth/callback` deep link (params incl. `error`, `error_code`) in the app so a
  failed verify that *does* redirect back is visible in app logs next time.

## Blocker
**RESOLVED 2026-06-21** — the DB-connected Supabase MCP (`project_ref=etzzkjskpdpltmuioakg`) was
approved; the three confirming queries ran (see Investigator Findings). **Remaining gap is
dashboard-only** (not exposed via MCP/SQL): the *deployed* Magic Link email template, hosted
`mailer_otp_exp`, and the URL Configuration redirect allow-list. Confirm those in the Supabase
dashboard (or via the Management API) to fully close out Root Causes #3 and #4.
