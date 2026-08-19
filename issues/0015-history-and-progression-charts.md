---
id: 15
title: History and progression charts
parent: 1
labels: [wayfinder:prototype]
status: closed
assignee: henk
blocked-by: []
---

## Question

Flow 4, graduated from the map's fog. Fitty moves the user's weight up and then shows the climb
nowhere. An app whose whole mechanism is progression, with no way to see the progression, is
missing its reward — so this is a hole in the validated flows, not a new feature.

What to settle:

- **Which views exist.** A per-Exercise weight-over-time chart is the obvious one. Beyond it:
  a Workout list or calendar, per-Workout-Day volume, a streak or frequency view, an
  all-Exercises overview. Each one earns its place or it does not ship.
- **Where history is reached from.** [Workout summary screen prototype](0009-workout-summary-screen.md)
  ends on a single `DONE`, and the exercise counter `3 / 5 ▾` is the only navigation in the
  logging screen. Fitty has no tab bar yet, and this ticket is what forces one — or refuses one.
- **What a per-Exercise chart plots.** Working Weight is the honest line, because it is what
  Fitty tracks and what progression moves. Estimated 1RM, volume per session and top-set reps
  are the alternatives, and each says something different about a plateau.
- **The Name is a label, not an identity**
  ([Exercise name suggestions](0010-exercise-name-suggestions.md)), so `Barbell Bench Press` in
  Day A and Day C are two lines, not one. That decision explicitly left it open whether charts
  may group by name anyway. Decide it here.
- **A One-off Weight is logged but never becomes the Working Weight**
  ([Progression edge cases](0004-progression-edge-cases.md)). Does it appear on the chart, and
  how, without reading as a drop?
- **Skipped Exercises log no Sets.** A gap in the line, or nothing at all?

### Mixed units

The hard part, and the reason this is not a small ticket.
[Progression edge cases](0004-progression-edge-cases.md) put the Weight Unit on the Exercise, so
one Program mixes kg and lbs, and a Microloading Exercise can carry a Microload in the *other*
unit again — `100 LBS + 1 KG`.

[Workout summary screen prototype](0009-workout-summary-screen.md) set the precedent worth
reusing: **a per-Exercise number never converts; an aggregate over several Exercises converts to
the Program's default and says so in its label** (`KG VOLUME`). A per-Exercise chart is
therefore safe. An overview chart across Exercises is where it bites, and a Microload has no
sensible place on either.

### Constraints already fixed

- Dark first, "Plate Rack" language
  ([Design language & visual direction](0002-design-language-and-visual-direction.md)), amended
  by [Microplate accumulation](0011-microplate-accumulation.md): **colour plus size means
  weight, and a plate is always filled while steel is never filled**. A chart's line colour must
  not claim to be a plate.
- A Workout keeps the day it started, even when finished the next day
  ([Workout session lifecycle](0003-workout-session-lifecycle.md)). That is the date the x-axis
  uses.
- Fitty states, it never advises. A chart shows what happened; it does not tell the user they
  are behind.

Prototype ticket: produce `/design` artboards, and back any chart with real fixture data from
the logging prototype's module rather than invented curves. Consult the **dataviz** skill for
the chart forms and the **frontend-design** skill for the surface, and hold both to the palette
rules above.

Depends on nothing, but it reads better once
[Editing a Program over time](0014-editing-a-program-over-time.md) has settled what deleting an
Exercise does to its logged Sets.

## Resolution

Flow 4 exists. Ten artboards, every number on them produced by Fitty's own progression rules
rather than drawn by hand.

