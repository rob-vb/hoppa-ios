---
id: 2
title: Design language & visual direction
parent: 1
labels: [wayfinder:prototype]
status: closed
assignee: henk
blocked-by: []
---

## Question

What is Fitty's visual language? Produce a `/design` canvas with the dark-first direction: typography, color, spacing, and one or two hero screens (e.g. the active-workout screen) at high fidelity — big numbers, high contrast, thumb-friendly for gym use. The user reacts and picks; the chosen direction becomes the standard for every later prototype ticket.

## Resolution

**Direction A — "Plate Rack"** is the visual language for Fitty. Three directions were drafted (A Plate Rack, B Console, C Logbook), each with a style tile and the same active-workout screen. The user chose A outright.

Asset: [Fitty Visual Directions canvas](https://claude.ai/code/artifact/cd36141c-1c13-4052-ab0c-6ce8a3add70d) — source artboards in `design/0002-visual-direction/`. The rejected directions stay on the canvas as the record of the choice.

### The standard

**Thesis**: the app speaks in plates. Calibrated plate colours are the palette, and colour never decorates — it only ever means weight.

**Surface palette**
| Role | Value |
| --- | --- |
| Floor (background) | `#0E0F10` |
| Card | `#17191B` |
| Line | `#26292C` |
| Steel (icons, shafts) | `#9BA1A7` |
| Dim text | `#8D9296` |
| Text | `#F4F1EC` |

**Plate palette** (colour is data, never decoration): 25 & 2.5 kg `#C8322B`, 20 kg `#1F5FCB`, 15 kg `#E4BC1B`, 10 kg `#2E9E52`, 5 kg `#E8E6E1`, 1.25 kg `#B9BEC3`. Green `#2E9E52` doubles as the "done / progression" colour.

**Type**
- Display: **Anton** — Working Weight, headings, set numbers, button labels. Uppercase, tight line-height (0.78–0.94).
- Body: **IBM Plex Sans** — labels, meta lines, body. Tabular figures on.
- Labels are uppercase, 10–11 px, letter-spacing 0.12–0.14 em.

**Shape and spacing**: 2–3 px radii (industrial, near-square). Screen padding 20 px, safe top inset 54 px with nothing drawn in it. Vertical rhythm on a 8/16 px gap. Hit targets 50 px (set rows) and 64 px (bottom controls).

**Signature — the loaded bar**: a side view of the bar with plates drawn to relative diameter and width, in their real colours, mirrored around a knurled centre shaft. Caption underneath gives the per-side sum in words and figures.

### Change requested by the user, applied

The bottom control row is **`−` · `LOG n REPS` · `+`**. The user sometimes performs more reps than the top of the Rep Range, so logging above the range must be possible from the same one-tap row. Both adjust buttons are 62 × 64 px and flank the primary action.

This forces a decision that ticket 4 (Progression edge cases) already carries: what over-range reps mean for progression, and how the screen signals them. Not decided here.
