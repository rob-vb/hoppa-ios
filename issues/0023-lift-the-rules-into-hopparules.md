---
id: 23
title: Lift the rules into HoppaRules
parent: 17
labels: [wayfinder:task]
status: closed
assignee: agent
blocked-by: [22]
---

## Question

Nothing to decide — [The rules module and its oracle](0020-the-rules-module-and-its-oracle.md)
decided all of it. **Build `app/HoppaRules` and its tests, and deliver every test green.**

Zoom ticket 20's resolution and treat it as given. This ticket is the execution of it, and its
deliverable is not a paste: it is a package that `swift test` proves on the VPS before it is pushed.

### The shape, restated only far enough to work from

- Local Swift package `app/HoppaRules`. Target `HoppaRules`, test target `HoppaRulesTests`.
- **`HoppaRules` imports nothing.** `Timestamp` is a `Double` of seconds since epoch, defined in the
  target. `Rules.reduce(_ workout: Workout, _ action: Action, at: Timestamp) -> Workout`.
- It owns `Logbook`, `Program`, `WorkoutDay`, `Exercise`, `LoggedSet`, `PlateInventory`,
  `Workout`, `PerformedExercise`, `ProgressionOutcome`, `Weight` and the enums `EquipmentType`,
  `ProgressionMode`, `WeightUnit`. **[Persistence and the data
  model](0019-persistence-and-the-data-model.md) fixed their shape — zoom it and treat it as given.**
  The parts that change how you write the code:
  - **A weight is `struct Weight { let hundredths: Int; let unit: WeightUnit }`.** Never a `Double`.
    The prototype's floats do not come across. `≈ CLOSEST` and *is the Microload one Stack Step* are
    exact `Int` comparisons, and the committed snapshot stays byte-stable.
  - The domain type is **`LoggedSet`**, not `Set`, which would shadow `Swift.Set`. The word **Set**
    stays the domain term everywhere a person reads it.
  - A `LoggedSet` carries **no id**; its position is its identity. Ids are typed and come from a
    counter the app owns, so `reduce` never sees one.
  - `Workout` carries `restStartedAt: Timestamp?`; `PerformedExercise` carries `oneOffWeight:
    Weight?` and `outcome: ProgressionOutcome?`, written at Finish.
  - `baseWeight` and `stackStep` are stored flat but read through accessors that return `nil` on a
    type that has none. `microload` is a real `Weight?`. `weightUnit` is **derived** for Barbell,
    Smith, Plate-loaded and Bodyweight: `weightUnit(in: inventory)`.
- **Every type is `Codable`, and every enum has an explicit `String` raw value.** `Codable` is in the
  standard library, so this costs the zero-import rule nothing. A Swift case name must never be the
  data on Rob's phone.
- `screen`, `overlay`, `draft`, the keypad buffer and `events` do **not** come across.
- `HoppaRulesTests` may import Foundation. Framework is Swift Testing.

### The order of work, which is the whole point

1. **Eight failing tests first**, one per defect in `SPEC.md` §8.2. Write them red against the
   lifted code, then fix the code. The two summary defects are not in scope here.
2. **The invariant tests**: roll-up never goes down and Microload < one Stack Step (§4.2), *at
   least* the planned Sets (§4.1), the Mode-scoped solver (§5.3), `≈ CLOSEST` rounds down on a tie
   (§5.4), a One-off Weight never progresses, reps above the top raise the weight once.
   `design/0015-history/check-rollup.mjs` holds four cases that port straight across as parameterized
   data — including the one it calls "the case that broke".
3. **The nine walkthroughs** from `design/0007-logging/fitty-workout-logging.html` (`SCENARIOS`),
   minus their keypad and overlay steps. These are the acceptance tests of the logging flow.
4. **The `Logbook` round-trip fixture.** One full `Logbook` — a Program, a Plate Inventory, a few
   Workouts — encoded, decoded and re-encoded, asserted identical, and **committed**. An accidental
   key rename then fails in review instead of on the phone.
5. **The 56-Workout snapshot.** Port the deterministic lifter simulation from
   `design/0015-history/gen-fixture.mjs` — the seeded LCG and `repsFor` — into the test target. Run
   four Workout Days, 18 Exercises, 16 weeks forward. Assert the invariants at every progression.
   Write `HoppaRulesTests/Snapshots/history.json` and commit it. One flag re-records.

