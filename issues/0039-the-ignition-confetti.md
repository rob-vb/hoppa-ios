---
id: 39
title: The Ignition confetti
parent: 17
labels: [wayfinder:task]
status: open
assignee:
blocked-by: [38, 31]
---

## Question

**Build the burst on the Summary (§6.5, §7.1), using the technique
[Drawing the loaded bar and the Ignition confetti](0031-drawing-the-bar-and-the-confetti.md) picks.**

The last ticket of the trainable milestone, and the one that **closes hand-off batch 3** — after it,
Rob can walk the whole route: empty app → Program → Workout → Finish → Summary.

Ignition, chosen live against two rejected models (Density covers the numbers at five Exercises;
Bursts reads the count but floats free of the list):

- Each Went-up row **lands on its own, 190 ms after the row above it**, and throws **~15 particles
  from its own plate chip**.
- The sequence runs **~1.4 s**, after which the screen is quiet and every number is readable. The
  named trade-off, accepted: the list is not fully readable until the last row lands.
- **Zero progressed fires nothing at all.**

The colour rules, which are the part a technique choice can quietly break:

- **The burst throws what the Plate Breakdown draws** — one rule on every Equipment Type. Bar-like
  types throw the per-side plates of the **new** Working Weight with the Base Weight excluded; a
  stack throws the Microplates on the pin plus one steel slab per loaded pin block; a Dumbbell throws
  steel; Bodyweight throws the plate on the belt.
- **Sampling is proportional by plate count**, from a list holding one entry per plate in the load,
  picked uniformly. Not one share per distinct size — that makes a plate louder as it gets smaller,
  inverting rule 1 of §7.1. Not proportional by mass — that erases the microplate.
- Particles are **plate-shaped slabs**, the same glyph the Inventory and the rows draw, with gravity,
  drag and spin, and a **1.5 px rim** so a dark plate reads as a moving ring rather than a hole.
- **The face is never brightened, because the face is the weight.** A weak burst is fixed with more
  particles, never with lighter ones.
- **Steel particles are hollow** — a 1 px outline, per rule 2 of §7.1, **without exception**. A
  filled steel slab at 5 × 14 px is nearly the 1.25 kg grey `#70767C`, so a Dumbbell burst would read
  as a rack of 1.25s. Throwing nothing was rejected too: the count is the hero, so **every Went-up
  row must land**.

Done, hand-off and testing follow ticket 29's rules. **This ticket triggers hand-off batch 3.**
Confetti is the one thing on this map that a type-check cannot judge at all, so the hand-off note
should say what to watch for and what a wrong answer looks like.

Consult `SPEC.md` §6.5, §7.1 and §7.3,
[Confetti plate source](0012-confetti-plate-source.md), and
`design/0009-summary/fitty-workout-summary.html`.
