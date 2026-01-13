Create a mobile-first protocol library screen.

Background: #030303 with subtle grid texture (white/[0.02] lines, radial mask fading to edges).
Top decorative: Faint radial glow (brand-sky/5) at top center, creating subtle warmth.

Layout (px-6):

1. Logo (mt-12, text-center):
   - NeuroStack logo mark: Brand Sky #38BDF8, 36px
   - Subtle glow: 0 0 15px rgba(56,189,248,0.2)

2. Header section (mt-10, text-center):
   - Headline: "Welcome back"
     - Newsreader italic, 32px, text-white/90, letter-spacing: -0.025em
   
   - Subhead (mt-3):
     - "Enter your email and we'll send you a magic link."
     - Inter, 15px, font-weight: 300, text-white/50, max-width: 280px, mx-auto

3. Form section (mt-12):
   
   Email input:
   - Label: "EMAIL"
     - Inter mono, 11px, font-weight: 500, uppercase, tracking-[0.15em], text-white/40, mb-3
   
   - Input container: 
     - bg-white/[0.02], rounded-2xl, h-14
     - Border: 1px solid white/10
     - Focus state: border-brand-sky/50, box-shadow 0 0 0 3px rgba(56,189,248,0.1)
     - Padding: px-5
   
   - Input text: Inter, 16px, font-weight: 400, text-white/90
   - Placeholder: "you@example.com" - text-white/25
   
   - Mail icon (left inside, optional): 18px, text-white/30
   
   - Error state (if invalid email on submit attempt):
     - Border: border-red-500/50
     - Helper text below: "Enter a valid email" - Inter, 12px, text-red-400, mt-2

4. CTA button (mt-6):
   - Full width, h-14, rounded-full
   
   Default state:
   - Solid bg-brand-sky (#38BDF8)
   - Text: "Send magic link" - Inter, 15px, font-weight: 600, text-#030303
   - Arrow icon (→) with group-hover:translate-x-1
   - Glow: 0 0 20px rgba(56,189,248,0.3)
   
   Disabled state (empty input):
   - bg-white/5, border border-white/10
   - text-white/30, no glow
   
   Loading state:
   - bg-brand-sky/80
   - Spinner (dark, 20px) replaces text
   - Button disabled, no pointer events
   
   Transition: all 300ms ease-out

5. Security note (mt-6, text-center):
   - "We'll email you a secure link to sign in. No password needed."
   - Inter, 13px, font-weight: 300, text-white/30
   - Small lock icon inline before text (optional): 12px, text-white/20

6. Bottom spacer: pb-12 for comfortable thumb reach

Animation:
- Form fades in 500ms ease-out with translateY(10px → 0)
- Input focus has smooth border color transition (200ms)
- Button loading state: text fades out, spinner fades in (150ms crossfade)

Keyboard behavior:
- Email keyboard type
- "Send" / "Go" return key action
- Input auto-focused on screen load (optional based on UX preference)
