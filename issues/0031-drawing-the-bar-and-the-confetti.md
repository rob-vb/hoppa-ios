---
id: 31
title: Drawing the loaded bar and the Ignition confetti natively
parent: 17
labels: [wayfinder:prototype]
status: closed
assignee: Rob
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

---

## Resolution

**Plain `Shape`s for the bar. `Canvas` + `TimelineView` for the confetti.** That is the reverse of
the reflex — `Canvas` sounds like the tool for a drawing and `Shape`s sound like the tool for a
view — and the reason is the same fact read twice: **`Canvas` gives you a draw call and takes away
layout.** The bar is layout and no animation; the confetti is animation and no layout.

### The loaded bar — plain `Shape`s in an `HStack`

The bar **is** a row of rounded rectangles: collar, plates ascending outward, sleeve stop, knurled
shaft, and the mirror of that. The prototype draws it with flexbox and nothing else
(`drawBar()` in `design/0007-logging/fitty-workout-logging.html`), which is `HStack` under another
name. Taking `Canvas` here means computing every x-offset by hand to get back the one thing
`HStack` already does.

What decides it, beyond the layout:

- **§7.1 rule 2 is a fill/stroke distinction, and shapes carry it in the type system.** A plate is
  `.fill(colour)`; steel is `.stroke(lineWidth: 1)`. In a `Canvas` both are calls on the same
  context and nothing stops a later hand filling a steel slab — which is exactly §8.2's second
  summary defect, written once already.
- **A weight change is an animation over a changing list.** Plates appear and disappear when the
  Working Weight moves. Shapes with an `.id` get that from SwiftUI; a `Canvas` redraws with no
  notion that a plate is the same plate.
- **The cost `Canvas` would buy is not being paid.** A bar holds at most a handful of plates per
  side and redraws when a weight changes, not per frame. There is no draw-call problem to solve.

**Rejected: an image.** The plate list is data — arbitrary sizes, colours from
`PlatePalette.hex(for:)`, and an `≈ CLOSEST` bar that differs from the exact one. Nothing static
can hold it.

### The Ignition confetti — one `Canvas` inside `TimelineView(.animation)`

§6.5 specifies gravity, drag, spin and a per-particle rim. That is a **physics integration**, not
an interpolation, so no SwiftUI animation curve expresses it — something has to step the state once
per frame whichever technique wins. Given that, the question is only what draws the result, and a
single `Canvas` draws up to ~75 slabs in one pass with no view identity to maintain. `step()` in
`design/0009-summary/fitty-workout-summary.html` ports almost line for line.

- **Rejected: `SpriteKit`.** A whole framework, a scene, a `SpriteView` and a texture per colour,
  for 1.4 seconds of animation. Its hollow steel particle needs a bespoke image; `Canvas` strokes
  a rounded rect.
- **Rejected: `CAEmitterLayer`.** Cheapest per particle and the worst fit for the spec: it wants
  one cell per appearance, so §6.5's proportional-by-count sampling becomes cell birth-rate
  arithmetic, hollow steel needs a bespoke image again, and it is UIKit under a bridge.
- **Rejected: one SwiftUI view per particle.** 75 views with per-frame `.offset` and `.rotation`,
  and the physics still has to be stepped by hand. It is the `Canvas` design plus a view tree.

**The one thing argument cannot settle: whether ~75 particles hold 60 fps on Rob's phone.** That is
answered in Batch 3, on the real Summary screen, at no extra cost. If it does not hold, it is a
**finding with its own ticket**, and the fallback is fewer particles per burst — never lighter
ones, which §6.5 rules out by name.

### How it gets proved: no Mac session of its own

Ticket 31 asked for one Mac session showing every candidate side by side. **Rob chose to fold it
into the three hand-offs instead**, and that stands:
[Build order](0029-build-order-and-what-done-means.md)'s batches already carry both drawings —
the bar rides Batch 2 (the logging screen) and the confetti rides Batch 3 (the Summary). A
throwaway comparison screen would spend the scarce resource to answer, by eye, a question that the
APIs answer by what they can and cannot do. **Nothing ran on this machine, and the ticket says
"judged by something that ran"** — that is the honest cost, and it is paid down in Batch 2 rather
than avoided.

### Reduce Motion: the rows still land, the particles do not

Handed here by [Dark only, or a light mode too](0030-dark-only-or-a-light-mode.md). Rob chose it.

`@Environment(\.accessibilityReduceMotion)`. When it is on, the 190 ms row-by-row sequence
**stays** and `burst()` is never called. The sequence is what makes the count *a count you watch
land*, which is the whole reason Ignition beat Density and Bursts (§6.5); the particle cloud is the
part that causes motion trouble. Killing the sequence too would have thrown away the decision and
kept the cheap half.

