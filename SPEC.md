# Hoppa — Specification

**Status**: complete for the flows this map charted. Build-ready.
**Produced by**: [Fitty prototype map](issues/0001-fitty-prototype-map.md), ticket [Assemble the spec](issues/0008-assemble-the-spec.md).
**Date**: 2026-08-19.

This document is the handoff from the design effort to the build effort. It states what Hoppa
does and how it looks, with the reasoning compressed out; every section links the ticket that
holds the argument, the options rejected, and the trade-offs the user accepted by name. Read a
ticket when you want to know *why*; read this document when you want to know *what*.

Three companions, all normative:

| Artefact | Holds |
| --- | --- |
| [`CONTEXT.md`](CONTEXT.md) | The glossary. Every capitalised term below is defined there and nowhere else. |
| `design/` | The validated artboards and clickable prototypes, per ticket. |
| `issues/` | The decision record, one file per ticket. |

Where this document and `CONTEXT.md` seem to disagree, `CONTEXT.md` wins on *what a term means*
and this document wins on *what the app does*.

---

## 1. The product

Hoppa is a public iOS app for tracking strength-training workouts. It follows a lifter through a
Program they wrote themself, logs the Sets they perform, and moves the weight up when they earn
it.

**The audience is not the beginner.** The user's own words while choosing the entry model:
*"Deze app is niet voor de beginner, maar iemand die er al wel wat verstand van heeft."* Someone
who knows a Smith machine from a cable stack does not want the app to decide for them. This
single fact settled the most expensive decision on the map — see §6.2 — and it should settle the
next one the same way: **when in doubt, ask the user rather than infer.**

Three consequences run through every screen:

1. **Hoppa states, it never offers.** Progression is applied, not suggested. There is no Accept
   and no Undo (§4.1, §6.5).
2. **Hoppa shows what happened; it does not scold and it does not console.** Skipped Exercises
   are listed plain. Reps over the range are printed plain. A zero-progress day gets a calm
   screen, not encouragement (§3.3, §6.5).
3. **Hoppa never acts by itself.** It never picks a Workout Day, never starts a Workout, never
   finishes one, never deloads, and never jumps to the next Exercise (§3.1, §4.4).

### 1.1 What this spec covers

Four flows, all validated with the user against drawn screens:

- **Flow 1 — Onboarding**: creating a Program, the plate rack, entering Exercises.
- **Flow 2 — Logging**: performing a Workout.
- **Flow 3 — Summary**: what the user sees at Finish.
- **Flow 4 — History**: the Workout list, the streak, and the per-Exercise progression chart.

A fifth is specified but not drawn:

- **Flow 5 — Editing a Program** (§6.6): changing a Program that already has Workouts behind it.
  Its rules are settled and its screens were deliberately left to the build, because add and edit
  are the same sheet and only three small screens have no precedent.

No flow is missing. One **rule** is wrong and has a live ticket; see §9.

Implementation, persistence, backend and App Store release are out of scope; see §10.

---

## 2. The domain model

`CONTEXT.md` defines the terms. This section gives the shape a build needs: which entity holds
which field, and which fields are conditional.

### 2.1 Program

| Field | Notes |
| --- | --- |
| Name | Free text. |
| Workout Days | Ordered list. |
| Progression Mode | Default for its Exercises. An Exercise may override it. |
| Default Weight Unit | For **new** Exercises only. A Program may hold Exercises in both units. |

A user may hold more than one Program. Exercise names are read across **all** of them (§6.3).

### 2.2 Workout Day

| Field | Notes |
| --- | --- |
| Name | Free text — "Push", "Upper A". |
| Exercises | Ordered list. |

### 2.3 Exercise

Ten fields. Two of them are conditional on Equipment Type, and one row on the sheet swaps with
the Progression Mode. Weight Unit is printed beside Working Weight, so the user never sees more
than eight fields at once (§6.2).

| # | Field | Shown for | Notes |
| --- | --- | --- | --- |
| 1 | Name | always | Free text. A **label, not an identity** — see §2.7. |
| 2 | Equipment Type | always | One of five; see §2.6. |
| 3 | Weight Unit | always | Printed beside Working Weight. Steel text for the three types loaded off the user's own rack — Barbell, Machine (Plates) and Bodyweight — and for an add sheet before a chip is picked. Dumbbell and Machine (Stack) get a one-tap chip. No lock line. |
| 4 | Sets | always | Carries over from the previous Exercise. |
| 5 | Rep Range | always | Carries over from the previous Exercise. |
| 6 | Working Weight | always | Any number the user types. Bodyweight: added weight only. **May be unset**: a new Exercise has none until the user types one, and §6.6 clears it back to unset. Unset is not zero — see §2.8. |
| 7 | Increment | Progressive Overload | Any number. Defaults 2.5 kg, 5 kg for legs (lbs: 5 / 10). **May be unset**, like the Working Weight, and §6.6 clears it with it. |
| 7′ | Microloading Increment | Microloading | Picked from the Microplates in the Plate Inventory, never typed. Keeps the **Inventory's** unit. |
| 8 | Progression Mode override | always | Inherits from the Program. |
| 9 | Base Weight | Machine (Plates) | The empty-carriage weight. No default; typed per Exercise. |
| 10 | Stack Step | Machine (Stack) | The fixed jump of the stack, e.g. 10 lbs. |

Plus one derived-and-stored value:

| Field | Notes |
| --- | --- |
| Microload | A **weight** in the Plate Inventory's unit, hanging on the pin. Exists **only** on a Machine (Stack) whose Weight Unit differs from the Plate Inventory's — the only place with somewhere to hang it and a Stack Step to roll it into (§4.2). Zero otherwise. Never a count of plates, and **always less than one Stack Step**. |

**The Exercise always holds both Increments**, whatever its current Mode. Switching the Mode
swaps the row on the sheet and keeps the other value, so nothing is ever re-asked.

### 2.4 Workout

One performance of a Workout Day.

| Field | Notes |
| --- | --- |
| Workout Day | Which Day was performed. |
| Started at | The Workout keeps **the day it started**, even when finished the next day. |
| State | Open until Finish or Discard. **One Open Workout at a time.** |
| Exercise States | Open / Completed / Skipped, per Exercise. Every Exercise starts Open. |
| Sets | Logged per Exercise. |
| Names | The Workout Day's Name and each performed Exercise's Name, **as they read at the time**. A fallback only: Hoppa shows the live Name while the thing still exists, and reaches for this copy after a delete (§6.6). |
| Progression outcome | Per performed Exercise, **what progression did**: the planned Sets and the threshold that applied, whether the Exercise went up, and **the Working Weight it ended on**. Written at Finish, never recomputed. |

**The outcome is stored because the question it answers moves.** §6.7 draws a green dot for a
session that progressed, a steel one for a session that stayed, and a Set grid with one cell per
Set filled where that Set met the threshold of its Progression Mode. The threshold is the top or
the bottom of the Rep Range, and the Rep Range is editable. Solve those cells live, and changing
`8–12` to `6–10` today silently re-fills every grid and moves every dot in the whole history. That
is §2.5's defect in a second place: a record of the past that a later edit rewrites. So the Workout
keeps the planned Sets, the threshold reps and the progressed flag as **facts**, exactly as the Set
keeps its weight.

**The weight it ended on is stored for the same reason**, and §6.7's Workout detail is what
found it. The Summary (§6.5) reads a Working Weight live and is right to: it stands between
Finish and `DONE`, and nothing can edit an Exercise in between. Open a Workout from three weeks
ago and the live weight has moved on, so a row reading it claims a progression that never
happened. Nor can it be recomputed: adding the Increment back reaches an Increment that is
editable (§2.8), and any weight the user has since set by hand (§4.3) is past recomputing
altogether. So the Workout keeps it, and the row states a fact.

> Found while building. Decision record:
> [Persistence and the data model](issues/0019-persistence-and-the-data-model.md), and
> [A past Workout opened and deleted](issues/0048-a-past-workout-opened-and-deleted.md).

### 2.5 Set

**A Set is the record of a performance, and nothing later changes it.** It holds:

| Field | Notes |
| --- | --- |
| Reps | The count achieved. |
| Weight | The weight lifted, **stored on the Set** — not read live off the Exercise. |
| Weight Unit | As performed. |
| Microload | As performed, where the Exercise had one (§4.2). |
| One-off mark | Set under a One-off Weight, yes or no. |

The weight sits on the **Set** and not on the logged Exercise, because §6.4 lets the user raise
the weight part-way through an Exercise: the Sets before that raise were lifted lighter, and one
weight per Exercise would lie about them.

The weight is logged against the **Working Weight** — never against the load actually on the bar
(§5.4). **A Set stores no Plate Breakdown.** The breakdown is a solve against the Plate Inventory
and the Progression Mode (§5.3), and both can change; storing the picture would turn every
Inventory edit into a history migration, to answer a question nobody asked.

> Without this, the Exercise is the only home of a number that must not move — and progression
> raises it at every Finish, so every past Workout would show the weight the user lifts *now*.
> Decision record: [Editing a Program over time](issues/0014-editing-a-program-over-time.md).

### 2.6 Equipment Type

Five types, in chip order (`EquipmentType.allCases`):

- **Barbell** — 20 kg bar (45 lbs). Prints no Base Weight; the bar is standard. Plate Breakdown applies. Weight Unit comes from the Plate Inventory.
- **Dumbbell** — weight per dumbbell. Sets count both dumbbells for volume. Weight Unit is the Exercise's own — the number the machine itself is marked with.
- **Machine (Plates)** — Smith and plate-loaded machines. Base Weight per Exercise. Same loaded-bar drawing as Barbell. Plate Breakdown applies. Weight Unit comes from the Plate Inventory.
- **Machine (Stack)** — selectorized stack and cable. Pin weight plus Microplates. Weight Unit is the Exercise's own.
- **Bodyweight** — added weight only. The added weight **is** a plate off the user's own rack,
  hanging from a belt, so its unit comes from the rack. It has no Plate
  Breakdown of its own — it draws one plate (§5.5) — but the unit rule is the same one: you cannot
  hang a plate you do not own.

**Microloading is available on every one of the five.** The user notes that people tie
microplates to dumbbells, so Hoppa blocks no type. One combination has nowhere to put the plate
and is refused: **Microloading on a Dumbbell whose Weight Unit differs from the Plate
Inventory's**. A Dumbbell has no pin and no Stack Step, so there is neither somewhere to hang a
Microload nor anything to roll it into (§4.2). Hoppa states this on the Exercise sheet, where the
user stands, in the manner §5.2 already uses for an empty Microplate group: *a dumbbell has
nowhere to hang a plate — set this exercise in kg, or use progressive overload.* A Dumbbell in the
**same** unit as the Inventory microloads normally: the plate ties on and raises the Working
Weight.

### 2.7 The Name is a label, not an identity

`Barbell Bench Press` in Day A and in Day C are **two Exercises** with two Working Weights, and
Hoppa never ties them together through their names. A lifter deliberately presses heavier on one
day than the other, and progression is per Exercise.

Two things follow, and a build must not undo them:

- Renaming is free. It keeps the logged Sets and the Working Weight. There is nothing to migrate.
- The own-names suggestion source is a **set of strings**, not a list of movements (§6.3).

This left it open whether charts could group by name anyway. They do not: §6.7 refused it, because
joining two Exercises that progress apart produces a line where no point is true.

> Decision record: [Exercise name suggestions](issues/0010-exercise-name-suggestions.md).

### 2.8 What storage must guarantee

§10 keeps the build itself out of this spec, and that stands: **how** the app writes to disk is the
build's business. But §2 does impose requirements on any store, and they are the part a build can
get wrong quietly. They are gathered here so nothing has to be re-derived from three sections.

- **A Set is a value, not a view of the Exercise.** Nothing may reach a stored Set from a distance
  and move its numbers (§2.5).
- **Identity is a stored id.** A Name never identifies anything (§2.7). An id is never reused after
  a delete, so a dead Exercise can never be confused with a new one.
- **The Name is read live and kept as a fallback.** History points at the id and carries the Name as
  it read; the store must let that link survive the deletion of its target (§2.4, §6.6).
- **A Workout keeps what progression did**, because the Rep Range and the planned Sets change
  afterwards (§2.4).
- **A weight is exact, and it carries its unit.** A weight is a whole number of hundredths of its
  unit, so `≈ CLOSEST` and *is the Microload now one Stack Step* stay exact comparisons (§5.4,
  §4.2). The unit rides on the number, so *units never convert* (§5.1) is something no rule can
  break by accident.
- **The Weight Unit of a plate-loaded Exercise is not stored on it.** Barbell, Machine
  (Plates) and Bodyweight read it from the Plate Inventory, so a stale copy cannot exist (§5.1,
  §6.6).