Asset: [Fitty History and Charts canvas](https://claude.ai/code/artifact/a6451a92-3c59-4d4c-a1ce-7a3c81112989)
— source in `design/0015-history/`. The rejected chart stays on the canvas as the record of the
choice.

### Two doors, and no tab bar

History is reached from the two places the user already stands: a **HISTORY row at the foot of
the Workout Day picker**, and **every Exercise card in the Program sheet**, which opens that
Exercise's chart and already carries a sparkline so the door announces itself. A tab bar was
refused. It is permanent chrome on an app built for big numbers and thumbs, and Fitty is one
screen deep — a tab bar would be the only thing in it that assumed otherwise.

### Three views ship

**The per-Exercise chart**, **the Workout list**, and **a week streak**. An all-Exercises
overview and a volume view were both dropped: one shared axis is impossible across mixed units,
and volume falls when the weight rises and the reps reset, so a progression would read as a loss.

### The chart plots the Working Weight, and the reps are a grid

The line is the Working Weight — what Fitty tracks and what progression moves — drawn in
**steel**, because a plate colour on a line would claim to be a plate. Green is the single
exception: [Design language & visual direction](0002-design-language-and-visual-direction.md)
already made green mean progression everywhere, so a **green dot is a session that earned the
step** and a steel dot is one that did not. Estimated 1RM and volume were rejected as computed
guesses about a lift Fitty does not track.

The reps were the real question, and **the ticket's own answer lost to the alternative it
provoked**. Reps as a figure over each point — the option picked before drawing — collides at
fifteen sessions and makes one number carry two meanings (the best Set, and, in green, all Sets).
Instead the reps are a **Set grid under the line**: one column per session, one cell per Set,
filled where that Set met the threshold of its Progression Mode. Three filled cells *is* the
progression rule, so the grid answers "why did it not go up" with no words, no advice and no
collisions. Both were drawn on the same data and compared; the user took the grid.

A **Last sessions** list under the chart carries the exact rep counts for the four most recent
sessions, so nothing lives only in a picture.

### Solid is lifted, dashed is not

New, and not in the ticket. Fitty applies the progression at Finish, so after a session that went
up, the weight on the Exercise card is one step above the last weight actually lifted. The hero
number and the end of the line would contradict each other. A **dashed green step to a hollow
NEXT marker** carries the difference: solid is lifted, dashed is applied but not yet performed.

### The cases the ticket asked about

- **A One-off Weight** never joins the line, so the line never dips. It hangs **off** the line as
  a hollow marker at the weight actually lifted, tied to its session by a dotted drop, labelled
  ONE-OFF. Its column in the Set grid is never filled, whatever the reps: a One-off cannot
  progress, and a full green column beside a step that never came would be a lie.
- **A Skipped Exercise** draws nothing at all — no point, no gap marker. The x axis is real time,
  not the session number, so the pause is already in the spacing. The same axis makes a missed
  week visible on every chart at once.
- **Grouping by Name** is refused. The Name is a label, not an identity, so `Barbell Bench Press`
  in Upper A and in Upper B are two lines with their own Working Weight. Joining them would splice
  two lifts into a line where no point is true. They sit apart in the list, each under its
  Workout Day.

### Mixed units: the pin never moved

Lat pulldown is an lbs stack with a kg Microplate on the pin, and the two units never convert, so
there is no single number to plot. In fifteen weeks the **pin has not moved once** — every gram of
the climb is in the Microload — so the **Microload is the line**, the axis reads `+ KG`, and the
two heroes stack as `90 LBS` and `+ 3 KG` with their own labels.
[Workout summary screen prototype](0009-workout-summary-screen.md)'s precedent holds: a
per-Exercise number never converts. No aggregate view ships, so the converting half of that
precedent never gets used.

### The streak states, it never punishes

A week counts as soon as it holds **one Workout** — the question was "did you go to the gym", and
a busy week with one session should not wipe the run. The strip is 16 week blocks; the missed
week is a darker block and **nothing else**: no flame, no warning, no notification, no "streak
lost", and no best-ever number to fall short of. The grid is the hero and the count is a fact
about it. This is the one view that could have broken *Fitty states, it never advises*, and the
absence of a best-ever number is what keeps it whole.

### Deleting a past Workout

Delete exists, and **the Working Weight stays where it is**. Fitty applied the progression at
Finish and never lowers a weight by itself; recomputing the chain would also reach past any weight
the user later set by hand. The confirm states both halves — what it removes, and what it does not
touch — so the plain confirm
[Editing a Program over time](0014-editing-a-program-over-time.md) gave a delete holds here too.

Its button is the **25 kg plate red**, which settles a palette question this screen raised: a
filled rectangle of plate colour is a plate **only inside a Plate Breakdown**. Outside one, the
palette is just Fitty's palette, and red is free to mean destructive. Rule 1 —
*colour plus size means weight* — is a rule about the loaded bar, not about every pixel.

### What building it found

Running the real rules forward over 16 weeks did something no single screen had: it showed that
**nothing ever stops a Microload**. Microloading on a mixed-unit Exercise adds a Microplate to the
Microload at every progression and nothing ever moves the pin, so with the user's own 1 kg
Microplate the Lat pulldown reaches **+11 kg hanging on a pin** — a weight no hook carries. The
fixture uses a 0.25 kg Microplate so the screens are honest, but the hole is real and it is not a
chart problem: it changes progression, the Plate Inventory and the logging screen. It graduated to
its own ticket, [Bounding the Microload](0016-bounding-the-microload.md), with the constraint that
makes it hard already established — **a roll-up into the pin would have to convert kg into lbs,
and this map forbids that everywhere**, so the answer cannot be arithmetic.
