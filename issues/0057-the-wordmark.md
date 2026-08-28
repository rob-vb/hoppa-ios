---
id: 57
title: The wordmark, placed quietly
parent: 17
labels: [wayfinder:task]
status: closed
assignee: agent
blocked-by: []
---

## Question

Rob pushed `hoppa.svg` on 2026-08-28 — a five-letter wordmark, white, 547 × 218 — and asked:
*"kun je dit logo op een subtiele manier neerzetten ergens."*

## Resolution

**Two places, both on the root screen, both in a quiet grey.**

- **The picker**, which is home (§6.1): 12 pt tall in `labelText` (`#55595D`), left-aligned above
  the Program name, 4 pt under the safe inset and 6 pt above the header. It is the quietest thing
  on the screen — the Program name beside it is in `steel`, one step louder — and nothing else
  moved.
- **The first run**, which has no header: 22 pt in `steel` at the top, over `Nothing here yet`.
  That screen said nothing about whose app it was, and it is the first thing a new install shows.

**How it is held.** `Assets.xcassets/Wordmark.imageset/` carries the SVG as a **template** image
with `preserves-vector-representation`, so it is tinted by `foregroundStyle` and sharp at any
height. The SVG's own `#FCFCFC` is discarded by template rendering — §7.2 says no view holds a
colour literal, and this way the asset does not either. `Wordmark.swift` is one view: a height,
the SVG's aspect ratio, an accessibility label. The catalogue is inside the file-system
synchronised group, so **no `project.pbxproj` edit** — worth noting because Rob's own commit
`5b5748f` shows Xcode rewriting that file on its side and changing nothing but key order. One
more clean run for the fog's first entry.

**Not placed:** on any pushed screen — the chevron and the Program name already say where you
are — and not on the Summary, where the count is the only hero. `HANDOFF.md` item 129.
