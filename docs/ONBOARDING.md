# Dust — Onboarding Screens

Dust's user is someone who's been staring at a nearly-full disk and needs to find what's taking up space fast. Onboarding should respect urgency — get them scanning in 3 screens, then get out of the way.

---

## Screen 1 — Welcome / Start a Scan

**Trigger:** First launch

**Layout:** Centered layout — large illustration, headline, subtext, one primary action.

**Illustration concept:**
A wide, friendly illustration of a hard drive (stylized as a rounded rectangle with a subtle platter design inside) surrounded by floating dust particles — irregular blob shapes in various sizes and warm grays. Some particles are large (amber), some small (light gray). A subtle upward arrow on the right side suggests "space being freed."

**Visual style:**
- Hard drive: `#F5F5F4` fill, `#E7E5E4` stroke, large corner radius (16pt), 200pt wide
- Dust particles: irregular blob shapes (4–8 sided polygons, softened corners), sizes vary from 8pt to 32pt
- Large particles: amber `#F59E0B` fill at 80% opacity
- Small particles: `#D6D3D1` fill at 60% opacity
- Arrow: `#22C55E`, 2pt stroke, pointing up-right, with a small arrowhead

**Text:**
> "Find what's eating your disk."
> "Dust scans your filesystem, finds the largest files and duplicates, and helps you clean up — safely."

**CTA:** "Scan My Mac" — `#F59E0B` fill, 44pt height, 8pt corner radius, white text.
**Secondary:** "Choose a folder instead" — text link below in `#78716C`.

---

## Screen 2 — Reading the Treemap

**Trigger:** After first scan completes

**Layout:** Side-by-side — treemap mockup on the left, explanation of the color coding on the right.

**Illustration concept:**
A simplified treemap illustration: a large rectangle subdivided into 8–10 smaller rectangles of varying sizes and colors. Above the treemap, three small legend items explain the color coding: amber = Large file, violet = Duplicate group, teal = Selected to keep.

Below the treemap, a tooltip callout points to one of the rectangles (a medium-sized amber one) with the label "62 MB — 3 copies found."

**Visual style:**
- Treemap rectangles: flat fills, no strokes, 2pt corner radius on each rectangle
- Color coding for legend: small 16pt squares in amber `#F59E0B`, violet `#8B5CF6`, teal `#14B8A6`
- Tooltip: `#1C1917` fill, white text, 4pt corner radius, small white triangle pointer
- File size callout: `#78716C` text

**Text:**
> "Each rectangle is a file or folder. Bigger = more space."
> **Amber** — Large files  |  **Violet** — Duplicates  |  **Teal** — You marked it safe

**Instruction:**
> "Click any rectangle to preview it and see options. Dust never deletes anything without asking."

---

## Screen 3 — Duplicates Deep Dive

**Trigger:** First time navigating to the Duplicates smart group

**Layout:** Duplicate group cards shown in a list, with an expanded group detail beside it.

**Illustration concept:**
A mockup of the duplicate finder results: on the left, a list of 3 duplicate groups — each group is a card with 2–3 file rows inside, connected by a violet bracket on the left edge. A small checkbox on each file row. The expanded group on the right shows a full file preview (filename, path, size, modification date) with two action buttons: "Keep Leftmost" (teal) and "Move to Trash" (rose `#E11D48`).

Small icons for file type (document, image, video) shown as small SF Symbols to the left of each filename.

**Visual style:**
- Duplicate group cards: white fill, `#E7E5E4` border, 6pt corner radius, 8pt internal padding
- Violet bracket: `#8B5CF6`, 2pt stroke, left side of each group card
- Checkboxes: macOS-native style, `#F59E0B` when checked
- "Keep" button: `#14B8A6` fill, white text
- "Trash" button: `#E11D48` outline, `#E11D48` text (destructive style, not filled)
- File type icons: `#78716C`, 12pt SF Symbols

**Text:**
> "Dust found 3 sets of duplicates — 1.2 GB recoverable."
> "Select one file per group to keep, then trash the rest."

**Below callout:**
> "Smart Groups automatically mark the oldest or smallest copy as safe — review before deleting."

---

## Screen 4 — Safe Cleaning & Exclusions

**Trigger:** First time opening Settings or the Exclusions manager

**Layout:** Two-column — exclusion rules list on the left, a warning callout on the right.

**Illustration concept:**
Left panel: A list of 4–5 exclusion rules, each shown as a small card with a folder icon, a path or app name, and a toggle switch (all toggles in the ON/safe position — green `#22C55E`):

1. `~/Library/Caches` (System Cache — protected)
2. `~/Downloads` (Downloads folder)
3. `/Applications` (Apps folder)
4. Steam Library (gaming data)
5. Docker data (developer data)

Right panel: A warning card with an amber `#F59E0B` left border, containing a lock icon and a list of "protected" locations that Dust will never touch.

**Visual style:**
- Exclusion cards: white fill, `#E7E5E4` border, 6pt radius, 44pt height
- Toggle ON: `#22C55E` track, white thumb
- Toggle OFF: `#D6D3D1` track, white thumb
- Warning callout: white fill, `#F59E0B` left border (3pt), amber `#F59E0B` lock icon
- Protected locations list: small gray text, indented

**Text:**
> "Tell Dust what to skip."
> "Excluded folders are invisible to Dust. Add folders, apps, or file types."

**Warning callout:**
> "Dust never touches: System files, app caches (unless you exclude explicitly), or files modified in the last 24 hours."

**CTA:** "Start Cleaning →" — `#F59E0B` fill, opens main window in scan-ready state.