- **An unset weight is not zero.** A weight the user has not typed — a new Exercise, or one §6.6
  has just cleared — is **absent**, and the store must be able to say so. Zero is a real weight: a
  Bodyweight Exercise done with no belt. An Exercise with no Working Weight does not progress, and
  the Re-weigh list (§6.6) is exactly the Exercises that have none.
- **A Base Weight and a Stack Step survive a change of Equipment Type; a Microload does not survive
  a change of unit.** The first is a fact about a machine in the gym and §2.3 refuses to re-ask it.
  The second is a state that belongs to a unit, and §6.6 destroys it and recreates it at zero.

> Decision record: [Persistence and the data model](issues/0019-persistence-and-the-data-model.md),
> [Program edits, and which of them are rules](issues/0026-program-edits-and-the-rules-boundary.md).

---

---

## 3. The Workout lifecycle

> Decision record: [Workout session lifecycle](issues/0003-workout-session-lifecycle.md).

### 3.1 Picking and starting

- **Free pick, always.** Hoppa never chooses the Workout Day and never pre-selects one. No
  rotation, no suggestion.
- The Workout Day list shows **when the user last did each Day** — "Push — 4 days ago". That is
  information, not advice. It reads the newest **finished** Workout on that Day, by the day it
  **started** (§2.4); the Open Workout does not count, because it has been started and not done.
  A Day that has never been done reads `Never` — which is every Day of a Program the user has just
  created, so it is the common first case and not an edge. The phrasing is in **calendar days**:
  `Today`, `Yesterday`, then `n days ago`.
- A Workout starts on an **explicit action**, not on the first logged Set. This gives a warm-up
  window and makes the start moment unambiguous for duration.
- One Open Workout at a time.
  **While one is Open, its Day's line reads `Running`** in place of the last-trained line —
  that line reads the newest *finished* Workout, and running now is the more useful of the two
  facts while it is true. **The other Days stay tappable.** The rules refuse a second start,
  and the logging screen meets that arrival with a screen naming the Day that is running and
  one door back to it. A dead row would refuse in silence, and silence explains nothing.
  Found while building; decision record in §3.3.

### 3.2 Exercise States

Open, Completed, Skipped. The distinction the user insisted on, which the UI must never
conflate:

> **Navigating past an Exercise means "later". Skipping means "not at all".**

- An Exercise becomes **Completed automatically** when the user logs all planned Sets. This is
  the normal path and costs no taps.
- **"Done early"** completes an Exercise with fewer Sets. It exists because stopping at 2 of 3
  Sets is real work, and calling it Skipped would be a lie.
- A **Skipped** Exercise logs no Sets and never progresses. It can be **reopened** inside the
  same Workout — the busy-rack case.
- A **Completed** Exercise goes back to **Open** when the user raises the planned Sets above the
  number of Sets logged (§6.6). Finish is gated again, and the user logs the missing Set or ends
  early. Otherwise the edit would take away a progression the user earned, with no way to earn it
  back the same day.
  **"Done early" is the exception.** It never earned a progression, so a raise takes none away, and
  ending early is a deliberate act that an edit made afterwards must not argue with. So a raise
  reopens what Hoppa completed **by itself** — the Exercise whose logged Sets reached its plan —
  and leaves a Done-early Exercise Completed.
- **Lowering** the planned Sets to the number already logged **Completes** an Open Exercise. It is
  the mirror of the rule above, and without it the Exercise is stuck: the plan is full so no Set
  can be logged, nothing fires to complete it, and it holds the Finish gate until the user finds
  *Done early*.

> Both sharpenings were found while building. Decision record:
> [Program edits, and which of them are rules](issues/0026-program-edits-and-the-rules-boundary.md).

### 3.3 Ending a Workout

- **Finish is gated**: allowed only when no Exercise is Open.
- The gate has a **shortcut**, because it would otherwise bite hardest when the user wants to
  leave. Tapping Finish with Open Exercises prompts *"3 Exercises are still open. Skip them and
  finish?"* One tap skips them all and finishes. Nothing becomes ambiguous — every Exercise still
  ends Completed or Skipped.
- **Discard** sits in a menu, never beside Finish, and asks for confirmation. A Workout with no
  logged Sets discards without a question.
- Hoppa **never ends a Workout by itself**, at any time interval.
- An Open Workout from an earlier day is **not** closed silently. On next open Hoppa asks:
  resume, finish, or discard.
  **An earlier day is a calendar day**, the same test §3.1's picker line uses, and not an
  elapsed gap. The word in this spec is *day*, and a Workout carries one clock — Started at
  (§2.4) — because a Set holds no timestamp, so *hours since the last Set* is not a question
  the model can answer. The cost is one case and it is accepted: a Workout started at 22:00
  and opened at 01:00 in the same session is on a new calendar day, so Hoppa asks. The
  question destroys nothing and **resume** is one tap.
  **The question lives on the picker**, as a sheet over it: the picker is home (§6.1), so
  *on next open* is *on the picker*, and a sheet keeps the Program behind the question.
  **Finish takes the gate's shortcut in place.** A forgotten Workout almost always has Open
  Exercises, so the Finish answer carries *"3 Exercises are still open · will be skipped"*
  where the user taps, and one tap finishes. Discard asks its confirmation exactly as above.
  A Finish lands on the Workout Summary (§6.5); a Discard stays on the picker.
  **The question comes back at the next launch, not at every glance.** Hoppa never ends a
  Workout by itself, so dismissing the sheet is not an answer — but it is not a trap either:
  the picker keeps showing which Day is running (§3.1) and the question returns next launch.

> Found while building. Decision record:
> [The Open Workout on next open](issues/0040-the-open-workout-on-next-open.md).

---

## 4. Progression

> Decision record: [Workout session lifecycle](issues/0003-workout-session-lifecycle.md),
> [Progression edge cases](issues/0004-progression-edge-cases.md),
> [Microplate accumulation](issues/0011-microplate-accumulation.md).

### 4.1 The rule

Hoppa evaluates progression **per Exercise, never per Workout**, and applies the result **at
Finish**. There is no pending suggestion and no acceptance step; the Workout Summary announces
the change as old → new.

An Exercise progresses only when **both** hold:

1. The user logged **at least the planned Sets**. Fewer Sets means no progression, even when every
   logged Set hit the threshold.
2. **Every** Set met the threshold of the Exercise's Progression Mode — the **top** of the Rep
   Range under Progressive Overload, the **bottom** under Microloading.

**Hoppa reads the Exercise as it stands at Finish** — the Mode, the planned Sets and the Rep
Range. An edit made at the rack therefore counts for the Workout it was made in (§6.6), and
*at least* rather than *exactly* keeps that from producing arithmetic surprises: drop the planned
Sets from 4 to 3 with three logged at the top, and the Exercise progresses, because three Sets at
the top is what the plan now asks for.

Two consequences the user accepted with the trade-off named:

- **"Done early" never progresses.** Two Sets at 12 out of a planned three does not raise the
  weight. Otherwise the user progresses by doing less and the weight climbs faster than the
  strength. The user is the first test user and expects this rule to bite; revisit only if it
  does.
- **A user who progressed by luck must lower the weight themself next time.** That makes the
  manual weight change the escape hatch, so it must be fast (§4.3).

Hoppa **never lowers a Working Weight by itself**, ever.

### 4.2 What moves, and by how much

| Mode | Fires when | Moves |
| --- | --- | --- |
| Progressive Overload | every Set reaches the **top** of the Rep Range | Working Weight, by the Increment |
| Microloading | every Set reaches the **bottom** of the Rep Range | Working Weight by the Microloading Increment — **or** the Microload on a mixed-unit stack, which rolls into the pin at one Stack Step |

**Microloading moves a weight, like every other progression.** Hoppa stores a weight and never a
count of plates. This is the single model; an earlier prototype held a second one (a microplate
counter) and it is deleted — see §8.2.

**A bar takes a pair.** Barbell and Machine (Plates) have two sides, so a
0.25 kg Microloading Increment moves the weight by **0.5 kg** there. Every other Equipment Type
takes one plate, so the same Increment moves it by 0.25. The picker states both:
`0.25 kg microplate · +0.5 kg on the bar`.

**The mixed-unit case is the only two-number case.** On a Machine (Stack) whose Weight
Unit differs from the Plate Inventory's, Microloading moves the **Microload** instead, and the
screen stacks two numbers that never convert: `100 LBS` over `+1 KG`. Hoppa does the mixed-unit
arithmetic itself and never shows the result of it; the user never types 2.76 lbs.

#### The roll-up: a Microload is never bigger than one Stack Step

> Decision record: [Bounding the Microload](issues/0016-bounding-the-microload.md).

A Microload that only ever grows reaches a weight no hook carries — with a 1 kg Microplate on a
10 lbs stack it passes **+11 kg** inside four months. So the pin moves.

**At every Microloading progression on a mixed-unit stack:**

1. The Microload goes up by one Microplate, as always.
2. **While** the Microload is at or past one Stack Step, Hoppa adds one Stack Step to the
   **Working Weight** and keeps the remainder as the new Microload, **rounded up** to a weight the
   Plate Inventory can build.

Two invariants follow, and they are the whole rule:

- **After any progression the Microload is less than one Stack Step.** There is never more than
  one pin step of iron on the hook.
- **The weight never goes down.** Rounding the remainder *up* is what guarantees it, at the cost
  of at most one Microplate more than the user asked for — well inside the promise that the user
  never meets a weight they did not choose, and far better than a progression that silently
  drops.

**Comparing a Stack Step to a Microload is a conversion, and Hoppa does it — internally.** That is
already this section's rule: Hoppa does the mixed-unit arithmetic itself and never shows the
result. Nothing converted reaches the screen. The Workout Summary states the roll-up the way it
states every other progression, two numbers with their own labels and no total (§5.5):

```
Lat pulldown
90 LBS + 4.5 KG  →  100 LBS + 0.25 KG   NEXT TIME
```

There is no "the pin moved" line. A pin step is not a concept the user is asked to hold; it is
what the numbers already say.

Where the Microloading Increment is bigger than the Stack Step, the rule still holds — every
progression simply rolls, and the Exercise steps the pin each time. That is correct: a stack whose
steps are smaller than the user's smallest plate has no use for a Microload.

**Reps above the top of the Rep Range count the same as reaching the top** — the weight goes up
by the Increment, **once**, never more. Progression must stay predictable: the user must never
meet a weight they did not choose. The extra reps are recorded as performed and printed plain,
`14 reps · 8–12`, with no warning colour.

### 4.3 Changing the weight by hand

The user changes the weight **inside the Workout**, on the Exercise card — that is where they
stand when they find out the weight is wrong.

- **Raising always sticks**, with no question. The sheet closes at once.
- **Lowering asks once**: *"Just today, or from now on?"*
  - *From now on* writes the new Working Weight.
  - *Just today* creates a **One-off Weight**: Hoppa logs its Sets, but it never becomes the
    Working Weight and it never progresses.
- The prompt appears **only on the way down**, which is the rare direction, so the common edit
  still costs one tap. A bad day is real: without the prompt, dropping 100 → 90 because of
  illness erases the record of 100, and progression climbs back 2.5 kg at a time.
- **A changed weight progresses under the normal rules in the same Workout.** All planned Sets,
  all at threshold, weight goes up. There is no "unless you edited it" clause — one rule, nothing
  to remember. A One-off Weight is the exception by definition.

### 4.4 Edges, settled

| Case | Hoppa does |
| --- | --- |
| A long gap between Workouts | **Nothing.** No deload, no prompt, no confirmation round. The Working Weight after six weeks off is the Working Weight from before. Hoppa has no data to pick the right deload; that is a coaching decision. The Day list already says "6 weeks ago". |
| Progression Mode changed on the Program | Changes the **default only**. Exercises with an override keep theirs — an override is a deliberate act. Exercises moving to Microloading get the default Microloading Increment filled in. |
| Progression Mode changed at all | **Never** changes the current Working Weight. It changes only the rule for next time. |
| Microloading Increment changed | Plain field, no migration, no warning. The next progression uses the new plate. |
| The exact weight cannot be built from the rack | Progression does **not** snap to buildable weights. The Working Weight is exactly what the Increment makes it; only the display deals with the gap (§5.4). |

**The default Microloading Increment is the smallest Microplate switched on**, and there is none
when the rack has none on. §5.2 ships every Microplate off, so *none* is the common case, and such
an Exercise falls into the empty state §5.2 already draws rather than getting a plate the user does
not own. The smallest is the right default because the smallest jump the rack can make is the whole
point of Microloading; the largest would be Progressive Overload with extra steps.

> Found while building. Decision record:
> [Program edits, and which of them are rules](issues/0026-program-edits-and-the-rules-boundary.md).

---

## 5. Weight, units and the Plate Breakdown

> Decision record: [Progression edge cases](issues/0004-progression-edge-cases.md),
> [Plate display design](issues/0005-plate-display-design.md),
> [Microplate accumulation](issues/0011-microplate-accumulation.md).
> Artboards: `design/0005-plate-display/`.

