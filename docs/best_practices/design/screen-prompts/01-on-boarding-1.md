Create a mobile-first dark splash screen.

Background: #030303 with subtle grid texture.
Top decorative: Very faint radial glow (white/5) creating depth.

Layout (px-6, vertically centered with slight top bias):

1. Headline sequence (staggered reveal animation):

   Line 1: "You've read the studies."
   - Newsreader italic, 32px, text-white/90, letter-spacing: -0.025em
   - Fades in first (0ms)

   Line 2 (mt-6): "You know cold plunges work."
   - Inter, 18px, font-weight: 300, text-white/60, line-height: 1.6
   - Fades in at 400ms

   Line 3: "You know zone 2 cardio extends lifespan."
   - Same styling
   - Fades in at 700ms

   Line 4: "You know what you should be doing."
   - Same styling, but "should" in italic and text-white/80
   - Fades in at 1000ms

2. The kicker (mt-12):
   - "So why aren't you doing it?"
   - Newsreader italic, 24px, text-brand-sky (#38BDF8)
   - Fades in at 1500ms with slight scale up (0.95 → 1)
   - Subtle text glow: 0 0 30px rgba(56,189,248,0.2)

3. Bottom section (fixed, pb-10, px-6):
   - Progress dots: 4 dots, first filled (white), rest empty (white/20), gap-2, centered, mb-6
   - CTA button:
     - Full width, h-14, rounded-full
     - bg-white/5, border border-white/10
     - Text: "That's me" - Inter, 15px, font-weight: 500, text-white/70
     - Arrow: → with hover:translate-x-1
     - Hover: bg-white/10, border-white/20
     - Touch: 56px target

Animation:
- Each line fades in + translateY(10px → 0) with stagger
- Kicker has extra emphasis (scale + glow pulse once)
- Total sequence: ~2s
