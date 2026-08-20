---
id: 29
title: Build order across the flows, and what done means for a screen
parent: 17
labels: [wayfinder:grilling]
status: open
assignee:
blocked-by:
---

## Question

**Everything under the screens is built. What is left is SwiftUI, and nothing says which screen
first.**

The map has held this since charting, and it was fog for a stated reason: it waited on the store
being proved on a real device. [The Logbook on disk](0025-the-logbook-on-disk.md) passed its
force-quit test on Rob's phone on 2026-08-20, so the condition is met.

What exists now:

- `HoppaRules` — every rule of §3, §4, §5, §6.3 and §6.6, 98 tests green.
- `HoppaStore` — one door, `send(Action)`, 25 tests green, proved on the phone.
- An Xcode project that builds and installs, with the fonts and the palette in it.
- `AcceptanceHarness.swift` and `HarnessSeed.swift`, which are scaffolding the first real screen
  deletes.
- Validated artboards for almost every screen, and `SPEC.md` §6 describing all five flows.

Settle:

- **Which flow is built first, and why.** Flow 2 (logging) is the screen Rob stands in front of at
  the rack and the one with the most rules behind it. Flow 1 (creating a Program) is what makes
  `HarnessSeed` deletable and is the only honest way to get a real Program onto the phone. Flow 5
  shares the Exercise sheet with Flow 1, so those two may be one build rather than two.
- **What "done" means for a screen**, precisely enough that a ticket can be closed. Faithful to the
  artboard, or working and roughly right? The artboards are HTML at a fixed width; a phone is not.
- **How big a screen ticket is**, given that one agent session is 100K tokens and the Mac is a batched
  hand-off. What does a single ticket hand Rob to look at, and how many tickets does a flow take?
- **What the Mac has to see each round**, so the queue in the map's Notes stays one session per
  batch and not one per screen.

Do not decide the drawing technique — [Drawing the loaded bar and the Ignition
confetti](0031-drawing-the-bar-and-the-confetti.md) owns that — and do not decide the appearance —
[Dark only, or a light mode too](0030-dark-only-or-a-light-mode.md) owns that. Both may run in
parallel with this.

Consult `SPEC.md` §6 and §7, `CONTEXT.md`, and the map's Notes on batching the Mac work.