### 5.1 Where the unit lives

**The Weight Unit sits on the Exercise.** The Program holds one only as the default for new
Exercises. One Program mixes units freely.

The reason is a real gym: the user's rack is kg, but its machines step in lbs, so a 2.5 kg rise
on a stack machine is really 2.3 kg — a number no machine in that gym displays. Each screen shows
the number the machine shows.

- **The Plate Inventory decides the unit** for Barbell, Machine (Plates) **and
  Bodyweight**. The user gets no choice there: you cannot load a plate you do not own, and a
  Bodyweight Exercise's added weight is a plate off that same rack (§2.6).
- Dumbbell and Machine (Stack) carry their own unit — the one the machine is marked with.
- **Units never convert**, anywhere, with exactly one exception: **total volume** on the Workout
  Summary converts to the Program's default unit and shows as one labelled number. Volume is a
  rough progress number, not a loading instruction, so a conversion misleads nobody there —
  unlike the Plate Breakdown, which stays exact.

### 5.2 The Plate Inventory

The plate sizes available in the user's gym, in **one** unit. That unit sets the Weight Unit of
every Exercise with a Plate Breakdown.

- A unit toggle `KG | LBS`, with the line *"This unit applies to every barbell, machine (plates) and
  bodyweight exercise in the Program."*
- A list of plate sizes: a colour chip sized to the plate, the weight, an on/off toggle.
- **Microplates are a second group** under their own label.
- **On/off only — no count of pairs.** A pairs count was drawn and rejected as too much setup.
  Hoppa accepts that it can propose a load the user cannot build from the plates they physically
  own.
- Footer, which is Program-level and knows no Exercise's Mode, so it states both — but **only
  what is true**. With no Microplate switched on it reads `Smallest jump on the bar: 2.5 kg`, and
  it gains `· 0.5 kg with Microloading` the moment one is switched on.
  **The jump is twice the smallest plate the Mode may reach for**, because a bar has two sides —
  the shipped kg rack's 1.25 kg plate is a 2.5 kg jump. **A rack with nothing switched on has no
  jump to state**: the footer reads `No plate is switched on.`, and with only Microplates on the
  first half reads `nothing`. Printing `0 kg` would claim the bar moves in steps of nothing, which
  is a different thing from saying it does not move. Found while building.

**Defaults, per side. Every Microplate ships OFF, in both units.**

| Unit | Normal plates on | Normal plates off | Microplates — all off |
| --- | --- | --- | --- |
| kg | 1.25, 2.5, 5, 10, 20 | 25 | 0.25, 0.5, 0.75, 1 |
| lbs | 2.5, 5, 10, 25, 45 | 35, 55 | 0.5, 1, 1.25, 2.5 |

Normal plates are near-universal, so their defaults earn their "on". Microplates are owned by a
minority, so "off" is the honest default; it costs an owner four taps on a screen that already
asks them to check the rack, and it keeps the footer true on a fresh install. This supersedes
[Program onboarding flow prototype](issues/0006-program-onboarding-flow-prototype.md)'s "both
Microplates on", which was written when the rack held two. The tap counts in §6.2 are unaffected.

**Microloading with an empty Microplate group.** The Progression Mode sits one tap away on the
Program card at onboarding step 1, so a fresh user can choose Microloading before any Microplate
exists — and the Microloading Increment must name a Microplate the user owns. Machine (Stack)
Exercises hit the same wall.

Choosing Microloading with no Microplate on **opens the Microplate group of the Plate Inventory
as a sheet, in place**. The user switches on what they own and lands back where they were. The
Microloading Increment field, while empty, reads `NO MICROPLATES · SET UP YOUR RACK` and taps
through to the same sheet.

**Hoppa never blocks the Mode and never disables the option.** A disabled control makes the user
hunt for the reason, which is the one thing Hoppa does nowhere else — every other screen states
its condition in place.

**Hoppa holds one Plate Inventory.** Several saved racks, one per gym, is out of scope (§10).

**Editing the Inventory once Exercises exist** reaches across every Program at once. Both cases
are specified in §6.6: switching a Microplate **off** strands the Exercises using it as their
Microloading Increment, and switching the **unit** clears the weight on every plate-loaded
Exercise there is.

> Decision record: [Plate Inventory shipped defaults](issues/0013-plate-inventory-shipped-defaults.md),
> [Editing a Program over time](issues/0014-editing-a-program-over-time.md).

### 5.3 The solver

Hoppa solves the Plate Breakdown **greedily, from the biggest plate down**, against the Plate
Inventory.

**The Progression Mode decides which plates the solver may use:**

- **Progressive Overload** — normal plates only.
- **Microloading** — the whole Inventory, Microplates included.

This was decided **against the recommendation on the map**, and the reason is sound:
Microloading is rare and Progressive Overload is the common case, so a normal barbell exercise
must never be told to hang a 0.5 kg microplate.

Consequences, accepted knowingly:

- The same Working Weight can draw **two different loads** on the same bar, depending on the
  Exercise's Mode.
- An Exercise switched from Microloading to Progressive Overload can land on a weight the coarse
  rack cannot build, so `≈ CLOSEST` appears. That is correct; the user rounds the weight
  themself if they want to.

Because Hoppa stores a weight and solves it greedily, **identical plates are never stacked and
there is nothing to roll up**: 1.25 kg of Microload draws as one 1.25 kg plate, never as five
0.25 microplates. Four progressions at +0.25 land on +1 kg (one microplate); the fifth lands on
+1.25 kg (one normal plate).

**The pin follows the Working Weight, and the Microload rolls into it.** Hoppa does not choose the
pin: the user sets the Working Weight and the pin takes the largest Stack Step at or under it,
with the remainder hanging on it as Microplates.

An earlier draft of this section said a stack *never* rolls into the next pin step, on the grounds
that one step is about eighteen microplates away and the case is therefore theoretical. **It is
not.** Eighteen assumed the smallest Microplate; with a 1 kg plate it is five progressions, and
the charts of §6.7 — the first thing in this spec to run the rules further than one Workout —
walked a Microload to +11 kg. §4.2 now carries the roll-up, and the Microload is bounded by one
Stack Step at all times.

### 5.4 The unreachable weight

The big number is **always the Working Weight Hoppa tracks**. It never changes to fit the plate
rack. Sets are logged against it, not against the load actually on the bar.

When the exact weight cannot be built, one extra caption line appears under the bar drawing:

```
[≈ CLOSEST]  you load 62.5 kg · 0.5 over
20 kg + 1.25 kg              21.25 kg per side
```

- The closest buildable load wins, **up or down**. On a tie, Hoppa rounds **down**.
- The `≈ CLOSEST` chip is **steel** (`#3A3E42` border, `#9BA1A7` text), never a plate colour.

Two alternatives were drawn and rejected: A, round the target down to buildable; B, move the
target to the closest either way. Both change the number Hoppa tracks, and the rack must not do
that. The rejected artboards stay in `design/0005-plate-display/` as the record.

### 5.5 What each Equipment Type draws

**One drawing for Barbell and Machine (Plates).** Both draw the **same loaded bar**: plates to relative diameter and width in their real
colours, mirrored around a knurled shaft. No guide rails for a Smith, no carriage block for a
plate-loaded machine — per-type silhouettes were rejected as needless variation.

The **Base Weight is the only difference, and it lives in text**: the meta line reads
`… · BASE 15 KG`. The load line is the plates to hang, each with its unit
(`20 kg + 5 kg + 2.5 kg + 1.25 kg`); the qualifier names the Base Weight with the per-side
sum (`15 base + 28.75 kg per side`). Mixing the base into the plate list made it unclear
what to add per side. A Barbell prints no Base Weight at all, so its qualifier is only the
per-side sum.

**The caption stacks, and the half that says what to hang is the loud one** — corrected at
[The weight is too big and the plates too small](issues/0053-the-hero-and-the-load-line.md),
which is Rob's own verdict from the walk and not an artboard's. The two halves were side by side
at 11 px each; they are now a **load line** at 17 px in full text colour over a **qualifier line**
at 11 px dim. Which half is loud is per Equipment Type: a Barbell and a
stack load on the left of the table below, a Dumbbell and a belt on the right — `each hand` hangs
nothing, so it is the qualifier there.

| Type | Drawing | Caption |
| --- | --- | --- |
| Machine (Stack) | The stack as blocks, loaded ones in steel and the rest dark, the pin below the last loaded block, the Microplate hanging on it | `pin at 10 × 10 lbs · 1 microplate` / `100 lbs + 1.25 kg` |
| Dumbbell | A steel dumbbell, no plate colours — nothing is loaded | `each hand` / `2 × 22.5 kg` |
| Bodyweight | The added plate face-on, hanging from a belt clip | `added weight only` / `1 × 15 kg on the belt` |

**Mixed units** stack two numbers, each with its own unit label: the Working Weight big
(`100` / `LBS`), the Microload under it (`+1.25` / `KG`). **There is no combined total anywhere
on the screen.** The Working Weight is **64 px** and the Microload **30 px** — cut from the
artboard's 88 and 38 at ticket 0053, in the same breath that promoted the caption. It is still the
biggest number on the screen; §7.4 never pinned this size, only the small ones.

---

## 6. Screens and flows

### 6.1 Flow 1 — Onboarding

> Decision record: [Program onboarding flow prototype](issues/0006-program-onboarding-flow-prototype.md).
> Artboards: `design/0006-onboarding/`.

**Hoppa starts empty.** No starter skeleton, no template, no Workout Days invented for the user.

**The first run shows the Workout Day picker, empty.** `NOTHING HERE YET`, and one
`CREATE A PROGRAM` button. Hoppa does not jump straight into step 1. The picker (§3.1) is always
home, and onboarding is an ordinary route to it, so the app never has to decide at launch which
screen it opens on. §6.6 refuses to delete the last Workout Day, so this is in practice a first-run
state. Settled at
[Build order across the flows, and what done means for a screen](issues/0029-build-order-and-what-done-means.md).

Three steps to owning a Program:

1. **Name the Program.** Under the name field, one card shows the three decisions Hoppa makes at
   Program level — Weight Unit `KG`, Progression Mode `Progressive Overload`, Plate Rack
   `standard kg`. They are **pre-answered and visible**, each one tap from being changed. Nothing
   else is asked at Program level.
   **A Program must be named**, and Hoppa states that where the user taps rather than disabling
   the button: `CONTINUE` on an empty field says `Give it a name first.` under the field, in the
   same voice §5.2 uses for the Mode. **The Weight Unit row follows the rack** until the user taps
   it — a lifter who sets the rack to lbs at step 2 is standing in an lbs gym, and §2.1's default
   is for new Exercises, which is exactly what that lifter is about to add. One deliberate tap
   ends the following.
2. **Your plate rack.** The Plate Inventory (§5.2) with the standard defaults already correct.
   One confirm if the rack matches.
   **The confirm is where the Program is created**, in one act carrying everything step 1
   collected. Backing out of step 2 therefore leaves nothing behind — where creating it at step 1
   would strand a Program with no Workout Days on the phone, and the picker shows the first
   Program it finds, so its `CREATE A PROGRAM` button would be gone with it. The rack is the other
   way round and writes through at once: Hoppa holds **one** Plate Inventory (§5.2) and it belongs
   to no Program. Found while building.
3. **The Program sheet — the hub.** The Workout Days with their Exercise counts, `ADD A DAY`, and
   a link to Program settings.
   **Step 3 and Flow 5's hub are one screen**, reached two ways: from step 2's confirm, and from
   the `•••` on the picker. What it draws is identical — a Program made a minute ago and a Program
   trained on for a year are the same thing — and only two words of chrome differ: the step count,
   and a bottom control reading `START A WORKOUT` at the end of onboarding and `DONE` outside it.
   Both taps do the same thing, which is go home to the picker: **a Workout is picked at the
   picker** (§3.1), never here. Found while building.
   **A Workout Day is named before it exists.** `ADD A DAY` opens a one-field sheet and the Day is
   created with the name already on it, because a Day with no name would be a row the user cannot
   read. The same sheet renames — a Name is a label (§2.7) — and the Day screen carries a `RENAME`
   beside its title so a typo made during onboarding has somewhere to be fixed.

Smart defaulting was allowed to remove input **at Program level only**: one unit, one Progression
Mode, one plate rack, decided once and never asked again per Exercise.

### 6.2 The Exercise sheet — Model B, the full sheet

Two entry models were drawn and counted against each other on the user's real Program (Upper /
Lower, 4 Workout Days, 22 Exercises, empty start, standard kg rack):

| Model | Taps | Shape |
| --- | --- | --- |
| A — fast list | ~287 | Never leave the Workout Day. Type four letters, tap the match, type the weight, confirm. A catalogue sets Equipment Type and Increment; six values arrive filled in. |
| **B — full sheet (chosen)** | **~400** | One sheet per Exercise, every field on screen, picked by hand. |

