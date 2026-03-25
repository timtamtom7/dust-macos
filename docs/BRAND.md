# Dust — Brand Guide

## App Overview

Dust is a disk space analyzer and smart cleaner for macOS. It scans the filesystem to find large files, duplicate groups, and clutter — then helps users safely remove it. Built for people who want a fast, visual, and trustworthy alternative to "du in terminal."

---

## Icon Concept

**Primary icon:** A stylized dust cloud being swept by a broom — the cloud is made of layered organic blob shapes suggesting accumulated files and cache, while a clean geometric broom shape clears it away. A subtle sparkle or two indicates the "clean" result.

**Alternative compositions:**
- A hard drive outline with dust particles floating off it
- A file folder with a wind/gust effect pushing files away

**Design principles:** The "dust" should feel light and ephemeral — soft blob shapes, not heavy blocks. The broom is the active agent of change: it's precise, purposeful, and gives the app personality. The contrast between the messy cloud and the clean sweep should be immediately legible.

**Do NOT:** Use garbage trucks, trash cans, or other heavy/dour cleaning imagery. Dust is a light and empowering tool, not a janitor.

---

## Color Palette

| Role | Name | Hex | Usage |
|------|------|-----|-------|
| Background | Snow | `#FAFAF9` | Main window background (light) |
| Background Alt | Onyx | `#1C1C1E` | Main window background (dark) |
| Surface | Pearl | `#FFFFFF` | Cards, panels, list rows |
| Surface Alt | Graphite | `#2C2C2E` | Cards in dark mode |
| Border | Ash | `#E7E5E4` | Dividers, row separators |
| Text Primary | Charcoal | `#1C1917` | Headings, primary labels |
| Text Secondary | Stone | `#78716C` | Captions, file sizes, secondary info |
| Accent | Warm Amber | `#F59E0B` | Primary CTAs, selected states, progress |
| Accent Alt | Tangerine | `#EA580C` | Large file indicators, warnings |
| Danger | Rose | `#E11D48` | Trash/delete actions, destructive |
| Success | Fresh Green | `#22C55E` | Space recovered, clean state |
| Duplicate Group | Violet | `#8B5CF6` | Visual coding for duplicate file groups |
| Safe Zone | Teal | `#14B8A6` | Files marked as "keep" |

> **Note:** Warm amber (`#F59E0B`) is the dominant brand color. It reads as energetic but not aggressive — appropriate for a cleaning tool. Avoid using the danger color (`#E11D48`) as a background; use it only for borders and icons on destructive actions.

---

## Typography

**Font family:** SF Pro (system font)

| Element | Weight | Size |
|---------|--------|------|
| Section Header | Semibold | 13pt |
| File / Folder Name | Medium | 12pt |
| Body / Path | Regular | 11pt |
| File Size | Medium | 11pt, SF Mono |
| Captions | Regular | 10pt |
| Space Recovered Counter | Bold | 24pt |

**Guidelines:**
- File sizes always in `SF Mono` — ensures digit alignment in lists and prevents layout shifts
- The "space recovered" counter uses the brand amber color and bold weight to make the success metric prominent
- No custom fonts

---

## Visual Motif

**Core motif: The sweep and the particle.**
The visual language contrasts two states: files as accumulated dust (soft, clustered blob shapes) and files being swept away (crisp edges, directional motion, sparkles).

**Key visual elements:**
- **Treemap:** Dust's main visualization is a file size treemap. Each rectangle represents a file or folder, sized proportionally. The color of each rectangle encodes type or status: amber for large files, violet for duplicates, teal for selected-to-keep, ash/gray for small/negligible.
- **Duplicate groups:** When duplicates are detected, each group is visually connected by a thin `#8B5CF6` (violet) underline or bracket, making it easy to scan the list and identify which files belong together.
- **Progress bar:** A thin amber progress bar fills left-to-right during scanning. It has a subtle shimmer animation to communicate activity.
- **Recovery counter:** When files are trashed, a small floating counter animates upward showing space recovered — it bounces in with spring physics, then fades to a static number.

**Icon library:** SF Symbols. Key symbols: `doc`, `folder`, `trash`, `checkmark.circle`, `exclamationmark.triangle`, `arrow.up.circle`, `magnifyingglass`.

**Patterns:** A very subtle dot-grid pattern can be used in empty/welcome states. The dots are `#E7E5E4` at 40% opacity, 4pt spacing. Never in the main scan results.

---

## Size Behavior

| Context | Width | Height | Notes |
|---------|-------|--------|-------|
| Main window | 800pt | 560pt | Default, resizable (min 600×400pt) |
| Treemap (main view) | Fluid | Fluid | Fills main content area |
| Sidebar (Smart Groups) | 180–240pt | Full height | Collapsible |
| Duplicate group card | Fluid | 72pt | Shows 2–3 file rows |
| Detail panel (right) | 220pt | Full height | File preview + actions |
| Progress overlay | 400pt | 120pt | Centered modal during scan |
| Confirmation dialog | 360pt | auto | Standard macOS alert |

**Adaptive:** The treemap is the hero — it scales to fill available space. The sidebar and detail panel collapse gracefully on narrower windows. Minimum supported width is 600pt.
