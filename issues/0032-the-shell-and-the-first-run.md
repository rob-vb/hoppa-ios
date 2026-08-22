---
id: 32
title: The shell and the first run
parent: 17
labels: [wayfinder:task]
status: open
assignee:
blocked-by: [30]
---

## Question

**Build the app's home: the Workout Day picker, and what it shows before there is anything to pick.**

The first of eight screen tickets from
[Build order across the flows, and what done means for a screen](0029-build-order-and-what-done-means.md).
It is the one that turns the app from a harness into an app.

Build:

- **The Workout Day picker** (§3.1). Free pick, no rotation, no pre-selection, no suggestion. Each
  row shows the Workout Day's Name and **when it was last done** — "Push — 4 days ago" — which is
  information and not advice (§7.6). A Workout starts on an explicit action.
- **The empty state**, decided at ticket 29 and now in §6.1: `NOTHING HERE YET` and one
  `CREATE A PROGRAM` button. The picker is always home; onboarding is a route to it.
- **A `HISTORY` row at the foot** (§6.7). It is a door to a screen that does not exist yet — build
  the row disabled or absent, and say which in the hand-off note. Hoppa has **no tab bar**.
- **The navigation spine.** §6.7 names two doors and no tab bar, so the shape is a `NavigationStack`
  whose path lives in `@State` on the view, per
  [The view layer around the rules](0024-the-view-layer-around-the-rules.md).
- **The colour tokens** in whatever shape [Dark only, or a light mode too](0030-dark-only-or-a-light-mode.md)
  settles. `Palette.swift` exists from ticket 18 and this ticket is the first real user of it.
- **Retire the scaffolding.** Delete `AcceptanceHarness.swift`; this screen replaces it. **Keep
  `HarnessSeed`** behind a debug switch — Flow 4 needs sixteen weeks of history to look at, and
  typing that on a phone is not a test.

Done means, per ticket 29: §7.4's constants hold exactly (padding 20, radii 2–3, hit target 50,
safe top inset 54 with nothing in it, the 8/16 rhythm); the artboard is the reference for
arrangement and copy; **`SPEC.md` beats the artboard** wherever they disagree. No UI tests — the
view reads `ResolvedExercise` and calls `store.send`, and any logic worth testing belongs below the
view.

Type-check the file here against the built modules before pushing — see the map's Notes on what
reaches further than "imports nothing". This ticket does **not** hand over to the Mac on its own:
batch 1 goes over after ticket 35, when there is a path from an empty app to a real Program.

Consult `SPEC.md` §3.1, §6.1, §6.7 and §7.4, and `design/0006-onboarding/`.