**Do not port `gen-fixture.mjs`'s rules.** It has no roll-up — ticket 20 established that, and its
own comment admits it dodged the case. Port its *lifter*, and let `HoppaRules` supply the rules.

### Two things this ticket must not do

- **Do not patch `project.pbxproj`.** Rob adds the package through *File → Add Package Dependencies
  → Add Local*. Hand him that instruction in the resolution.
- **Do not write a view.** The SwiftUI layer is
  [its own ticket](0024-the-view-layer-around-the-rules.md) and it is blocked on this one and on
  storage.

### Expect to find the spec wrong

The map's Notes say a rule the build proves wrong is **a finding with its own ticket**, never a
quiet fix. This is the first session that executes the rules in anger, and the design map found four
of its own defects exactly this way. If a test cannot be made to pass without contradicting
`SPEC.md`, stop and write the ticket.

## Resolution

**`app/HoppaRules` is built, and `swift test` runs 46 tests green on the VPS.** 1 427 lines of
rules that import nothing, 1 483 lines of tests, one committed `Logbook` fixture and one committed
56-Workout snapshot. Rob adds it to Xcode himself: *File → Add Package Dependencies… → Add Local…*
→ pick `app/HoppaRules`, then add the `HoppaRules` library to the **Hoppa** target.

    cd app/HoppaRules && swift test          # 46 tests, 5 suites
    HOPPA_RECORD=1 swift test                # re-record the two committed files

Everything ticket 20 and ticket 19 decided is in place: zero imports, the clock as an argument,
value types with `Codable` and explicit `String` raw values, `Weight` as `Int` hundredths carrying
its unit, `LoggedSet` with no id, `restStartedAt` and `oneOffWeight` with real homes, the derived
Weight Unit, ids from a counter. `screen`, `overlay`, `draft`, the keypad buffer and `events` did
not come across.

### The signature had to change, and the reason is a rule

Ticket 20 fixed `Rules.reduce(_ workout: Workout, _ action: Action, at: Timestamp) -> Workout`.
**It cannot be that**, and this is the ticket's largest finding.

Progression writes to the **Program**. The Working Weight lives on the Exercise (§4.1), a Microload
lives on the Exercise (§2.3), and an edit at the rack is a Program edit (§6.6). A `reduce` that
returns only a `Workout` can move no weight at all — and it cannot even *evaluate* progression,
because the planned Sets and the Rep Range it must write into a Progression Outcome (§2.4) are on
the Exercise and not on the Workout.

So the signature is **`Rules.reduce(_ logbook: Logbook, _ action: Action, at: Timestamp) -> Logbook`**.
Nothing else about the boundary moved: it is still one pure function, the clock is still an
argument, and `Logbook` is the root value [Persistence and the data
model](0019-persistence-and-the-data-model.md) landed on **after** ticket 20 wrote that line. Ids
are minted from `logbook.nextId` inside `reduce`, which is deterministic and keeps *an id is never
reused* in one place; ticket 23's "reduce never sees an id" was about a `LoggedSet`, which still has
none.

### A ninth defect, now in §8.2

§8.2 listed eight. There are nine. `Fitty.breakdown()` puts the pin at
`Math.round(w / ex.blockSize)`, which **rounds the pin up**: 105 lbs on a 10 lbs stack draws a pin
at 110, a weight the user is not lifting. §5.3 and §5.5 both say the pin takes the largest Stack
Step **at or under** the Working Weight and the remainder hangs on it. Added to `SPEC.md` §8.2 as a
ninth row, with a test — the spec was right and the code was wrong, as it has been eight times
before.

### The 56-Workout snapshot does not use gen-fixture's Microplate

`gen-fixture.mjs` gave the Lat pulldown a **0.25 kg** Microplate, and its own comment says why: with
that plate sixteen weeks of Microloading lands *under* one Stack Step, so the roll-up is never
reached. Porting that number would have committed a 160 KB snapshot that proves the rules work
everywhere except the one place [Bounding the Microload](0016-bounding-the-microload.md) exists for.
The Swift run uses the **1 kg** plate. The pin now moves twice in sixteen weeks:

    90 lbs + 4 kg  ->  100 lbs + 0.5 kg      (week 5)
    100 lbs + 4.5 kg  ->  110 lbs + 1 kg     (week 12)

