Create a mobile-first protocol selection/deactivation modal.

Modal: Full screen, bg-#030303. Blocking — no close button.

Layout:

1. Header (px-6, pt-8, text-center):
   - Title: "Choose 2 Protocols to Keep"
     - Newsreader italic, 26px, text-white/90, letter-spacing: -0.025em
   - Selection counter (mt-3):
     - Container: bg-white/5, rounded-full, px-4, py-1.5, inline-flex
     - Text: "1/2 selected" - Inter mono, 12px, font-weight: 500, tracking-[0.1em]
     - Color: text-white/50 (incomplete), text-brand-sky (complete at 2)
     - Updates in real-time with number transition

2. Protocol list (px-6, mt-8, space-y-3):

   Each protocol card:
   - Container: bg-white/[0.02], rounded-[24px], p-5
   - Border: 1px solid white/10
   - Spotlight on touch
   
   Layout (flex, items-center, gap-4):
   - Checkbox (left):
     - Size: 26px × 26px, rounded-lg
     - Unselected: bg-white/[0.02], border-2 border-white/20
     - Selected: bg-brand-sky, white checkmark (16px)
       - Glow: 0 0 10px rgba(56,189,248,0.3)
     - Transition: 200ms ease-out with slight scale
   
   - Content (flex-1):
     - Protocol name: "Norwegian 4×4 HIIT" - Inter, 16px, font-weight: 500, text-white/90
     - Category pill (inline, mt-1): mono styling, 10px
     - Investment: "12 sessions logged" - Inter, 12px, font-weight: 300, text-white/40, mt-2
       - Small activity icon before text
   
   Selected state: 
   - Card border: border-brand-sky/30
   - Subtle card glow
   
   Tap anywhere on card toggles selection (min 56px touch target)
   
   Pre-selection: 2 highest session count protocols start selected

3. Confirm button (fixed bottom, px-6, pb-10):
   - Full width, h-14, rounded-full
   
   Disabled (not exactly 2):
   - bg-white/5, border border-white/10
   - text-white/30
   - No interaction feedback
   
   Enabled (exactly 2):
   - Solid bg-brand-sky (#38BDF8)
   - text-#030303, Inter font-weight: 600, 15px
   - Glow: 0 0 20px rgba(56,189,248,0.3)
   - Hover: bg-brand-sky/90
   
   Text: "Confirm Selection"
   Transition: 300ms ease-out on all properties

No dismiss. User must select exactly 2 and confirm.