**The user chose B**, and the reason is the audience, not the count (§1). The 113-tap difference
buys explicit control over every field that changes how an Exercise behaves.

Behaviour of the sheet:

- **Add and edit are the same sheet.**
- **Sets and Rep Range carry over** from the previous Exercise, marked `CARRIED OVER`. **Every
  other field starts empty** — Equipment Type, Working Weight, Increment and Base Weight are
  always picked by hand.
- Base Weight appears only after Machine (Plates) is picked; Stack Step only for Machine
  (Stack). The sheet never grows for a Barbell.
- The Increment row swaps with the Progression Mode:
  `INCREMENT · +2.5 KG`, or `MICROLOADING INCREMENT · 0.25 KG MICROPLATE · +0.5 KG ON THE BAR`.
  With no Microplate switched on, that second row reads `NO MICROPLATES · SET UP YOUR RACK` and
  taps through to the Microplate group of the Plate Inventory (§5.2).
- Weight Unit is printed beside Working Weight. The three types loaded off the user's own rack —
  Barbell, Machine (Plates) and Bodyweight — show it as steel text. Dumbbell and Machine (Stack)
  carry their own, and a chip flips it in one tap: two values do not need a picker (§5.2). No lock
  line.

**Five things the sheet does that no artboard shows.** Found while building
([The Exercise sheet, and the name field](issues/0035-the-exercise-sheet.md)):

- **The two lives leave differently, and each says so where the user taps.** An **edit** sheet has
  an Exercise behind it, so **closing is the save** — the one act §6.2 allows — and a line under
  the fields states it. There is no *cancel*: half this sheet opens at the rack mid-Workout, where
  §6.6 already refuses to ask twice about a change the user made and watched land. An **add** sheet
  has nothing behind it: its save is the control that says so — `SAVE`, which **closes the sheet**
  — and the `✕` **asks before it discards** a filled-in sheet.

  > **`SAVE AND ADD ANOTHER` was tried first, and it was wrong on the phone.** It reopened the
  > sheet empty and saved a tap, and Rob read the empty sheet as work thrown away: nothing on
  > screen said the Exercise had landed. The Day screen behind it is the confirmation, so the
  > save now closes and the next Exercise starts at `ADD AN EXERCISE`. The carry-over is
  > untouched — it is read off the Day, not held by the sheet — and the cost is one tap per
  > Exercise, priced into the budget below. **A tap saved that costs the user their confidence
  > is not saved.** Neither reading survives a
  swipe-down, so the sheet has one visible way out and interactive dismissal is off.
- **`REMOVE EXERCISE` is on the sheet**, where the artboard draws it. §6.6 gives deleting an
  Exercise no block to state, so the whole control is one confirm and one action.
- **The Equipment Type really does start empty**, so no chip is lit on a new Exercise and the save
  refuses until one is picked. The five chips are in §2.6's order (`EquipmentType.allCases`).
  Dumbbell and Machine (Stack) carry their own unit — which is the lock rule made visible.
- **The carry-over crosses Workout Days.** The previous Exercise is the one above it in the Day, or
  — for the first Exercise of a Day — the last Exercise of the Day before it: a second Day usually
  opens on the same kind of work, and re-asking at the top of every Day is taps for nothing. The
  very first Exercise of a Program has nothing behind it and starts at **3 × 8–12**, and only a real
  carry-over is marked `CARRIED OVER`.
- **The Increment chips are offers, not defaults** — 1.25 / 2.5 / 5 in kg, 2.5 / 5 / 10 in lbs, and
  `…` types any number (§2.3). Nothing is pre-selected: an Increment the user did not pick is a
  weight Hoppa invented.

**The tap budget — the ticket's core question. 14 taps per Exercise is the floor, 400 for the
Program.** `SAVE AND ADD ANOTHER` becoming `SAVE` added a tap; Weight Unit leaving the add path
as its own row takes that tap back.

| Step | Taps |
| --- | --- |
| Program name and the three assumptions | 16 |
| Plate rack — standard kg, one confirm | 3 |
| 4 Workout Days, named | 40 |
| 22 Exercises at 14 taps each | 308 |
| Base Weight on the 5 machine Exercises | 15 |
| Rep Range changed on 6 of them | 18 |
| **Total** | **400** |

Model A's artboards stay in `design/0006-onboarding/` (`DayA`, `DayAFilled`, `DetailA`, `DayB`),
off the canvas, as the record of the choice.

### 6.3 The name field

> Decision record: [Exercise name suggestions](issues/0010-exercise-name-suggestions.md).

**Two sources, one ranked list.** The user's own names on top, a shipped **Exercise Catalogue**
underneath. A name in both appears once.

- **Free text always wins.** `Smith incline 30°` is a keepable name.
- **A suggestion sets the Name and nothing else** — never the Equipment Type, never the Increment.
  The catalogue is a typing aid, not an inference engine. This holds on the edit sheet too.
- **The own-names source is derived live, never stored**: Hoppa reads the names off the Exercises
  that exist right now, across **all** of the user's Programs. Correct a typo and the wrong name
  is gone at once; delete an Exercise and its name goes with it — one retype, and no cleanup
  screen is ever needed. The scope is all Programs because a second Program is exactly where old
  names are worth the most.
- **Matching starts at any word**, case- and accent-insensitive. `incline` finds both
  `Incline Dumbbell Press` and `Dumbbell Incline Press`. String-start matching fails exactly where
  it is needed, because a name often opens with the equipment. Fuzzy matching (`idp` →
  `Incline Dumbbell Press`) was rejected as noise.
- **A word breaks on a space or a hyphen, never on an apostrophe.** `up` finds `Pull-up` and
  `Chin-up`, which are two words to a lifter. `Farmer's` stays one word, because `s` is not a
  search anyone makes.
- **Most recently used means most recently *trained*.** The own names sort by the start of the
  newest Workout that performed them, newest first, and **the Open Workout counts** — the Exercise
  logged ten minutes ago belongs at the top. A name on an Exercise that exists but was never
  trained sorts under the trained ones, in Program order.
- **Six rows at most, on focus and while typing alike.** A keyboard leaves room for about that
  many, and the reason the catalogue stops at ~150 names is that `press` must not return thirty
  rows — an uncapped typing list hands that failure straight back.
- **On focus, before typing**: the user's own names, most recently used first, **six at most**, no
  catalogue entries mixed in. On a first run it shows nothing and the user types.
- **A name in both sources keeps its own-names row**, because that row carries the recency and the
  user wrote it.

**The Exercise Catalogue:**

- **About 150 names.** ~50 leaves the user typing in full too often on the first run, which is
  what the catalogue exists for; 500+ works against word-start matching, where `press` would
  return thirty rows.
- **Order is curated and fixed**, shipped with the list — `Barbell Bench Press` above
  `Barbell Bench Press Close Grip`. Alphabetical puts variants above the movement they vary.
  The order never changes between two sessions.
- **The catalogue is never browsable** and is never filtered by Weight Unit or Equipment Type. A
  suggestion sets neither, so there is nothing to filter on.
- **Equipment goes in front of a name only where it distinguishes**, by a mechanical rule: as soon
  as the same movement exists in the catalogue on more than one Equipment Type. `Bench Press`
  exists as barbell, dumbbell and Smith, so all three carry a prefix; `Leg Press` exists only as
  plate-loaded, so it stays bare. `Pull-up` stays bare while it is the only version. The rule is
  checkable against the list, so two people extending the catalogue land on the same name.
- Adding a variant later can force a bare name to gain a prefix. That never touches existing
  Exercises: **a suggestion copies the name at the moment it is picked**, and no link survives.

Writing the ~150 names is content work for the build (§10). **It is done**: the list lives in
`app/HoppaRules/Sources/HoppaRules/ExerciseCatalogue.swift`, as a plain array of strings, and the
two conventions above — the curated order and the equipment-prefix rule — are checked mechanically,
so a name added later cannot quietly break either.

**The matching and the ranking are rules, and they live in `HoppaRules` with everything else.**
They were once recorded as needing Foundation to fold accents, which `HoppaRules` does not import.
That was wrong: `lowercased()` is standard library, Swift compares `é` and `e`+combining-acute
as equal already, and the base letter behind an accent is readable from the Unicode character names
the standard library ships. So folding costs about ten lines and no import. The catalogue moved down
into `HoppaRules` beside the rule that reads it, and both are built: `Rules.nameSuggestions(in:query:)`
and `Rules.fold(_:)` in `Suggestions.swift`. See
[Name suggestions, and where a rule that needs Foundation lives](issues/0027-name-suggestions-and-foundation.md)
and [Build the Program edits](issues/0028-build-the-program-edits.md).

**Trained means at least one logged Set.** The recency sort reads the Workouts that *performed* an
Exercise, and a Workout the user opened and walked away from, or one where the Exercise was Skipped,
performed nothing. Neither lifts a name to the top of the list.

### 6.4 Flow 2 — Logging a Workout

> Decision record: [Workout logging clickable prototype](issues/0007-workout-logging-clickable-prototype.md),
> amended by [Microplate accumulation](issues/0011-microplate-accumulation.md).
> Prototype: `design/0007-logging/fitty-workout-logging.html` — **approved outright on the first
> pass**, no iteration needed.

The screen, top to bottom: the exercise counter as navigation, the Working Weight as the hero,
the rule chip, the loaded bar, the Set rows, the bottom control row.

**The bottom control row is `−` · `LOG n REPS` · `+`.** One tap logs at Target Reps (the top of
the Rep Range); the flanking buttons adjust, and the `+` is what makes logging **above** the
range reachable by design. Both adjust buttons are 62 × 64 px.

**The rule chip under the weight** states the rule, never an offer:

| State | Chip |
| --- | --- |
| While logging, Progressive Overload | steel `+2.5 KG IF ALL 12` |
| While logging, Microloading | steel `+0.5 KG IF ALL 8` — mixed units: `+0.25 KG IF ALL 8` |
| The instant the Exercise completes | green `→ 75 KG NEXT TIME` — Microloading mixed: `→ 100 LBS +1.25 KG NEXT TIME` |

**Changing the weight**: tapping the big number opens a bottom sheet with a numeric keypad plus
`−` / `+` stepping by the Increment. Raising closes the sheet at once. Lowering raises the
*Just today, or from now on?* sheet, exactly once, on the way down only (§4.3).

**On a Machine (Stack) the sheet grows a second stepper**, because a stack moves in pin
steps and not in Increments: `PIN` steps by the Stack Step (`− 100 LBS +`), `MICRO` steps by the
Microloading Increment (`− +1 KG +`), and the keypad stays under them. The big number is still
the Working Weight. A bar keeps the single `−`/`+` at the Increment.

**Except on a mixed-unit pin, where there is no `MICRO` row — only `PIN`.** A Machine (Stack)
whose Weight Unit differs from the Plate Inventory's carries its Microplates as a
**Microload**, a second stored number in the rack's unit that the Working Weight can never absorb,
because units never convert (§5.1). Stepping it by hand is a different write with a different
rule: `+` is §4.2's roll-up, and `−` past zero would be a **roll-down**, which §4.2 does not have and
which would be the first thing in Hoppa to lower a Working Weight without asking (§4.3). The pin is
the way down there, and it already asks what §4.3 asks. Ruled **out of scope** rather than built:
see [The MICRO stepper on a mixed-unit pin](issues/0042-the-micro-stepper-on-a-mixed-unit-pin.md),
which records the answer should a mixed-unit rack ever arrive — `−` refuses at zero.

**A One-off Weight is marked twice**: a steel chip `ONE-OFF · 72.5 KG STAYS` beside the unit — it
names the Working Weight that survives, not just the fact of the one-off — and a plain `ONE-OFF`
chip on every Set row logged under it.

**Completing an Exercise costs no tap; moving on costs one.** The last Set completes the Exercise
by itself, and the bottom button then becomes `NEXT: BARBELL ROW`, or `FINISH WORKOUT` when
nothing is Open. **Hoppa does not jump by itself.**

**The exercise counter is the navigation.** `3 / 5 ▾` opens a full-screen list where every
Exercise carries its state as a pill, under the line *"Leaving an open Exercise means later,
never 'not at all'"*.

**Reps over the range** read `14 reps · 8–12` on the Set row — plain, no colour.

**The Rest Timer** is a count-up stopwatch that starts automatically after each logged Set.

Nine awkward cases were driven end to end headlessly with no errors:

