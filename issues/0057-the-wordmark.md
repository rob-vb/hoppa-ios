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

## Second pass — Rob's correction, same day

> bij de dag picker, het logo mag gewoon in het wit en die mag linksboven staan en dat
> program-naam er naast. Als program-naam te lang is dan afkappen. Ook de "drie puntjes" als
> settings icoon mag een tandwiel icoon zijn

**Three changes to the picker header, and the first-run placement stays as it was.**

- **The wordmark is white** (`text`), 14 pt, **top-left**, in the header row itself.
- **The Program name sits beside it** in `steel`, `lineLimit(1)` with a tail ellipsis. Anton
  sits high in its box, so it carries 2 pt of top padding to land beside the mark.
- **The gear.** `GearGlyph` is a `Shape` — eight teeth on a ring with a hole, one `Path`,
  stroked 1.5 pt in `steel` and never filled (§7.1 rule 2). Drawn rather than an SF Symbol,
  because every glyph in the app is (§7.1), and Rob kept §7 at ticket 0056. It sits in the
  same 50 pt hit target `•••` had.

The "quietest thing on the screen" line above no longer holds for the picker; Rob wants the
mark seen, and it is his mark. `HANDOFF.md` item 129 rewritten.

## Third pass — same day

> hmmm, ok het logo mag 2x zo groot, en dan programma naam toch eronder. het logo en het
> tandwiel icoon lijnen op elkaar uit, programma daaronder

The header is **two rows**: the wordmark at 28 pt with the gear (22 pt) centred on its line,
and the Program name under them in steel, still one line with a tail ellipsis. The 50 pt band
is now the gear's row alone; the name adds its own line under a 6 pt gap.
