Create a mobile-first dark splash screen.

Background: Solid #030303 with subtle grid pattern overlay (white/[0.02] lines at 40px intervals, masked with radial fade to transparent at edges).

Center vertically and horizontally:
- NeuroStack logo mark: Abstract brain/neural stack icon, 64px
  - Fill: Brand Sky #38BDF8
  - Glow effect: box-shadow 0 0 20px rgba(56,189,248,0.3), 0 0 40px rgba(56,189,248,0.1)
  
- Below logo (mt-6): Loading indicator
  - Three small dots (6px each) in a row, gap-2
  - Color: Brand Sky #38BDF8
  - Animation: Sequential pulse, each dot scales 1→1.3→1 with 200ms stagger
  - Subtle glow on each dot: 0 0 10px rgba(56,189,248,0.5)

Animation: 
- Logo fades in over 500ms ease-out with slight translateY(-10px) → translateY(0)
- Dots begin pulsing after 300ms delay
- Entire composition has subtle breathing glow (shadow opacity 0.2→0.4 on 2s ease-in-out loop)

No text. Ultra-minimal. Premium feel through restraint and glow effects.