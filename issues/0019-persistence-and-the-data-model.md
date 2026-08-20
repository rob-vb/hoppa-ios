---
id: 19
title: Persistence and the data model
parent: 17
labels: [wayfinder:grilling]
status: closed
assignee: henk
blocked-by: [20]
---

## Question

**How does `SPEC.md` §2 become types that survive the app closing?** The biggest architectural
decision on this map, and the one hardest to walk back: it decides the shape of every screen's
data and every migration for the life of the app.

`SPEC.md` §2 is unusually specific for a spec — fields per entity, and three rules that are really
storage requirements in disguise. Those three are the test any answer has to pass.

### The three rules that constrain the model

1. **A Set is a record of the past (§2.5).** It stores its own reps, weight, Weight Unit, Microload
   and One-off mark *as performed*, and **no later edit to the Exercise, the Program or the Plate
   Inventory changes it**. The design map found this the hard way: before ticket 14 a Set held the
   rep count only and read the weight live off the Exercise, so every finished Workout displayed a
   weight that progression had since moved. A model that lets a Set point at a mutable Exercise
   weight reintroduces that bug.
2. **A Set stores no Plate Breakdown (§2.5).** It is a solve, not a fact. Storing the picture would
   make every Plate Inventory edit a history migration.
3. **The Name is looked up live, and stored only as a fallback (§2.4, §2.7).** A Workout keeps the
   Name of its Workout Day and every Exercise, but Fitty shows the **live** Name while the Exercise
   exists and falls back to the kept one **only after a delete** — so a rename still fixes a typo
   everywhere in history. That is a relationship that must survive the deletion of its target,
   which is exactly where an ORM's cascade rules bite.

### What to settle

- **SwiftData, Core Data, or Codable value types written to disk?** SwiftData is the modern default
  and the least code; it is also young, opinionated about mutability and object identity, and its
  migration story is thinner than Core Data's. Plain `Codable` structs in a file are trivially
  testable and make rule 1 nearly free — a stored Set is a value, so nothing can mutate it from a
  distance — at the cost of writing the querying and loading by hand. Weigh them against the three
  rules above, not against fashion.
- **How do the stored types meet the rules module?** This ticket is **blocked by** [The rules
  module and its oracle](0020-the-rules-module-and-its-oracle.md) for exactly this reason: the two
  would contradict each other if worked in parallel. The rules operate on domain values that exist
  whatever the storage is, so the module's boundary is the stronger constraint and gets decided
  first. **Storage maps to the rules, not the other way round** — start by zooming ticket 20's
  resolution and treating it as given. If it turns out to make storage unreasonable, that is a
  finding, not a licence to reopen it quietly.
- **What identifies an Exercise?** §2.7 is explicit that the **Name is a label, not an identity**:
  two Exercises may share a Name and still be two Exercises with their own Working Weight. So
  identity is a stored id, and history points at it — but see rule 3 for what happens when it is
  gone.
- **What does a delete actually do**, given §6.6 says a delete can no longer destroy history?
- **Migration.** The model will change during this map. Decide now what happens to Rob's real
  logged Workouts when it does, because by then the data is weeks of actual training and there is
  no seed script to re-run.

Consult `SPEC.md` §2 in full, §4.1, §6.6, and `CONTEXT.md`. The answer becomes a Swift file Rob can
paste into the project, plus whatever `SPEC.md` needs to say about storage that it does not say yet.


## Resolution

**One JSON document, holding value types the rules already own.** No SwiftData, no Core Data, no
second model. The `Logbook` is a single `Codable` value written to `Documents/logbook.json`, loaded
whole at launch and rewritten atomically after every change.

The ticket asked to weigh the options against §2's three rules rather than against fashion. Weighed
that way it is not close, and the reason is a decision that was already made: ticket 20 gave
`HoppaRules` the domain as **value types**. SwiftData needs `@Model` classes, and those classes
cannot be those value types. So SwiftData buys its convenience with a second model and a mapping
layer in both directions — the exact duplication ticket 20 refused when it killed the JavaScript
oracle.

It also loses on all three rules. A `Set` as a class with a relationship to `Exercise` is the
ticket-14 bug restored: the weight can move from a distance. Rule 3 needs a link that outlives the
deletion of its target, which is where cascade rules bite hardest. And the volume never justifies
the machinery: sixteen weeks of the design map's simulation is 56 Workouts and 18 Exercises, so five
years of real training is a few hundred kilobytes. The whole store fits in memory.

### The document

```
Logbook
  schemaVersion  : Int
  nextId         : Int
  plateInventory : PlateInventory
  programs       : [Program]
  openWorkout    : Workout?          <- one, or none
  workouts       : [Workout]         <- finished, by startedAt

Workout
  id, workoutDayId, workoutDayName
  startedAt      : Timestamp
  restStartedAt  : Timestamp?
  state          : Open | Finished
  exercises      : [PerformedExercise]

PerformedExercise
  exerciseId     : ExerciseID
  name           : String                 <- as it read at the time
  state          : Open | Completed | Skipped
  sets           : [LoggedSet]
  oneOffWeight   : Weight?                <- this Workout only
  outcome        : ProgressionOutcome?    <- written at Finish

ProgressionOutcome
  plannedSets : Int, thresholdReps : Int, progressed : Bool
```

