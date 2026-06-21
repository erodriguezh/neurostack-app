# Ubiquitous Language

This is the canonical glossary for the Neurostack app (a single bounded context). It consolidates the product/domain vocabulary, the subscription & paywall model, the app lifecycle/architecture vocabulary, and the core invariants.

**Conventions used in this document**

- **Tables** (Term · Definition · Aliases to avoid) are used for lifecycle, architecture, and store-integration terms, where the alias guidance carries the weight.
- **Definition lists** (Definition · Properties · Example · UI Label) are used for product and monetization nouns that carry UI copy and concrete examples.
- Terms are ordered **logically** within each section (temporal/lifecycle or dependency order), not alphabetically.
- Cross-references appear as **bold term names**. See **Flagged Ambiguities** for overloaded words that must always be qualified.
- ⏳ **Planned (#NN)** marks vocabulary that describes the **target state of epic #16** ("Deepen monetization gating into one Entitlement module", slices #17–#21) and **has not shipped yet**; the marker names the slice that introduces or finalizes it. This doc deliberately leads the refactor — delete each marker as its slice merges. Until then, the live mechanism noted in the marker (typically `SubscriptionStatusResolver`) is what the running code uses.

---

## Domain Model

### Core Domain Terms

**Protocol** (noun)

- Definition: A science-backed routine with specific parameters (e.g., "Norwegian 4x4 HIIT")
- Properties: Name, Target Specification, Frequency, Research Citation, Category
- Example: "Sauna Protocol: 20 min at 108°F, 3-4x/week (Finnish study, 2020)"
- UI Label: "Protocol"

**Target** (noun)

- Definition: The ideal specification for a protocol (frequency, duration, intensity)
- Properties: Frequency (e.g., "3-4x/week"), Duration (e.g., "20 min"), Intensity (e.g., "108°F")
- Example: "Target: 40 min at 65% max HR"
- UI Label: "Target"

**Session** (noun)

- Definition: A single instance of completing a protocol
- Properties: Protocol ID, Timestamp, Duration, Notes (optional)
- Example: "Sauna session on Nov 21, 2025, 22 minutes"
- UI Label: "Session" or "Log"
- Note: The per-protocol count of `Session` records is the **Session Count** (see **Protocol Stack & Limits**), used by **Pre-selection** in the **Protocol Selection Modal**.

**Completion** (noun/verb)

- Definition: The state of meeting a protocol's target within a time period
- Properties: Protocol ID, Period (week/month), Status (complete/incomplete/partial)
- Example: "3/4 sessions completed this week"
- UI Label: "Completed" or "Done"

**Streak** (noun)

- Definition: Consecutive periods (days/weeks) of protocol adherence
- Properties: Protocol ID, Count, Period Type
- Example: "7-day HIIT streak"
- UI Label: "Streak"

**Stack** (noun / value object)

- Definition: The ordered list of **Active Protocols** currently associated with a **User**, modeled as the `Stack` value object
- Properties: List of Protocol IDs, ordered by **Activation** time
- Example: "My morning stack: Sunlight, Cold Shower, Zone 2"
- UI Label: "Your Stack" or "Active Protocols"
- Aliases to avoid: Active list, user protocols, my list
- Note: Operations on the Stack (Activation, Deactivation, Stack Trim, Protocol Limit) are defined under **Protocol Stack & Limits**.

**Research Citation** (noun)

- Definition: Academic source backing a protocol
- Properties: Authors, Year, Study Title, Journal, DOI/Link
- Example: "Wisløff et al. (2007). Circulation."
- UI Label: "Research" or "Source"

**Category** (noun)

- Definition: Protocol grouping for organization
- Values: "Exercise", "Heat Therapy", "Nutrition", "Supplements", "Mind", "Sleep"
- UI Label: "Category"

**Evidence Level** (enum)

- Definition: Scientific backing strength
- Values: "Multiple RCTs", "Single RCT", "Observational", "Expert Consensus"
- UI Label: "Evidence"

### Authentication

**Sign-In** (noun/verb)

- Definition: The act by which a **User** proves ownership of their email to become Authenticated. Passwordless — no password is ever set.
- Example: "Enter your email, then the code we send you, to sign in."
- UI Label: "Sign in"
- Aliases to avoid: log in, login, authenticate

**One-Time Code** (noun)

- Definition: The short, single-use numeric code emailed to a **User**; entering it completes one **Sign-In** and, on first use, confirms the account.
- Example: "Enter the 6-digit code we emailed you."
- UI Label: "code"
- Aliases to avoid: magic link, magic code, OTP, PIN
- Note: The authenticated state is **never** called a "Session" — that term is reserved for a single logged instance of completing a protocol (see **Session**). Auth state uses the Authenticated / Unauthenticated language on the **User**.

### Protocol Stack & Limits

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **Active Protocol** | A **Protocol** currently present in the **User**'s **Stack** | Active (unqualified), enabled protocol |
| **Activation** | Adding a **Protocol** to the **Stack** via `User.activateProtocol(id)` | Add, enable, opt-in |
| **Deactivation** | Removing a single **Protocol** from the **Stack** via `User.deactivateProtocol(id)`; raises one `ProtocolDeactivatedEvent` | Remove (unqualified — also used for sessions), disable |
| **Protocol Limit** | The maximum **Active Protocols** allowed by the **User**'s **Effective Status**, sourced from `SubscriptionStatus.protocolLimit` — **2** for `free`/`expired`, `null` (unlimited) for `trial`/`premium*`/`grace`. See the canonical **Protocol Limit Rule** in Core Invariants. UI: "X/2 protocols active" (free) or "Unlimited" (premium). ⏳ Today the **User** aggregate reads this off the enum directly; #19 makes it an injected input computed by **Entitlement** — same values, one place. | Cap (overloaded), max protocols |
| **Stack Trim** | The user-driven operation that reduces **Stack** count to the **Protocol Limit** by selecting which protocols to keep; canonical multi-protocol intent (vs. single-protocol **Deactivation**) | Prune, batch deactivation, downgrade trim |
| **Session Count** | For a given **Active Protocol**, the number of `Session` records logged by the **User**; used by **Pre-selection** in the **Protocol Selection Modal** | Sessions, log count |

---

## Subscription, Paywall & Monetization

### Monetization Terms

**Free Tier** (noun)

- Definition: Permanent access to core functionality with a 2-protocol limit
- Properties: No time limit, no credit card required, full tracking capability
- Constraint: Can only activate 2 protocols simultaneously (see **Protocol Limit**)
- UI Label: "Free" or "Basic"

**Premium Trial** (noun)

- Definition: 7-day period with full access to all protocols and features
- Properties: Starts on subscription start (RevenueCat-managed); requires payment method (App Store/Play Store)
- Behavior: Reverts to **Free Tier** automatically after 7 days if not converted to a paid subscription
- UI Label: "Premium Trial" or "Trial"
- Note: This is the user-facing access period. The store-side configuration mechanism is the **Introductory Offer** — see **Flagged Ambiguities** ("Trial").

**Trial Status** (enum)

- Definition: Current state of the user's trial period
- Values: `active` (days 1-7), `expired` (day 8+), `converted` (subscribed)
- Calculation: `subscriptionStartDate + 7 days`
- UI Label: "X days left in trial"

**Premium Subscription** (noun)

- Definition: Paid tier unlocking unlimited protocols
- Tiers: Monthly ($7.99) or Annual ($59.99 — 37% off monthly)
- Properties: Auto-renewing, managed by RevenueCat (StoreKit SDK wrapper)
- UI Label: "Premium" or "Pro"

**Subscription Status** (enum)

- Definition: The raw enum field on the **User** aggregate representing the user's payment state. It is a **cached replica of RevenueCat's word**, not an independent source of truth — written *only* by the **Webhook (RevenueCat)** (Design Principle #3; the client never persists it). Not necessarily the value the UI gates on — see **Effective Status**.
- Values: `free`, `trial`, `premiumMonthly`, `premiumAnnual`, `expired`, `grace`
- Per-value properties (defined on the enum): `protocolLimit` and `canAccessPremium` — see the table under **`isPremium` / `canAccessPremium`** and the **Protocol Limit Rule**.
- UI Label: Hidden from user (internal only)
- Aliases to avoid: Status (unqualified), tier

### Subscription State & Entitlement Resolution

> **Design principles** (cited verbatim by the code):
> - **#1 — RC authority.** RevenueCat is the source of truth for entitlement state; the persisted **Subscription Status** is the fallback used only when RC is unavailable.
> - **#3 — Webhook-only writer.** Only the **Webhook (RevenueCat)** writes Subscription Status to the DB; the client never persists subscription state.
> - **#8 — Caller supplies time.** Time-based decisions take `now` as a parameter (testability).
> - **#10 — User-scoped snapshot.** An **EntitlementSnapshot** is authoritative only when its `appUserId` equals the current user's id.
>
> ⏳ This whole section describes the **target** vocabulary of epic #16. Until #21 lands, the live implementation is `SubscriptionStatusResolver` (`lib/paywall/domain/subscription_status_resolver.dart`); the markers below name what replaces it.

**Entitlement** (domain value object) — *canonical*

- Definition: The resolved answer to "what can this user do right now" — the **Effective Status** and what follows from it (**Protocol Limit**, premium flags)
- Factory: `Entitlement.of(user, snapshot)` — a pure function, no injected dependencies; the caller supplies the user and the nullable **EntitlementSnapshot**
- Interface: `effectiveStatus`, `protocolLimit` (`null` = unlimited), `isPremium`, `canAccessPremium`
- Resolution precedence (Design Principle #1 + #10): the snapshot wins when present **and** scoped to the user (`snapshot.isForUser(user.id)`); otherwise fall back to the persisted **Subscription Status** — itself RevenueCat's last-written word, used when the live read is unavailable (web, SDK failure). RC therefore never loses the last word; the DB is only ever its cache.
- Distinction: `EntitlementSnapshot` is the raw RevenueCat input; **Entitlement** is the resolved domain output. Bare "Entitlement" means **this**, never the store-side **RevenueCat Entitlement** — see **Flagged Ambiguities**.
- Enforcement note: the **User** aggregate still enforces the limit (`activateProtocol` blocks at `count >= limit`, `canLogSession` at `count > limit`) but receives the limit as **input** from Entitlement; the entity never imports a RevenueCat type.
- Location: `lib/paywall/domain/entitlement.dart` (beside `entitlement_snapshot.dart`)
- ⏳ **Planned — introduced #17, finalized #21.** In #17 `Entitlement.of` *delegates to* `SubscriptionStatusResolver` byte-for-byte (adds the seam, changes no logic). #21 inlines the resolver's `resolveEffectiveStatus` + `mapSnapshotToStatus` here as private implementation and deletes the resolver. Published reactively as `ValueNotifier<Entitlement>` by **PremiumAwareViewModelMixin** (#17), which every screen reads (#20).

**EntitlementSnapshot** (value object) — *exists today*

- Definition: The raw RevenueCat input — a point-in-time read of RC's authoritative entitlement state for a given `appUserId` (`hasProEntitlement`, `isTrialPeriod`, `isInGracePeriod`, `productId`, `expirationDate`, `wasTrialThatExpired`, `wasPaidThatExpired`)
- Distinction: the raw input; **Entitlement** is the resolved domain answer
- Scope rule: authoritative only when `snapshot.isForUser(user.id)` (Design Principle #10)
- Location: `lib/paywall/domain/entitlement_snapshot.dart`

**Effective Status**

- Definition: The `SubscriptionStatus` value the UI gates on — exposed as `Entitlement.effectiveStatus`. Computed from the raw `User.subscriptionStatus` + the RevenueCat `EntitlementSnapshot` (+ **Last-Seen Status** for the modal decisions). The snapshot→status mapping: no pro entitlement → `free` (or `expired` if `wasPaidThatExpired`); grace → `grace`; trial → `trial`; monthly/annual product → `premiumMonthly`/`premiumAnnual`.
- Aliases to avoid: Computed status, derived status, current status
- ⏳ Until #21 this value is produced by `SubscriptionStatusResolver.resolveEffectiveStatus`; `Entitlement.of` delegates to it in the interim.

**Trial Expiry Policy** (decision module) — *canonical*

- Definition: Decides what to *surface* to the user about trial state — distinct from **Entitlement**, which decides what they *can do*
- Decisions: `shouldShowReminder(snapshot, now)` (within the 24h window before expiry, INV-P4); `shouldShowExpiredModal(effectiveStatus, lastSeen, snapshot)` (the `trial` → `free`/`expired` transition, plus the fresh-install gate: `lastSeen == null` **and** `snapshot.wasTrialThatExpired`)
- Inputs: effective status (from **Entitlement**), **Last-Seen Status** (from `TrialExpirationDecisionStore`), current time, `EntitlementSnapshot`
- Location: `lib/paywall/domain/trial_expiry_policy.dart`
- ⏳ **Planned — introduced #18, finalized #21.** Absorbs the resolver's `shouldShowTrialReminder` + `shouldShowTrialExpiredModal`.

**Last-Seen Status**

- Definition: The previously observed **Effective Status**, persisted per-user via **`TrialExpirationDecisionStore`** under `lastSeenEffectiveStatus:<userId>`; used to detect the `trial → free/expired` transition and suppress duplicate **Trial Expired Modal** display
- Aliases to avoid: Previous status, prior status

**`TrialExpirationDecisionStore`** — *exists today*

- Definition: SharedPreferences-backed store that persists **Last-Seen Status** per user; gates re-showing the **Trial Expired Modal**
- Location: `lib/paywall/data/trial_expiration_decision_store.dart`
- Aliases to avoid: Decision store, status memo

**`markTrialExpiredDecisionResolved`**

- Definition: `HomeViewModel` action that resolves the current **Effective Status** and writes it to **`TrialExpirationDecisionStore`**; **must only be called after a successful save**
- Aliases to avoid: resolveDecision, ackTrialExpiration

**Decision-Store Guard**

- Definition: The non-negotiable invariant: `markTrialExpiredDecisionResolved` runs only when `confirmProtocolDeactivation` returns `true`. Resolving the decision after a failed save would persist a "free" **Last-Seen Status**, suppress the **Trial Expired Modal** on next launch (per the `lastSeen == null` gate), and trap the **User** over-limit.
- Aliases to avoid: Save-success gate, resolution guard

**Webhook (RevenueCat)**

- Definition: The RevenueCat → backend edge function pipeline that is the **only writer** of **Subscription Status** to the DB (Design Principle #3); the client never persists subscription state. This is the mechanism that keeps the cached **Subscription Status** in sync with RevenueCat's authoritative **RevenueCat Entitlement**.
- Aliases to avoid: RC webhook, server webhook

### RevenueCat Subscription Architecture

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **Hosted Paywall** | A paywall UI built and rendered by RevenueCat's SDK via `RevenueCatUI.presentPaywall()`, not custom app code | Custom paywall, local paywall, native paywall |
| **Paywall Component** | A configurable UI element within a Hosted Paywall (Text, Button, Image, Package, Purchase Button, Footer) | Widget (ambiguous with Flutter), element |
| **Offering** | A RevenueCat-managed named set of Packages presented to the user; exactly one is marked "current" | Plan set, product group |
| **Package** | A duration-keyed container within an Offering (`$rc_monthly`, `$rc_annual`) that holds one Product per store | Plan, tier (overloaded) |
| **RevenueCat Entitlement** ("pro") | The single store-side entitlement RevenueCat is the **source of truth** for — the named feature set ("pro") reflected by `EntitlementSnapshot.hasProEntitlement`. RevenueCat processes payments, so it has the last word on who is pro; the app's persisted **Subscription Status** is only a webhook-synced cache of it. | Entitlement (unqualified — means the domain value object), permission, access level, feature flag |
| **RevenueCat Product** | A purchasable subscription item registered in RevenueCat, linked to a store-specific product identifier | Product (unqualified — ambiguous with App Store Connect Product) |
| **Test Store** | RevenueCat's sandbox app type for development testing without a real store connection | Sandbox (ambiguous with Apple Sandbox), dev store |
| **App Store app** | The RevenueCat app entry connected to a real App Store bundle ID, requiring ASC API key configuration | Production app (too vague), real app |

### Paywall Compliance

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **Restore Purchases** | An Apple-required user action that re-syncs previous store purchases to recover entitlements on a new device or reinstall | Sync purchases (different SDK method), recover |
| **Manage Subscription** | The Settings tile action that opens the platform's subscription management page | Cancel Subscription (old label — action is broader than cancellation) |
| **Auto-Renewal Disclosure** | Required legal text informing users about subscription renewal terms, cancellation window, and billing behavior | Fine print, legal text, boilerplate |
| **Introductory Offer** | Apple's term for a free trial or discounted period on an auto-renewable subscription, configured in App Store Connect | Free trial (when referring to the configuration mechanism), promo |
| **Delayed Close Button** | A paywall dismiss button with an artificial delay before appearing — Apple rejects these during App Review | Timed close, gated dismiss |
| **`canAccessPremium`** | The inclusive flag (on the `SubscriptionStatus` enum) that is `true` for `trial`, `premiumMonthly`, `premiumAnnual`, `grace`; `false` for `free`, `expired`. Use this when gating features trial users should reach (e.g. the **Manage Subscription** tile). | isPremium (excludes trial — see **Flagged Ambiguities**) |
| **`isPremium`** | The exclusive flag (`SubscriptionStatus.isPremium` getter) that is `true` only for `premiumMonthly`, `premiumAnnual`, `grace`; `false` for `trial`, `free`, `expired`. It differs from **`canAccessPremium`** by **exactly `trial`**, and — like `canAccessPremium` — **includes `grace`** (the getter comment: "Includes grace period"). Use only when you must distinguish paid subscribers from trial users. | canAccessPremium (includes trial) |

### Downgrade & Protocol Selection Flow

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **Downgrade** | A **Subscription Status** transition from premium-tier (`trial`/`premium*`/`grace`) to non-premium (`free`/`expired`), driven by RevenueCat → **Webhook (RevenueCat)** → DB; the client never *causes* a downgrade, only *responds* to one | Cancel, expire (subset), free conversion |
| **Protocol Selection Modal** | The blocking full-screen modal that prompts the **User** to choose 2 protocols to keep when **Stack** count exceeds the new **Protocol Limit** after a **Downgrade** | Deactivation Modal (legacy spec name — see **Flagged Ambiguities**), choose-2 modal |
| **KeepIds** | The `List<String>` of protocol IDs the **User** chooses to retain in a **Stack Trim**; parameter to `applyProtocolLimitSelection(...)` | Selected IDs, picked protocols, kept list |
| **Removed IDs** | The protocol IDs computed as `stack.protocolIds \ keepIds` during a **Stack Trim**; each becomes the subject of a `ProtocolDeactivatedEvent` | Deleted IDs, dropped IDs |
| **Pre-selection** | The deterministic initial selection state of the **Protocol Selection Modal**: top 2 by **Session Count** descending, ties broken by **Stack** insertion order ascending; falls back to first 2 in **Stack** when all session counts are zero | Default selection, smart pick |
| **Hard Cap** | The interaction rule that exactly 2 protocols may be selected at once in the **Protocol Selection Modal**; a 3rd-row tap is a silent no-op with `lightImpact` haptic | Strict limit, max selection |
| **Initial Selection** | An optional `Set<String>` argument to the **Protocol Selection Modal** that overrides **Pre-selection**; populated during **Same-Session Retry** with the prior **KeepIds** | Prefilled selection, restored selection |
| **Same-Session Retry** | The orchestrator's policy of re-opening the **Protocol Selection Modal** once after a save failure, with **Initial Selection** preset to the previous **KeepIds**; max 2 modal attempts per trial-expired flow | In-session retry, re-prompt |
| **Selector (pattern)** | A modal that returns a value (`Future<T>`) without persisting anything; the caller owns side effects. The **Protocol Selection Modal** is a **Selector**. Contrasts with "orchestrator modals" that own async submission state (e.g., `LogSessionView`) | Pure modal, dumb modal, return-value modal |
| **`applyProtocolLimitSelection`** | Domain method on **User** that takes **KeepIds**, validates `length == 2` + all currently active + no duplicates, deactivates **Removed IDs**, emits N `ProtocolDeactivatedEvent`s, and returns a new **User** with `subscriptionStatus` unchanged | trimStackForDowngrade (rejected), transitionToFreeTier (incorrect — that name implied status mutation) |
| **`confirmProtocolDeactivation`** | `HomeViewModel` method that orchestrates `applyProtocolLimitSelection` → `userRepository.save` with retry-once → toast on failure → authoritative reload; returns `bool` for success | confirmDowngrade, applyDowngrade |
| **`activeProtocolSelectionItems`** | `HomeViewModel` method that assembles `List<ProtocolSelectionItem>` for the modal by joining `Stack.protocolIds` with protocol metadata and per-protocol **Session Count**s | getProtocolsWithCounts |

---

## Core Invariants (Must ALWAYS be true)

### Protocol Limit Rule (canonical)

This single rule is the source of truth for the active-protocol cap. **INV-M5, INV-U1, INV-B2, and INV-U5 are facets of it** (kept as numbered anchors because the code and epic #16 cite them by number).

```sh
PROTOCOL LIMIT RULE
Cap = SubscriptionStatus.protocolLimit → 2 for free/expired, null (unlimited) for trial/premium*/grace.
Enforced by the User aggregate in two intentional guards (two operators, two failure codes — NOT drift):
  • Activation — activateProtocol blocks at count >= limit → protocolLimitReached    (free-tier paywall trigger)
  • Logging    — canLogSession   blocks at count >  limit → tooManyActiveProtocols   (post-downgrade over-limit)

Activation facet (INV-M5 / INV-U1 / INV-B2): any status with a non-null limit — today free AND expired —
  is blocked from activating another protocol at count >= limit; a free user's 3rd-protocol attempt
  triggers the paywall.
Logging facet (INV-U5): a status with a non-null limit and count > limit cannot log new sessions until the
  Stack is trimmed; the realistic trigger is a Downgrade (premium → free/expired) dropping the limit below
  the current count.
→ The >= vs > difference is intentional and must be preserved (Activation asks "can I add one more?";
  Logging asks "is my Stack already over the limit?"). #19 moves the limit lookup into Entitlement
  (limit-as-input) without changing these values or operators.
```

### Monetization Invariants

```sh
INV-M1: Free Tier MUST have no time limit
→ Rationale: "Free forever" promise, ethical design
→ Enforcement: No expiration date on free tier
→ Test: User can use free tier indefinitely with 2 protocols

INV-M2: Premium Trial MUST last exactly 7 days from subscription start
→ Rationale: Standard trial period, conversion optimization (RevenueCat-managed)
→ Enforcement: RevenueCat SDK manages trial duration from subscription creation
→ Test: Trial expires at exactly 168 hours after subscription start
→ Note (fn-81): trial_duration was null on Test Store products until fn-81-paywall-apple-compliance.1 configured P7D

INV-M3: [DEPRECATED] Premium Trial MUST NOT require credit card
→ DEPRECATED: RevenueCat manages trials via App Store/Play Store which require payment method
→ Rationale (historical): Lower friction, better mobile UX, App Store compliance
→ Replacement: Trials are now managed by RevenueCat; payment method is handled by App Store/Play Store

INV-M4: After trial expiration without payment, user MUST revert to Free Tier automatically
→ Rationale: No surprise charges, ethical conversion
→ Enforcement: RevenueCat webhook updates subscription status; client adjusts protocol limit
→ Test: On day 8, user with 5 protocols sees paywall when trying to log (if not subscribed)

INV-M5: Free Tier users CANNOT activate more than 2 protocols
→ Canonical: see Protocol Limit Rule (activation facet)
→ Rationale: Freemium conversion trigger
→ Enforcement: UI validation + API check
→ Test: "Upgrade to Premium" modal appears on 3rd protocol selection

INV-M6: Premium Trial users MUST see full feature set
→ Rationale: Demonstrate value before asking for payment
→ Enforcement: Feature flags based on subscriptionStatus
→ Test: Trial user can activate all protocols from library

INV-M7: Subscription pricing MUST offer annual discount
→ Rationale: Increase LTV, encourage commitment
→ Enforcement: Annual = $59.99 (37% off monthly rate)
→ Test: Annual saves $36.89/year vs monthly
```

### Protocol Invariants (INV-PR*)

```sh
INV-PR1: Every Protocol MUST have at least one Research Citation
INV-PR2: Protocol Target specifications MUST be measurable
INV-PR3: Protocol names MUST NOT include researcher names
INV-PR4: Deleted Protocols MUST preserve historical Session data
```

### Session Invariants

```sh
INV-S1: A Session MUST belong to exactly one Protocol
INV-S2: Session timestamp CANNOT be in the future
INV-S3: Session duration MUST be > 0 if specified
```

### User Invariants

```sh
INV-U1: Free Tier AND Expired users CANNOT activate more than 2 protocols
→ Canonical: see Protocol Limit Rule (activation facet)
→ Rationale: Freemium paywall, unlimited during trial/premium
→ Enforcement: UI + API validation via SubscriptionStatus.protocolLimit
→ Logic: IF subscriptionStatus.protocolLimit != null (today: free, expired) THEN activeProtocolIds.count < limit
→ CORRECTED: previously read "IN ['free']"; the User aggregate caps any status with a non-null limit,
  so expired (expired.protocolLimit == 2) is equally capped at activation — not free-only.

INV-U2: Premium Trial users CAN activate unlimited protocols
→ Rationale: Showcase full value during trial
→ Enforcement: Feature flag check
→ Logic: IF subscriptionStatus == 'trial' THEN no protocol limit (protocolLimit == null)

INV-U3: (DEPRECATED) Trial MUST auto-activate on first app launch
→ DEPRECATED: RevenueCat manages trials; new users start as 'free' until they start a subscription
→ Rationale (historical): No friction, immediate value demonstration
→ Replacement: New users start with 'free' status; trial begins when subscription with trial period starts (INV-P6)

INV-U4: Users MUST complete onboarding before tracking Sessions
→ Rationale: Set expectations, legal disclaimer
→ Enforcement: Onboarding flow gate

INV-U5: Over-limit users CANNOT log new sessions
→ Canonical: see Protocol Limit Rule (logging facet)
→ Rationale: Force subscription or protocol deactivation after a downgrade
→ Enforcement: Session logging checks protocol count > limit (any status with a non-null limit; the realistic
  trigger is an expired trial / downgrade that drops the limit below the current Stack count)
→ Test: Day 8 user with 5 protocols sees "Deactivate 3 protocols or upgrade" modal
```

### Business Invariants

```sh
INV-B1: Trial period MUST be exactly 7 days
→ Rationale: Industry standard, faster conversion cycle
→ Enforcement: Subscription configuration

INV-B2: Paywall MUST trigger when Free Tier user tries 3rd protocol
→ Canonical: see Protocol Limit Rule (activation facet)
→ Rationale: Clear freemium boundary
→ Enforcement: UI modal + API rejection
→ Logic: IF subscriptionStatus == 'free' AND activeProtocolIds.count >= 2 THEN showPaywall()

INV-B3: Paywall MUST offer monthly + annual options
→ Rationale: Maximize revenue, user choice
→ Enforcement: RevenueCat (StoreKit SDK wrapper) product configuration
→ Products: "neurostack.premium.monthly" ($7.99), "neurostack.premium.annual" ($59.99)

INV-B4: All UI text MUST include legal disclaimer on first launch
→ Rationale: Liability protection
→ Enforcement: Forced onboarding screen

INV-B5: Users MUST be able to use Free Tier indefinitely
→ Rationale: Ethical design, App Store guidelines compliance
→ Enforcement: No artificial time limits on free tier
→ Test: User can access free tier 1 year later without changes
```

### Paywall Invariants (RevenueCat Integration, INV-P*)

```sh
INV-P1: Paywall dismissal without purchase MUST return to previous screen
→ Rationale: Non-intrusive UX, user maintains control
→ Enforcement: Navigator.pop() on dismiss
→ Test: Dismiss paywall → user returns to screen that triggered it

INV-P2: Successful purchase MUST update local User and UI immediately via RevenueCat (optimistic)
→ Rationale: Responsive UX, no waiting for webhook
→ Enforcement: RevenueCat listener updates local state immediately
→ Test: Purchase complete → premium UI unlocked within 1 second

INV-P3: Webhook is source of truth for DB; client uses RevenueCat for UI gating
→ Rationale: Separation of concerns - DB for server-side auth, SDK for real-time UI
→ Enforcement: Webhook updates Supabase; Flutter uses RevenueCat CustomerInfo
→ Test: DB state may lag; UI responds instantly via RevenueCat SDK

INV-P4: Trial reminder MUST be shown max once per 24h period
→ Rationale: Non-annoying UX, avoid badgering users
→ Enforcement: SharedPreferences stores lastTrialReminderShown timestamp
→ Test: Reminder shown → same reminder blocked for 24 hours

INV-P5: RevenueCat app_user_id MUST match Supabase auth.uid
→ Rationale: Identity consistency between payment and auth systems
→ Enforcement: Set app_user_id on RevenueCat login to auth.uid
→ Test: RevenueCat customerInfo.appUserId == supabase.auth.currentUser.id

INV-P6: New users MUST start with 'free' status (not 'trial')
→ Rationale: Trial only begins when subscription with trial period starts via RevenueCat
→ Enforcement: Default subscription_status = 'free' in user profile
→ Test: Fresh install → user.subscriptionStatus == 'free'
```

---

## Settings & Support

### Terms

**Settings Screen** (noun)

- Definition: The 4th bottom-navigation tab exposing account management and support actions
- Properties: Upgrade Banner (conditional), Support Section (6 tiles), subscription-aware layout
- UI Label: "Settings"

**Support Tile** (noun)

- Definition: A tappable row in the Settings "Support & Resources" section that triggers an action
- Properties: Icon (Lucide), Label, Trailing icon (chevron or external-link), Tap callback
- Examples: Contact Us, Send Feedback, Rate the App, Feature Request, Restore Purchases, Manage Subscription
- UI Label: Varies per tile

**Send Feedback** (action)

- Definition: Opens the device's default email client with a pre-filled mailto link addressed to the support inbox
- Properties: To (`feedback@getneurostack.app`), Subject ("NeuroStack Feedback"), Body (app version, platform, subscription tier)
- Constraint: No in-app fallback if no email client is configured
- UI Label: "Send Feedback"
- Note: Replaces the originally-planned Wiredash integration

**Feedback Email** (noun)

- Definition: The pre-composed email opened via `url_launcher` when the user taps Send Feedback
- Properties: Recipient address, subject line, body with diagnostic context (app version, platform, subscription status)
- Example body: "App Version: 1.0.0+1\nPlatform: iOS\nSubscription: premiumAnnual"

### Invariants

```sh
INV-SET1: Send Feedback MUST open a mailto link with diagnostic context
→ Rationale: Support needs device/subscription context to triage feedback
→ Enforcement: SettingsViewModel composes URI with app version, platform, subscription status
→ Test: Tap Send Feedback → mailto URI contains version, platform, and subscription tier

INV-SET2: Send Feedback MUST NOT provide an in-app fallback
→ Rationale: Scope decision — no fallback for now; revisit if user reports show email-client absence is common
→ Enforcement: Fire-and-forget launchUrl call
→ Test: If no email client → system handles error; app does not intervene
```

---

## App Lifecycle & Architecture

### App Startup Lifecycle

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **Native launch surface** | The OS-rendered screen visible from app tap until Flutter draws its first frame | Splash screen (unqualified), launch screen (ambiguous) |
| **Flutter splash** | The first Flutter-rendered startup screen while initialization completes | Splash screen (unqualified) |
| **First frame** | The moment Flutter first renders to screen and replaces the native launch surface | First paint, initial render |
| **Cold start** | A full app launch from a terminated state where startup surfaces are visible | Fresh launch, first launch |
| **Bootstrap** | The async initialization sequence that runs behind the Flutter splash, from `initDataSource()` through service init to final state resolution | Startup work, init, setup |
| **Minimum splash duration** | The 500ms floor enforced via `Future.wait` so the entrance animation completes before any state transition | Splash delay, artificial delay |
| **Frame-anchored timing** | Starting a timer from a post-frame callback so the measured interval begins after the splash is actually visible on screen | Post-frame timing |

### App State Machine

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **InitializingApp** | The app state from `runApp()` until bootstrap completes or fails | Loading, booting |
| **AppInitialized** | The app state after successful bootstrap, where normal routing drives navigation | Ready, loaded |
| **AppInitializationError** | The app state when bootstrap fails and the user is shown recovery/retry UI | Crash, failure |
| **OfflineNoUserState** | The app state when no cached user exists and the device is offline at startup | Offline error |
| **BootstrapResult** | The typed outcome of `_bootstrap()` — either `initialized` or `offlineNoUser` — used to preserve branching through `Future.wait` | Return value, status |

### Dependency Initialization

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **Startup-critical module** | A dependency that must be available before first-frame-critical flow | Core module (too vague) |
| **Deferred module** | A dependency that can be initialized after async resolution without blocking first frame | Late module, lazy module (conflicts with DI lazy semantics) |
| **Phased bootstrap** (updated) | Startup strategy where `initDataSource()` and `SharedPreferences.getInstance()` run first, then `buildModules()` registers all DI modules, then services init sequentially | Split registration, two-phase init |
| **Idempotent init guard** | A completer-based wrapper around `Supabase.initialize()` that makes it safe to call multiple times: no-op after success, resets on failure for genuine retry | Double-init guard, singleton guard |
| **Test seam** | An injectable constructor parameter (e.g., `dataSourceInitializer`, `sharedPreferencesLoader`) that defaults to the real implementation but can be replaced in tests | Mock point, hook |

### Router Lifecycle

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **Deferred router** | The pattern where `BestRouterConfig` is created lazily on first `AppInitialized` render, not during `initState()` | Lazy router |
| **Router invalidation** | Clearing the cached `_routerConfig` when the app returns to `InitializingApp` state, ensuring a fresh `RouterService` instance is used after `locator.reset()` | Router reset, router refresh |
| **App shell** | A non-router `MaterialApp` used for splash, error, and offline screens, sharing localization delegates, theme, and `Translate.init()` with the router variant | Basic MaterialApp, wrapper |
| **Router app** | The `MaterialApp.router` variant used only in `AppInitialized` state, wrapping `InternalNotificationListener` and `_AuthStatusShell` | Full app, main app |

### Retry Lifecycle

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **Retry** | The path triggered by user tap on error/offline screen: flips to `InitializingApp` before disposal, then the view schedules re-bootstrap from a post-frame callback | Restart, re-init |
| **Flip-before-disposal** | The safety invariant where `appStateNotifier.value = InitializingApp` is set before `_disposeServices()` and `locator.reset()`, preventing widgets from reading disposed services | State-first reset |
| **View-driven re-bootstrap** | The pattern where `retryInitialization()` only cleans up, and the view's `ValueListenableBuilder` schedules `initializeApp()` via post-frame callback when it sees `InitializingApp` | ViewModel-driven retry |

### Theming Policy

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **Dark-first route** | A route policy that always renders with dark theme regardless of system setting | Dark mode route |

---

## Relationships

- A **Cold start** shows the **Native launch surface**, then the **Flutter splash**, then the app
- The **Bootstrap** runs concurrently behind the **Flutter splash** during **InitializingApp**
- The **Minimum splash duration** and **Bootstrap** are raced via `Future.wait` — whichever is slower determines when the state transition happens
- **BootstrapResult** determines the terminal state: `initialized` → **AppInitialized**, `offlineNoUser` → **OfflineNoUserState**, exception → **AppInitializationError**
- The **Deferred router** depends on **AppInitialized** — it is never created during **InitializingApp**
- **Router invalidation** is triggered by **Retry**, which returns the app to **InitializingApp**
- The **App shell** renders during **InitializingApp**, **OfflineNoUserState**, and **AppInitializationError**; the **Router app** renders only during **AppInitialized**
- The **Idempotent init guard** makes the **Bootstrap** safe across **Retry** cycles
- An **Offering** contains one or more **Packages**; each **Package** holds one **RevenueCat Product** per store
- A **RevenueCat Entitlement** ("pro") is unlocked by one or more **RevenueCat Products** across **Test Store** and **App Store app**
- A **Hosted Paywall** is paired to exactly one **Offering** and renders its **Packages** as purchasable options
- **Restore Purchases** re-syncs store receipts and refreshes the **RevenueCat Entitlement** — accessible from both the **Hosted Paywall** and the Settings **Manage Subscription** area
- An **Introductory Offer** is configured per product in App Store Connect; RevenueCat reads it and the **Hosted Paywall** renders it automatically via template variables
- **RevenueCat** is the source of truth for the **RevenueCat Entitlement**; the persisted **Subscription Status** is a cache written *only* by the **Webhook (RevenueCat)**; the **Entitlement** value object prefers the live **EntitlementSnapshot** (when scoped to the user) and falls back to the cached **Subscription Status** otherwise
- **`isPremium`** ⊂ **`canAccessPremium`**: they differ by exactly **`trial`** (canAccessPremium includes it, isPremium does not); **both include `grace`**
- A **Stack** contains zero or more **Active Protocols**, ordered by **Activation** time
- The **Protocol Limit** is determined by **Effective Status** via `SubscriptionStatus.protocolLimit`, not by a hard-coded literal — `free`/`expired` → 2, all others → unlimited
- A **Downgrade** does not itself trim the **Stack** — if **Stack** count exceeds the new **Protocol Limit**, the **Protocol Selection Modal** prompts a **Stack Trim** as a *response* to the downgrade
- The **Protocol Selection Modal** is a **Selector**: it returns **KeepIds**; the caller (`HomeViewModel.confirmProtocolDeactivation`) owns persistence
- `applyProtocolLimitSelection(keepIds)` is the canonical **Stack Trim** operation — emits N `ProtocolDeactivatedEvent`s for **Removed IDs**, never mutates **Subscription Status**
- `markTrialExpiredDecisionResolved` runs only when `confirmProtocolDeactivation` returns `true` — the **Decision-Store Guard**
- **Same-Session Retry** re-opens the **Protocol Selection Modal** with **Initial Selection** = previous **KeepIds**; max 2 modal attempts before falling through to next-launch retry

---

## Example Dialogue

> **Dev:** "When the user taps retry on the error screen, what happens to the **Deferred router**?"
> **Domain expert:** "The **Retry** flips to **InitializingApp** first — that's the **Flip-before-disposal** invariant. The view sees **InitializingApp**, triggers **Router invalidation** to clear the stale `BestRouterConfig`, then schedules **View-driven re-bootstrap** from a post-frame callback."
> **Dev:** "So the 500ms timer starts after the **Flutter splash** repaints?"
> **Domain expert:** "Exactly. That's the **Frame-anchored timing** — the **Minimum splash duration** begins after the splash frame paints, not when `retryInitialization()` is called. On both **Cold start** and **Retry**, the entrance animation gets its full 500ms."
> **Dev:** "What if `initDataSource()` already succeeded on the first attempt?"
> **Domain expert:** "The **Idempotent init guard** handles that — second call is a no-op after success. If the first attempt failed, the guard resets so **Retry** genuinely re-attempts Supabase initialization."

> **Dev:** "Should trial users see **Manage Subscription** in Settings?"
> **Domain expert:** "Yes — **Manage Subscription** is visible when **`canAccessPremium`** is true, which includes trial users. A trial user might want to cancel before being charged. Don't gate it on **`isPremium`** — that excludes trials."
> **Dev:** "And **Restore Purchases** — is that only on the **Hosted Paywall**?"
> **Domain expert:** "Both. Apple requires it accessible from outside the paywall too. We add a Settings tile visible to ALL users — even free users who might have lost their **RevenueCat Entitlement** after a reinstall. The tile calls `RevenueCatService.restorePurchases()`, not `Purchases.syncPurchases()` — restore is user-initiated only."
> **Dev:** "What about the 7-day trial? The **Hosted Paywall** says 'free trial' but the **RevenueCat Products** show `trial_duration: null`."
> **Domain expert:** "That's a configuration gap. For **Test Store**, set trial duration directly in RevenueCat. For the **App Store app**, create an **Introductory Offer** in App Store Connect — RevenueCat reads it from there. The **Hosted Paywall** uses template variables like `{{ product.offer_period_with_unit }}` so it auto-renders the trial terms once configured."

> **Dev:** "After the user taps 'Use Free Tier' with 4 active protocols, who actually does the downgrade?"
> **Domain expert:** "Be careful with 'downgrade' here. The **Webhook (RevenueCat)** is the only writer of **Subscription Status**. What the client does in response is a **Stack Trim** — the **Protocol Selection Modal** asks for **KeepIds**, then `applyProtocolLimitSelection` on the **User** aggregate returns a new User with the **Stack** reduced. **Subscription Status** is untouched."
> **Dev:** "And when does `markTrialExpiredDecisionResolved` run?"
> **Domain expert:** "Only after `confirmProtocolDeactivation` returns `true`. That's the **Decision-Store Guard**. If we resolved the decision after a failed save, **Last-Seen Status** would record `free` and the **Trial Expired Modal** would be suppressed on next launch — the user gets trapped over-limit."
> **Dev:** "What if save fails the first time?"
> **Domain expert:** "**Same-Session Retry**: we reload state, and if **Stack** count is still above the **Protocol Limit**, we re-open the **Protocol Selection Modal** with **Initial Selection** set to the previous **KeepIds** so the user doesn't have to re-pick. One re-open max. On the second failure we exit with the decision unresolved and the **Trial Expired Modal** retriggers on next launch."
> **Dev:** "Why is the modal a **Selector** instead of doing the save itself?"
> **Domain expert:** "Atomicity and testability. As a **Selector** it's a pure state machine over selection; the caller `HomeViewModel.confirmProtocolDeactivation` owns retry-once, toast, and reload — the same shape as `LibraryViewModel`'s add/remove path. If the modal owned its own async save, we'd duplicate that error-handling and break the architectural pattern that says repository writes live in view models."

---

## Flagged Ambiguities

- **"Entitlement"** is overloaded across **three** distinct things — always qualify:
  - **Entitlement** (bare, canonical) — the domain value object (`lib/paywall/domain/entitlement.dart`), the resolved "what can this user do right now," computed by `Entitlement.of(user, snapshot)`. ⏳ Lands in #17.
  - **EntitlementSnapshot** — the raw RevenueCat input read (`hasProEntitlement`, trial/grace flags, product id…). The input, not the answer.
  - **RevenueCat Entitlement** ("pro") — the store-dashboard entitlement RevenueCat owns and is the source of truth for. This is what File 1 used to call simply "Entitlement."
- **`SubscriptionStatusResolver`** is **being deleted** (#21) — it is *not* canonical vocabulary. Its resolution + status-mapping logic moves into **Entitlement** (private impl); its two modal-decision functions move into **Trial Expiry Policy**. It still exists and is load-bearing in the running code until #21 merges; new code should target **Entitlement** / **Trial Expiry Policy**. Likewise `CheckEligibilityUseCase` is removed by the epic (its delegation folds into the caller computing the limit from **Entitlement** and calling `canLogSession(id, limit:)`).
- **"splash screen"** was used to mean both the **Native launch surface** (OS-rendered) and the **Flutter splash** (Dart widget). These are distinct: the native surface covers engine startup, the Flutter splash covers **Bootstrap**. Always qualify which one.
- **"restart"** was used interchangeably with **Retry**. In this codebase, `restartApp()` in `AppLifecycleService` delegates to `retryInitialization()` in `StartupViewModel`. Use **Retry** for the user-facing concept and `restartApp()`/`retryInitialization()` for the code path.
- **"delay"** was used to describe the **Minimum splash duration**, but it is not an artificial delay — it is a floor that only adds wait time when **Bootstrap** is faster than 500ms. Prefer "minimum duration" over "delay."
- **"pre-runApp work"** (from the previous glossary) is now obsolete — after the refactor, there is no async work before `runApp()`. The term is replaced by **Bootstrap**, which runs after `runApp()` inside `initializeApp()`.
- **"Cancel Subscription"** was the UI label in Settings, but the action opens subscription management (not just cancellation). Resolved: renamed to **Manage Subscription**. The old label persists in specs and code (`onCancelSubscriptionTap`) until fn-81 is complete — do not use "Cancel Subscription" in new code.
- **"isPremium"** vs **"canAccessPremium"** — both are properties of the `SubscriptionStatus` enum. `canAccessPremium` is `true` for `trial`, `premiumMonthly`, `premiumAnnual`, `grace`; `isPremium` is `true` for `premiumMonthly`, `premiumAnnual`, `grace` only. They differ by **exactly `trial`**, and **both include `grace`**. Use **canAccessPremium** when gating features that trial users should access (e.g., **Manage Subscription** tile). Use **isPremium** only when you need to distinguish paid subscribers from trial users.
- **"Product"** is overloaded: **RevenueCat Product** (a purchasable item in RC), App Store Connect product (an IAP in Apple's system), and "the product" (the Neurostack app). Always qualify with the system name.
- **"Trial"** has two meanings: **Premium Trial** (the 7-day access period the user experiences) vs **Introductory Offer** (Apple's configuration mechanism in App Store Connect). Use **Premium Trial** for the user-facing concept and **Introductory Offer** for the store configuration.
- **"Deactivation Modal"** vs **"Protocol Selection Modal"** — the legacy spec section heading (`screen-functional-specifications.md` § 10) reads "Deactivation Modal", but every user-facing label says "Choose 2 Protocols to Keep". Canonical: **Protocol Selection Modal**. The word "deactivation" describes what the modal *causes* (via the resulting `ProtocolDeactivatedEvent`s), not what the user *does*. "Deactivation Modal" persists only in the legacy spec heading; do not use it in new code, tests, or docs.
- **"Active"** is overloaded across protocols and subscriptions: an **Active Protocol** lives in the **Stack**; an "active subscription" means **Subscription Status** ∈ `{trial, premium*, grace}`. Always qualify — never bare "active" in domain conversation.
- **"Trim"** vs **"Prune"** vs **"Batch Deactivation"** — canonical: **Stack Trim** is the multi-protocol operation that reduces the **Stack** to the **Protocol Limit**; **Deactivation** is the single-protocol operation. "Prune" is not used.
- **"Downgrade"** is strictly a **Subscription Status** transition driven by the **Webhook (RevenueCat)**. The client never *performs* a downgrade — it only performs a **Stack Trim** in response. Saying "the modal downgrades the user" is wrong; the modal trims the stack while the downgrade is webhook-driven.
- **"Subscription Status"** vs **"Effective Status"** — **Subscription Status** is the raw, webhook-written cache field on **User**; **Effective Status** is what the **Entitlement** value object returns (`Entitlement.of`; ⏳ `SubscriptionStatusResolver` until #21) after consulting the RevenueCat snapshot and **Last-Seen Status**. UI gating decisions and **Protocol Limit** use **Effective Status**. They diverge only when the live snapshot disagrees with the stale cache.
- **"Selection"** is overloaded: in this build it means the user's transient set of selected rows in the **Protocol Selection Modal**, captured at confirm time as **KeepIds**. Do not conflate with the **Entitlement** value object's resolution of effective status.
