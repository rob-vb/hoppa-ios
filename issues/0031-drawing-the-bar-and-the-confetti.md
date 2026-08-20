---
id: 31
title: Drawing the loaded bar and the Ignition confetti natively
parent: 17
labels: [wayfinder:prototype]
status: open
assignee:
blocked-by:
---

## Question

**`SPEC.md` §7.5 and §6.5 specify both drawings exactly, both exist as working HTML, and neither has
a native technique yet.**

This sat in the map's fog as *"not sharp until there is a project to run them in"*. There is one:
the app builds, installs and runs on Rob's phone.

Two drawings, and they are not the same problem:

- **The loaded bar** is static, redraws when a weight changes, and must be exact — §5.5 draws what
  the user actually loads, per side, biggest plate first. Candidates: SwiftUI `Canvas`, plain
  `Shape`s in a stack, or an image. Plain shapes are the most SwiftUI-shaped and the easiest to
  test; `Canvas` is one draw call and no view tree.
- **The Ignition confetti** (§6.5, §7.1) is a one-shot particle burst, and its particles carry
  colour rules — steel particles are **not filled**, and every particle takes a 1.5 px rim.
  Candidates: `Canvas` with a `TimelineView`, `SpriteKit`, or Core Animation emitters. `SpriteKit`
  is a whole framework to carry for one animation.

What to settle: which technique for each, judged by something that ran — not by argument. The
prototype skill exists for this.

Two constraints worth knowing before choosing:

- **This machine cannot run any of them.** Write the candidates here, type-check what can be
  type-checked, and batch one Mac session that shows all of them side by side. That session is the
  cost of this ticket, so make it carry every candidate at once.
- **A drawing is not a rule.** Whatever this picks renders a `PlateBreakdown` that `HoppaRules`
  already solves, and it decides nothing about which plates go on the bar.

Consult `SPEC.md` §5.5, §6.5, §7.1 and §7.5, and
`design/0007-logging/fitty-workout-logging.html` and `design/0009-summary/fitty-workout-summary.html`
for the HTML that already works — including §8.2's two summary defects, which must not port.
