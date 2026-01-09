# **🗣️ UBIQUITOUS LANGUAGE**

## **Monetization Terms**

**Free Tier** (noun)

- Definition: Permanent access to core functionality with 2 protocol limit
- Properties: No time limit, no credit card required, full tracking capability
- Constraint: Can only activate 2 protocols simultaneously
- UI Label: "Free" or "Basic"

**Premium Trial** (noun)

- Definition: 7-day period with full access to all protocols and features
- Properties: Auto-activates on first launch, no credit card required
- Behavior: Reverts to Free Tier automatically after 7 days if not subscribed
- UI Label: "Premium Trial" or "Trial"

**Trial Status** (enum)

- Definition: Current state of user's trial period
- Values: `active` (days 1-7), `expired` (day 8+), `converted` (subscribed)
- Calculation: `trialStartDate + 7 days`
- UI Label: "X days left in trial"

**Premium Subscription** (noun)

- Definition: Paid tier unlocking unlimited protocols
- Tiers: Monthly ($7.99) or Annual ($59.99 - 37% off monthly)
- Properties: Auto-renewing, managed by RevenueCat (StoreKit SDK wrapper)
- UI Label: "Premium" or "Pro"

**Subscription Status** (enum)

- Definition: User's payment state
- Values: `trial`, `free`, `premiumMonthly`, `premiumAnnual`, `expired`, `grace`
- UI Label: Hidden from user (internal only)

**Protocol Limit** (computed property)

- Definition: Maximum number of protocols user can activate
- Values:
  - Free Tier: 2
  - Premium Trial: Unlimited
  - Premium: Unlimited
- UI Label: "X/2 protocols active" (free) or "Unlimited" (premium)

## **Core Domain Terms**

**Protocol** (noun)

- Definition: A science-backed routine with specific parameters (e.g., "Norwegian 4x4 HIIT")
- Properties: Name, Target Specification, Frequency, Research Citation, Category
- Example: "Sauna Protocol: 20 min at 108°F, 3-4x/week (Finnish study, 2020)"
- UI Label: "Protocol"

**Session** (noun)

- Definition: A single instance of completing a protocol
- Properties: Protocol ID, Timestamp, Duration, Notes (optional)
- Example: "Sauna session on Nov 21, 2025, 22 minutes"
- UI Label: "Session" or "Log"

**Target** (noun)

- Definition: The ideal specification for a protocol (frequency, duration, intensity)
- Properties: Frequency (e.g., "3-4x/week"), Duration (e.g., "20 min"), Intensity (e.g., "108°F")
- Example: "Target: 40 min at 65% max HR"
- UI Label: "Target"

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

**Stack** (noun)

- Definition: A user's collection of active protocols
- Properties: List of Protocol IDs
- Example: "My morning stack: Sunlight, Cold Shower, Zone 2"
- UI Label: "Your Stack" or "Active Protocols"

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

## **⚖️ CORE INVARIANTS** (Must ALWAYS be true)

### **Monetization Invariants**

```sh
INV-M1: Free Tier MUST have no time limit
→ Rationale: "Free forever" promise, ethical design
→ Enforcement: No expiration date on free tier
→ Test: User can use free tier indefinitely with 2 protocols

INV-M2: Premium Trial MUST last exactly 7 days
→ Rationale: Standard trial period, conversion optimization
→ Enforcement: trialStartDate + 7 days calculation
→ Test: Trial expires at exactly 168 hours after first launch

INV-M3: Premium Trial MUST NOT require credit card
→ Rationale: Lower friction, better mobile UX, App Store compliance
→ Enforcement: No payment info collection during trial
→ Test: User can start trial without entering payment method

INV-M4: After trial expiration, user MUST revert to Free Tier automatically
→ Rationale: No surprise charges, ethical conversion
→ Enforcement: Background job checks trial status, adjusts protocol limit
→ Test: On day 8, user with 5 protocols sees paywall when trying to log

INV-M5: Free Tier users CANNOT activate more than 2 protocols
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

### **Protocol Invariants**

```sh
INV-P1: Every Protocol MUST have at least one Research Citation
INV-P2: Protocol Target specifications MUST be measurable
INV-P3: Protocol names MUST NOT include researcher names
INV-P4: Deleted Protocols MUST preserve historical Session data
```

### **Session Invariants**

```sh
INV-S1: A Session MUST belong to exactly one Protocol
INV-S2: Session timestamp CANNOT be in the future
INV-S3: Session duration MUST be > 0 if specified
```

### **User Invariants**

```sh
INV-U1: Free Tier users CANNOT activate more than 2 protocols
→ Rationale: Freemium paywall, unlimited during trial
→ Enforcement: UI + API validation + trial status check
→ Logic: IF subscriptionStatus IN ['free'] THEN activeProtocolIds.count <= 2

INV-U2: Premium Trial users CAN activate unlimited protocols
→ Rationale: Showcase full value during trial
→ Enforcement: Feature flag check
→ Logic: IF subscriptionStatus == 'trial' THEN no protocol limit

INV-U3: Trial MUST auto-activate on first app launch
→ Rationale: No friction, immediate value demonstration
→ Enforcement: Onboarding sets trialStartDate
→ Test: Fresh install = trial active immediately

INV-U4: Users MUST complete onboarding before tracking Sessions
→ Rationale: Set expectations, legal disclaimer
→ Enforcement: Onboarding flow gate

INV-U5: Expired trial users with >2 active protocols CANNOT log new sessions
→ Rationale: Force subscription or protocol deactivation
→ Enforcement: Session logging checks protocol count + subscription status
→ Test: Day 8 user with 5 protocols sees "Deactivate 3 protocols or upgrade" modal
```

### **Business Invariants**

```sh
INV-B1: Trial period MUST be exactly 7 days
→ Rationale: Industry standard, faster conversion cycle
→ Enforcement: Subscription configuration

INV-B2: Paywall MUST trigger when Free Tier user tries 3rd protocol
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
