Create a mobile-first weekly progress screen.

Background: #030303 with grid texture.

Layout:

1. Header (px-6, pt-6):
   - Title: "This Week" - Newsreader italic, 32px, text-white/90, letter-spacing: -0.025em
   - Date range: "Dec 2 – Dec 8, 2025" - Inter, 14px, font-weight: 300, text-white/40, mt-1

2. Week grid card (mx-6, mt-8):
   - Container: bg-white/[0.02], rounded-[24px], p-6
   - Border: 1px solid white/10
   
   Day headers row:
   - 7 columns, equal width
   - Days: "M  T  W  T  F  S  S" - Inter mono, 11px, font-weight: 500, text-white/40, text-center
   - Current day: text-brand-sky, subtle underline

   Protocol rows (mt-6, space-y-5):
   Each row:
   - Protocol name (mb-2): "Norwegian 4×4" - Inter, 14px, font-weight: 400, text-white/70, truncate
   - 7 status cells (grid, gap-2):
     - Cell size: 36px × 36px, rounded-xl
     - Completed: 
       - bg-brand-sky/20, border border-brand-sky/30
       - Checkmark icon: Brand Sky, 16px
       - Subtle inner glow
     - Not done (past): 
       - bg-white/[0.02], border border-white/5
       - X icon or empty, white/20
     - Future: 
       - bg-transparent, border border-dashed border-white/10
       - No icon

3. Legend (px-6, mt-8):
   - Horizontal row, justify-center, gap-8
   - Each item (flex, items-center, gap-2):
     - Completed: Brand Sky dot (8px) with glow + "Done" text-white/50
     - Missed: white/20 dot + "Missed" text-white/50
     - Upcoming: dashed border dot + "Upcoming" text-white/50
   - Typography: Inter, 11px, font-weight: 400

4. Empty states:
   - No protocols: 
     - Card shows: "Add protocols to track" centered
     - Icon: Layers, 32px, white/20
     - Text: Inter, 14px, text-white/40
   - No sessions this week:
     - All past cells show empty state
     - Message below grid: "No sessions logged this week" - Inter, 13px, text-white/40, text-center, mt-4

5. Bottom navigation (same styling, Progress tab active)
