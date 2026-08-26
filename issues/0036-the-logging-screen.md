---
id: 36
title: The logging screen
parent: 17
labels: [wayfinder:task]
status: closed
assignee: agent
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

## Resolution

**§6.4 is built and pushed.** `LoggingScreen.swift` (918 lines), `PlateDrawing.swift` (415) and
`PlateGlyph.swift` (94), plus §7.3's plate rim in `Palette.swift` and one swapped `case` in
`HoppaApp`. `HoppaRules` **119 green**, `HoppaStore` 31, and `project.pbxproj` needed no edit
again — the app target is a synchronized folder group, so three new files arrive by themselves.

**Nothing here is a rule.** Every call the screen and the drawing make into `HoppaRules` and
`HoppaStore` was lifted into a throwaway file and `swiftc -typecheck`ed here against the built
modules under `-swift-version 6`. `PlateGlyph.swift` imports nothing but `HoppaRules`, so it went
further: it was **compiled and run** on the VPS, and it reproduces ticket 0031's reference sizes
exactly and is monotone in both units. What is left unproven is the SwiftUI, which is ticket
0022's line and nothing more.

### §7.1 rule 2, taken at its word — and the bar does not look like the prototype

*"A plate is always a filled shape, and steel is never filled. Steel is text and a 1 px border,
always."* [Drawing the loaded bar](0031-drawing-the-bar-and-the-confetti.md) chose plain `Shape`s
over `Canvas` for exactly this — the distinction is in the type system there and is one call on a
shared context in a `Canvas` — and this is where it lands on a screen.

**So the collars, the sleeve stops, the knurled shaft, the sleeve, a stack's blocks, the pin, the
dumbbell and the belt clip are all hollow outlines.** The prototype fills every one of them. That
is not a tenth §8.2 row — §8.2 is the `Fitty` *module*, and `drawBar()` lives on the throwaway page
around it — but it is a **visible departure from the artboard, made on purpose**, and it is the
first thing to look at on the phone. If hollow steel reads as unfinished at arm's length in a gym,
that is a **finding with its own ticket**, and the fallback is a fill at a low opacity that still
cannot be mistaken for a plate. It is not a reason to fill steel outright: rule 2 is what keeps the
1.25 kg grey `#70767C` from reading as the steel of the `≈ CLOSEST` chip, and that pair is on this
very screen.

An **lbs plate** falls out of the same rule for free. §7.3 paints no lbs rack, so
`PlatePalette.hex(for:)` answers `nil`, the plate falls back to steel — and steel is never filled,
so it draws as a hollow outline at its right size. Rule 1's own claim is that size carries the rest
of the meaning, and there it is carrying all of it.

### Plate geometry: a kg table, then a ramp

`PlateGlyph.size(for:)` is shaped exactly like `PlatePalette.hex(for:)`, and for the same reason:
**the spec paints one gym's rack, in kg.** So the kg sizes are a table at ticket 0031's measured
values — 20 at 34×114 down to 1.25 at 11×60, the 25 extrapolated one step above the 20 — and the
microplates run 26 down to 17, which is §7.1 rule 1's *roughly a quarter of the smallest normal
plate*, a step the prototype never drew because it never drew a microplate.

Everything else falls to a **piecewise-linear ramp on the fraction of a full rack**, anchored on
the kg table's own normal-plate points so an lbs rack draws in the proportions the kg one was
measured at. **The ramp carries no microplate cliff, on purpose**: `2.5 lbs` sits in both the
normal and the Microplate group of §5.2's shipped list, so no weight alone can say which one is on
the bar, and a ramp that guessed would draw the wrong one half the time. The cliff is a fact about
the kg rack, and the kg rack has a table. This is the same lbs gap the map already holds in
**Not yet specified**, seen from a third side.

**§7.3's rim is real and it is a derivation, not a hue.** Every plate gets *a 1 px rim one step
lighter than its face* — written in §7.3 for the black family, given to every plate because a rim
on only three sizes would itself be a signal. Each channel moves 30/255 towards white, which is the
step `#33373A → #4E5358 → #70767C` are spaced at, so the 5 kg's rim lands beside the 2.5 kg's face.
Ticket 0030's escalation rule fires nothing, for the third time.

