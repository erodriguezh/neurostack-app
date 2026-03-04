Create a mobile-first settings screen.

Background: #030303 with grid texture.

Layout:

1. Header (px-6, pt-6):
   - Title: "Settings" - Newsreader italic, 32px, text-white/90, letter-spacing: -0.025em

2. Upgrade banner (px-6, mt-8, conditional — hidden for premium users):
   - Container: bg-white/[0.02], rounded-[24px], p-6
   - Border: 1px solid brand-sky/30
   - Row layout:
     - Crown/gem icon: 32px, stroke brand-sky, glow rgba(56,189,248,0.25)
     - Column:
       - "Unlock All Protocols" - Inter, 17px, font-weight: 500, text-white/90
       - "Unlimited protocols, all future updates" - Inter, 13px, font-weight: 300, text-white/50
     - Trailing: chevron-right, 18px, text-white/30
   - Full card tappable, min 72px height
   - Tap navigates to paywall

3. Support & Resources section (px-6, mt-10):
   - Section header: "SUPPORT & RESOURCES" - Roboto Mono, 11px, font-weight: 500, uppercase, letter-spacing: 0.15em, text-white/40, mb-4
   - Tile container: bg-white/[0.02], rounded-[24px], border 1px solid white/10, overflow hidden

   Tiles (each):
   - Padding: px-5, py-4
   - Row: icon (20px, white/40, stroke-width 1.5) + label (Inter, 15px, w400, white/80, flex-1) + trailing icon (16px, white/20)
   - Min height: 56px, full width tap target
   - Press: bg-white/[0.03], scale(0.99), 150ms
   - Divider between tiles: 1px white/5, mx-5

   Tile definitions:
   | Label | Icon | Trailing | Visibility |
   |-------|------|----------|------------|
   | Contact Us | mail | chevron-right | Always |
   | Cancel Subscription | credit-card | external-link | Premium only |

4. Animations:
   - Content fade-in: 400ms ease-out, translateY(8 to 0)
   - Stagger: banner first, tile container 100ms later

5. Bottom navigation (same styling, Settings tab active)
