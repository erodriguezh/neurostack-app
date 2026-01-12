Create a mobile-first protocol library screen.

Background: #030303 with subtle grid texture.

Layout (px-6, centered content):

1. Visual indicator (mt-20, text-center):
   - Mail/envelope icon: 64px
     - Stroke: Brand Sky #38BDF8, stroke-width: 1.5
     - Animated: Subtle float/bounce (translateY 0 → -5px → 0 on 3s ease-in-out infinite)
     - Glow: 0 0 30px rgba(56,189,248,0.25)
   
   - Optional: Small checkmark or sparkle accent near envelope indicating "sent"

2. Header section (mt-8, text-center):
   - Headline: "Check your inbox"
     - Newsreader italic, 28px, text-white/90, letter-spacing: -0.025em

3. Email confirmation (mt-6, text-center):
   - "We sent a link to"
     - Inter, 15px, font-weight: 300, text-white/50
   
   - Email address (mt-2):
     - Container: bg-white/[0.02], rounded-xl, px-4, py-2.5, inline-flex
     - Border: 1px solid brand-sky/20
     - Email: "user@example.com" - Inter, 15px, font-weight: 500, text-brand-sky
     - Subtle glow on container: 0 0 15px rgba(56,189,248,0.1)

4. Instruction (mt-8, text-center):
   - "Tap the link in your email to continue."
   - Inter, 15px, font-weight: 400, text-white/60

5. Spam hint (mt-4, text-center):
   - "Not seeing it? Check your spam folder."
   - Inter, 13px, font-weight: 300, text-white/30, italic

6. Actions section (mt-12, text-center, space-y-4):

   Resend link button:
   - Container: bg-white/[0.02], rounded-full, h-12, px-6, inline-flex
   - Border: 1px solid white/10
   
   Available state (after cooldown):
   - Text: "Resend link" - Inter, 14px, font-weight: 500, text-white/70
   - Refresh icon (left): 16px, text-white/50
   - Hover: bg-white/[0.05], border-white/20
   
   Cooldown state (60s timer):
   - Text: "Resend in 47s" - Inter, 14px, font-weight: 400, text-white/30
   - Button disabled, reduced opacity
   - Timer counts down in real-time
   - Icon: Clock instead of refresh, text-white/20
   
   Success state (after resend):
   - Brief flash: "Link sent!" - text-brand-sky
   - Then returns to cooldown state
   
   Change email link (mt-3):
   - "Change email" - Inter, 14px, font-weight: 400, text-white/40
   - Underline on hover: border-b border-white/20
   - Left arrow icon (←): 14px, text-white/30
   - Tap → Navigate back to `/auth` with email pre-filled
   - Touch target: 44px height

7. Bottom section (fixed, pb-10, px-6, text-center):
   - Optional: "Having trouble?" link
     - Inter, 12px, text-white/20
     - Links to support/help

Animation:
- Screen fades in 400ms ease-out
- Email icon has continuous gentle float animation
- Timer countdown is smooth (not jarring number changes)
- Resend success state: checkmark icon briefly replaces refresh, green flash

State management:
- Cooldown persists if user navigates away and returns
- Email passed from previous screen as route parameter
