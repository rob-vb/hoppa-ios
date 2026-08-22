---
id: 30
title: Dark only, or a light mode too
parent: 17
labels: [wayfinder:grilling]
status: closed
assignee: Rob
blocked-by:
---

## Question

**`SPEC.md` is dark-first from end to end and never says whether a light mode exists.**

§7.2 puts the app on a `#0E0F10` floor, §7.3 gives the plates the colours of real iron, and every
artboard the design map produced is dark. None of that states a decision — it states a default that
was never questioned, because a static artboard has no system setting to obey.

On iOS it is a decision with real work behind it, and the work is not symmetrical:

- **Dark only** means locking the app with `.preferredColorScheme(.dark)`, and that has a real cost:
  the app ignores the phone's own setting, which iOS users notice. It is one line, and it is a
  promise that every future screen may hard-code a colour.
- **A light mode** means every colour becomes a token with two values, and it reaches further than a
  palette swap. The plate colours are **physical** — a blue 20 kg plate is blue in the gym — so they
  cannot invert. The Anton hero, the steel of the loaded bar and the Ignition confetti (§7.1's rule
  that steel particles are not filled) all read against a dark floor by design.

Settle:

- Does Hoppa have a light mode, now or ever?
- If not: is it locked to dark, or does it merely look dark and drift when someone changes a
  setting? Say which, because they are different builds.
- If so: what does §7.3's physical plate palette do on a light floor, and who decides the token
  values — this map, or the launch effort?
- Either way: **what shape do the colours take in code**, so the first screen does not hard-code a
  hex that a later decision has to hunt down. `Palette.swift` already exists from ticket 18.

This blocks nothing today, and it gets much more expensive after three screens are written. Consult
`SPEC.md` §7, and the map's Out-of-scope note on user-set plate colours — a related question that
stays out.

## Resolution

**Hoppa is dark only, and it is locked in both places.** `.preferredColorScheme(.dark)` alone was
never the whole answer: it pins the SwiftUI hierarchy and nothing else, so the launch screen and any
UIKit chrome still followed the phone. `INFOPLIST_KEY_UIUserInterfaceStyle = Dark` is now on both
build configurations, beside the two flags ticket 25 added. Two locks, because they cover different
surfaces.

**A light mode is out of scope, not fog.** Rob said "dark locked for now", and "for now" is real —
but fog only ever gathers *toward* the destination, and the destination is Rob training in his own
gym. A light mode serves the second lifter in a bright gym, who first appears at the App Store
effort. `SPEC.md` §10 carries it now, with the reason: §7.3's plate colours are **physical** and
cannot invert, so a light mode is a design effort of its own rather than a token swap.

**Dynamic Type is ignored, and that is not free.** SwiftUI's `Font.custom(_:size:)` **scales with
Dynamic Type by default**; only `Font.custom(_:fixedSize:)` does not. So a screen that writes the
obvious thing gets the behaviour this ticket just ruled out. §7.4 fixes its sizes in points, a
0.78 line-height and a 50 px hit target, and none of that survives a text scale. The lock is
`.dynamicTypeSize(.large)` at the root plus `fixedSize` on every face. **Reduce Motion** goes to
[Drawing the loaded bar and the Ignition confetti](0031-drawing-the-bar-and-the-confetti.md), which
is the ticket that draws the thing it would turn off. **Increase Contrast** stays in the fog.

**Two palettes collided, and one has been trimmed.** `PlatePalette` in `HoppaRules` declared
`steel = "#3A3E42"`; `Palette.swift` in the app declares `steel = 0x9BA1A7`. §7.2 says both are
right about *different things* — steel is `#9BA1A7`, the **chip border** is `#3A3E42` — so the same
word carried two values across two files, and the plate one was the chip's. It also held
`progression = "#2E9E52"`, which duplicates `Color.go`.

The boundary that settles it: **the rules own a fact about a plate; the app owns a surface role.**
`PlatePalette` is now `hex(for:)` and nothing else. Applying the map's `is-this-a-rule` test to a
colour is what exposed the confusion — a floor colour passes step 1's first half (it is decided from
the `Logbook` alone) but fails the second, because two lifters *need not* see the same floor. A
plate colour must match the iron in front of them, so it stays a rule. Both removed symbols were
unused; **98 tests still green** on the VPS.

Which steel value the *drawing* uses for a stack block, a dumbbell and an unpainted plate is
deliberately left open — `hex(for:)` returns `nil` there and the view falls back. That is
[ticket 31](0031-drawing-the-bar-and-the-confetti.md)'s question, and this ticket refused to
pre-answer it by keeping a misnamed constant.

**No view holds a colour literal — and the artboard proves why the rule is needed.** The logging
artboard uses **38 distinct hexes; §7.2 and §7.3 name 16.** So every screen ticket will meet a value
the spec does not name. The rule, now in `SPEC.md` §7.2: one file holds every hex; a screen that
needs a value adds a **named role** or derives it from a named one; **a new hue is a finding with
its own ticket**, not a quiet addition.

**And the escalation rule fires zero times on the artboard that has been checked.** All 22
off-table hexes were traced, and none is a spec gap:

- The gold `#E4BC1B` is the **15 kg plate** — §8.2 row 4 already says it does not exist, and row 5
  says the whole `PLATE` table holds invented colours.
- The amber pair `#D9974A` / `#7A4E23` is the `.tag` class, which draws exactly one thing: the
  **"PROTOTYPE — THROWAWAY"** banner. It is not app chrome and it dies with the prototype.
- The desaturated red pair `#D98A85` / `#5A3230` is `.danger`, the destructive button. §7.1 says
  plainly that **DELETE wears the 25 kg red `#C8322B`**, and Notes already say the spec beats the
  artboard. Not a new §8.2 row: §8.2 lists defects in the `Fitty` module, and this is artboard CSS.
- The rest are tints and pressed states of a named role — `#141517` over the `#0E0F10` floor.

So the guard costs nothing today. It exists so that the first screen that *does* meet a real new hue
raises it instead of inventing it.

**What ticket 32 inherits.** Four consequences reach the app target, and all four import SwiftUI, so
none can be proved on the VPS — they are the shell ticket's opening work, deliberately not written
here unproven:

1. `.dynamicTypeSize(.large)` in `HoppaApp`, beside the existing `.preferredColorScheme(.dark)`.
2. A `Typography.swift` beside `Palette.swift`, holding §7.4 as named roles — display, label, meta,
   body — each built with `fixedSize` and carrying its own letter-spacing and line-height. A view
   never calls `.custom` itself.
3. A `Color(hex: String)` bridge, because `PlatePalette.hex(for:)` returns a `String` and
   `Palette.swift`'s existing initialiser takes a `UInt32`.
4. `Palette.swift` regains nothing yet — `Color.go` and `Color.steel` already carry what
   `PlatePalette` gave up.

`project.pbxproj` gained **2 additive lines**, one per configuration. Unverified until Rob opens
Xcode, like every patch this side writes.