### What the view holds, and what it hands to the rules

Three lines, and they are what keeps §8.2 from happening again:

- **The rep counter is view state.** `Action.logSet(reps:)` takes a finished number and its own
  doc-comment says why: the prototype's reducer mixed the screen, the overlay and the keypad buffer
  in with real rules, and none of that can fail a test. `pendingReps` lives in the view and reaches
  the rules once, as an argument. It clears on every log, every `NEXT`, every pick from the drawer
  and every menu action — a `−` on one Exercise must not follow the user to the next.
- **The Rest Timer holds no clock.** `restStartedAt` is a `Timestamp` the rules write and a
  `TimelineView(.periodic)` reads `now − restStartedAt`, so a lock, a background and a phone call
  cost no code — ticket 0024's claim, now standing on a screen.
- **The rule chip asks `Rules.evaluateProgression`.** The green `→ 75 KG NEXT TIME` is the rules'
  own answer, including the four cases where a Completed Exercise does **not** move (no Working
  Weight, stranded, the refused Dumbbell combination, no Microplate switched on) — the chip then
  reads steel `STAYS 72.5 KG`. A view that worked it out again would be a second copy of §4.1.

### Three things the ticket did not name, and one it did not foresee

- **The `•••` menu is here** — Skip / Put it back / Done early / Change the weight / Finish /
  Discard. The ticket named only the Finish gate, but §3.3 puts **Discard in a menu, never beside
  Finish**, and §3.2's three states have nowhere else to be reached. Walkthrough 6 — skip the
  Barbell row, reopen it later — has no screen without it.
- **Finish and Discard pop to the picker.** [The Workout Summary](0038-the-workout-summary.md)
  takes that line: Finish goes to the Summary. Until then the picker is the only place to land, and
  a Workout that finished with nowhere to go would be worse.
- **The weight sheet is a `NotBuiltYet`** presented from the big number, in `Route.swift`'s own
  *the door is real, the room is not* shape. [The weight sheet](0037-the-weight-sheet.md) replaces
  the body and touches nothing else. Batch 2 goes over after it, so Rob never meets the placeholder.
- **One Open Workout at a time is reachable mid-session, and it now has a screen.** Start Upper,
  press back to the picker, tap Lower: `Rules.reduce` refuses the second `.startWorkout` and in
  silence that leaves a blank screen. The screen now says which Day is running and offers the one
  door to it. This is **not** [The Open Workout on next open](0040-the-open-workout-on-next-open.md)
  — that one asks resume, finish or discard about a Workout from an earlier day, and this one only
  has to point — but ticket 40 should know it exists, and its body now says so.

Two SwiftUI hand-overs were written around rather than discovered on the Mac: **a sheet presented
in the same tick as another is dismissed is dropped**, so the Finish gate replaces the menu as a
`.sheet(item:)` swap instead of a nil-then-set; and the drawer's own `FINISH WORKOUT` waits for the
full-screen cover's `onDismiss` before it opens the gate. The Finish gate is the one thing on this
screen that must never be silently dropped.

**And the screen must never say a day is gone before it has started.** `.task` runs after the first
body, so the first frame has no Open Workout — the empty state is `Color.clear`, and *that day is
gone* is reserved for a Day the Logbook really does not hold.

### What only the Mac can answer

All in the hand-off, so none of it is read as a defect:

- **Whether hollow steel reads at arm's length**, above.
- **Whether the bar fits.** Every part's width is known before layout, so `LoadedBar` shrinks to fit
  rather than clipping when five plates a side land on a 390 pt phone. Unmeasured.
- **Whether `Typography.display(88)` at `leading(.tight)` holds §7.4's 0.78.** The Working Weight is
  the biggest type in the app and the tightest, and ticket 0033 already recorded that SwiftUI cannot
  state a line-height below 1.0 as a number.
- **Whether the Rest Timer's `.periodic` ticks after the phone sleeps.** It reads a `Timestamp`, so
  the number is right whenever it redraws; whether it redraws promptly on wake is a phone question.
