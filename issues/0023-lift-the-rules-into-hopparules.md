---
id: 23
title: Lift the rules into HoppaRules
parent: 17
labels: [wayfinder:task]
status: open
assignee:
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
