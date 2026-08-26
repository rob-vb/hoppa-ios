---
id: 39
title: The Ignition confetti
parent: 17
labels: [wayfinder:task]
status: closed
assignee: agent
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

---

## Resolution

**Built and pushed** (`cdc3d81`). Three files, and the split is the point: `ParticleField.swift`
imports `Foundation` and nothing else, so every number below was **run on the VPS**;
`Confetti.swift` is the `Canvas` and the chip rectangles; `SummaryScreen.swift` keeps only the
order and the timing. What reaches the Mac is the SwiftUI, which is the only part a type-check
cannot judge.

### What the machine proved, so the Mac does not have to

- **The sampling is exactly §6.5's two worked examples.** Over 6000 particles, `20 + 10` per side
  threw **3021 blue / 2979 green**, and `20 + 10 + 2.5 + 2.5` threw **half grey** (2979 of 6000).
  Nothing weights anything: `Rules.burstSource(_:)` returns one entry per plate and the view picks
  uniformly, which is what makes *proportional by plate count* come out for free.
- **The flight, measured.** One burst clears a 750 pt canvas in **1.28 s**. The whole sequence goes
  quiet at **1.27 s at one Went-up row, 1.38 at two, 1.52 at three, 1.65 at four, 1.75 at five**.
  §6.5's *"~1.4 s, after which the screen is quiet"* is therefore right at the small counts and
  stretches to ~1.75 s at five. **Not a finding** — it is the approved variant's own physics, and
  the spec's figure is a "~". Recorded because it is the number Rob will actually watch.
- **A 30 s gap moves a particle 7.7 pt, not through the floor.** A backgrounded Summary comes back
  to a cloud that is where it was, because `advance(by:)` drops everything past four steps.
- **60 / 120 / 30 Hz land within ~10 pt of each other after half a second**, which is the fixed-step
  remainder and not a drift.

`HoppaRules` **143** green and `HoppaStore` **31** green, unchanged — this ticket added no rule,
because ticket 31 had already written `Rules.burstSource(_:)` and its nine tests. Every rules and
store call the new view makes was lifted into a throwaway file and `swiftc -typecheck`ed against the
built modules under `-swift-version 6`. Clean.

### Two things in the prototype that did not port

- **Its constants are per frame, and its browser ran at 60 Hz.** `vy += .42` once per frame on a
  120 Hz phone falls twice as fast. `ParticleField` steps a **fixed 1/60 s off the real clock** and
  carries the remainder, so the burst lasts the same time on any display. Rob's iPhone 16 is 60 Hz,
  so this buys nothing today and costs one accumulator; it is here because the constant would have
  been silently wrong on the next phone.
- **Its spawn box is 34 x 12, and the chip is 9 x 34.** That box is variant B's point-source jitter
  left in place when C was built on top. §6.5 says the burst comes **from the row's own plate
  chip**, so particles now spawn across the chip's own rectangle. Not a §8.2 defect — the spawn box
  is not a spec statement — but it is a deliberate difference from the HTML.

### Where the burst gets its rectangle

The chip reports its frame through a `PreferenceKey` in a named coordinate space that the canvas
shares, because `onGeometryChange` is iOS 18 and the app ships to iOS 17 (ticket 18). The canvas is
an overlay on the same `ZStack`, with no `ignoresSafeArea` on either, so a chip rectangle is the
burst rectangle with no arithmetic in between. **No chip, no burst**: a row whose rectangle has not
been reported has not been laid out, and a burst from `.zero` would come off the corner of the
screen. The sequence waits up to 30 frames for the first report and then goes anyway.

### The two loops that had to be right

- **`TimelineView` is paused unless something is flying.** It starts at the first burst and stops
  when the field empties. A clock left running redraws an empty canvas forever, and §6.5 asks for a
  screen that is *quiet* afterwards.
- **The wait for quiet checks `Task.isCancelled`.** A cancelled `Task.sleep` returns at once, and
  the canvas that empties the field stops rendering when the screen goes — so without the check a
  dismissed Summary spins on the main actor forever. Found by reading, not by running.

### What is still unproven, and it is the whole point of batch 3

**Whether ~75 particles hold 60 fps on the phone**, and whether the burst reads as plates rather
than as sparks. Ticket 31 named this as the one thing argument cannot settle. If it does not hold,
it is a **finding with its own ticket**, and the fallback is fewer particles per burst — never
lighter ones, which §6.5 rules out by name.

Also unproven: the sequence under **Reduce Motion**. The branch is one `if`, and the rows still
land; nothing here can tell whether that reads as intended.

### This closes hand-off batch 3

The walkable path is now empty app → Program → Workout → Finish → Summary. The batch covers
[The Workout Summary](0038-the-workout-summary.md) and this ticket, and it goes over on top of
batch 2, which Rob has not walked yet. Kept here because the map's hand-offs are messages and a
message does not survive the session.

1. `git pull`, then build and run on the phone. → It builds, and the app opens where it was left.
2. Start a Workout on a Day with two or more Exercises. Log every Set at the top of the Rep Range.
   → The rows tick green, and `FINISH WORKOUT` appears in the drawer.
3. Finish. → The Summary lands: a green count, then `WENT UP` one row at a time, each row throwing
   a small burst of plate-coloured slabs out of the chip at its left edge.
4. **Watch the burst, because this is the one thing no test can judge.** Right looks like: plates
   in the colours of the weight you just earned, thrown upward and falling, spinning, fading out at
   the bottom of the screen. Wrong looks like: a stutter or a frame drop while they fly; particles
   that read as grey sparks rather than as plates; a burst that starts anywhere other than the chip;
   a burst on a row that did not go up; steel slabs that look *filled* rather than hollow rings.
5. Watch the timing. The screen must be still and every number readable about a second and a half
   after the last row lands. A cloud that hangs around is a defect.
6. Turn on **Settings → Accessibility → Motion → Reduce Motion**, finish another Workout. → The rows
   still land one at a time, and **no particle appears at all**.
7. `git push` if Xcode changed anything.

**What is not built yet**, so none of it is a defect: Flow 4 (the history list, the streak, the
per-Exercise chart), Flow 5's reorder handles, the delete dialogs and the Re-weigh list, and the
Open Workout on next open — the three tickets still on the frontier are
[the Open Workout on next open](0040-the-open-workout-on-next-open.md),
[a weight retyped after a unit change](0041-a-weight-retyped-after-a-unit-change.md) and
[the MICRO stepper on a mixed-unit pin](0042-the-micro-stepper-on-a-mixed-unit-pin.md).