| Walkthrough | Outcome |
| --- | --- |
| Everything at the top of the range | 5 Exercises progress |
| Done early, 2 of 3 Sets at 12 | 0 progress — the rule bites as designed |
| 14 reps against 8–12 | one Increment, never more |
| Lower to 65 → *Just today* | Working Weight stays 72.5 kg; the Summary says so |
| Raise to 75 by hand | sticks silently, then progresses to 77.5 under the normal rules |
| Skip the Barbell row, reopen it later | works inside the same Workout |
| Finish with 4 Open | the gate holds, with the one-tap way out |
| 61.25 kg on a kg rack | `≈ CLOSEST` · you load 60 kg · 1.25 under (tie rounds down) |
| lbs stack + kg microplate | `100 LBS` over `+1 KG`, never converted |

The 61.25 kg walkthrough **stands unchanged** under the Mode-scoped solver of §5.3 — that
Exercise runs Progressive Overload, so microplates were never in its solve.

### 6.5 Flow 3 — The Workout Summary

> Decision record: [Workout session lifecycle](issues/0003-workout-session-lifecycle.md),
> [Workout summary screen prototype](issues/0009-workout-summary-screen.md).
> Prototype: `design/0009-summary/fitty-workout-summary.html`; artboards
> `design/0009-summary/canvas/`.

Top to bottom: the Workout Day and a `SUMMARY` label; **the count as the hero** — one Anton
numeral in green over `EXERCISES WENT UP`; then `WENT UP`, `STAYED`, `SKIPPED`; then one steel
bar with duration, Sets and volume; then a single `DONE` button.

**The count is the hero because the count is exactly what the confetti scales to.**

**There is no Accept and no Undo anywhere on the screen.** Hoppa applied the new Working Weight
at Finish, so the green number is a statement of fact. That is the whole mechanism; nothing else
was needed to make it read that way.

| Section | Row |
| --- | --- |
| WENT UP | A plate chip in the added plate's colour, the Exercise name, `72.5 KG → 75 KG`, and a small steel `NEXT TIME`. Microloading mixed: `+1 → +1.25 KG · NEXT TIME` under the `100 LBS` it belongs to. |
| STAYED | **States the condition**: `ALL 3 SETS AT 12 → 75 KG` — the logging screen's rule chip, restated. Microloading: `ALL 3 SETS AT 8 → 73 KG`. |
| SKIPPED | Listed plain. No warning colour, no icon, no invitation to fix. |

**Every stayed Exercise carries its condition line, in every state.** A One-off Weight replaces
it with the steel `ONE-OFF · 22.5 KG STAYS` chip, because nothing was ever going to progress;
its meta line shows the weight actually lifted, not the Working Weight.

**Mixed units**: per-Exercise lines never convert. **Total volume is the one number that does**,
to the Program's default unit, labelled `KG VOLUME`. Dumbbell Sets count both dumbbells. It is
printed **whole**, grouped with a thin space — `8 023`. A converted volume lands on hundredths, and
volume is a rough progress number rather than a loading instruction, so the decimal is noise; the
rounding is the screen's and the stored number stays exact.

#### The added plate, which is what the chip is painted with

> Settled while building, at [The Workout Summary](issues/0038-the-workout-summary.md).

A Went-up row's chip is **the plate the progression puts on**, and ticket 39 fires its burst from
that rectangle.

- **Under Microloading the Increment already is a plate**, on every Equipment Type (§4.2). The chip
  is that Microplate.
- **Under Progressive Overload the Increment is a total.** A bar takes a pair, so a Barbell, Smith
  or Plate-loaded Exercise adds **half** the Increment per side and the chip is that half — a
  2.5 kg Increment is a 1.25 kg plate, light grey and not the mid grey of the 2.5. Every other
  Equipment Type takes one plate and the Increment is it.
- **Where the rack has no colour the chip is steel**, hollow, per §7.1 rule 2 — an lbs plate (§7.3
  paints kg only), a pin Increment that is no plate size, and an Increment that does not halve.

The prototype's chips do not port: `design/0009-summary/canvas/Main.dc.html` paints every bar row
red, which is §8.2's *invented colours* defect, and its Microloading row steel, which is §8.2's
first summary defect seen on the chip instead of the burst.

#### Nowhere to put the plate

§4.1 counts four ways a completed Exercise that met its condition still does not move, and §6.6
asks the Summary to state that condition "in place of the green line". They are **not one
sentence** — an Exercise waiting for a weight and one stranded by a switched-off Microplate send
the user to two different screens, and §5.2's principle is that Hoppa states its condition where
the user stands. The rep condition still reads; only the `→ 75 KG` is replaced:

`ALL 3 SETS AT 12 · NO MICROPLATES · SET UP YOUR RACK`

