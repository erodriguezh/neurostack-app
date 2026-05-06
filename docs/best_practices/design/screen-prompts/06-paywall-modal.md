Create a mobile-first paywall modal.

Modal: Full screen, bg-#030303.
Top decorative: Radial gradient glow at top center (brand-sky/10, large radius, fading).

Layout (px-6):

1. Header:
   - Close button (top-right, pt-4): X icon in white/40, bg-white/5 rounded-full, 44px
   - Spacer: mt-12

2. Value proposition (text-center):
   - Icon: Unlock/gem icon, 56px
     - Stroke: Brand Sky, stroke-width: 1.5
     - Glow: 0 0 30px rgba(56,189,248,0.3)
   - Headline: "Unlock All Protocols" - Newsreader italic, 32px, text-white/90, mt-6, letter-spacing: -0.025em

3. Benefits list (mt-10, space-y-4, max-w-[280px], mx-auto):
   Each benefit:
   - Row: flex, items-center, gap-4
   - Checkmark: Brand Sky, 18px, with subtle glow
   - Text: Inter, 15px, font-weight: 300, text-white/70
   
   Benefits:
   - "Unlimited protocol activation"
   - "All 5 protocols available"
   - "All future protocols included"

4. Pricing cards (mt-12, space-y-3):

   Annual card (pre-selected/featured):
   - Container: bg-white/[0.02], rounded-[24px], p-5
   - Border: 2px solid brand-sky/50 with glow (0 0 15px rgba(56,189,248,0.15))
   - Spotlight effect active (subtle)
   
   - Layout (flex, items-center):
     - Selection indicator (left): 
       - Filled circle: 22px, bg-brand-sky, inner white dot 8px
       - Glow around circle
     - Content (ml-4, flex-1):
       - "Annual" - Inter, 16px, font-weight: 500, text-white/90
       - "$59.99/yr" - Inter, 14px, font-weight: 300, text-white/50, mt-0.5
     - Badge (right): 
       - "SAVE 37%" - bg-brand-sky, text-#030303
       - Inter, 10px, font-weight: 700, uppercase, tracking-wide
       - rounded-full, px-2.5, py-1

   Monthly card (not selected):
   - Container: bg-white/[0.02], rounded-[24px], p-5
   - Border: 1px solid white/10
   - Selection indicator: Empty circle, border-2 border-white/30, 22px
   - Content same layout, no badge
   - Tap to select: border animates to brand-sky, 200ms

5. Actions (mt-10, space-y-4):
   
   Subscribe button:
   - Full width, h-14, rounded-full
   - Animated conic gradient border (spinning, brand-sky via white/20)
   - Inner: bg-#050505
   - Text: "Subscribe" - Inter, 15px, font-weight: 500, text-white
   - Arrow icon, hover:translate-x-1
   - Glow on hover
   - Processing: Spinner, disabled appearance
   
   Free option:
   - Full width, h-12, bg-transparent
   - Text: "Continue with Free" - Inter, 14px, font-weight: 400, text-white/40
   - Hover: text-white/60
   - Always available, 48px touch target

Error: Toast from bottom with red accent.
Success: "Welcome to Premium!" toast with Brand Sky accent, sparkle icon.

6. Compliance elements (RevenueCat hosted paywall, fn-81):
   - The hosted paywall (designed in RevenueCat dashboard) now includes:
     - Restore Purchases button (Apple requirement 3.1.1)
     - Privacy Policy link (Apple requirement 5.1.1)
     - Terms of Use link (Apple requirement 3.1.2)
     - Auto-renewal disclosure text with cancellation instructions
   - These elements are configured in the RevenueCat paywall builder, not in Flutter code.
   - Temporary URL for Privacy Policy and Terms of Use: `https://getneurostack.app`
