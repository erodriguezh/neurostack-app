Create a mobile-first transformation/offer screen.

Background: #030303 with grid texture.
Top decorative: Radial glow (brand-sky/10) creating optimistic energy shift.

Layout (px-6):

1. Headline (mt-12, text-center):
   - "What if you just..."
   - Newsreader italic, 28px, text-white/70
   
   - "did the thing?"
   - Newsreader italic, 32px, text-white/90, mt-1
   - Subtle brand-sky underline or glow

2. Subhead (mt-4, text-center):
   - "NeuroStack is the simplest way to stick with science-backed protocols."
   - Inter, 15px, font-weight: 300, text-white/50, max-width: 300px

3. Value props card (mt-10):
   - Container: bg-white/[0.02], rounded-[24px], p-6
   - Border: gradient border (from-brand-sky/20 via-white/10 to-white/5 on top)
   - Spotlight effect
   
   Three value lines (space-y-4):
   Each line:
   - Icon: Brand Sky, 18px (eye, flame, sparkle respectively)
   - Text: Inter, 15px, font-weight: 400, text-white/70, ml-4
   
   - 👁 "See exactly what to do today"
   - 🔥 "Build streaks that feel good to maintain"
   - ✨ "Actually become the person who does this stuff"

4. Trial offer section (mt-8, text-center):
   - Container: bg-brand-sky/5, rounded-2xl, p-5, border border-brand-sky/20
   
   - "7 days free" - Inter, 20px, font-weight: 500, text-brand-sky
   - "No credit card required" - Inter, 13px, font-weight: 400, text-white/50, mt-1
     > **fn-81 note:** "No credit card required" is inaccurate for App Store distribution.
     > Apple requires a payment method to start a free trial via StoreKit/RevenueCat.
     > The onboarding code was updated in fn-46 Phase 0.3 to remove this copy.

5. Bottom section (fixed, pb-8, px-6):
   - Progress: dots 3 of 4
   
   - Primary CTA (mt-4):
     - Full width, h-14, rounded-full
     - Solid bg-brand-sky (#38BDF8)
     - Text: "Start my free trial" - Inter, 15px, font-weight: 600, text-#030303
     - Arrow icon
     - Glow: 0 0 25px rgba(56,189,248,0.35)
   
   - Secondary link (mt-3):
     - "Maybe later" - Inter, 13px, font-weight: 400, text-white/30
     - Tappable, links forward without trial activation context (goes to disclaimer anyway)

Animation:
- Headline has slight bounce ease on "did the thing"
- Value props stagger in 150ms each
- Trial offer card pulses glow once after props load
- CTA has animated border spin (subtle, brand-sky conic gradient)
