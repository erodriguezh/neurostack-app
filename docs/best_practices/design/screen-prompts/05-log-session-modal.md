Create a mobile-first session logging modal.

Modal presentation: Slides up from bottom, bg-#050505, rounded-t-[32px], covers ~85% of screen.
Background overlay: #030303 at 80% opacity with backdrop-blur-sm.

Layout (p-6):

1. Modal header:
   - Drag indicator: white/20 pill, 40px × 4px, rounded-full, centered, mb-6
   - Row (flex, justify-between, items-center):
     - Title: "Log Session" - Newsreader italic, 24px, text-white/90
     - Close button: X icon, 20px, text-white/40, bg-white/5 rounded-full p-2, 44px touch target
   - Protocol context: "Norwegian 4×4 HIIT" - Inter, 14px, font-weight: 400, text-brand-sky, mt-2

2. Form fields (mt-10, space-y-6):

   Date field:
   - Label: "WHEN" - Inter mono, 11px, font-weight: 500, uppercase, tracking-[0.15em], text-white/40, mb-3
   - Input container: bg-white/[0.02], rounded-2xl, p-4, border border-white/10
     - Focus: border-brand-sky/50, subtle glow
   - Value: "Today, Dec 8, 2025" - Inter, 16px, font-weight: 400, text-white/80
   - Calendar icon (right): 18px, text-white/30
   - Touch: Opens native picker (future dates disabled)

   Duration field:
   - Label: "DURATION" - same mono styling
   - Optional badge: "(optional)" - Inter, 11px, text-white/30, ml-2
   - Input container: same styling as date
   - Placeholder: "0" - text-white/20
   - Suffix: "min" - Inter, 14px, text-white/40, inside right
   - Numeric keyboard
   - Error state: border-red-500/50, red glow
     - Helper: "Must be greater than zero" - Inter, 12px, text-red-400, mt-2

   Notes field:
   - Label: "NOTES" + "(optional)"
   - Textarea: bg-white/[0.02], rounded-2xl, p-4, border border-white/10, min-h-[100px]
   - Placeholder: "How did it go?" - text-white/20
   - Character counter (absolute bottom-right inside): "0/50" - Inter mono, 10px, text-white/30

3. Submit button (mt-10):
   - Full width, h-14, rounded-full
   - Solid bg-brand-sky (#38BDF8)
   - Text: "Log Session" - Inter, 15px, font-weight: 600, text-#030303
   - Glow: 0 0 20px rgba(56,189,248,0.3)
   - Processing: Spinner (dark, 20px), button bg-brand-sky/80
   - Disabled: bg-white/10, text-white/30, no glow

Animation: 
- Modal: 400ms ease-out slide up + fade
- Overlay: 300ms fade
- Success: Modal slides down, toast appears

Showing modal over dimmed Stack screen.
