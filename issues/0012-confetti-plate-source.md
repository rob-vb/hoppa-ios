---
id: 12
title: Confetti plate source
parent: 1
labels: [wayfinder:grilling]
status: closed
assignee: henk
blocked-by: [9, 11]
---

## Question

Which plates does a Went-up burst throw — the **whole per-side Plate Breakdown of the new
weight**, or **only the plates that changed**? Two closed tickets answer this differently, and
the second answer walks back into a case the first one tested and rejected.

- [Workout summary screen prototype](0009-workout-summary-screen.md) chose colour rule **Rack**:
  the particles take the colours of the per-side breakdown of the weight just earned, so a Smith
  bench at 75 kg (20 + 10 per side) throws blue + green. It rejected rule **Increment** — the
  plate you added — because every Increment in this Program is 2.5 kg, so a five-Exercise day
  came out almost entirely one colour and the celebration said nothing new.
- [Microplate accumulation](0011-microplate-accumulation.md) needed a rule for the stack machine,
  which has no per-side breakdown at all. It wrote: **"the burst throws the plates that changed,
  not the whole load"** — a bar that went 72.5 → 73 throws one 0.25 microplate per side, a stack
  that went `+1 → +1.25 kg` throws one 1.25 kg disc, and a stack with no microplates throws its
  pin step in steel.

Read generally, ticket 11's sentence replaces Rack everywhere, including on the bar. That is
rule Increment under a new name — and under the real rack from ticket 11 the common Progressive
Overload day is now worse than it was when it was rejected, because 2.5 kg is a grey plate
(`#4E5358`), so five Exercises throw five grey bursts against a `#0E0F10` floor.

To settle:

1. Does "the plates that changed" apply only where there is no per-side breakdown (Machine
   (stack), Cable), leaving Rack in force for Barbell, Smith and Plate-loaded — or does it
   replace Rack outright?
2. If it replaces Rack, does the grey Progressive Overload burst read at all, and does that
   matter given the count of Exercises is the hero and not the colour?
3. What does a Dumbbell or Bodyweight Exercise throw? Neither was named in either ticket, and
   neither has a per-side breakdown.

Recommendation to put to the user first: **keep Rack where a per-side Plate Breakdown exists and
use "the plates that changed" only where it does not.** That honours both tickets — ticket 9's
tested finding on the bar, ticket 11's fix for the stack — at the cost of one branch in the
particle code.

Nothing else about Ignition is open: the 190 ms stagger, ~15 particles, ~1.4 s run, the plate
glyph, the 1.5 px rim, the never-brightened face and the silent zero-progressed screen all
stand. This ticket decides colour only.

Surfaced by [Assemble the spec](0008-assemble-the-spec.md). Whatever this settles, `SPEC.md`
§6.5 and §9 must be amended.

## Resolution

**The burst throws what the Plate Breakdown draws.** One rule, no branch on "changed", and
ticket 11's sentence is retired as an overreach — it solved the stack and reached into the bar,
where it became the rule ticket 9 had already tested and rejected.

| Equipment Type | The burst throws |
| --- | --- |
| Barbell, Smith, Plate-loaded | The per-side plates of the **new** Working Weight, Base Weight excluded — [Workout summary screen prototype](0009-workout-summary-screen.md)'s Rack rule, unchanged |
| Machine (stack), Cable | The Microplates on the pin, plus one steel slab per loaded pin block |
| Dumbbell | Steel. [Plate display design](0005-plate-display-design.md) draws the dumbbell in steel with no plate colours, so the burst never throws the Increment plate |
| Bodyweight | The plate on the belt |

The burst is therefore the drawn load, sampled. Nothing about it needs a rule of its own, which
is why this beat the two alternatives: ticket 11 read literally (the plates that changed, which
under the real palette makes the common Progressive Overload day five grey bursts against
`#0E0F10`), and a split rule keyed on Equipment Type.

### Sampling — proportional, by plate count

Fifteen particles take their colour from a list holding **one entry per plate in the load**,
picked uniformly. So 20 + 10 per side throws half blue and half green; 20 + 10 + 2.5 + 2.5
throws half grey.

Decided on merit, not because the prototype already did it. The alternative — one share per
distinct size — gives a lone 1.25 kg plate the same volume as two 20s, which inverts *colour
plus size means weight*: a plate would get louder as it got smaller. Proportional-by-count also
matches the drawing under it exactly, particle for plate, which is what makes "throw what's
drawn" true rather than approximate. Proportional by **mass** was rejected on the same test in
the other direction: it nearly erases the small plates, and a 61.25 kg load would never show its
microplate.

### Steel particles are hollow

Answer A makes steel common — every Dumbbell burst, every stack pin block, a bar with nothing on
it. [Microplate accumulation](0011-microplate-accumulation.md)'s rule holds without exception:
**a plate is always a filled shape, and steel is never filled.** A steel particle is a 1 px
outline.

A filled steel slab was rejected: at 5 × 14 px it is the same shape and nearly the same value as
the 1.25 kg grey `#70767C`, so a Dumbbell burst would read as a rack of 1.25s. Throwing nothing
was rejected too — the count of Exercises is the hero, so every Went-up row must land.

**A weak burst is fixed with more particles, never with lighter ones** — ticket 11's rule for
dark plates, now the rule for steel as well.

### Two defects this exposes in the prototype

`design/0009-summary/fitty-workout-summary.html`, recorded in `SPEC.md` §8.2:

- `colours()` falls back to `rack = [added]` — the Increment colour — for every Equipment Type
  that is not plate-loaded. That fallback is replaced by the table above.
- `burst()` fills every particle and draws no rim. Particles need ticket 11's 1.5 px rim, and
  steel particles must not be filled at all.