Two rules of §2 are enforced by the **types** rather than by code that has to remember them.
`openWorkout` is one `Optional` at the top, so *one Open Workout at a time* (§2.4) cannot be
expressed wrongly. `outcome` is an `Optional` inside the Performed Exercise, so an Open Workout
cannot carry a result. Finished Workouts sit at the top level and not inside a Program, because
history is global: the streak and the Workout list read across everything (§6.7).

A fresh install needed no decision. §6.1 pre-answers it: `KG`, Progressive Overload, the standard kg
rack. An empty `Logbook` is that Plate Inventory and nothing else.

### The five findings

This ticket was expected to choose a database. Most of its value turned out to be five things the
model got wrong or left out, and four of them are now in `SPEC.md`.

**1. A Workout stored no record of what progression did — and §6.7 needs one.** §2.4 listed six
fields, none of them the outcome. But the chart draws a green dot for a session that progressed and
a steel one for a session that stayed, and under it a Set grid with one cell per Set, filled where
that Set *met the threshold of its Progression Mode*. The threshold is the top or the bottom of the
Rep Range, and the Rep Range is editable. Solve those cells live, and changing `8-12` to `6-10`
today re-fills every grid and moves every dot in the entire history. **That is §2.5's defect in a
second place**, and it is exactly what ticket 14 caught for the weight. Fixed in `SPEC.md` §2.4:
the Workout keeps the planned Sets, the threshold reps and the progressed flag as facts.

**2. `Double` cannot hold a weight here.** The JavaScript prototype uses floats, so the lift would
have carried them into `Double` without a thought. Two things break. Ticket 20 commits a 56-Workout
snapshot so that drift shows as a diff — but adding `0.25` fifty times in binary floating point
writes `12.499999999999998`, and a snapshot that alarms falsely is a snapshot nobody reads. And
§5.4's `≈ CLOSEST` with *a tie rounds down*, and §4.2's *is the Microload now one Stack Step*, are
exact comparisons; `Double` turns both into guesses.

So a weight is `struct Weight { let hundredths: Int; let unit: WeightUnit }`. The smallest plate in
the spec is 0.25 kg, so hundredths leave room even for a typed Base Weight. **The unit rides on the
number**, which turns *units never convert* (§5.1) — the loudest rule in the spec and the source of
several past bugs — into a compile error rather than a discipline. An Exercise genuinely holds two
units at once: its Microloading Increment keeps the Plate Inventory's unit whatever the Exercise
uses. The roll-up may still convert inside itself, exactly and in `Int`, and its result is snapped
to a weight the rack can build anyway.

**3. The active One-off Weight and the Rest Timer had nowhere to live.** A One-off belongs to one
Workout and never becomes the Working Weight, so it is not on the Exercise; and before the first Set
is logged it is not on a Set either. Close the app in that gap and the choice is gone. `restStartedAt`
had the same hole: ticket 20 made it a pure `Timestamp`, and no field held it. Both are now on the
Workout tree above. Note that `oneOffWeight` on the Performed Exercise and the One-off mark on the
Set are **two different things** — the live choice and the record of it — and must not be collapsed
into one.

**4. Storing the Weight Unit of a plate-loaded Exercise creates a second copy of one truth.** §2.3
lists it as a field, but for Barbell, Smith, Plate-loaded and Bodyweight it is locked to the Plate
Inventory's unit (§5.1). Store it and §6.6's Inventory-unit switch has to walk every Program and
rewrite every one of them; miss one and an Exercise sits in lbs on a kg rack with nothing to notice.
It is now **derived**: only Dumbbell, Machine (stack) and Cable keep a unit of their own, and the
rest read `weightUnit(in: inventory)`. A stale unit becomes unrepresentable, and §6.6 is left with
only the job it describes — clearing the weights.

**5. Deleting a Program is not specified anywhere.** §6.6 covers deleting an Exercise and a Workout
Day, with two blocks. §2.1 allows more than one Program. Nothing says what happens to a whole
Program, or whether the last one is blocked as the last Workout Day is. **Not decided here** — it is
a gap in the spec, not a rule that is wrong, so it goes to the map's **Not yet specified**. The model
survives it either way: the Workout keeps its Workout Day's Name, so history stays whole.

### The smaller decisions

- **Identity is a counter.** `UUID` lives in Foundation, and `HoppaRules` imports nothing. The
  stronger reason is ticket 20's committed snapshot: random ids make `history.json` differ at every
  re-record, and the snapshot then proves nothing. So the `Logbook` holds `nextId: Int`, ids are
  typed per entity (`ExerciseID`, `WorkoutID`), and **an id is never reused** after a delete.
