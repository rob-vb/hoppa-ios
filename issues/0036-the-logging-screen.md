---
id: 36
title: The logging screen
parent: 17
labels: [wayfinder:task]
status: open
assignee:
blocked-by: [35, 31]
---

## Question

**Build §6.4 — the screen Rob stands in front of at the rack.**

Its prototype was **approved outright on the first pass**, so the arrangement is settled and this
ticket transposes it. It also carries the most of §8.2's nine defects, and **not one of them ports.**

Top to bottom:

- **The exercise counter as navigation.** `3 / 5 ▾` opens a full-screen list where every Exercise
  carries its state as a pill, under *"Leaving an open Exercise means later, never 'not at all'"*.
  That list is part of this ticket.
- **The Working Weight as the hero**, in Anton. Tapping it opens ticket 37's sheet.
- **The rule chip**, which states the rule and never an offer (§7.6): steel `+2.5 KG IF ALL 12`
  while logging, green `→ 75 KG NEXT TIME` the instant the Exercise completes.
- **The loaded bar** — technique from
  [Drawing the loaded bar and the Ignition confetti](0031-drawing-the-bar-and-the-confetti.md).
  It draws what the user actually loads, per side, biggest plate first (§5.5, §7.5). It renders a
  `PlateBreakdown` that `HoppaRules` already solves and decides nothing about which plates go on.
- **The Set rows.** 50 px hit targets. Reps over the range read `14 reps · 8–12` — plain, no colour.
  A `ONE-OFF` chip on every Set row logged under a One-off Weight.
- **The bottom control row `−` · `LOG n REPS` · `+`**, 62 × 64 px on the adjust buttons. One tap logs
  at Target Reps; the `+` is what makes logging **above** the range reachable by design.
- **The Rest Timer**: a count-up stopwatch, started after each logged Set. It is a `TimelineView`
  over `now − restStartedAt` ([The view layer around the rules](0024-the-view-layer-around-the-rules.md)),
  which is why a lock, a background and a call cost no code here.
- **Completing costs no tap; moving on costs one.** The last Set completes the Exercise by itself and
  the bottom button becomes `NEXT: BARBELL ROW`, or `FINISH WORKOUT` when nothing is Open.
  **Hoppa does not jump by itself.**
- The **Finish gate** with its one-tap way out, when Exercises are still Open (§3.3).

The nine walkthroughs in §6.4 all pass headlessly already. This ticket does not re-prove them — it
must not contradict them.

Done, hand-off and testing follow ticket 29's rules. Batch 2 goes over after ticket 37.

Consult `SPEC.md` §3.2, §3.3, §5.5, §6.4, §7.4, §7.5 and §8.2, and
`design/0007-logging/fitty-workout-logging.html`.
