Create a mobile-first agitation screen, Aura Financial premium dark style.

Background: #030303 with grid texture.

Layout (px-6):

1. Headline (mt-16):
   - "The gap between knowing and doing"
   - Newsreader italic, 26px, text-white/90, letter-spacing: -0.025em, line-height: 1.3
   
   - "is where results go to die."
   - Same font, but text-amber-400 (#FBBF24) for "go to die"
   - Subtle amber glow on those words

2. Body copy (mt-10):
   - Container: No card, just text
   
   Paragraph styling:
   - Inter, 16px, font-weight: 300, text-white/60, line-height: 1.8
   
   Content with emphasis:
   - "You start strong." - normal
   - "Week one, you're locked in." - "locked in" in text-white/80
   - (spacing: mt-4)
   - "Week two, life gets busy." - normal
   - (spacing: mt-4)  
   - "Week three, you forgot which day you're supposed to do what." - longer, wraps naturally
   - (spacing: mt-4)
   - "By month two, that protocol you were excited about?" - normal
   - "Just another abandoned experiment." - text-white/40, italic

3. Transition hook (mt-10):
   - "Sound familiar?"
   - Inter, 18px, font-weight: 500, text-white/80
   - Slight left-align with rest of content

4. Bottom section (fixed, pb-10, px-6):
   - Progress: dots 2 of 4
   - CTA: "Too familiar" + arrow
     - Same ghost button styling
     - Slightly more emphasis: border-white/20

Animation:
- Body paragraphs fade in with 200ms stagger (creates reading rhythm)
- "Sound familiar?" fades in last with slight delay