The lifter itself — the seeded LCG, `repsFor`, the calendar with its missed week, its short week,
its One-off week and its Skip week — is ported to the bit. `SPEC.md` §8.3 records this.

### What proves it, in the order it was built

1. **Nine tests, one per §8.2 defect.** Every one is load-bearing: each was re-run against a
   deliberate re-break of the rule it covers, and each went red. `>=` back to `==`, Progressive
   Overload handed the whole rack, the tie rounding up, Microloading returning the old weight — all
   caught.
2. **Twenty invariant tests.** The four `check-rollup.mjs` cases as parameterized data, 40
   progressions each, asserting three things at every step: the Microload is under one Stack Step,
   the weight never goes down, **and the Microload is a weight the rack can build** — the third one
   is what a `roundedDown` mutation trips, and it was added after the first two proved blind to it.
   Plus *at least* the planned Sets, the Mode-scoped solver, `≈ CLOSEST` on a tie, a One-off never
   progressing, reps above the top raising once, the Finish gate, one Open Workout at a time, and
   the derived Weight Unit relabelling rather than converting.
3. **The nine walkthroughs of §6.4**, minus their keypad and overlay steps, each asserting the rule
   it was written to demonstrate. All nine hold, including `61.25 kg → you load 60 kg · 1.25 under`
   under the Mode-scoped solver.
4. **The `Logbook` round-trip**, committed at `Tests/HoppaRulesTests/Fixtures/logbook.json` —
   encode, decode, re-encode, byte-identical, plus a check that the committed bytes still decode.
5. **The 56-Workout snapshot**, committed at `Tests/HoppaRulesTests/Snapshots/history.json`, with
   the invariants asserted at every progression of every Exercise and a determinism test beside it.

### Decisions taken inside the lift

- **`currentIndex` is on the `Workout`, not in the view.** `.selectExercise(index:)` is an action, so
  the Exercise Rob was standing at survives a relaunch mid-session. The rep counter went the other
  way: `.logSet(reps:)` carries the number and `targetReps` is a pure query the view prefills from.
  [The view layer around the rules](0024-the-view-layer-around-the-rules.md) has been trimmed.
- **`ResolvedExercise` is the one place derivation happens.** Every rule takes one, so a stale Weight
  Unit, a Base Weight on a Barbell or a Stack Step on a Dumbbell is unrepresentable *inside the
  rules* rather than something each rule has to remember. `SPEC.md` §2.8 asked for exactly this and
  this is the shape it took.
- **A derived unit relabels; it never converts.** `workingWeight.relabelled(unit)` moves no iron.
  §6.6 clears the weights when the rack's unit changes, so nothing is ever reinterpreted behind the
  user's back.
- **The bar is solved on the total, with the plate sizes doubled.** 61.25 kg on a 20 kg bar is
  20.625 per side, which is not a whole number of hundredths — so a per-side target is never
  represented at all. Every buildable per-side load is exact, because it is a sum of real plates.
- **The roll-up converts the Stack Step downwards**, as an exact `Int` ratio and never a `Double`.
  Down and not up, because a step converted down leaves the remainder no smaller than it should be.
- **`PlatePalette` lives in the rules**, because §8.2 calls the invented colours a defect and a plate
  colour is a fact about a plate. It is kg-only, which is what §7.3 specifies; an lbs rack gets
  `nil` and the view falls back to steel. §7.3 already defers a second palette, so this is not a new
  gap.
- **Total volume is here too**, because it is the one conversion the spec allows (§5.1) and a rule
  is the right place to keep the exception honest.

### What this ticket did not build, and where it went

`reduce` handles the logging flow and **one** Program edit — `.setWorkingWeight`, because §4.3 puts
it inside the Workout and three walkthroughs need it. The rest of §6.6 is not here: raising the
planned Sets reopening a Completed Exercise (§3.2), a unit change clearing the weights, the Re-weigh
list, a stranded Microloading Increment, deleting. Those are rules with nowhere to live —
`LogbookStore` is forbidden from deciding anything (ticket 25) — so they graduate as
**[Program edits, and which of them are rules](0026-program-edits-and-the-rules-boundary.md)**.

No view was written, and `project.pbxproj` was not touched.