| Blocker | The row says |
| --- | --- |
| No Working Weight (§6.6's Re-weigh list) | `no weight yet` |
| Progressive Overload with no Increment | `no increment yet` |
| Microloading with no Microplate picked (§5.2) | `no microplates · set up your rack` |
| Stranded — the Microplate is switched off (§6.6) | `microplate switched off · set up your rack` |
| A mixed-unit pin with no Stack Step to roll into (§4.2) | `no stack step yet` |

An Exercise **deleted mid-Workout** has no Rep Range left to state a condition from, so its row
keeps the Name it was logged under (§2.7) and reads `REMOVED FROM THE PROGRAM`.

#### Confetti — "Ignition"

Three models were built into one watchable prototype and driven live; the user chose Ignition.

- Each Went-up row **lands on its own, 190 ms after the row above it**, and throws a burst of
  ~15 particles **from its own plate chip**.
- Particles are plate-shaped slabs — the same glyph the Inventory and the rows draw — with
  gravity, drag and spin, and a 1.5 px rim so a dark plate reads as a moving ring rather than a
  hole. **The face is never brightened, because the face is the weight.** A burst that reads as
  nothing is fixed with more particles, never with lighter ones.
- The sequence runs **~1.4 s**, after which the screen is quiet and every number is readable.
- **Zero progressed fires nothing at all.**
- **Reduce Motion is honoured** — the one system setting Hoppa does not ignore. When it is on the
  rows still land in sequence, and no burst fires. The sequence is what makes the count *a count
  you watch land*, which is why Ignition won; the particle cloud is the part that causes motion
  trouble. §7.2's two locks are about a design that depends on them, and this is not that.

#### Which plates a burst throws

**The burst throws what the Plate Breakdown draws.** One rule, on every Equipment Type.

| Equipment Type | The burst throws |
| --- | --- |
| Barbell, Machine (Plates) | The per-side plates of the **new** Working Weight, Base Weight excluded |
| Machine (Stack) | The Microplates on the pin, plus one steel slab per loaded pin block |
| Dumbbell | Steel — §5.5 draws the dumbbell in steel, so it never throws the Increment plate |
| Bodyweight | The plate on the belt |

**Sampling is proportional, by plate count.** The fifteen particles take their colour from a list
holding one entry per plate in the load, picked uniformly: 20 + 10 per side throws half blue and
half green, and 20 + 10 + 2.5 + 2.5 throws half grey.

One share per *distinct size* was rejected — it gives a lone 1.25 kg plate the same volume as two
20s, so a plate would get louder as it got smaller, which inverts rule 1 of §7.1. Proportional by
*mass* was rejected in the other direction: it nearly erases the small plates, so a 61.25 kg load
would never show its microplate. Proportional-by-count matches the drawing under it particle for
plate, which is what makes "throw what's drawn" exact rather than approximate.

**Steel particles are hollow** — a 1 px outline, per rule 2 of §7.1, without exception. A filled
steel slab at 5 × 14 px is the same shape and nearly the same value as the 1.25 kg grey
`#70767C`, so a Dumbbell burst would read as a rack of 1.25s. Throwing nothing was rejected too:
the count is the hero, so every Went-up row must land.

> Decision record: [Confetti plate source](issues/0012-confetti-plate-source.md), which retires
> [Microplate accumulation](issues/0011-microplate-accumulation.md)'s "the burst throws the plates
> that changed" as an overreach — it solved the stack and reached into the bar, where it became
> the rule [Workout summary screen prototype](issues/0009-workout-summary-screen.md) had already
> tested and rejected.

"More" reads as a **count you watch land**, not a cloud you estimate, and the motion is tied to
the data rather than layered over it. Named trade-off, accepted: the list is not fully readable
until the last row lands.

Rejected: **Density** (one burst, particle count scaling with the count) — at five Exercises the
particles cover the numbers. **Bursts** (one burst per Exercise from a fixed point) — reads the
count fine, but the motion floats free of the list.

#### The zero-progressed screen — approved unchanged

No confetti. The hero becomes `NOTHING WENT UP` in text colour, with
`n Exercises performed. Every Set is logged.` under it — and `No exercises performed.` where every
Exercise was skipped, because there is then no Set to call logged. What keeps it worth reading is the
`STAYED` section stating the condition for every Exercise. **It is a fact, not encouragement, so
the screen neither scolds nor consoles.**

### 6.6 Flow 5 — Editing a Program

> Decision record: [Editing a Program over time](issues/0014-editing-a-program-over-time.md).
> **Specified, not drawn.** Add and edit are the same sheet (§6.2) and the empty states come from
> §6.2 and §5.2, so only three screens here have no precedent: the Re-weigh list, the two warning
> dialogs and the reorder handles. The user chose to spec them rather than prototype them.

A Program is a living document. This section says what changes, and what a build may safely store
while it changes. It rests on §2.5: **a Set holds its own numbers**, so nothing below can rewrite
the past.

#### An edit at the rack is a Program edit

The Exercise sheet opens from the Exercise card **during** a Workout, and every change sticks at
once and everywhere. Sets, Rep Range, Increment and Equipment Type get **no** *Just today*
question. The weight keeps the one it already has (§4.3).

The lifecycle already covers both temporary cases: "fewer Sets today" is ending the Exercise early
(§3.2), and "lighter today" is the One-off Weight. What is left when the user edits at the rack is
a real plan change. Taxing every field with a question, to serve a case that is already served,
buys nothing.

It follows that, mid-Workout:

- Reorder takes effect at once, and the `3 / 5 ▾` counter renumbers with it. **The user does not
  move with it**: Hoppa keeps him on the Exercise he was standing at, not on the position he was
  standing in, so a drag never changes the card under his thumb (§6.4).
- An Exercise added arrives **Open**, so it gates Finish like any other — and it arrives at its
  place in the Workout Day, not at the end of the Workout.
- An Exercise deleted keeps the Sets it already logged, and the Summary counts them. The user
  lifted them. It **stops holding the Finish gate**, because the user cannot reach it any more:
  with Sets logged it ends Completed, with none it ends Skipped.
- Raising the planned Sets can **reopen** a Completed Exercise (§3.2). Nothing fires before
  Finish; the rule chip restates the condition the moment the edit lands, `+2.5 KG IF ALL 3` →
  `+2.5 KG IF ALL 4`, so the cost of the edit is visible in place.

Reordering Workout Days is cosmetic: a Workout records **which** Day was performed, and picking is
a free pick with no rotation (§3.1).

**The handle itself, settled while building** at
[The reorder handles](issues/0044-the-reorder-handles.md). A grip of three drawn bars on the
**leading** edge of every card, on every row, always. Hoppa has no edit mode to hide it behind, and
this app does not hide an affordance behind a long press — the same reason `RENAME` is a word on
the Day screen. The handle and the row's tap target are **siblings and not stacked**: the grip
drags, the rest of the card opens what it always opened, and nothing has to be given priority over
anything. The card under the finger **renumbers before the drop**, so the list the user reads is
the list the rule is about to write.

#### Changing a Weight Unit clears the weights

For the two Equipment Types that carry their own unit — Dumbbell and Machine (Stack) —
changing the Weight Unit **clears the Working Weight, the Increment and the Stack Step**, and the
same sheet asks for them again in the new unit. The Microloading Increment survives untouched,
because it keeps the Plate Inventory's unit whatever the Exercise does (§5.1).

> This paragraph said **four**, and named Bodyweight among them. That was wrong and the rest of the
> spec never agreed with it: §2.3 locks the Weight Unit row for Bodyweight, §5.1 gives it the Plate
> Inventory's unit because its added weight is a plate off that same rack, the next paragraph here
> clears it *with* the other three rack types, and the Microload table below calls the Dumbbell "the
> only other type that can change unit". A Bodyweight Exercise has no unit of its own to change.
> Found while building.

Converting was rejected: it produces numbers no machine can make. `100 lbs` on a 10 lbs stack
becomes `45.4 kg` in steps of `4.54 kg`, with an Increment of `2.27 kg`. **The rule *units never
convert* now covers the stored number, not only the display.**

**Cleared means unset, not zero** (§2.8): the field is empty, and the Exercise does not progress
until the user types a number.

**While the sheet is open the numbers are held, not destroyed.** Closing an edit sheet *is* the
save (§6.2) and there is no cancel, so one wrong tap on the unit row would otherwise be the last
word on three numbers. The sheet keeps what it took off the screen, filed under the unit it was
typed in, and puts it back if that unit comes back — for as many flips as the user makes, and on
the add sheet as well as the edit sheet. **Nothing is converted and nothing is merged**: a number
retyped after a flip is filed under *its* unit, so both survive and each appears under its own
label. This is the sheet's memory of one visit and it is not a rule: it decides nothing from the
`Logbook`, it never reaches the save, and what the save writes is exactly what is on the screen.

> Found and settled at
> [The numbers a mis-tap cleared](issues/0043-the-numbers-a-mistap-cleared.md).

**What makes *the same sheet* possible: the sheet says which unit it typed in.** The sheet saves
once (§6.2), so a number retyped after the flip arrives in the very same save as the flip. A rule
that asks *did the unit move* clears it with the stale ones. So the sheet carries **the unit its
numbers are written in**, and the rule clears a field when that unit is not the one the Exercise
now resolves to. The number's own label cannot answer this: a stored label may be stale by design
(§2.8), and the sheet opens by copying stored labels.

**The Microload hangs on the other trigger.** The three typed fields go when *the draft was typed
in another unit*; the Microload goes when *the Exercise's unit moves*, retyped or not. It is not a
number the sheet asks for — it is a state that belongs to a unit, and that unit has left. The same
two triggers guard adding an Exercise, because an add sheet can change its Equipment Type after a
weight is typed.

> Found while building
> [The Exercise sheet](issues/0035-the-exercise-sheet.md), settled at
> [A weight retyped after a unit change](issues/0041-a-weight-retyped-after-a-unit-change.md).

**Changing the Equipment Type across the rack boundary is the same event**, and clears the same
three fields. A Machine (Stack) in lbs that becomes a Barbell now reads its unit off a kg rack
(§5.1), so its `100` means something it was never typed to mean. The unit is derived, so what the
rule watches is the unit the Exercise *resolves to* — however the user changed it.

The **Microload follows and never carries across**:

| Change | The Microload |
| --- | --- |
| Exercise unit moves **to** the Plate Inventory's unit | Deleted — really gone, not merely hidden. Hide it instead and a second unit change brings the old Microload back. The Working Weight is retyped anyway, so there is nothing to fold in. |
| Exercise unit moves **away** from it | Created at zero on a Machine (Stack), for the next Microloading progression to fill. |

#### Changing the Plate Inventory's unit — the Re-weigh list

The same rule at full blast radius. One switch:

- clears the Working Weight, Increment and Base Weight of **every** Barbell, Machine
  (Plates) and Bodyweight Exercise, in every Program — the types whose unit the Inventory names
  (§5.1);
- resets **every** Microloading Increment, because the other unit's Microplates all ship off
  (§5.2);
- creates or destroys a Microload on every Machine (Stack) Exercise, which is the only
  type that can carry one (§2.3).

So Hoppa warns with the count — `THIS CLEARS THE WEIGHT ON 12 EXERCISES` — and the confirm leads
to **one Re-weigh list**: every affected Exercise on one screen, each with an empty weight field.

**The Re-weigh list is every Exercise with no Working Weight**, which is what the switch has just
made them. It is not a list the switch writes down. Leave the screen, close the app, come back a
day later, and the same Exercises still have no weight — so the same list appears, without anything
having to remember it. The count in the warning is the same rule, asked before the switch instead
of after.

The user throws this switch when they change gym or country, so it is rare and deliberate. Paying
its cost once at the kitchen table beats meeting it twelve times at the rack. Blocking the switch
once Workouts exist was rejected: it locks a real event out of the app.

**The One-off Weights in an Open Workout go with the Working Weights.** A One-off is a number for
today in the Exercise's unit (§4.3) and a logged Set prefers it to the Working Weight, so one left
standing through a rack switch is exactly the stale number this section exists to prevent — it
would be written into a Set under the new label. Only the three types that read the rack; a Dumbbell
in lbs is untouched. The Sets **already logged** are not touched and must not be: a Set records the
weight as performed (§2.4), and those really were lifted. Found while building.

##### The list has two doors, and it asks for one field

§6.6 named the list and left three things open. Each was settled while building it, and each is a
decision rather than a gap.

- **The weight is typed inline, in a field per row** — not in §6.4's weight sheet. The argument for
  this screen is that paying the cost once at the kitchen table beats meeting it twelve times at
  the rack, and twelve full-screen keypads, each opened and dismissed, puts the twelve back. The
  Exercise sheet is the other kitchen-table screen that asks for a Working Weight, and it asks with
  a decimal field; this is the idiom the user already has. **§5.4's closest line comes with it**,
  drawn under a row the moment its number parses — a weight the user's new rack cannot build is
  precisely what a change of gym produces. **The field writes when it is left, never on the
  keystroke**: a write per digit would send `13` to disk on the way to `135`.
- **The list is frozen while the screen is open.** The rule is *has no Working Weight*, so a row
  would leave the list on its first digit and the rows under the user's thumb would move. The ids
  are read once, on open, and every one keeps its place until the screen is left. Re-entering
  re-derives, which is the whole point of a list nobody writes down.
- **Two doors.** The confirm leads to it, as above. The second is a **banner at the top of the
  picker** — `3 EXERCISES HAVE NO WEIGHT` — for as long as the condition is true. Without a second
  door a user who leaves the screen never finds it again, because nothing wrote the list down. A
  sheet at launch was rejected: the list holds *every* Exercise with no Working Weight, including
  one added last night, so a modal would ambush the user with a thing he did on purpose. §7.6:
  Hoppa states its condition where the user stands. The foot of the picker stays §6.7's History
  door.
- **A row states what else the switch cleared, and the statement is the door to it.** The switch
  clears the Increment and the Base Weight too, and this list shows one field. An Exercise
  re-weighed but still without an Increment does not progress (§4.1), so the note under the name
  reads `no base weight`, `no increment` or `no microplate`, and tapping it opens the Exercise
  sheet. Hoppa states the condition rather than filling the field quietly.
- **Zero is accepted here**, and it is why this screen's write is not §4.3's. Zero is a real weight
  (§2.8) — a Bodyweight Exercise done with no belt — and it is the only true answer for a chin-up
  the switch has just cleared. Refuse it and that row can never leave the list.

> Settled at [The Re-weigh list, and the two warnings that count before they
> fire](issues/0046-the-reweigh-list-and-the-two-counts.md).

#### Switching a Microplate off strands, and says so

The switch warns with the count — `3 EXERCISES USE THIS PLATE` — and the affected Exercises fall
into the empty state §6.2 already draws: `NO MICROPLATES · SET UP YOUR RACK`, tapping through to
the Inventory. Such an Exercise **does not progress** until a plate is picked, and the Summary
states that condition in place of the green line.

A **stranded** Exercise is one whose Microloading Increment names a Microplate that is now off.
Nothing is written and nothing is cleared: switch the plate back on, and the Exercise progresses
again with the plate the user picked. The count in the warning asks the same question before the
switch.

Hoppa never re-points to the nearest remaining Microplate, which would change the steel the user
hangs on the bar without telling them. It never blocks the switch either, which would lock a rack
the user owns out of their own settings. §5.2's principle holds: Hoppa states its condition where
the user stands.

#### Deleting

| Action | Hoppa does |
| --- | --- |
| Delete an Exercise | It leaves the Program from today forward. Past Workouts keep their Sets, labelled by the Name stored at the time (§2.4). The Name leaves the suggestions — a cost §6.3 already accepted. |
| Delete a Workout Day | The same, and the Workout keeps the Day's name too. |
| Delete the Workout Day the Open Workout runs on | **Blocked**: `FINISH YOUR WORKOUT FIRST`. |
| Delete the last Workout Day in a Program | **Blocked.** A Program with no Days cannot be started. |
| Confirm | Plain, with **no** count of destroyed Sets — because nothing is destroyed. |

A block is stated **before** the user commits: the delete control refuses with its reason where the
user taps it. A confirm that quietly does nothing is not a block, it is a bug the user gets to
diagnose.

**Where the control lives, and how it refuses — settled while building** at
[Deleting an Exercise or a Workout Day](issues/0045-deleting-and-the-two-blocks.md). Each delete
sits at the foot of **the room for the thing it deletes**: `REMOVE EXERCISE` on the Exercise sheet,
`REMOVE DAY` on the Workout Day screen. Not a swipe and not a `•••` on a row — a swipe hides the
control, a row already carries a reorder grip and a tap through its middle, and a block has to be
**read** before it can do its job. A word in a room has space for a sentence beside it.

The blocked control is **never disabled**. It stays live, and the tap prints the reason under it in
the stop red; the reason is read off the rule on every pass, so it appears and goes as the rule
starts and stops refusing, with no second tap. This is §5.2's principle applied to a button, the
same shape `CONTINUE` has at step 1: Hoppa never disables the control and never hides the reason.

**An Exercise deleted from under the user mid-Workout** leaves the logging screen with a card that
names nothing. The screen says so — *that exercise is gone; what you logged is kept* — and offers
the bottom row's own control, `NEXT: …` while an Open Exercise is left and `FINISH WORKOUT` when
none is. Hoppa still does not jump by itself (§6.4); it offers the jump, because a dead card whose
only way on was Finish would strand the user behind §3.3's gate.

#### Program-level edits, which follow from rules already fixed

- The Program's **Weight Unit** is a default for new Exercises only (§2.1), so changing it touches
  nothing that exists.
- The Program's **Progression Mode** changes every Exercise that does not override it (§4.4). That
  re-solves their Plate Breakdowns (§5.3), and with no Microplate on, §5.2 opens the Microplate
  group in place.
- **Renaming** anything is free and migrates nothing (§2.7).

**Program settings is a screen**, reached from the hub's own row, and it holds exactly these:
the Name, the Weight Unit, the Progression Mode and the Plate Rack — step 1's card of three,
plus the Name step 1 promised the user could change later. It is also **the only door to the
Plate Inventory outside onboarding**: until it landed, the rack screen's own `DONE` branch had
no way in. Found while building.

> Sharpened while building. Decision records:
> [Program edits, and which of them are rules](issues/0026-program-edits-and-the-rules-boundary.md),
> [Build the Program edits](issues/0028-build-the-program-edits.md).

### 6.7 Flow 4 — History and the progression chart

> Decision record: [History and progression charts](issues/0015-history-and-progression-charts.md).
> Artboards: [Fitty History and Charts](https://claude.ai/code/artifact/a6451a92-3c59-4d4c-a1ce-7a3c81112989),
> source in `design/0015-history/`.

Hoppa moves the weight up at every Finish. This is where the climb is visible.

#### Two doors, no tab bar

Hoppa has **no tab bar**. History is reached from the two places the user already stands:

| Door | Opens |
| --- | --- |
| A **HISTORY** row at the foot of the Workout Day picker | The history screen: the streak, then the Workout list |
| Any **Exercise card** in the Workout Day screen | That Exercise's chart. The card carries a sparkline, so the door announces itself |

Nothing permanent is added to the logging screen.

**The sparkline *is* the door**, and the rest of the card still opens §6.2's Exercise sheet.
Settled while building, at
[The Exercise card's two doors](issues/0050-the-exercise-cards-two-doors.md): §6.7's own
sentence makes the mark the announcement, so the announcement and the door are one object
and no third affordance has to be explained. An Exercise card is edited far more often than
it is charted — every Exercise is opened while the Program is being built, and none of them
has a chart then — so the frequent path keeps the whole card.

**No sparkline, no door.** The mark is drawn only where the Exercise has been performed at
least once, so a card with nothing to plot offers no way into an empty room. That is this
section's own empty state, one room further out — and note the two gates are **not** the
same gate: two sessions make a *line*, one makes a *screen worth reaching*, because at one
session the chart still states the hero, the chip and the condition for the next step.

**The mark is the chart's own line**, on the chart's own scale and its own real-time x axis,
in **2 px steel** — §7.1's rule that no plate colour enters a chart does not stop at the
chart's edge. It draws no One-off marker and no `NEXT` step: a hollow marker is a smudge at
that size, and the step's destination is already the big number printed beside it on the
same card.

> **This row said *the Program sheet* and the room is the Workout Day screen.** In this app
> the Program sheet lists Workout Days; Exercise cards live one room down. The artboard
> settles it — `design/0015-history/Program.dc.html` is headed
> `‹ Upper / Lower · Upper A · 5 exercises`, which is the Workout Day screen. Corrected at
> ticket 0050.

#### The per-Exercise chart

The line is the **Working Weight** — what Hoppa tracks and what progression moves. Estimated 1RM
and volume per session are not offered: both are computed guesses about a lift Hoppa does not
track, and volume *falls* when the weight rises and the reps reset, so a progression would read as
a loss.

| Element | Rule |
| --- | --- |
| The line | 2 px, **steel** `#9BA1A7`. No plate colour ever enters a chart — a coloured line would claim to be a plate (§7.1) |
| A session that **progressed** | Filled green dot. Green already means progression everywhere (§7.3), so this needs no legend to learn |
| A session that **stayed** | Filled steel dot |
| A **One-off Weight** | Hollow marker **off** the line, at the weight actually lifted, tied to its session by a dotted drop, labelled `ONE-OFF`. The line itself never dips — a One-off never became the Working Weight (§4.3) |
| A **Skipped** Exercise | Nothing at all. No point, no gap marker |
| The x axis | **Real time**, not the session number, using the date the Workout started (§2.4). A missed week is therefore already visible as a wider gap |
| The **NEXT** step | Where the last session progressed, a **dashed green step** from the last point to a hollow marker at the current Working Weight. **Solid is lifted; dashed is applied but not yet performed.** Without it the hero number contradicts the end of the line, because Hoppa applies the weight at Finish (§4.1). **Where the user set the weight by hand instead (§4.3), the same step is drawn in steel and labelled `NOW`** — settled while building, at [The per-Exercise chart](issues/0049-the-per-exercise-chart.md): the gap is the same gap, and green is progression everywhere |

**The reps are a Set grid, not figures on the points.** Under the line sits one column per
session and one cell per Set, filled where that Set met the threshold of its Progression Mode.
Three filled cells *is* the progression rule (§4.1), so the grid answers "why did it not go up"
with no words and no advice. A One-off's column is **never** filled, whatever the reps: it could
not have progressed, and a full green column beside a step that never came would be a lie.

Figures over every point were drawn and rejected: at fifteen sessions they collide, and one number
carries two meanings at once — the best Set, and, in green, all Sets.

Under the grid, a **Last sessions** list gives the exact rep counts for the four most recent
sessions, so nothing lives only in a picture. The screen ends on three figures: the first weight
with its date, the total gain, and the number of times the Exercise went up.

**Charts never join by Name** (§2.7). `Barbell Bench Press` in Upper A and in Upper B are two
Exercises with their own Working Weight, so joining them would splice two lifts into a line where
no point is true. They sit apart in the list, each labelled with its Workout Day.

#### Mixed units on a chart

A Machine (Stack) whose Weight Unit differs from the Plate Inventory's carries a
Microload (§2.3), and
the two units never convert, so **there is no single number to plot**. The chart plots whichever
number actually moves. For the reference case — a 90 lbs stack with a kg Microplate — the pin has
not moved in fifteen weeks and the whole climb is in the Microload, so the **Microload is the
line** and the axis reads `+ KG`. The two heroes stack as `90 LBS` and `+ 3 KG`, each with its own
label, converting nothing.

§6.5's precedent survives intact: a per-Exercise number never converts. No aggregate view ships,
so the converting half of that precedent is never used.

**Open, and stated on the screen rather than solved** — found while building, at
[The per-Exercise chart](issues/0049-the-per-exercise-chart.md). The reference case is a pin that
has *not* moved. When it does, the roll-up empties the Microload into it (§4.2) and **the line
falls while the weight on the machine rises** — the shape this section refused volume for. The
chart draws what it plots and the sentence under it says why the line drops; nothing is smoothed
behind the user's back. It is unreachable on a kg rack with kg stacks, so it waits for a lifter who
can reach it.

#### The Workout list

Reverse date order. Each row: the date, the Workout Day's Name, the count of Exercises and Sets,
any skips, and — when there were any — how many Exercises went up, in green. Opening a row shows
every Set as performed, from the Set's own stored numbers (§2.5), with the progression each
Exercise earned stated beside its name.

#### The Workout detail is not the Summary

> Settled while building, at [A past Workout opened and deleted](issues/0048-a-past-workout-opened-and-deleted.md).

§6.5 is a **verdict on a session that has just ended**: a count as the hero, three sections, a
condition line under every stayed Exercise and `NEXT TIME` beside every green one. This is a
**record**: one Exercise after another in the order performed, every Set with the weight it was
lifted at, and the progression it earned on the right — `STAYED`, or a green `25 → 27.5 KG`.

**A past Workout states no future.** `NEXT TIME` and `ALL 3 SETS AT 12 → 75 KG` are both about
the session *after* this one, and three weeks later that session has already happened. Printing
neither is what keeps the screen from going stale, and it is why the two screens are two screens.

| Element | Rule |
| --- | --- |
| The reps | Green where the Set met the recorded threshold — **the same fact the chart's Set grid fills a cell with**, so the two views can never disagree. **Never green on a One-off**, whatever the reps (the grid rule, from the other side) |
| The weight on a Set row | The Set's own stored number and its own unit (§2.5). Not relabelled to the Exercise's unit the way §6.5 relabels: the Summary is looking at the minute the Set was logged, this is looking at three weeks ago, and a unit may have moved since (§6.6) |
| A **One-off** | Replaces the verdict with the steel chip, in the past tense: `ONE-OFF · 80 KG STAYED`. It states the Working Weight that survived, read off the record (§2.4) |
| A **Skipped** Exercise | Listed plain with `SKIPPED` and no Set rows — §6.5's own rule about a skip |
| An Exercise deleted **mid-Workout** | Finish wrote no outcome, so there is no verdict: the row reads `REMOVED FROM THE PROGRAM`. An Exercise deleted *after* the Workout keeps its outcome and reads normally (§2.8) |
| The header | The list row's own line — the date, the Exercises, the Sets, the skips — so the list and the screen it opens can never state two different numbers, and the delete confirm counts what the header counts |

#### The streak

One block per week. **A week counts as soon as it holds one Workout** — the question is whether
the user went, and a busy week with one session should not wipe the run. Above the strip, the
current run as a figure: `9` · `WEEKS IN A ROW`.

A week with no Workout is a **darker block, and nothing else**. No flame, no warning, no
notification, no "streak lost", and — deliberately — **no best-ever number**, which would make the
current run read as a shortfall. The strip is the record and the figure is a fact about it. This
is the one view that could have broken §7.6's rule that Hoppa states and never advises; the
absence of a comparison is what keeps it whole.

#### Deleting a past Workout

Delete lives behind the Workout's `•••` menu.

| | |
| --- | --- |
| What it removes | Every Set of that Workout |
| What it does **not** touch | Every **Working Weight**. Hoppa applied the progression at Finish and never lowers a weight by itself (§4.1); recomputing the chain would also reach past any weight the user later set by hand (§4.3) |
| The confirm | States both halves: what is removed, and that the working weights stay. The user restores a weight by hand if they want to |

The confirm's **DELETE** button uses the 25 kg plate red `#C8322B`. This is allowed, and it fixes
the boundary of §7.1's first rule: **a plate colour is a plate only inside a Plate Breakdown.**
Outside one, the palette is simply Hoppa's palette.

#### Empty state

Before the first Workout: `NOTHING HERE YET`, and one line saying a Workout lands here when it is
finished, and an Exercise gets a line once it has two.

---

## 7. The visual language — "Plate Rack"

> Decision record: [Design language & visual direction](issues/0002-design-language-and-visual-direction.md),
> amended by [Microplate accumulation](issues/0011-microplate-accumulation.md).
> Artboards: `design/0002-visual-direction/`.

**Thesis: the app speaks in plates.** Three directions were drawn (A Plate Rack, B Console,
C Logbook) with the same active-workout screen; the user chose A outright. The rejected
directions stay on the canvas as the record.

### 7.1 The two rules

1. **Colour plus size means weight, and size is never decorative.** Colour never decorates. The
   real rack repeats hues — blue is 20 kg *and* the 0.75 microplate, green is 10 kg *and* the
   0.5 — so size carries the rest of the meaning. A microplate draws at roughly a quarter of the
   smallest normal plate, so a blue disc that small can only be the 0.75.
2. **A plate is always a filled shape, and steel is never filled.** Steel is text and a 1 px
   border, always. This is what keeps the 1.25 kg grey (`#70767C`) from reading as the steel of
   the `≈ CLOSEST` and `ONE-OFF` chips. Form carries the separation, so it holds for any palette
   a later gym brings (§9).

**Both rules are rules about the Plate Breakdown.** A plate colour is a plate **only inside one**.
Outside a Plate Breakdown the palette is simply Hoppa's palette: the destructive **DELETE** button
wears the 25 kg red (§6.7) and no reader takes it for a plate, because nothing near it is a
drawing of a bar. Charts hold the same boundary from the other side — a chart draws **no** plate,
so its line is steel and its only colour is green, which §7.3 already gives a second meaning.

### 7.2 Surface palette

**Hoppa is dark only, and it is locked.** The app ignores the phone's Appearance setting, in both
places that setting reaches: `.preferredColorScheme(.dark)` on the SwiftUI hierarchy and
`UIUserInterfaceStyle = Dark` in the Info.plist, which is what the launch screen and any UIKit
chrome obey. **Reduce Motion is the one system setting it does honour** (§6.5). **It ignores Dynamic Type too**, for the same reason §7.4 fixes its sizes in points:
a layout with a 0.78 line-height and a 50 px hit target does not survive a text scale. That is
`.dynamicTypeSize(.large)` at the root, and every font built with `fixedSize` rather than `size`.
A light mode is out of scope (§10).

**No view holds a colour literal.** The nine roles below live in one file, and a screen that needs a
value this table does not name adds a **named role** there — or, better, derives it from a role
that is already named, because most of what the artboards add is a tint of the floor or a pressed
state. A genuinely **new hue** is not a role: it is a finding, and it gets a ticket.

| Role | Value |
| --- | --- |
| Floor (background) | `#0E0F10` |
| Card | `#17191B` |
| Line | `#26292C` |
| Steel (icons, shafts, chips) | `#9BA1A7` — chip border `#3A3E42` |
| Dim text | `#8D9296` |
| Text | `#F4F1EC` |
| Label text (the small uppercase labels above a block) | `#55595D` |
| Row text (a name read down a quiet list — §6.5's `STAYED` rows) | `#C9CCCF` |
| Hairline (a divider inside a quiet section, one step under Line) | `#1E2123` |

The last two arrived with §6.5's Summary and are **derivations, not new hues**: both sit on the
same hue 210° / 6.4% ramp as every grey above, at lightness 0.800 and 0.1275. They exist because
the Summary draws two sections of different weight — `WENT UP` is the loud one — and a name or a
divider borrowed from `Text` or `Line` makes the quiet section as loud as the loud one.

### 7.3 Plate palette — the user's real rack

Where a colour repeats, **shades separate the sizes, and the lighter shade is the lighter
weight**. Three black plates cannot sit flat on the `#0E0F10` floor, so the black family lifts
into greys that survive it, each with a 1 px rim one step lighter than its face.

| Plate | Colour | Value |
| --- | --- | --- |
| 25 kg | red | `#C8322B` |
| 20 kg | blue | `#1F5FCB` |
| 10 kg | green | `#2E9E52` |
| 5 kg | black → dark grey | `#33373A` |
| 2.5 kg | black → mid grey | `#4E5358` |
| 1.25 kg | black → light grey | `#70767C` |
| microplate 1 kg | red | `#C8322B` |
| microplate 0.75 kg | blue | `#1F5FCB` |
| microplate 0.5 kg | green | `#2E9E52` |
| microplate 0.25 kg | white | `#E8E6E1` |

**There is no 15 kg plate** — that was an invention in the prototype fixture and it is gone. The
25 kg stays in the shipped default list but switched off, because the Inventory is a toggle list
for any gym, not a picture of this rack. It is **red `#C8322B`**, the same red as the 1 kg
microplate: rule 1 carries the pair, exactly as it already carries blue (20 kg and the 0.75) and
green (10 kg and the 0.5).

**The shipped palette is one gym's iron rack, knowingly.** In a bumper or IWF set the 5, 2.5 and
1.25 are white, red and chrome, and 25 is red — so most public users will see wrong colours. A
second shipped palette, picked with one tap at onboarding step 2, was raised and deferred: it
needs the same care as the first and re-opens which colour means what. **User-set plate colours**
stays open (§9); rule 1 survives any palette, so this is safe to add later.

Green `#2E9E52` doubles as the **done / progression** colour.

### 7.4 Type, shape, spacing

- **Display: Anton.** Working Weight, headings, set numbers, button labels. Uppercase, tight
  line-height (0.78–0.94).
- **Body: IBM Plex Sans.** Labels, meta lines, body. **Tabular figures on.**
- Labels uppercase, 10–11 px, letter-spacing 0.12–0.14 em.
- **Radii 2–3 px** — industrial, near-square.
- Screen padding 20 px. Safe top inset 54 px with **nothing drawn in it**.
- Vertical rhythm on an 8 / 16 px gap.
- Hit targets **50 px** (Set rows) and **64 px** (bottom controls).

### 7.5 The signature

**The loaded bar**: a side view with plates drawn to relative diameter and width, in their real
colours, mirrored around a knurled centre shaft, with a caption underneath giving the per-side
sum in words and figures. It is the same drawing on all three plate-loaded Equipment Types
(§5.5).

**No collar outboard of the last plate.** Removed at
[The weight is too big and the plates too small](issues/0053-the-hero-and-the-load-line.md): an
8 × 40 outline in the darkest steel, sitting exactly where a fifth plate would, read as a plate on
the phone. §7.1 rule 2 — steel is never filled — was supposed to keep the two apart and did not at
arm's length. The **sleeve stops stay**; they are what says where the loading zone ends.

### 7.6 Copy

- Labels and buttons uppercase; sentences in the body sentence-case.
- **Statements, not offers.** `→ 75 KG NEXT TIME`, never "Accept +2.5?".
- **Conditions, not instructions.** `ALL 3 SETS AT 12 → 75 KG`, never "Do 3 sets of 12 to
  progress".
- No warning colour on anything the user did — over-range reps, skipped Exercises, a lowered
  weight.
- All UI copy is **English**.

---

## 8. The prototype code

### 8.1 What to lift

`design/0007-logging/fitty-workout-logging.html` holds a **pure module `Fitty`** —
`initialState`, `reduce`, `breakdown`, `progression` — with no DOM, no timers and no
`Date.now()`; every action that needs a clock takes an `at`. **That module is the part meant to
lift into the real app.** The page around it is throwaway, as is
`design/0007-logging/artifact.html` (the same file wrapped for publishing).

### 8.2 What it has wrong

The module predates [Microplate accumulation](issues/0011-microplate-accumulation.md). Fix these
before or during the lift — **the spec above is right and the code is wrong**:

| Defect | Correct behaviour |
| --- | --- |
| `Fitty.progression()` returns `to: ex.weight` with `fromPlates`/`toPlates` under Microloading | It must return a new **Working Weight**, or a new **Microload** where the units differ (§4.2) |
| `ex.microplates` — a **count** | Replaced by a **Microload** — a weight (§2.3) |
| `greedy()` takes `inv.plates` unconditionally | It must take the plate list the **Progression Mode** allows (§5.3) |
| The fixture holds a 15 kg plate | It does not exist (§7.3) |
| `PLATE` holds the invented colours | Use the real rack (§7.3) |
| `ex.blockSize` | Rename to **Stack Step**, and give it a place on the Exercise sheet (§2.3, §6.2) |
| A logged Set holds the rep count only, and the weight is read live off the Exercise | A Set stores its own reps, weight, Weight Unit, Microload and One-off mark (§2.5) |
| Progression tests the logged Sets for **equality** with the planned Sets | The test is **at least** the planned Sets (§4.1) |
| `breakdown()` puts the pin at `Math.round(w / blockSize)`, which can place it **above** the Working Weight | The pin takes the largest Stack Step **at or under** the Working Weight, and the remainder hangs on the pin (§5.3, §5.5) |
| `SUBMIT_WEIGHT` decides *raise or lower* against the **performed** weight, so a number above a standing One-off Weight reads as a raise — and a raise sticks by writing the Working Weight, which takes the record down with no question asked | The question guards the **Working Weight**: it is asked whenever the write would move the Working Weight down (§4.3) |
| The weight sheet's `−` / `+` step by `blockSize` under Microloading, whatever the Equipment Type — the Stack Step, on a bar | The step is **what the rule moves the Working Weight by**: the Increment under Progressive Overload, the Microplate doubled on a bar under Microloading (§4.2). A stack grows the PIN and MICRO steppers instead (§6.4) |
| The `NUDGE` and `KEY` reducers, and the keypad buffer, sit **inside** `Fitty.reduce` beside the real rules | The buffer is view state; only the finished `Weight` reaches a rule (§6.4) |

The ninth row was found during the lift itself, at
[Lift the rules into HoppaRules](issues/0023-lift-the-rules-into-hopparules.md), and the last three
while building the weight sheet, at [The weight sheet](issues/0037-the-weight-sheet.md). Every row
above is now a named, green test in `app/HoppaRules` — except the last, which is proven by where
the code **is not**: `HoppaRules` has no keypad in it.

The tenth is the one worth reading twice, because it is what the twelfth row causes: **§4.3's
decision lived in a view**, so nothing could fail a test on it. It is `Rules.weightEdit` now.

The prototype's Workout Summary is a deliberate placeholder; the real one is §6.5.

The **summary** prototype `design/0009-summary/fitty-workout-summary.html` has two defects of its
own, both exposed by [Confetti plate source](issues/0012-confetti-plate-source.md):

| Defect | Correct behaviour |
| --- | --- |
| `colours()` falls back to `rack = [added]` — the Increment colour — for every Equipment Type that is not plate-loaded | Use the table in §6.5: steel pin blocks plus Microplates for a stack, steel for a dumbbell, the belt plate for bodyweight |
| `burst()` fills every particle and draws no rim | Every particle carries a 1.5 px rim; **steel particles are not filled at all** (§7.1 rule 2) |

### 8.3 Published prototypes

| Artefact | Link |
| --- | --- |
| Visual directions canvas | https://claude.ai/code/artifact/cd36141c-1c13-4052-ab0c-6ce8a3add70d |
| Plate Breakdown canvas | https://claude.ai/code/artifact/6562a440-efd1-4f87-81b9-4630dc3c9ae6 |
| Program Onboarding canvas | https://claude.ai/code/artifact/cdf0fcb9-5c71-4bfa-b7f1-ac64e1f480ca |
| Workout Logging prototype | https://claude.ai/code/artifact/11e1688b-5cd9-4010-9448-53c9bdc47e53 |
| Workout Summary prototype | https://claude.ai/code/artifact/027b21df-315f-461d-a358-e511b6e5fb26 |
| Workout Summary screens canvas | https://claude.ai/code/artifact/5b35afe6-8883-42c5-a233-242e800b4309 |
| History and Charts canvas | https://claude.ai/code/artifact/a6451a92-3c59-4d4c-a1ce-7a3c81112989 |

`design/0015-history/` also holds a **history generator** (`gen-fixture.mjs`) that runs the
progression rules of §4 forward over the whole Program — four Workout Days, 18 Exercises, 56
Workouts, 16 weeks. It is throwaway prototype code, but it is the only thing in this map that has
ever tested the rules over more than one Workout, and it is what found §9's open item.

**It has now been re-run against the real implementation.** Its lifter — the seeded generator and
the rep model — ports into `app/HoppaRules`'s test target, and the rules come from `HoppaRules`
itself. Its 0.25 kg Microplate does **not** port: `gen-fixture.mjs` picked that size so sixteen
weeks would stay under one Stack Step and the roll-up would never be reached, so the Swift run uses
the 1 kg plate and the pin moves twice. The result is committed as a snapshot, and drift shows up as
a diff. Decision record:
[Lift the rules into HoppaRules](issues/0023-lift-the-rules-into-hopparules.md).

---

## 9. Open items

**Nothing is open.** All five flows are specified, every screen the app needs has been drawn, and
every rule that was found wrong has been fixed. The map that produced this document is closed, and
this spec is what it was for.

The one item that had been deferred rather than decided — **user-set plate colours** — was ruled
out of scope on the way out; it is now the first entry in §10, with the reason.

---

## 10. Out of scope

- **The build phase itself**: SwiftUI implementation, persistence, backend, App Store release.
  This spec is where that effort starts, as a fresh one.
- **Writing out the ~150 names of the Exercise Catalogue.** Content work for the build. §6.3
  fixes the size, the order and the naming rule that govern the list, which is as far as a spec
  needs to go.

Eight features were ruled out of scope deliberately. Each is a **new feature, not a hole** in the
flows this spec validates, so each is a later effort rather than a resumption of this one:

- **User-set plate colours.** §7.3 ships one gym's iron rack: 5, 2.5 and 1.25 in black, where a
  bumper or IWF set paints them white, red and chrome and 25 red. Most public users will therefore
  see wrong colours, and this **should ship before the app is public** — but nothing in this spec
  depends on which rack it is, because rule 1 of §7.1 (*colour plus size means weight*) survives
  any palette that replaces this one. A second palette needs the same care as the first and
  re-opens which colour means what, which is a design effort of its own.
- **A light mode.** §7.2 locks the app to dark. The palette is not merely a preference: §7.3's
  plate colours are **physical** — a blue 20 kg plate is blue in the gym — so they cannot invert,
  and the Anton hero, the steel of the loaded bar and §7.1's unfilled steel confetti particles all
  read against a dark floor by design. A light mode is therefore a design effort of its own, not a
  token swap, and it rides with the App Store effort where a second lifter in a bright gym first
  appears. §7.2's one-file rule is what keeps it cheap: a second value per role, not a hunt.
- **Template library** (5/3/1, PPL, …): how templates and manual entry meet. Onboarding was built
  empty-first on purpose (§6.1).
- **Equipment profiles shared across Exercises** — "Smith machine at my gym, 7 kg base". Base
  Weight is typed by hand on every Smith and plate-loaded Exercise with no default, so a profile
  is exactly what would replace that repetition.
- **Warm-up sets**: whether Hoppa shows them and computes their plates.
- **Bodyweight rep-progression before added weight** — chin-ups without a belt.
- **Deload guidance after repeated failure.** Hoppa deliberately does nothing today (§4.4), and
  the reason stands: it has no data to pick the right deload.
- **Several Plate Inventories, one per gym.** Hoppa holds one (§5.2). Changing its unit is
  therefore a gym move that clears and re-asks every plate-loaded weight (§6.6), which is the
  honest cost of one Inventory. Saved racks would remove it, and that is a feature.
- **Whether the name `Hoppa` survives an App Store name check.** The app **is** called Hoppa —
  Rob named it at [An empty app on the phone](issues/0018-an-empty-app-on-the-phone.md), and the
  bundle id `com.robvb.hoppa` is fixed. What is out of scope is the *public* name: the App Store
  requires a unique app name, and at least one established `Hoppa` exists already. That rides with
  the App Store effort. It does not threaten the bundle id, which only has to be globally unique
  and is never shown to a user.

---

## 11. Decision index

| # | Ticket | Settles |
| --- | --- | --- |
| 2 | [Design language & visual direction](issues/0002-design-language-and-visual-direction.md) | The "Plate Rack" language: palette, type, shape, the loaded bar (§7) |
| 3 | [Workout session lifecycle](issues/0003-workout-session-lifecycle.md) | Free pick, explicit start, Exercise States, the Finish gate, per-Exercise progression (§3, §4.1) |
| 4 | [Progression edge cases](issues/0004-progression-edge-cases.md) | Applied at Finish, over-range reps, manual weight changes, the Weight Unit moving to the Exercise (§4, §5.1) |
| 5 | [Plate display design](issues/0005-plate-display-design.md) | One drawing for three types, the Plate Inventory, `≈ CLOSEST`, mixed units (§5) |
| 6 | [Program onboarding flow prototype](issues/0006-program-onboarding-flow-prototype.md) | Empty start, three steps, Model B, 14 taps per Exercise (§6.1, §6.2) |
| 7 | [Workout logging clickable prototype](issues/0007-workout-logging-clickable-prototype.md) | The logging screen, the weight sheet, the rule chip, the `Fitty` module (§6.4, §8) |
| 8 | [Assemble the spec](issues/0008-assemble-the-spec.md) | This document |
| 9 | [Workout summary screen prototype](issues/0009-workout-summary-screen.md) | The count as hero, Ignition confetti, the zero-progressed screen (§6.5) |
| 10 | [Exercise name suggestions](issues/0010-exercise-name-suggestions.md) | Two sources, the derived own-names list, the Catalogue's rules (§2.7, §6.3) |
| 11 | [Microplate accumulation](issues/0011-microplate-accumulation.md) | One Microloading model, the Microload, the Mode-scoped solver, Stack Step, the real palette (§4.2, §5.3, §7.3) |
| 12 | [Confetti plate source](issues/0012-confetti-plate-source.md) | The burst throws what the Plate Breakdown draws; proportional sampling; steel is hollow (§6.5) |
| 13 | [Plate Inventory shipped defaults](issues/0013-plate-inventory-shipped-defaults.md) | 25 kg is red, every Microplate ships off, the empty-Microplate path (§5.2, §7.3) |
| 14 | [Editing a Program over time](issues/0014-editing-a-program-over-time.md) | The Set stores its own numbers, at-least-the-planned-Sets, unit changes clear the weight, the Re-weigh list, deleting (§2.4, §2.5, §3.2, §4.1, §6.6) |
| 15 | [History and progression charts](issues/0015-history-and-progression-charts.md), amended by [The per-Exercise chart](issues/0049-the-per-exercise-chart.md) | Two doors and no tab bar, the Working-Weight line with a Set grid, the NEXT step, the streak, deleting a past Workout, plate colour outside a Plate Breakdown (§6.7, §7.1) |
| 16 | [Bounding the Microload](issues/0016-bounding-the-microload.md) | The roll-up into the pin, the Microload only where there is a Stack Step, Bodyweight takes the Inventory's unit (§2.3, §2.6, §4.2, §5.1, §5.3) |