This is **not** the ignore that §7.2 applies to Appearance and Dynamic Type. Those two are locked
because the design depends on them; Reduce Motion is an accessibility setting, and honouring it
costs one branch.

### Which plates a burst throws is a rule, and it is green here

**The line: which plates a burst throws is decided by the `Logbook`; how a particle looks and moves
is not.** Two lifters with the same `Logbook` must watch the same colours come off the same row —
§6.5 fixes it exactly and [Confetti plate source](0012-confetti-plate-source.md) records why — and
the arc each particle takes is random by design. So the first half passes the `is-this-a-rule` test
and the second half fails it.

`Rules.burstSource(_:) -> [BurstParticle]` is in `HoppaRules`, with `BurstParticle` being
`.plate(Weight)` or `.steel`. It returns the **sampling list**, one entry per plate in the load,
never the fifteen particles: §6.5's *proportional by count, picked uniformly* comes out for free
from a one-entry-per-plate list, so the view needs no weighting of its own. Step 2 of the test:
**it needs no Foundation**, and the whole file imports nothing.

This is what kills §8.2's first summary defect for good. `colours()` in the prototype falls back to
`rack = [added]` — the Increment plate — for every Equipment Type that is not plate-loaded, so a
stack threw its Increment and a dumbbell threw a colour §5.5 never draws. **Nine new tests, and
every one of them fails against the prototype.** `HoppaRules` is at **107 green**, up from 98;
`HoppaStore` holds at 25.

Two edges the spec implies and the code now states:

- **Everything hanging on the pin throws, not just the Microload.** §6.5's table says "the
  Microplates on the pin", and the drawing hangs both `pinRemainder` (the same-unit part the pin
  cannot reach) and `microloadPlates` in the same place. "The burst throws what the Plate Breakdown
  draws" is one rule with no exception, so both are in.
- **An empty source throws steel.** A Working Weight equal to the bar has no plates, but the row
  still went up, and §6.5 rejected throwing nothing by name — the count is the hero, so every
  Went-up row must land.

### The steel of a drawing: one hue, seven lightnesses

[Dark only, or a light mode too](0030-dark-only-or-a-light-mode.md) left this open on purpose — `PlatePalette.hex(for:)`
returns `nil` for anything unpainted and the view falls back. **It falls back to a ramp, not to a
literal.**

Measured, not assumed: **every grey in §7.2 and every grey in both prototypes sits on hue 210° at
4–10% saturation.** Floor, card, line, chip border and steel; the collar, the two knurl stripes, the
sleeve stop, the dumbbell bell and handle, the pin, and an unloaded stack block. They are one colour
at eleven lightnesses. So **zero new hues, and zero findings** under ticket 30's escalation rule —
the second time that rule has been checked and fired nothing.

`Steel.hex(lightness:)` in the app target derives the ramp from §7.2's `#9BA1A7`, and
`Palette.swift` names the seven points (`stackEmpty`, `collar`, `knurlLow`, `sleeveStop`, `shaft`,
`knurlHigh`, `pin`). **It imports nothing, so it was compiled and run on the VPS**: it reproduces
`#9BA1A7` exactly and every other prototype grey within 3/255.

One thing the run caught that no reading would have: **`Double.rounded()` is libm, and libm is not
linked without Foundation.** The file rounds by hand instead. This is step 2 of the map's
`is-this-a-rule` test biting a *view* file, which is new — the rule was written for rules, and it
applies to anything meant to be provable here.

### What tickets 36 and 39 inherit

Facts, so neither has to re-derive them:

- **Plate glyph geometry stays in the view**, per this ticket's own line that a drawing is not a
  rule. The prototype's relative sizes are the reference — 20 kg at 34x114, 10 at 24x96, 5 at 20x90,
  2.5 at 15x74, 1.25 at 11x60 — and **its colours are §8.2 defect 5, so take the size and drop the
  hex.** There is no 15 kg. A microplate draws at roughly a quarter of the smallest normal plate
  (§7.1 rule 1), which the prototype never drew and which the logging screen must invent.
- **Plates run smallest outermost**, mirrored, and §5.5's "biggest plate first" is the *loading
  order*, not the draw order — `BarLoad.plates` is biggest-first and the drawing reverses it.
- **Particle constants**, from the chosen variant C: 15 particles per burst, rows 190 ms apart,
  power 7.4, spread 0.95pi, gravity 0.42/frame, drag 0.992/frame, spin +/-0.17 rad/frame, slab
  5-9 x 14-27 px, radius 2, and a **1.5 px rim on every particle** (§8.2 summary defect 2, which the
  prototype has wrong).
