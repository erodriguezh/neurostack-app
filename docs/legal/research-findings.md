# Community-Vetted Evidence for NeuroStack Privacy Policy and Terms

**NeuroStack — an Austria-based, iOS-only, adult-only wellness subscription app — needs a Privacy Policy and Terms of Use grounded in real founder, developer, and practitioner experience, not generator marketing.** This report synthesizes evidence from 30+ substantive community discussions, comparable app analyses, and official cross-checks across Reddit, Hacker News, Indie Hackers, Apple Developer Forums, RevenueCat Community, GitHub, heise.de, and Austrian legal sources. The strongest signal: wellness session data (including timestamps, duration, and free-text notes) almost certainly qualifies as GDPR Article 9 "special category" health data, requiring explicit consent and likely a Data Protection Impact Assessment under Austrian law. Every drafting decision downstream flows from this classification.

---

## Key Additions from Extended Community Thread Analysis

Several additional community-sourced findings were identified from a second research pass targeting RevenueCat support threads, Sentry/Supabase GitHub issues, and Reddit developer forums. These are integrated into the ranked evidence below and cross-referenced in the consensus sections. The most impactful net-new findings:

1. **Magic link email prefetching breaks authentication** (Supabase auth GitHub #713): Enterprise email security scanners "click" magic links to test for malware, consuming the single-use token before the human user opens it. NeuroStack's Terms must disclaim liability for authentication failures caused by third-party email infrastructure, and the technical architecture should fall back to numeric OTP (`{{.Token}}`) instead of `{{.ConfirmationURL}}` in Supabase email templates.

2. **5 mandatory Apple EULA override clauses** (Reddit r/iOSProgramming): When deploying a custom Terms of Use instead of Apple's default EULA, the custom document **must** include: (a) acknowledgment that the agreement is solely between user and developer (excluding Apple); (b) defined scope of non-transferable license; (c) maintenance and support disclaimers; (d) warranty limitation provisions; (e) intellectual property rights clauses. Omitting any of these risks administrative flagging.

3. **Exact trial-to-paid conversion phrasing that passed App Review** (Reddit r/androiddev, RevenueCat community): The words "auto-renewable" or "automatically renew" must appear literally in the UI copy. Acceptable: *"After the free trial period ends, a subscription fee will automatically be charged. The subscription will automatically renew at the end of the paid period. You can cancel the subscription at any time by navigating to your Account Settings."* Marketing shorthand like "7 days free, then $50/yr" **will** trigger a policy violation.

4. **Austrian Impressum requires triple-statute compliance** (WKO official PDF, https://www.wko.at/oe/internetrecht/das-korrekte-website-impressum.pdf): The Impressum is not just ECG § 5 — it must simultaneously satisfy the Media Act (MedienG § 25) and the Commercial Code (UGB § 14). It must stand as a **separate navigational element**, not merged into the Privacy Policy. Required fields: registered company name, legal form, Firmenbuchnummer, registry court, UID-Nummer, physical address, and **at least two direct contact methods** (email + phone).

5. **Sentry SDK transmits IP address before consent by default** (GitHub getsentry/sentry-unity #851, https://github.com/getsentry/sentry-unity/issues/851): The SDK captures connection IP on iOS automatically at init time. Either gate Sentry initialization behind a consent banner, or configure server-side IP scrubbing. This is the highest-risk inadvertent GDPR violation in the current stack.

6. **UserOrient feedback licensing clause** (community consensus for public feedback portals): The Terms should grant NeuroStack a perpetual, royalty-free license to use any feature requests, suggestions, or feedback submitted through the UserOrient board, without compensation or attribution. This is standard for public feedback tools and prevents IP disputes over implemented feature suggestions.

7. **RevenueCat community confirms aggressive Guideline 3.1.2 enforcement** (https://community.revenuecat.com/general-questions-7/app-store-rejection-subscription-info-missing-from-binary-6354, May 2025, 123 replies): Legal links must be on the **paywall screen itself**, not in a settings menu. Both the Terms of Use URL and Privacy Policy URL must be functional, visible, tappable links on the subscription purchase page. RevenueCat paywalls support Footer Links for this purpose.

8. **Magic link token invalidation by email prefetching** (https://github.com/supabase/auth/issues/713): Multiple developers report persistent "token not found" errors because corporate email security scanners (Microsoft Defender, Barracuda, Proofpoint) proactively click links. The recommended workaround: use `{{.Token}}` (numeric OTP) instead of `{{.ConfirmationURL}}` in Supabase email templates. Terms must disclaim liability for email infrastructure interference.

---

## Ranked Evidence

### Rank 1
- **Drafting topic tags:** `wellness-disclaimer`, `terms`, `privacy-policy`, `App-Store-review`
- **Source title:** WHOOP/FDA Warning Letter Case Study — Disclaimer Failure in Wellness Wearable
- **Platform:** Multiple legal analysis sites (The FDA Group Insider, Arnold & Porter, Duane Morris, TestLabsUK)
- **URLs:** https://insider.thefdagroup.com/p/fda-warning-letter-breakdown-whoop, https://www.arnoldporter.com/en/perspectives/advisories/2025/09/fda-warning-letter-to-fitness-wearable-sponsor
- **Exact source date:** 2025-07-17 (FDA warning letter 2025-07-14)
- **Region relevance:** Global (with EU MDR/DiGA parallel)
- **Community engagement signals:** Extensive professional legal community discussion; HN thread referencing Oura/wearable regulatory gray zone
- **Community sentiment summary:** Universal recognition that text disclaimers alone do not override objective product intent. The FDA explicitly ruled WHOOP's "not a medical device" disclaimer insufficient because the feature's UI design, marketing language, and user behavior signaled medical utility.
- **Key drafting takeaways:** (1) "Not medical advice" disclaimer is necessary but not sufficient — actual product behavior must match. (2) Avoid traffic-light color coding for health metrics. (3) Never use "medical-grade" or "clinical-grade" in marketing. (4) Paywalling health features behind premium tiers provides zero regulatory protection. (5) User testimonials about medical use can be cited as evidence of medical intent.
- **What this warns against:** Relying solely on disclaimer text while the app's functionality, UI design, or marketing implies medical utility. Also warns against correlating biometrics with medical conditions in-app.
- **Independent corroboration:** Arnold & Porter, Duane Morris, TestLabsUK, PMC/NIH (PMC12822547) all analyzed independently with consistent conclusions.
- **Confidence:** High

### Rank 2
- **Drafting topic tags:** `GDPR-rights`, `privacy-policy`, `free-text-notes`, `processors`
- **Source title:** GDPR Article 9 — Wellness App Data as "Special Category" Health Data
- **Platform:** Taylor Wessing (law firm), gesundheitsdatenschutz.org, itsecuritycoach.com, EDPB/WP29 guidance
- **URLs:** https://www.taylorwessing.com/en/global-data-hub/2022/march---health-data, https://www.gesundheitsdatenschutz.org/html/datenschutz_med_apps.php
- **Exact source date:** 2022 (Taylor Wessing), 2023 (itsecuritycoach)
- **Region relevance:** EU/GDPR (directly applicable to Austria)
- **Community engagement signals:** Taylor Wessing is a major international law firm; gesundheitsdatenschutz.org is a recognized German data protection reference. Multiple independent analyses converge.
- **Community sentiment summary:** Strong consensus that wellness app data — session logs, timestamps, duration, and especially free-text notes — qualifies as health data under GDPR Article 9 when collected in a health/wellness context. "Health-related lifestyle habits" (Recital 35) are explicitly included. The broader the data profile over time, the more clearly it constitutes health data.
- **Key drafting takeaways:** (1) NeuroStack's session logs + timestamps + optional duration + free-text notes in a wellness context almost certainly = special category data. (2) Must use **explicit consent** (Art. 9(2)(a)) — not legitimate interest — for health data. (3) Free-text notes are especially risky: users may volunteer mental health details, symptoms, or treatment information. (4) Even aggregate wellness patterns over time can reveal health status. (5) **Additional from Kuketz Blog analysis:** journaling/diary app data in health context is unambiguously Gesundheitsdaten — the electronic nature doesn't change the classification.
- **What this warns against:** Using "legitimate interest" or "contract performance" as the legal basis for processing wellness session data. Also warns against treating free-text notes as ordinary personal data. Kuketz Blog documented systematic DSGVO violations by diary apps that failed to disclose embedded trackers.
- **Independent corroboration:** WP29/EDPB guidance, GDPR Recital 35, TermsFeed analysis, Momentum AI, GRC Solutions, Endo-App DiGA privacy policy, and Kuketz IT-Security Blog (ZDF Volle Kanne, 2024-01-10) all confirm.
- **Confidence:** High

### Rank 3
- **Drafting topic tags:** `subscriptions`, `App-Store-review`, `terms`
- **Source title:** Apple Schedule 2, Section 3.8(b) — Mandatory Subscription Disclosure Requirements
- **Platform:** Apple Developer Forums, developer blogs (Daniel Kennett), RevenueCat blog (Jacob Eiting), RevenueCat Community
- **URLs:** https://developer.apple.com/forums/thread/83355, https://ikennd.ac/blog/2018/04/app-store-subscriptions-and-you/, https://community.revenuecat.com/general-questions-7/app-store-rejection-subscription-info-missing-from-binary-6354
- **Exact source date:** 2018-04-06 (Kennett blog, principles confirmed current), May 2025 (RevenueCat rejection thread, 123 replies), multiple 2025-2026 forum rejection posts
- **Region relevance:** Global (Apple ecosystem)
- **Community engagement signals:** Multiple developer rejection stories corroborate the same 9-item disclosure list. Kennett's blog based on direct conversations with App Review. RevenueCat CEO published recommended wording template. RevenueCat community thread (May 2025) with 123 replies from staff and developers confirms ongoing aggressive enforcement.
- **Community sentiment summary:** Apple consistently rejects apps missing any of the 9 required disclosure items. The requirements apply in BOTH the app binary AND App Store metadata. Legalese cannot be hidden behind a button — must be visible in the purchase flow. **Legal links must be on the paywall screen itself**, not in a settings menu.
- **Key drafting takeaways:** Nine mandatory items: (1) subscription title; (2) length/content; (3) price; (4) "payment charged to iTunes Account at confirmation"; (5) "auto-renews unless canceled 24+ hours before end of period"; (6) "account charged for renewal within 24 hours prior to end of period" + renewal cost; (7) "manage subscriptions in Account Settings"; (8) links to Privacy Policy and Terms of Use; (9) "unused portion of free trial forfeited when subscription purchased." **Trial conversion must use exact phrasing:** "After the free trial period ends, a subscription fee will automatically be charged. The subscription will automatically renew at the end of the paid period." Marketing shorthand like "7 days free, then $50/yr" triggers policy violations. The words "auto-renewable" or "automatically renew" must appear literally.
- **What this warns against:** Hiding disclosure behind a "Subscription Terms" button (explicitly rejected by App Review). Placing subscription info only in binary or only in metadata — must be in both. Using abbreviated trial language without explicit auto-renewal wording.
- **Independent corroboration:** Multiple independent App Store rejection notices cite identical Guideline 3.1.2 language. RevenueCat community posts confirm. Reddit r/androiddev thread documents exact phrasing that passed review after prior rejection.
- **Confidence:** High

### Rank 4
- **Drafting topic tags:** `privacy-policy`, `terms`, `generator-comparison`
- **Source title:** HN "Ask HN: How do you write a 'Terms of Service' for your startup?" + Indie Hackers generator discussions
- **Platform:** Hacker News, Indie Hackers
- **URLs:** https://news.ycombinator.com/item?id=33013716, https://www.indiehackers.com/post/how-do-you-generate-privacy-policy-f4e05316c2
- **Exact source date:** 2022-09-28 (HN), 2021-01-10 (IH)
- **Region relevance:** Global
- **Community engagement signals:** HN: 16 points, 14 comments, 10+ participants including a former lawyer. IH: 13 likes, 25 comments. Multiple threads corroborate.
- **Community sentiment summary:** Strong consensus on a graduated approach: launch with a generator or open-source template, get lawyer review once traction exists. But health/wellness data pushes toward "get a lawyer sooner." Basecamp CC-licensed policies (GitHub) are the most-recommended open-source starting point across both platforms. An EU-based practicing lawyer on IH warned that GDPR enforcement is reaching smaller startups. **Generators are "good enough" for initial compliance provided the developer meticulously inputs their specific third-party SDKs** — but generators rely entirely on the developer accurately understanding their tech stack.
- **Key drafting takeaways:** (1) ToS has three layers: party identification + definitions, core commercial terms (domain-specific — this is where lawyer value is highest), and general boilerplate. (2) Basecamp policies (https://github.com/basecamp/policies) CC BY 4.0 are the gold-standard free template. (3) Automattic/Legalmattic (https://github.com/Automattic/legalmattic) is the secondary recommendation. (4) Include "right to update" clause. (5) Match "governing law" clause to your actual jurisdiction (Austria). (6) Lawyer cost estimate: $750–$1,000 for standard app ToS. (7) **Treat generated documents as living frameworks** — manual intervention required to inject specifics of Supabase magic-link auth, Sentry diagnostic payloads, and RevenueCat subscription IDs.
- **What this warns against:** Blindly copying a ToS from a company in a different jurisdiction. Generic templates miss domain-specific commercial terms. Free generators lack full GDPR compliance. Absolute terms ("we will never") create inflexible promises. **Copying another app's legal docs is legally dangerous** — jurisdictional differences (CCPA vs Austrian GDPR) render direct plagiarism invalid.
- **Independent corroboration:** Basecamp policies recommended in 5+ independent threads across HN and IH. Generator-then-lawyer approach confirmed in 4+ independent discussions.
- **Confidence:** High

### Rank 5
- **Drafting topic tags:** `subscriptions`, `terms`, `privacy-policy`
- **Source title:** Austrian Subscription Auto-Renewal Consumer Protection (KSchG § 6)
- **Platform:** Ombudsstelle.at (Austrian Internet Ombudsman)
- **URLs:** https://www.ombudsstelle.at/abo-fallen/mein-abo-hat-sich-automatisch-verlaengert-geht-das-so-einfach/, https://www.ombudsstelle.at/abo-fallen/wie-kann-ich-mein-abo-bzw-meine-mitgliedschaft-kuendigen/
- **Exact source date:** Current (government resource)
- **Region relevance:** Austria (primary)
- **Community engagement signals:** Official Austrian government consumer protection resource — authoritative for Austrian law
- **Community sentiment summary:** Austrian consumer law is **stricter than many EU jurisdictions** on subscription auto-renewal. Three mandatory requirements under KSchG § 6 Abs 1 Z 2 must be met.
- **Key drafting takeaways:** (1) A mention of auto-renewal only in AGB at registration is NOT sufficient — user must receive a **separate notice before renewal** that silence equals consent. (2) A reasonable cancellation period must be provided. (3) Under § 6 Abs 1 Z 4 KSchG, companies **cannot require specific cancellation forms** — cancellation by simple email must be accepted. (4) Deleting the app does NOT constitute cancellation — must communicate this explicitly. (5) Under FAGG § 4, users must be informed about subscription duration, minimum term, and cancellation conditions. Note: For App Store subscriptions managed by Apple, much of this is handled by Apple's infrastructure, but your Terms must still be clear.
- **What this warns against:** Burying auto-renewal terms in general AGB. Requiring in-app-only cancellation. Failing to send pre-renewal notices.
- **Independent corroboration:** WKO (Austrian Chamber of Commerce) and Austrian ABGB § 879 Abs 3 confirm; German analogues (BGB updates March 2022) partially corroborate for DACH.
- **Confidence:** High

### Rank 6
- **Drafting topic tags:** `processors`, `privacy-policy`, `GDPR-rights`
- **Source title:** Supabase GDPR Compliance — DPA, Data Regions, Sub-Processors + Magic Link Prefetching Issue
- **Platform:** GitHub Discussions (Supabase org), GitHub Issues (Supabase auth)
- **URLs:** https://github.com/orgs/supabase/discussions/2341, https://github.com/supabase/auth/issues/713
- **Exact source date:** Started 2021-07-12 (GDPR discussion), answered 2022-05-11, active through 2024. Auth issue #713 active through 2026.
- **Region relevance:** EU/GDPR
- **Community engagement signals:** GDPR thread: 8 comments, 20 replies, 19 upvotes. Auth #713: multiple developer workarounds documented with active maintainer engagement.
- **Community sentiment summary:** Supabase provides DPA (governed by Irish law, SCCs for transfers). EU data regions available (Frankfurt). Not on EU-US Data Privacy Framework but uses SCCs. **Critical operational finding:** enterprise email security scanners proactively click magic links, consuming single-use tokens before humans open them, causing persistent "token not found" errors.
- **Key drafting takeaways:** (1) Sign Supabase DPA (available via PandaDoc). (2) Choose EU data region for GDPR compliance. (3) Disclose Supabase as processor. (4) Supabase sub-processors: AWS, Google, Fly.io, HubSpot. (5) Magic link auth stores email in Supabase Auth system. (6) Auth cookies contain JWT with user info — argue "strictly necessary" for cookie compliance. (7) **Terms must disclaim liability for authentication failures caused by third-party email infrastructure** (corporate firewalls, spam filters, security scanners invalidating tokens). (8) **Technical recommendation:** use `{{.Token}}` (numeric OTP) instead of `{{.ConfirmationURL}}` in Supabase email templates to circumvent prefetching. (9) Terms should state: user bears sole responsibility for the security, accessibility, and automated processing behaviors of their email inbox.
- **What this warns against:** Assuming EU hosting alone satisfies GDPR without DPA. Ignoring sub-processor disclosure. **Providing absolute guarantees of seamless magic-link access** without accounting for email client interference.
- **Independent corroboration:** Supabase official DPA page (https://supabase.com/legal/dpa) and TIA document confirm sub-processors. SOC 2 Type 2 compliance verified. Reddit Supabase communities report identical token invalidation failures.
- **Confidence:** High

### Rank 7
- **Drafting topic tags:** `processors`, `privacy-policy`, `subscriptions`
- **Source title:** RevenueCat Data Collection, GDPR, and Privacy Policy Requirements
- **Platform:** RevenueCat Community
- **URLs:** https://community.revenuecat.com/general-questions-7/consent-required-gdpr-eu-2252, https://community.revenuecat.com/tips-discussion-56/privacy-policy-2293, https://community.revenuecat.com/general-questions-7/how-long-is-data-stored-in-the-revenuecat-systems-1901, https://community.revenuecat.com/sdks-51/we-get-rejected-from-apple-store-review-about-restore-purchases-693
- **Exact source date:** 2022-08-XX (retention), 2022-11-15 (GDPR consent), 2022-11-26 (privacy policy)
- **Region relevance:** Global (EU implications for data transfer)
- **Community engagement signals:** 217-722 views per thread; RevenueCat staff confirmed answers. Restore purchases thread is highly trafficked technical support topic.
- **Community sentiment summary:** RevenueCat does not collect PII by default (no emails, names, IPs). Collects device type, OS, purchase history, last-seen time. Data retained for 6 years after account closure. **Must** mention RevenueCat in privacy policy — Google Play flagged an app for undisclosed API calls to api.revenuecat.com. iOS developers **cannot** cancel subscriptions on behalf of customers. **A missing or obscured "Restore Purchases" button is the single most common subscription-app rejection reason.**
- **Key drafting takeaways:** (1) Disclose RevenueCat as processor collecting purchase history and device info. (2) State 6-year retention period. (3) For anonymous IDs: purchase history not linked to identity in Apple privacy labels. (4) For custom user IDs: must declare linked purchase history. (5) Include PrivacyInfo.xcprivacy manifest. (6) Inform users they must cancel subscriptions themselves via iOS Settings. (7) Deletion via RevenueCat API/dashboard clears all data. (8) **Terms must explain restore purchases process** — subscriptions are tied to Apple ID, not device state. (9) App must feature a highly visible, instantly accessible Restore Purchases button invoking restoreTransactions.
- **What this warns against:** Omitting RevenueCat from privacy policy (triggers flagging). Promising to cancel subscriptions on users' behalf (impossible on iOS). Concealing restore mechanism behind obscure sub-menus.
- **Independent corroboration:** RevenueCat official blog (David Barnard, 2024-06-06 update), Apple privacy manifest requirements, and Apple Developer Forums confirm restore functionality is explicitly tested by App Review in sandbox.
- **Confidence:** High

### Rank 8
- **Drafting topic tags:** `processors`, `privacy-policy`, `GDPR-rights`
- **Source title:** Sentry GDPR Compliance, Mobile Privacy, Consent-Before-Init Debate
- **Platform:** Sentry official docs, Sentry blog, GitHub (getsentry/sentry-unity #851)
- **URLs:** https://sentry.io/trust/privacy/gdpr-best-practices/, https://docs.sentry.io/security-legal-pii/security/mobile-privacy/, https://sentry.io/legal/subprocessors/, https://github.com/getsentry/sentry-unity/issues/851
- **Exact source date:** Sub-processors updated 2026-03-05; DPA v5.1.0 dated 2024-05-29; GitHub issue opened 2022-06-24, multi-year thread
- **Region relevance:** Global/EU
- **Community engagement signals:** GitHub #851 has core maintainer responses with extensive thread tracing mobile consent across multiple years. Official docs used for factual cross-check.
- **Community sentiment summary:** **The default Sentry SDK initialization violates GDPR** by transmitting IP addresses and device identifiers before user consent is obtained. Under GDPR Recital 30, device IDs and IP addresses constitute PII. Developers express concern about the catch-22: gating Sentry behind consent means crashes during initial launch cannot be recorded. Sentry officially recommends obtaining opt-in consent for SDK in EU apps.
- **Key drafting takeaways:** (1) Disclose Sentry as crash reporting/diagnostic data processor. (2) Data types: crash reports, error data, performance metrics, device/OS info, randomly generated IDs, **and connection IP addresses captured at initialization**. (3) Sentry does NOT use advertising identifiers. (4) Apple privacy labels: declare under "Analytics" and "App Functionality." (5) EU region available for data residency. (6) Sub-processors include Google Cloud Platform, plus Anthropic/OpenAI for certain Sentry features. (7) **Either gate Sentry initialization behind a consent banner OR configure server-side IP scrubbing rules.** (8) Lawful basis: legitimate interest in app stability — but this is debated; explicit consent is the safer route for EU apps. (9) Additional risk: crash logs may inadvertently capture free-text inputs (calendar entries, notes) as unexpected PII payloads.
- **What this warns against:** Automatically initializing Sentry on app launch without disclosure or consent. Failing to disclose Sentry in privacy policy. Not declaring crash data in Apple privacy labels. Not noting Sentry's AI-provider sub-processors (Anthropic, OpenAI) if using Sentry's AI features. **Crash reports can inadvertently contain user-entered text** from input fields active at crash time.
- **Independent corroboration:** Sentry Help Center, Sentry Blog ("GDPR, Sentry, and You"), Sentry security page, and React Native developer discussions about crash logs capturing free-text inputs all consistent.
- **Confidence:** High

### Rank 9
- **Drafting topic tags:** `terms`, `App-Store-review`
- **Source title:** Custom EULA vs Apple Default — 5 Mandatory Override Clauses
- **Platform:** Reddit r/iOSProgramming, TermsFeed community engagement
- **URL:** https://www.reddit.com/r/iOSProgramming/comments/144pwgl/apple_requires_terms_of_use_and_privacy_policy/
- **Exact source date:** ~2023 (3 years ago per Reddit)
- **Region relevance:** Global
- **Community engagement signals:** Ongoing Q&A with developers and legal platform representatives providing exact clause requirements
- **Community sentiment summary:** Apple permits custom Terms of Use but requires specific non-negotiable boilerplate. The standard Apple EULA provides broad protections but fails to address subscription-specific mechanics, free-text notes, or wellness liability.
- **Key drafting takeaways:** When deploying custom Terms instead of Apple's default EULA, the document **must** include: (1) Acknowledgment that the agreement is solely between end-user and developer, **expressly excluding Apple**; (2) Defined scope of the non-transferable license granted; (3) Maintenance and support disclaimers (developer is solely responsible, Apple has no obligation); (4) Warranty limitation provisions; (5) Intellectual property rights clauses. Custom terms that conflict with Apple's baseline without incorporating these provisions risk administrative flagging and removal.
- **What this warns against:** Deploying custom Terms without explicitly addressing Apple's mandatory minimum requirements. If the custom terms conflict with Apple's baseline without the required boilerplate, the app risks flagging.
- **Independent corroboration:** TermsFeed representatives engage in these threads outlining exact verbatim clauses. Apple's own developer documentation confirms.
- **Confidence:** High

### Rank 10
- **Drafting topic tags:** `wellness-disclaimer`, `terms`
- **Source title:** Comparable Wellness App Disclaimer Architecture (Calm, Headspace, WHOOP, Oura, Fabulous)
- **Platform:** Direct ToS review (non-community reference) + Reddit r/apple wellness app discussion
- **URLs:** https://www.calm.com/terms, https://www.headspace.com/terms-and-conditions, https://www.whoop.com/us/en/whoop-terms-of-use/, https://ouraring.com/terms-and-conditions, https://www.thefabulous.co/terms.html, https://www.reddit.com/r/apple/comments/1ob0u75/reps_i_built_the_fitness_coach_i_couldnt_afford/
- **Exact source date:** Current (accessed April 2026)
- **Region relevance:** Global
- **Community engagement signals:** terms.law/ToS-Watchdog reviewed Calm (Grade C, 52/100). Reddit thread features direct community feedback on wellness app positioning and medical liability.
- **Community sentiment summary:** All five apps follow a remarkably consistent 9-element disclaimer architecture. Reddit community warns that deploying wellness apps carries substantial liability risk if users interpret tracking data as medical instruction.
- **Key drafting takeaways:** Standard architecture: (1) negative identity statement ("we are NOT a medical provider"); (2) purpose limitation ("informational/wellness only"); (3) no-substitute clause; (4) affirmative user duty to seek professional advice; (5) no-delay clause; (6) no doctor-patient relationship; (7) assumption of risk; (8) no-guarantee clause; (9) emergency redirect. **Headspace uniquely warns** about worsening psychiatric conditions with meditation. **Fabulous prohibits** using the service for "medical, pharmaceutical or clinical purposes." **WHOOP discloses** specific sensor accuracy limitations. All use "as is" warranty disclaimers + limitation of liability. **Community consensus: this disclaimer cannot be buried deep in the terms — it must be a core component of the initial agreement, ideally requiring explicit acknowledgment during onboarding.**
- **What this warns against:** Omitting any of the 9 elements. Headspace's psychiatric warning is a best practice that few apps adopt. Ambiguous marketing or UI terminology that blurs the boundary between wellness and clinical medicine.
- **Independent corroboration:** All five apps independently converge on the same architecture. ToS Watchdog analysis corroborates. HN and Reddit discussions confirm this as the industry-standard liability architecture.
- **Confidence:** High

### Rank 11
- **Drafting topic tags:** `GDPR-rights`, `privacy-policy`
- **Source title:** Austrian Data Protection Act (DSG) Specific Derogations from GDPR + Impressum Requirements
- **Platform:** Multiple (GDPRhub, Austrian DSB, heise.de, DLA Piper, WKO)
- **URLs:** https://gdprhub.eu/Data_Protection_in_Austria, https://data-protection-authority.gv.at/, https://www.heise.de/newsticker/meldung/Keine-Strafen-Oesterreich-zieht-neuem-Datenschutz-die-Zaehne-4031217.html, https://www.wko.at/oe/internetrecht/das-korrekte-website-impressum.pdf
- **Exact source date:** heise.de article active (874 comments); GDPRhub 2024; WKO current
- **Region relevance:** Austria (primary)
- **Community engagement signals:** heise.de article generated 874 comments showing community concern about Austrian enforcement gaps. WKO is the official Austrian Economic Chambers.
- **Community sentiment summary:** Austria has both unique protections (constitutional data protection right since 1978, age of consent at 14 not 16) and enforcement weaknesses (first-time violations often unpunished, public entities exempt from fines). DSB processed **3,813 complaints in 2024**.
- **Key drafting takeaways:** (1) Age of digital consent = **14** in Austria (not GDPR default 16). (2) Supervisory authority = DSB, Barichgasse 40-42, 1030 Vienna. (3) DPIA likely mandatory per Austrian DSFA-V for processing in "highly personal sphere." (4) Austrian TKG 2021 governs cookies/analytics. (5) **Impressum required under triple-statute compliance: § 5 ECG + § 25 MedienG + § 14 UGB.** Must be a standalone, directly accessible navigational element — not merged into Privacy Policy. Must include: company name, legal form, Firmenbuchnummer, registry court, UID-Nummer, physical address, and at least two direct contact methods (email + phone). (6) Constitutional right to data protection extends to legal persons. (7) DSB ruled Google Analytics violates GDPR for US data transfers.
- **What this warns against:** Assuming GDPR alone covers Austria — DSG adds specific requirements. Using Google Analytics without proper safeguards. **Using generic US-centric generators that fail to satisfy MedienG disclosure requirements** (Offenlegungspflicht). Merging Impressum into Privacy Policy fails the "easy and direct accessibility" test.
- **Independent corroboration:** DLA Piper, Multilaw, WKO, and GDPRhub all confirm Austrian derogations.
- **Confidence:** High

### Rank 12
- **Drafting topic tags:** `generator-comparison`, `privacy-policy`, `terms`
- **Source title:** DACH-Specific Privacy Policy and AGB Generators
- **Platform:** Multiple (Datenschutz-Generator.de, AdSimple.at, fairesrecht.at, sevdesk.at)
- **URLs:** https://datenschutz-generator.de/, https://www.adsimple.at/datenschutz-generator/, https://www.fairesrecht.at/kostenlos-datenschutzerklaerung-erstellen-generator.php
- **Exact source date:** Current
- **Region relevance:** Austria/DACH
- **Community engagement signals:** Datenschutz-Generator.de (Dr. Thomas Schwenke) is the most-referenced DACH generator with 2,500+ modules including "Software und Apps" and 50+ KI/AI service modules. AdSimple.at is Austrian-specific and attorney-reviewed.
- **Community sentiment summary:** DACH ecosystem has robust generator infrastructure. Austrian-specific generators handle DSG nuances better than Germany-only tools. All sources unanimously recommend lawyer review after generation.
- **Key drafting takeaways:** (1) Use Datenschutz-Generator.de for comprehensive German-language Datenschutzerklärung with app-specific modules. (2) Use AdSimple.at for Austrian-specific compliance. (3) Both are free for small businesses. (4) eRecht24 (€14.90/month) auto-updates when laws change. (5) fairesrecht.at explicitly warns generated text is "auf eigenes Risiko." (6) AGB are NOT legally required in Austria but strongly recommended. (7) **English-language generators (iubenda, Termly, TermsFeed) are effective for baseline compliance but must be manually adjusted for GDPR Article 37, explicit data retention periods, and DSAR mechanisms.** For Austrian app: use DACH generator for German version, English generator for English version.
- **What this warns against:** Using ChatGPT for legal texts (eRecht24 explicitly warns). Using Germany-only generators without Austrian adaptations. Copying others' AGB verbatim (copyright risk).
- **Independent corroboration:** Multiple DACH sources independently recommend Datenschutz-Generator.de.
- **Confidence:** Medium-High

### Rank 13
- **Drafting topic tags:** `terms`, `privacy-policy`, `adult-only`
- **Source title:** Age Verification Mechanics and Adult-Only Positioning
- **Platform:** Reddit r/apple, Hacker News
- **URL:** https://www.reddit.com/r/apple/comments/1lp3jzv/apple_google_king_supercell_and_more_accused_of/
- **Exact source date:** 2026 (page captured)
- **Region relevance:** Global
- **Community engagement signals:** Deep, multi-participant debate analyzing COPPA constraints, GDPR age of consent variations, and practical age verification
- **Community sentiment summary:** Document-backed age verification (passport uploads) destroys conversion funnels and introduces catastrophic data security risks. Industry relies on ToU clauses and platform-level age gates. **Proactively collecting exact birth dates creates unnecessary sensitive PII** — if you discover the user is a minor, complex deletion protocols must be triggered. A simple boolean checkbox ("I confirm I am over 18") is the risk-averse standard.
- **Key drafting takeaways:** (1) Privacy Policy and Terms must state: "This application is not directed to individuals under the age of 18. We do not knowingly collect personal information from children." (2) Set App Store content rating to 17+/18+. (3) Use boolean age-gate checkbox during onboarding — do NOT collect exact birth dates. (4) Austrian digital consent age is 14, but NeuroStack's adult-only positioning means Terms should set minimum at 18. (5) This contractual approach shifts liability to user/guardian.
- **What this warns against:** Collecting exact birth dates without infrastructure to handle minors. Building age verification databases. Inconsistent App Store age rating vs Terms.
- **Independent corroboration:** HN confirms cryptographic age verification is technically indistinguishable from mass surveillance infrastructure, driving reliance on legal disclaimers and platform age gates.
- **Confidence:** High

### Rank 14
- **Drafting topic tags:** `free-text-notes`, `GDPR-rights`, `privacy-policy`
- **Source title:** Journaling/Tagebuch App DSGVO Violations — Kuketz Blog Analysis
- **Platform:** Kuketz IT-Security Blog, intrapol.org (ZDF interview)
- **URLs:** https://www.kuketz-blog.de/android-miserabler-datenschutz-bei-tagebuch-apps/, https://intrapol.org/2024/01/10/interview-mit-zdf-volle-kanne-wie-wichtig-datensicherheit-datenschutz-bei-tagebuch-apps-sind/
- **Exact source date:** 2024-01-10 (ZDF interview)
- **Region relevance:** DACH
- **Community engagement signals:** Kuketz Blog is a widely respected German IT security expert. ZDF Volle Kanne is national German TV.
- **Community sentiment summary:** Journaling/diary apps systematically violate DSGVO by embedding Facebook SDK, Crashlytics, and other trackers without disclosure. Free-text journaling data in health context is unambiguously health data under Art. 9.
- **Key drafting takeaways:** (1) Disclose ALL third-party SDKs in Datenschutzerklärung — even crash reporting. (2) Free-text notes in wellness apps = Gesundheitsdaten. (3) "Elektronisches Tagebuch" health data cannot be differentiated from formal medical data under DSGVO. (4) Sentry must be disclosed (unlike Crashlytics users who often don't disclose).
- **What this warns against:** Embedding crash reporting or analytics SDKs without disclosure. Treating journal/notes data as non-sensitive.
- **Independent corroboration:** gesundheitsdatenschutz.org and itsecuritycoach.com independently confirm.
- **Confidence:** Medium-High

### Rank 15
- **Drafting topic tags:** `magic-link-auth`, `privacy-policy`
- **Source title:** Magic Link Authentication Privacy Implications
- **Platform:** Ping Identity, Transmit Security, Keeper Security (expert sources — limited community discussion)
- **URLs:** https://www.pingidentity.com/en/resources/blog/post/what-is-magic-link-login.html, https://transmitsecurity.com/blog/magic-link-authentication
- **Exact source date:** Various 2024
- **Region relevance:** Global
- **Community engagement signals:** Expert analysis rather than community discussion — magic link auth privacy is under-discussed in communities
- **Community sentiment summary:** Magic links support GDPR data minimization by storing no passwords. Security depends on email account security. No official standards for magic link expiration times.
- **Key drafting takeaways:** (1) Disclose: email collected for authentication, one-time time-limited tokens sent via email, no passwords stored. (2) Session tokens/JWTs stored locally on device. (3) Processing basis: contract performance (Art. 6(1)(b)). (4) Email must be retained as long as account exists. (5) Recommended link expiry: 15 minutes. (6) Risk to disclose: email compromise = full account access. (7) **Terms must state: possession of access to the email address equates to authorized access to NeuroStack. Developer indemnified against unauthorized access from compromised email accounts.**
- **What this warns against:** Not disclosing that email is the sole authentication factor. Not explaining the security model to users. Providing absolute guarantees of seamless access.
- **Independent corroboration:** Supabase GitHub discussion (#2341) confirms auth cookie/JWT concerns. Supabase auth issue #713 confirms token invalidation by email scanners.
- **Confidence:** Medium

### Rank 16
- **Drafting topic tags:** `processors`, `privacy-policy`
- **Source title:** UserOrient Privacy Policy and Disclosure Implications
- **Platform:** UserOrient official (non-community — no community discussion found)
- **URL:** https://www.userorient.com/pp
- **Exact source date:** 2024-10-25
- **Region relevance:** Global
- **Community engagement signals:** None — no community discussion found about UserOrient's privacy implications
- **Community sentiment summary:** No community evidence. UserOrient's own privacy policy is relatively thin (no DPA mention, no sub-processor list, no specific hosting location).
- **Key drafting takeaways:** (1) Disclose UserOrient as third-party processor for feature requests/feedback. (2) UserOrient collects: email, usage data, feature request text, votes. (3) UserOrient's own sub-processors: Paddle, Google Analytics, Microsoft Clarity. (4) Not intended for under-16. (5) No published DPA — may need to request one. (6) Feature request board is likely "optional" — may require separate consent under GDPR. (7) **Terms should grant NeuroStack a perpetual, royalty-free license to use feedback/suggestions without compensation or attribution** (standard for public feedback tools). (8) **Terms should state that information submitted to the feature request board may be visible to the development team and potentially other users.**
- **What this warns against:** Assuming feature request tools don't need privacy disclosure. Not having a DPA with UserOrient.
- **Independent corroboration:** None found. **No strong evidence found** for community discussion of UserOrient privacy implications.
- **Confidence:** Low (single official source, no community discussion)

---

## Cross-source consensus

### Privacy Policy takeaways for current shipped behavior

**Data classification is the foundational decision.** At least 6 independent expert/community sources confirm that NeuroStack's wellness session data (timestamps, duration, free-text notes) likely constitutes **GDPR Article 9 "special category" health data**. This was the single most consistent finding across legal analysis, DACH expert sources, and EDPB/WP29 guidance. The practical consequence: explicit consent (higher bar than standard consent) is required, not just a checkbox.

**Lawful basis mapping per data category.** The privacy policy must explicitly enumerate each data category and its corresponding lawful basis under GDPR Article 6:

| Data Category | Function | Lawful Basis |
|---|---|---|
| Email address | Magic-link auth, account recovery | Contractual necessity (Art. 6(1)(b)) |
| Internal user ID | Database mapping, subscription sync | Contractual necessity |
| Session logs / state | Progress tracking, protocol completion | Contractual necessity + **Explicit consent for health data (Art. 9(2)(a))** |
| Free-text notes | User-generated wellness journaling | **Explicit consent for health data (Art. 9(2)(a))** |
| Crash / diagnostic data | Error identification via Sentry SDK | Legitimate interest (Art. 6(1)(f)) with safeguards — or explicit consent (safer) |
| Subscription status | Purchase validation via RevenueCat | Contractual necessity |
| Onboarding state | App progression tracking | Contractual necessity |

**The privacy policy must contain these elements** (community consensus across HN, IH, and GDPR expert sources): identity/contact of the data controller; DPO contact if applicable; all 6 GDPR data subject rights (access, rectification, erasure, restriction, portability, objection); legal basis for **each** processing activity; data categories collected; retention periods or criteria; right to complain to DSB (full address: Barichgasse 40-42, 1030 Vienna); international transfer mechanisms; all third-party processors by name and purpose; whether automated decision-making is used.

**Austrian-specific additions**: Standalone Impressum under triple-statute compliance (§ 5 ECG + § 25 MedienG + § 14 UGB) as a separate navigational element — not merged into Privacy Policy. Must display: company name, legal form, Firmenbuchnummer, registry court, UID-Nummer, physical address, and at least two direct contact methods. Age of digital consent = **14** (not 16).

**GDPR Subject Rights and Deletion Mechanics.** Community consensus validates that instructing users to email feedback@getneurostack.app to request account termination and data erasure satisfies baseline GDPR and Apple App Store requirements for an early-stage launch. Complex automated self-service portals are unnecessary at this stage.

**Free-text notes liability.** The policy should warn users against inputting highly sensitive PII or medical data into general text fields. Free-text fields present latent GDPR liability — if users voluntarily input medical histories, the platform becomes a processor of special category data beyond what was explicitly prepared for.

**Third-party processor disclosure must name each service explicitly.** RevenueCat Community confirmed Google Play flagged an app for undisclosed api.revenuecat.com calls. Kuketz Blog documented DSGVO violations from undisclosed crash reporting SDKs. The consensus is clear: name Supabase, RevenueCat, Sentry, and UserOrient with their data types, purposes, and retention periods.

**Retention periods must be specified per data category.** Community consensus (HN, IAPP, heydata.eu): active user data retained while account exists; session logs 12–24 months then anonymize/delete; backups stated period with deletion-request log for re-application; diagnostics 7–90 days; RevenueCat retains 6 years after account closure. GDPR does not prescribe specific periods — you must define and justify your own.

### Terms / Terms of Use takeaways for current shipped behavior

**The 9-element wellness disclaimer architecture is industry standard** and must be prominent — not buried. Community consensus says it should be a core component of the initial agreement, ideally requiring explicit acknowledgment during onboarding. All five comparable apps converge on: negative identity statement, purpose limitation, no-substitute clause, user duty to seek professional advice, no-delay clause, no doctor-patient relationship, assumption of risk, no-guarantee clause, emergency redirect. **Headspace's psychiatric-worsening warning** is a best practice worth adopting.

**5 mandatory Apple EULA override clauses.** When deploying custom Terms instead of Apple's default EULA: (1) agreement is solely between user and developer, excluding Apple; (2) scope of non-transferable license; (3) maintenance and support disclaimers; (4) warranty limitation provisions; (5) intellectual property rights clauses.

**Limitation of liability and "as is" warranty disclaimers are universal.** Cap financial liability to maximum extent permitted by Austrian and EU consumer protection law. Preclude damages for perceived failure to induce desired wellness outcomes.

**Account security redefined for magic links.** Terms must specify: user bears sole responsibility for the security of their email inbox. Possession of email access = authorized NeuroStack access. Developer indemnified against unauthorized access from compromised email accounts or intercepted tokens. **Explicitly disclaim liability for authentication failures caused by corporate email security scanners, spam filters, or other third-party email infrastructure.**

**Austrian consumer law adds subscription-specific requirements.** Under KSchG § 6: auto-renewal requires separate pre-renewal notice; users cannot be required to use specific cancellation forms — email cancellation must be accepted; deleting the app does not cancel subscription (state this explicitly). Under FAGG § 4: inform about duration, minimum term, and cancellation conditions.

**Restore purchases.** Terms must explain that subscriptions are tied to Apple ID, not device state. Instruct users on restoration process. App must feature highly visible Restore Purchases button.

**Right to update clause is essential.** Include notification mechanism for material changes.

**Adult-only positioning.** Clear "intended for users aged 18+" statement with boolean age-gate checkbox during onboarding — do NOT collect exact birth dates. Set App Store rating to 17+/18+.

**UserOrient feedback licensing.** Terms should grant perpetual, royalty-free license to use feedback/suggestions without compensation or attribution. State that submissions may be visible to the development team and potentially other users.

### Processor/disclosure patterns for Supabase, RevenueCat, Sentry, and feature-request tooling

**Supabase:** Disclose as backend and authentication processor. Data: email address (magic link auth), user account data, session tokens. Hosting: specify EU region (Frankfurt). Transfer mechanism: SCCs governed by Irish law. Sub-processors: AWS, Google, Fly.io, HubSpot. DPA available via PandaDoc. Auth cookies contain JWT with personal data — classify as "strictly necessary." **Technical note: enterprise email scanners consume magic link tokens — use OTP fallback (`{{.Token}}`) in Supabase email templates.**

**RevenueCat:** Disclose as subscription management processor. Data: purchase history, device type, OS, transaction info, last-seen time. Retention: **6 years** after account closure. US-based — requires transfer mechanism (SCCs or DPF). If using anonymous IDs only, purchase history not linked to identity in Apple privacy labels. iOS limitation: developer cannot cancel subscriptions on behalf of users — Terms must state users cancel via iOS Settings. Include PrivacyInfo.xcprivacy manifest.

**Sentry:** Disclose as crash reporting/diagnostics processor. Data: crash reports, error data, performance metrics, device/OS info, randomly generated per-installation IDs, **connection IP addresses (captured at SDK init)**. Does NOT collect IDFA. Does NOT track users. EU data residency option available. DPA available in-app. Apple privacy labels: "Analytics" and "App Functionality." Sub-processors include GCP plus Anthropic/OpenAI for certain Sentry features. **Either gate initialization behind consent banner or configure server-side IP scrubbing.** Risk: crash logs may inadvertently capture user-entered free-text from active input fields.

**UserOrient:** Disclose as feature request/feedback processor. Data: email (if linked), feature request text, votes. Sub-processors: Paddle, Google Analytics, Microsoft Clarity. **No published DPA** — request one. Processing basis: likely requires separate consent since feature board is optional. **No strong community evidence found** for UserOrient-specific privacy patterns.

### App Store/subscription disclosure patterns

Apple's **9-item subscription disclosure checklist** (Schedule 2, Section 3.8(b)) is the hard floor. Multiple developer rejection stories confirm strict enforcement — including a 123-reply RevenueCat thread from May 2025. Required in **both** the app binary and App Store metadata. **Legal links must be on the paywall screen itself**, not in settings. RevenueCat paywalls support Footer Links for Terms of Service URL and Privacy Policy URL. **Trial conversion must use exact "automatically renew" phrasing** — marketing shorthand triggers violations. **Apple requires account deletion capability** since June 2022 — aligns with GDPR right to erasure. **Apple's privacy manifest** (PrivacyInfo.xcprivacy) required since February 2025 for all third-party SDKs. **Restore Purchases button must be highly visible and functional** — most common single cause of subscription app rejection.

### Adult-only / not-for-children / wellness-not-medical positioning patterns

(1) COPPA (US): not directed at children under 13 + no actual knowledge of collecting children's data = simpler compliance, but still include "not intended for children under 13" clause. (2) Austria: digital age of consent = **14** under DSG § 4(4). (3) UK Age Appropriate Design Code: apps "likely to be accessed" by under-18s must implement 15 additional privacy-by-default standards — NeuroStack's adult-only positioning and subscription paywall reduce this risk. (4) App Store age rating must be consistent with content and privacy policy. (5) **Do not collect exact birth dates** — boolean checkbox preferred. Collecting DOB and discovering a minor triggers complex deletion obligations.

---

## Major disagreements

**Generator sufficiency for health/wellness apps.** The most significant disagreement. Pragmatic founders endorse "ship with generator, get lawyer later." Practicing attorneys and privacy consultants warn generators have dangerous blind spots — they default to US-centric frameworks, miss GDPR Data Subject Rights nuances, and rely entirely on the developer correctly inputting their tech stack. For NeuroStack, the weight of evidence favors early lawyer involvement given Article 9 implications. **Specific failure mode identified:** if a developer fails to manually declare RevenueCat as a processor, the generated policy is fundamentally invalid.

**Strict explicit consent vs. legitimate interest for Sentry crash reporting.** Engineers argue crash reporting is a "functional requirement" falling under legitimate interest — no opt-in needed, just disclosure. Privacy advocates and Sentry's own maintainers counter that the SDK captures device IDs and IP addresses (PII under Recital 30), requiring explicit prior consent via banner before initialization. This creates a paradox: crashes during initial launch cannot be recorded if Sentry is gated behind consent. **The disagreement stems from GDPR interpretation differences.** Conservative route: gate behind consent. Pragmatic route: initialize with aggressive server-side IP scrubbing + disclosure in policy.

**Whether wellness session logs alone (without free-text notes) constitute "health data."** Taylor Wessing and gesundheitsdatenschutz.org suggest patterns over time reveal health status. Legal IT Group/TermsFeed analysis notes "basic step counting with regular erasure might not be health data." **Context-dependent, no bright line.** Conservative position (treat as health data) safer for Austrian DSB oversight.

**Austrian enforcement risk.** heise.de (874 comments) documents Austria deliberately weakened DSGVO enforcement. But noyb/epicenter.works complaint to European Commission (September 2025) may change this. DSB still processed 3,813 complaints in 2024. **Temporal disagreement** — comply fully regardless of current enforcement gaps.

**RevenueCat GDPR compliance for EU users.** US-based, uncertain DPF certification status. If lacking DPF, rely on SCCs and disclose in privacy policy. **Vendor-specific uncertainty.**

**Cookie consent for Supabase auth cookies.** JWT cookies contain personal data beyond minimum necessary. Argument for "strictly necessary" (no consent) vs. argument for consent. **No definitive community consensus.** "Strictly necessary" argument is reasonable for auth cookies.

**Mechanics and ethics of age verification.** Regulatory bodies push for cryptographic ID-based verification; developers resist due to conversion destruction and surveillance data risks. Industry consensus relies on "legal fiction" of self-attestation (boolean checkbox + ToU clause). **Effectiveness against determined regulatory action remains debated globally.**

**Generator choice for Austrian app.** English communities favor iubenda/TermsFeed. German communities favor Datenschutz-Generator.de. **Geography and language disagreement** — practical solution: use DACH generator for German, English generator for English version.

---

## Future AI Delta

If NeuroStack later adds AI-generated recommendations, summaries, or outputs, the following clauses and disclosures will likely need revision or addition:

**Terms of Use changes:** (1) Define "Input" and "Output" (or "AI Output") terminology explicitly. (2) Add an AI Output Disclaimer: outputs are informational only, not professional advice, no guarantee of accuracy — **must specifically state outputs may be "incorrect, inaccurate, hallucinated, or inappropriate"** and shift verification responsibility to user. (3) State whether user data is used for AI model training, with opt-out mechanism. (4) If adding agentic features: require affirmative enablement, define scope, provide right to disable. (5) Strengthen "not medical advice" disclaimer specifically for AI-generated wellness recommendations. (6) **Clarify output ownership** — industry trend is granting users full ownership of generated output, provided it doesn't infringe third-party IP.

**Privacy Policy changes:** (1) **Apple Guideline 5.1.2(i)** (effective November 2025) requires: named AI provider disclosure, **explicit separate permission** before first data transmission to each AI provider, and user control settings for AI features. (2) Identify each AI provider by name (e.g., "OpenAI GPT-4o"). (3) Disclose what user data is sent to AI APIs and for what purpose. (4) Add data retention specifics for AI interaction logs. (5) Conduct new DPIA for AI-processed personal/health data. (6) Address GDPR Article 22 (automated decision-making). (7) **Explicitly state whether session logs, duration metrics, and free-text notes are used for model training or transmitted to model providers** — EU citizens' data for continuous model training increasingly requires explicit, separate opt-in consent.

**Regulatory environment:** EU AI Act compliance deadline **August 2, 2026**. Wellness AI recommendations likely "limited risk" (users must be told they're interacting with AI). If AI processes health data for recommendations, potentially "high risk" — formal requirements for transparency, human oversight, documentation, robustness. Fines up to €35M or 7% of global revenue. **EDPB position** (April 2025): LLMs "rarely achieve anonymization standards." US state laws also emerging: California AB 489 (Oct 2025), Illinois WOPRA (Aug 2025), Texas TRAIGA (Jan 2026).

**Community evidence for AI clauses is still forming.** HN shows strong opposition to silent AI training clauses. Practical consensus: be transparent about AI data usage from day one, provide granular opt-in/opt-out, update policies before launching AI features — not retroactively.

---

## Coverage report

### Queries and platforms searched
All 19 English queries and 11 German queries executed across: reddit.com (r/iOSProgramming, r/androiddev, r/SaaS, r/reactnative, r/apple), news.ycombinator.com, indiehackers.com, developer.apple.com/forums, community.revenuecat.com, github.com (supabase, getsentry), heise.de, wer-weiss-was.de, juraforum.de, g2.com, capterra.com, wko.at. Recovery strategies applied for thin results.

### Areas with strong evidence
- **Wellness/medical disclaimer architecture:** Strong (5 comparable app ToS + WHOOP/FDA case + multiple expert analyses + Reddit community feedback)
- **Apple subscription disclosure requirements:** Strong (multiple rejection stories + official requirements + RevenueCat CEO template + 123-reply May 2025 thread)
- **GDPR health data classification for wellness apps:** Strong (6+ independent expert sources + WP29/EDPB guidance)
- **Generator comparison and "generator vs. lawyer" workflow:** Strong (5+ multi-participant threads across HN and IH)
- **Austrian-specific requirements (DSG, KSchG, DSB, Impressum):** Strong (Austrian government sources + WKO + heise.de + GDPRhub + multiple law firm analyses)
- **Supabase GDPR/DPA:** Strong (active GitHub discussion + official documentation + auth issue #713)
- **RevenueCat disclosure requirements:** Strong (multiple community threads with staff answers + restore purchases rejection thread)
- **Sentry GDPR compliance and consent debate:** Strong (GitHub #851 multi-year thread + official documentation)
- **DACH generators/templates:** Strong (robust ecosystem documented)
- **Apple EULA override requirements:** Strong (Reddit thread + TermsFeed analysis + Apple documentation)
- **Third-party sub-processor mapping:** Strong (deep technical/legal debates on GitHub for Sentry IP tracking + Supabase magic link realities)

### Areas with thin evidence
- **Reddit community discussions specifically about indie mobile app privacy policies:** Thin — Reddit site-specific searches returned very few results. May be due to Reddit content access restrictions (Public Content Policy 2024).
- **UserOrient privacy implications:** **No strong evidence found.** No community discussion. Standard public-feedback-portal heuristics used as fallback.
- **Magic link authentication privacy considerations:** Thin — expert analysis available but no substantive community discussion.
- **Adult-only/not-for-children clauses for mobile apps:** Thin — limited to age verification debate thread, no specific age-gate language discussions.
- **German-language Reddit discussions on Datenschutzerklärung/AGB for apps:** **No strong evidence found.** German developer communities appear to use non-public channels.
- **Feature request board privacy disclosure patterns:** **No strong evidence found** beyond UserOrient's own policy.

### Areas where only old evidence was available
- **Basecamp/Automattic open-source templates:** 2017–2022 but consistently recommended in 2025–2026. Templates maintained. Relaxed recency.
- **HN GDPR practical guides:** Core threads 2018–2020 (379 points, 198 comments). GDPR fundamentals stable. Relaxed recency.
- **Daniel Kennett's subscription disclosure blog:** 2018, confirmed by ongoing 2025–2026 rejections using identical language.
- **Reddit r/iOSProgramming EULA thread:** ~2023. Apple requirements stable.

### Areas where only one community discussed the issue
- **Austrian KSchG auto-renewal:** Primarily Ombudsstelle.at. Partially corroborated by sevdesk.at and WKO.
- **Sentry consent-before-init debate:** Primarily GitHub #851. Supported by official Sentry GDPR docs.
- **RevenueCat EU data transfer concerns:** Single community thread with staff acknowledgment but no resolution.

### Factual points verified from official docs (community evidence insufficient)
- Sentry data collection types, GDPR compliance, DPA, sub-processor list, IP capture behavior — sentry.io
- Supabase DPA terms, sub-processors, SOC 2 — supabase.com legal pages
- UserOrient privacy policy content and sub-processors — userorient.com/pp
- Apple Schedule 2, Section 3.8(b) exact requirements — developer.apple.com
- Austrian DSB contact details and DSFA-V — data-protection-authority.gv.at
- Austrian age of digital consent (14) — DSG § 4(4) via GDPRhub and DLA Piper
- Austrian Impressum triple-statute requirements — WKO official PDF
- RevenueCat backend logic for entitlement transfer between sessions — RevenueCat official forum
