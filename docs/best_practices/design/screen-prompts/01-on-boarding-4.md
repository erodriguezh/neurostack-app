Create a mobile-first disclaimer screen.

Background: #030303 with grid texture.

Layout (px-6):

1. Header section (mt-16, text-center):
   - "One more thing."
   - Newsreader italic, 28px, text-white/90, letter-spacing: -0.025em
   
   - "We take your health seriously. So should you."
   - Inter, 15px, font-weight: 300, text-white/50, mt-3

2. Disclaimer card (mt-10):
   - Container: bg-white/[0.02], rounded-[24px], p-6
   - Border: 1px solid white/10
   - Left accent: 3px solid bar, amber-400/50
   
   - Small icon top: Shield or heart with plus, 24px, text-amber-400/70
   
   - Disclaimer text (mt-4):
     "NeuroStack helps you track protocols based on published research—but we're not doctors, and this isn't medical advice. Before starting any new protocol, check with your healthcare provider."
   - Inter, 14px, font-weight: 300, line-height: 1.7, text-white/60
   - "we're not doctors" and "this isn't medical advice" slightly emphasized (text-white/70)

3. Consent section (mt-8):
   - Checkbox row:
     - Checkbox: 24px, rounded-lg, same styling as before
     - Label: "I understand" - Inter, 15px, font-weight: 400, text-white/70
   - Full row tappable, 52px touch target

4. Bottom section (fixed, pb-10, px-6):
   - Progress: dots 4 of 4 (all filled or last filled)
   
   - Primary CTA:
     - "Let's go"
     - Disabled: bg-white/5, text-white/30
     - Enabled: Solid bg-brand-sky, text-#030303, glow
     - Arrow icon with bounce on enabled state
   
   - Processing: Spinner, same as original

Success → Navigate to `/home`

Animation:
- Content fades in together (no stagger—this is functional, not dramatic)
- Checkbox has satisfying scale + color transition on check
- "Let's go" button transforms with 300ms ease when enabled
