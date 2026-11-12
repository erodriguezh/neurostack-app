  Setup facts (from the code):
  - There is no debug menu or mock RevenueCat in the repo — subscription states must come from a real RevenueCat sandbox account(expired trial, active trial, purchase) or from the webhook-written status in the DB.
  - Tabs are Stack (Home), Library, Progress, Settings.
  - Haptics never fire on the iOS Simulator — verify those on a device.
  - For accessibility cases use Xcode's Accessibility Inspector against the simulator.

  ---

  ## Setup guide (verified against code, DB, and the live RevenueCat project on 2026-07-13)

  ### How the app resolves subscription state (what we can and cannot fake)

  - Effective status: if a RevenueCat snapshot exists for the signed-in user, **RC wins entirely**; the DB `users.subscription_status` is
    used only when the snapshot is null (RC init/identify failed) — `lib/paywall/domain/entitlement.dart:17`. A user with no RC purchases
    gets snapshot `.none()` → effective **free**, regardless of what the DB says. Consequence: subscription states cannot be staged with
    SQL; only `users.protocol_ids` (the active stack) and `sessions` (counts) can.
  - Trial-expired modal trigger (`trial_expiry_policy.dart:26`, `home_view_model.dart:620`): fires when locally persisted
    `lastSeenEffectiveStatus:<uid>` was `trial` and effective becomes free/expired, OR prefs are fresh (reinstall) and RC reports
    `lastPeriodType == trial` with no entitlement, OR effective status is `expired` (lapsed paid).
    - Headline is **"Your Premium Trial Has Ended"** only when effective lands on `free` via a trial transition.
    - Effective `expired` (lapsed paid sub) shows the same modal/buttons with headline **"Your Subscription Has Lapsed"**, and it
      **re-fires on every launch by design** (not gated on lastSeen) until the user resubscribes.
  - Trial reminder banner (`trial_expiry_policy.dart:8`): needs a **live** RC trial with expiration ≤ 24 h away; shown at most once per
    24 h per user (`trialReminder:lastShownAt:<uid>`).
  - Local state reset: deleting the app clears both SharedPreferences keys above. The trim decision is only marked resolved after a
    successful save (`markTrialExpiredDecisionResolved`).
  - DB sync: the `revenuecat-webhook` edge function would write `subscription_status` back to Supabase, but as of 2026-07-13 **no
    webhook integration is configured in the RevenueCat project** — the function is never called, so DB statuses are stale
    (taishogun@ still says `trial` with no RC entitlement). Harmless for these tests (RC snapshot drives the app), but the DB
    fallback path shows stale data until the webhook is wired up in RC → Integrations.

  ### Two run lanes

  | Lane | Key file | Where | Can produce |
  |---|---|---|---|
  | Test Store | `env/env.json` (`test_…` key) | Simulator OK | free, active paid (premiumMonthly/Annual), lapsed paid (`expired`) |
  | Apple sandbox | `env/env.appstore.json` (`appl_…` key, gitignored) | **Physical device** + sandbox tester | live trial, expired trial (`free`), everything else |

  - Test Store: purchases are simulated via an in-app dialog (success/failure/cancel). **No free trials** — verified 2026-07-13: the v2
    API rejects `trial_duration`, there is no product-update endpoint, the MCP `create-product` only accepts `duration`, and RC staff
    confirmed it (community topics 7191/7193, Dec 2025). Subscriptions auto-renew on an accelerated clock, max 5 renewals, then cancel
    → entitlement deactivates → effective `expired`. **Buy Monthly for lapse tests** (≈5-min renewals, lapses in ~30 min); Yearly
    renews hourly and takes ~6 h to lapse (verified live). Test Store subs cannot be cancelled/refunded via API (Web Billing only).
  - Apple sandbox: run with `flutter run --dart-define-from-file=env/env.appstore.json`. Renewal compression: 3 days → 2 min,
    1 week → 3 min, 1 month → 5 min, 1 year → 1 h; max 12 renewals/day. Prerequisites (verify in App Store Connect): the 7-day
    free-trial intro offer on `neurostack_monthly`/`neurostack_yearly`, and a Sandbox Tester account signed in on the device.
    For a **pure trial expiry** (trial headline) the trial must lapse without converting to paid — cancel auto-renew during the
    compressed trial window (sandbox account subscription management); if it converts and then lapses you get the `expired`/lapsed-paid
    variant instead.

  ### Test users (Gmail plus-addressing delivers all to the main inbox; Supabase treats each as a distinct user; auth is magic-link/OTP)

  | User | Email | Lane | State to create | Covers cases |
  |---|---|---|---|---|
  | A | `taishogun+trial@gmail.com` | Apple sandbox | live trial, then cancelled → expired trial | 1, 2, 3, 4*, 15 (trial), clean 9/10 semantics |
  | B | `taishogun+expired2@gmail.com` (uid `fd702b40-…`) | Test Store | lapsed paid (Monthly) + 3 protocols `[122,120,129]`, sessions 5/2/0 | 5–11 (headline reads "Subscription Has Lapsed"), 14 |
  | C | `taishogun+expired@gmail.com` (uid `2dd21876-…`) | Test Store | lapsed paid (bought Yearly → lapses ~6 h after purchase) + 2 protocols `[122,120]` | 4 (lapsed variant) |
  | D | `taishogun@gmail.com` (exists, uid `1f93b4a9-…`) | Test Store | free with stack `[10, 122]`, purchase during case 16 | 12, 13, 16, then 15 (premium) |

  \* Case 4's "relaunch: does not re-show" only holds on the trial path (effective `free`). On the lapsed-paid path the modal
  re-appears every launch by design — same for case 9's relaunch expectation on user B; verify instead that the *selection* modal does
  not return and the stack stays trimmed.

  ### Step-by-step

  **User B (do first — simulator, no store accounts needed)** — staged 2026-07-13: stack `[122,120,129]`, sessions 122→5, 120→2, 129→0.
  1. [DONE] Run with the normal config, sign up as `taishogun+expired2@gmail.com`, complete onboarding. *(done)*
  2. [DONE] Stage the stack + session counts in Supabase (protocol ids from the seeded catalog; 122 HIIT, 120 Cold Plunge, 129 Meditation): *(done)*
     ```sql
     update public.users set protocol_ids = '[122, 120, 129]'::jsonb
     where id = (select id from auth.users where email = 'taishogun+expired2@gmail.com');

     insert into public.sessions (user_id, protocol_id, completed_at)
     select u.id, p.pid, now() - (n || ' days')::interval
     from (select id from auth.users where email = 'taishogun+expired2@gmail.com') u,
          (values (122, 5), (120, 2)) as p(pid, cnt),
          generate_series(1, 5) n
     where n <= p.cnt;  -- 122→5 sessions, 120→2, 129→0
     ```
  3. [DONE] In the app, open the paywall and buy **Monthly** (not Yearly!) with the Test Store dialog → "simulate success". Entitlement is
     live immediately.
  4. [DONE] Wait ~30 min (5 accelerated renewals, then auto-cancel). Verify expiry before testing:
     `GET https://api.revenuecat.com/v2/projects/proj2eeae544/customers/<supabase-uid>/subscriptions` → `status: expired`,
     `gives_access: false` (RC_API_KEY is set in the shell env).
  5. [DONE] Relaunch → lapsed modal → run cases 5–11 and 14. For case 10, re-add a 3rd protocol via the SQL above and delete/reinstall the
     app first (clears the resolved decision).

  **User C (simulator)** — accidentally bought **Yearly** on 2026-07-13 ~15:13 → hourly renewals, lapses ≈ 21:15. Stack already set
  to `[122,120]`, no sessions → case 4 (lapsed variant) once expired.

  **User D (simulator; account exists)** — [DONE] already free with stack `[10, 122]`. Note: DB `subscription_status` was stale (`trial`
  with no RC entitlement) — the app resolves it as free. Run cases 12–13, then 16 (Test Store purchase → simulate success), then 15
  as the premium variant.

  **User A (physical device, Apple sandbox — needs the ASC intro offer + sandbox tester)**
  1. Sign in the sandbox account on the device, run with `--dart-define-from-file=env/env.appstore.json`.
  2. Sign up as `taishogun+trial@gmail.com`, complete onboarding, start the 7-day trial through the paywall (sandbox sheet).
  3. While the trial is live (compressed to minutes): case 1 — the ≤24 h window is trivially satisfied; also case 15 (trial variant).
     Re-test of the banner requires app delete (24 h throttle).
  4. Immediately cancel auto-renew in the sandbox subscription management so the trial lapses without converting.
  5. After expiry (verify via the RC customers API as above): relaunch → cases 2, 3, and (with the stack trimmed to ≤2 via SQL) 4 —
     with the exact "Your Premium Trial Has Ended" headline and clean don't-re-show semantics for 9/10 if you also stage 3 protocols
     + sessions here.

  ### Verification / reset cheat-sheet

  - RC customer state: `GET /v2/projects/proj2eeae544/customers/<uid>` and `…/subscriptions` (bearer `RC_API_KEY`).
  - DB state: `select subscription_status, protocol_ids from public.users where id = '<uid>';`
  - Session counts: `select protocol_id, count(*) from public.sessions where user_id = '<uid>' group by 1;`
  - Reset local flags (lastSeen status, reminder throttle, unresolved decision): delete the app from the simulator/device.
  - RC state is keyed to the Supabase uid and survives reinstalls — a "fresh" trial/purchase state needs a fresh `+alias` account.

  ---

  A. Trial expiry — Stack (Home) tab

  1. Trial reminder banner (needs an account within 24h of trial expiry)
  - Steps: Launch to the Stack tab.
  - Expect: Banner above the content with a clock icon, text "Your trial ends soon", an "Upgrade Now" button, and an X dismiss. Dismiss it, relaunch: it does not
  reappear (shown once).

  2. Trial-expired modal appears
  - Steps: Launch as a user whose trial has expired, with 3+ active protocols.
  - Expect: Modal titled "Your Premium Trial Has Ended" with body line "You currently have 3 active protocols. The free tier allows 2." and two buttons: "Keep
  Everything" (subtitle "Subscribe to Premium") and "Continue with Free" (subtitle "Limited to 2 protocols").

  3. "Keep Everything" round-trips through the paywall
  - Steps: Tap "Keep Everything", then leave the paywall without buying.
  - Expect: You return and the expired modal re-shows (status is still expired).

  4. "Continue with Free" with ≤2 active protocols
  - Steps: Same flow but with an account that has 2 or fewer active protocols.
  - Expect: Modal closes with no selection step. Relaunch: it does not re-show.

  B. Protocol Selection Modal (via "Continue with Free" with 3+ active)

  5. Modal appearance and lockdown
  - Steps: Tap "Continue with Free".
  - Expect: Full-screen dark modal titled "Choose 2 Protocols to Keep", a counter pill reading "2/2 SELECTED", a "Confirm Selection" button, and one row per active
  protocol showing its name, its category in monospace caps (e.g. "EXERCISE"), and "N sessions logged". Status bar content is light. Tapping the dark background
  does nothing; there's no close affordance. On an Android emulator the system back button/gesture is blocked (PopScope(canPop: false)).

  6. Pre-selection ranks by session count
  - Steps: Before triggering, arrange distinct counts (e.g. A=5, B=2, C=0 sessions). Open the modal.
  - Expect: A and B arrive selected. Variants: with tied counts, the tie breaks by stack order (earlier-added wins); with all counts at 0, the first two in stack
  order are selected. Kill and relaunch mid-flow: the flow retriggers with the same default.

  7. Counter and Confirm react to selection
  - Steps: Deselect one row; watch; reselect.
  - Expect: Counter animates to "1/2 SELECTED" (digit swaps via animation, pill tint changes), checkbox de-fills with a scale/color transition, and "Confirm
  Selection" visibly transitions to disabled (dimmed, glow removed). Reselecting reverses it. Confirm is tappable only at exactly 2.

  8. Hard cap at 2 🫨
  - Steps: With 2 selected, tap a third row repeatedly.
  - Expect: Nothing changes — no fill, counter stays "2/2 SELECTED". (Device only: a light impact instead of the selection click.)

  9. Confirm trims the stack
  - Steps: Tap "Confirm Selection".
  - Expect: Modal closes; the Stack tab now shows only the 2 kept protocols; in Library the removed one is no longer in the stack. Relaunch: neither modal returns.

  10. Save failure re-opens once, selection preserved
  - Steps: Fresh over-limit account. In the modal, change the selection, then kill networking (Mac Wi-Fi off) and tap "Confirm Selection".
  - Expect: An error toast appears and the modal re-opens once with your same 2 pre-selected. If the retry fails too, the flow ends unresolved — restore network,
  relaunch, and the trial-expired flow retriggers (the decision is only marked resolved after a successful save).

  11. Accessibility semantics
  - Steps: Inspect a row, the counter, and the confirm button; toggle a row while watching the counter.
  - Expect: Rows read as buttons with name, category, "N sessions logged", and a selected state that flips. The counter is a live region announcing "1/2 selected" /
  "2/2 selected" as it changes. "Confirm Selection" reports enabled/disabled.

  C. Entitlement gating — Library / Progress / Settings

  12. Library locks beyond the limit
  - Steps: As a free user with 2 active protocols, open Library and look at a protocol not in your stack; tap it.
  - Expect: Its card is dimmed with a dashed border, a lock badge, and label "Upgrade to unlock". The detail sheet shows "Upgrade to Add" with subtitle "Free tier
  is limited to 2 active protocols." — tapping it navigates to the paywall (no toast).

  13. At the limit, logging still works
  - Steps: Same free user: on Stack, tap "Log Session" on a protocol card; on Progress ("This Week" grid), tap an empty cell for a protocol/day.
  - Expect: The log-session sheet opens and saves normally in both places — being at 2 blocks activation, never logging.

  14. Over the limit, logging is blocked (transient state: free/expired status with 3+ still active, i.e. before completing the trim — e.g. force-quit during the
  selection modal, relaunch, and switch tabs if the app lets you)
  - Steps: From Progress or the Library detail sheet, open log-session for any protocol.
  - Expect: Instead of the form, a locked view: lock icon, "Upgrade Required", "Free tier is limited to 2 active protocols. Upgrade to log sessions for more
  protocols.", and a "Got it" button that closes it. From the Stack tab's "Log Session", expect instead a toast "Deactivate protocols or upgrade to continue
  logging" followed by the deactivation (selection) modal.

  15. Trial/premium is unlimited
  - Steps: As an active-trial or premium sandbox user, add a 3rd and 4th protocol from Library ("Add to Stack" in the detail sheet).
  - Expect: No locked cards, no paywall, activation succeeds.

  16. Purchase unlocks immediately + Settings consistency
  - Steps: As a free user, buy via the paywall with a sandbox account, then without restarting check Library and Settings.
  - Expect: Locked Library cards unlock in place. Settings: the "Unlock All Protocols" / "Unlimited protocols, all future updates" banner disappears and "Manage Subscription" appears under Support & Resources. (As free, it's the inverse: banner visible, no "Manage Subscription".)

  Cases 12, 13, 14, and 16 exercise exactly the seams PRD #16 rewired (Library, Progress, Settings, and the mixin-published entitlement), so if any screen disagrees
  with another about premium state, that's a regression worth reporting.


| email               | test case | issue                                                   |
|---------------------|-----------|---------------------------------------------------------|
| taishogun@gmail.com | 13        | on Progress tab, tapping an empty cell does not open the "Log session" |
|        all emails   | 16        | all purchases are yearly, even when selecting monthly   |
| taishogun+expired2@gmail.com  | 6 | session logged on the choose protocols modal is 0, although protocols has logged sessions |
| taishogun+expired2@gmail.com  | 10 | tested offline, unfriendly error when hitting on confirm selection. It should say offline  |
| taishogun+expired2@gmail.com  | 10 | set offline, then online click on confirmed selection, changes applied. UI issues: offline message stays, going to menu item and back to stack retriggers the expired modal, although i just tackled it.  |
| taishogun+expired@gmail.com | 4 | the user status is free. I get the subscription expired modal, click on continue with free with < 2 protocols. Modal goes away, i change to another menu item, go back to stack menu item and see the modal again. It also affects the warning message "subscription has lapsed" at the top of the screen.
