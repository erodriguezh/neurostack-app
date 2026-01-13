Create a mobile-first protocol library screen.

Background: #030303 with grid texture.

Layout:

1. Header (px-6, pt-6):
   - Title: "Protocol Library" - Newsreader italic, 32px, text-white/90, letter-spacing: -0.025em

2. Protocol list (px-6, mt-6, space-y-4, pb-28 for nav clearance):

   Each protocol card — three visual variants:

   A) In Stack (already active):
   - Container: bg-white/[0.02], rounded-[24px], p-6
   - Border: 1px solid brand-sky/30 (accent border indicating active)
   - Badge (top-right, absolute): 
     - Circle: 24px, bg-brand-sky, checkmark icon (white, 14px)
     - Glow: 0 0 10px rgba(56,189,248,0.3)
   
   Contents:
   - Category: Mono pill (same styling)
   - Name: "Norwegian 4×4 HIIT" - Inter, 18px, font-weight: 500, text-white/90
   - Evidence: "Multiple RCTs" - Inter, 12px, font-weight: 400, text-emerald-400, mt-1
   - Status: "In your stack" - Inter, 12px, text-brand-sky, mt-3

   B) Available (can add):
   - Container: bg-white/[0.02], rounded-[24px], p-6
   - Border: 1px solid white/10
   - Spotlight effect on touch
   - Badge: Plus icon in white/30 circle, 24px
   
   Contents similar, status line: "Tap to add" - text-white/40
   
   Hover/touch: border-white/20, spotlight active

   C) Locked (free tier limit):
   - Container: bg-white/[0.01] (slightly more muted), rounded-[24px], p-6
   - Border: 1px dashed white/10
   - Badge: Lock icon in white/20 circle, 24px
   - All text at reduced opacity (name: white/50, others: white/30)
   - Status: "Upgrade to unlock" - text-amber-400/80
   - Tap → Paywall

   Evidence strength color coding:
   - "Multiple RCTs": text-emerald-400
   - "Single RCT": text-brand-sky
   - "Mechanistic": text-white/50

3. Bottom navigation (same as Stack screen, Library tab active with Brand Sky)