- **A `LoggedSet` has no id.** §6.4 was checked for this: the app appends Sets and never edits or
  deletes one. Position is identity. That matters because it keeps ticket 20's signature intact —
  `reduce` never needs to see the counter.
- **`Set` is renamed to `LoggedSet` in Swift.** The domain word stays **Set** in `SPEC.md`,
  `CONTEXT.md` and on screen. A type named `Set` inside the module shadows `Swift.Set` and traps
  every reader.
- **Deletes are hard, with no tombstone.** History already holds the id and the Name as it read, and
  no id is ever reused, so a hard delete cannot be confused with anything later.
- **`startedAt` is a `Timestamp` and nothing else.** A second frozen calendar date is a second
  truth that can disagree with the first. The instant is fixed; only its drawing follows the phone,
  and the streak counts weeks (§6.7), so an hour of drift changes nothing.
- **Base Weight and Stack Step are stored flat and read through an accessor.** They stay on the
  Exercise across a change of Equipment Type, because §2.3 makes a point of never re-asking a value.
  But `exercise.baseWeight` returns `nil` on a Barbell whatever is stored, so no rule can read one
  where it does not apply. **The Microload goes the other way** — `Weight?`, genuinely destroyed and
  recreated at zero — because §6.6 says so in as many words. A Base Weight is a fact about a machine;
  a Microload is a state that belongs to a unit.
- **Format stability costs two things, not more.** Every enum gets an explicit `String` raw value, so
  a Swift case name is never the data. And a second committed fixture — one full `Logbook` — is
  encoded, decoded and re-encoded in a test, so an accidental key rename fails in review. Hand-written
  `CodingKeys` on every property are not worth their volume when the fixture catches the same fault.
- **The Exercise Catalogue stays out of the `Logbook`.** It is shipped data, not the user's, and it
  would otherwise sit in every save and every backup. It is a plain Swift array in the app layer;
  `HoppaRules` reads no bundle and the Catalogue touches no rule (§6.3).

### Migration, and the file on the phone

The ticket named the real risk: by the time the model changes, the data is weeks of actual training
and there is no seed script to re-run.

- `schemaVersion` is the first field. On load, an older version is **copied to
  `logbook-v<n>-backup.json` first**, then migrated through a chain of one function per step.
- **A file that cannot be decoded is never written over.** The app reports it and leaves it alone. A
  read failure must not be able to destroy a training history.
- The file lives in `Documents`, with `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace`.
  Rob then copies `logbook.json` off the phone through the Files app, with **no screen to build** —
  an export flow appears in none of the five flows. Both `Documents` and `Application Support` ride
  the iCloud device backup, so the charter's recovery story is untouched.
- Writes happen **after every mutation, atomically**: to a temporary file, then a rename. The file is
  small, and view state (the keypad buffer, the draft) stays out of it per ticket 20, so mutations
  are coarse — a logged Set, an edit, a Finish. Because `openWorkout` sits in the same document, a
  Workout in the gym survives a crash or a flat battery.

### The seam to SwiftUI

One `@Observable final class LogbookStore` in the app layer, holding `private(set) var logbook`. It
does four things: load, migrate, call `Rules.reduce`, and save. It owns the id counter and the clock.
Views read values and never write to disk.

That keeps ticket 20's boundary straight: `HoppaRules` still knows no `Date`, no `JSONEncoder` and no
SwiftUI. Everything that faces outward is in `LogbookStore`. This answers two of the questions on
[The view layer around the rules](0024-the-view-layer-around-the-rules.md) — *one store or one per
screen*, and *when does a reduce become a save* — and that ticket has been trimmed accordingly.

### This ticket decides; it does not build

The ticket text asked for a Swift file to paste in. **Refused, for ticket 20's reason, which has not
changed**: [Swift on the VPS](0022-swift-on-the-vps.md) is still open, so any Swift written here
compiles nowhere. There is a second reason as well — `Logbook`, `Weight`, `PerformedExercise` and
`LoggedSet` are the domain value types ticket 20 already gave to `HoppaRules`. Writing them here and
again there produces two versions of one model, which is the failure this map keeps refusing.

So:

- The types land in **[Lift the rules into HoppaRules](0023-lift-the-rules-into-hopparules.md)**,
  with the tests around them. `Codable`, the exact `Weight`, and the round-trip fixture have been
  added to that ticket.
- The app-side store gets **[The Logbook on disk](0025-the-logbook-on-disk.md)**: `LogbookStore`,
  atomic writes, the migration chain and the two Info.plist flags. Foundation work, Mac-only, blocked
  by 23.
- `SPEC.md` and `CONTEXT.md` were changed **in this session**, because documents are not code:
  §2.4 gained the progression outcome, §2.8 gathers what any store must guarantee, and the glossary
  gained **Logbook**, **Performed Exercise** and **Progression Outcome**.
