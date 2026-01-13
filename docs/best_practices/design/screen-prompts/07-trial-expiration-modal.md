Create a mobile-first blocking trial expiration modal.

Modal: Full screen, bg-#030303. No close button. Blocking.
Background effect: Subtle radial glow (amber/10) at top.

Layout (px-6, centered vertically):

1. Visual indicator (text-center):
   - Icon: Hourglass or clock with depleted indicator, 72px
     - Stroke: Amber-400, stroke-width: 1.5
     - Subtle amber glow: 0 0 25px rgba(251,191,36,0.2)
   
2. Message (text-center, mt-8):
   - Headline: "Your Premium Trial Has Ended" 
     - Newsreader italic, 28px, text-white/90, letter-spacing: -0.025em
   - Subtext (conditional, if >2 protocols, mt-4):
     - "You currently have 4 active protocols. The free tier allows 2."
     - Inter, 15px, font-weight: 300, text-white/50, max-w-[280px]

3. Decision cards (mt-12, space-y-4):

   Upgrade option (featured):
   - Container: bg-white/[0.02], rounded-[24px], p-6
   - Border: 1px solid brand-sky/30, subtle glow
   - Spotlight effect
   
   Contents (text-center):
   - Icon: Crown or star, 28px, Brand Sky, glow
   - Title: "Keep Everything" - Inter, 18px, font-weight: 500, text-white/90, mt-3
   - Subtitle: "Subscribe to Premium" - Inter, 14px, font-weight: 300, text-brand-sky, mt-1
   - Arrow indicator at bottom: → in white/30
   
   Touch: Full card, 100px+ height
   Tap → Paywall

   Downgrade option:
   - Container: bg-white/[0.02], rounded-[24px], p-6
   - Border: 1px solid white/10
   
   Contents (text-center):
   - Icon: Layers with minus, 28px, white/40
   - Title: "Continue with Free" - Inter, 18px, font-weight: 500, text-white/70, mt-3
   - Subtitle: "Limited to 2 protocols" - Inter, 14px, font-weight: 300, text-white/40, mt-1
   
   Tap → Stack (if ≤2) or Protocol Selection (if >2)

No dismiss gesture. No tap-outside. No X button. User must choose.
