---
id: 26
title: Program edits, and which of them are rules
parent: 17
labels: [wayfinder:grilling]
status: closed
assignee: agent
blocked-by:
---

## Question

**§6.6 is full of rules, and none of them has a home.**

[Lift the rules into HoppaRules](0023-lift-the-rules-into-hopparules.md) built the logging flow's
rules and stopped at the edge of Flow 5. It landed exactly one Program edit — `.setWorkingWeight`,
because §4.3 puts it inside the Workout and three walkthroughs need it. Everything else §6.6
specifies is still nowhere:

- **Raising the planned Sets returns a Completed Exercise to Open** (§3.2). A rule about an Open
  Workout, triggered by an edit to the Program.
- **Changing a Weight Unit clears the weights** on that Exercise (§6.6).
- **Changing the Plate Inventory's unit** clears the weight on **every** plate-loaded Exercise there
  is, and produces the **Re-weigh list** (§6.6).
- **Switching a Microplate off strands** every Exercise using it as its Microloading Increment, and
  says so (§6.6).
- **Deleting** an Exercise or a Workout Day, with two blocks — and history must survive it (§2.8).
- **A Microload is destroyed and recreated at zero** when a unit changes, while a Base Weight and a
  Stack Step survive a change of Equipment Type (§2.8).

Each one is already specified. What is **not** decided is where they live, and that is a boundary
question this map has been careful about twice already:

- [The rules module and its oracle](0020-the-rules-module-and-its-oracle.md) put the rules in one
  place so they cannot be implemented twice.
- [The Logbook on disk](0025-the-logbook-on-disk.md) forbids `LogbookStore` from deciding anything:
  *the moment it decides something, rules live in two places*.

So a §6.6 edit cannot be a plain struct mutation in a view or a store without breaking one of those.
The likely answer is that these become `Action` cases on `HoppaRules` beside the logging ones — but
that makes `reduce` the entry point for editing a Program as well as performing one, and it deserves
to be said out loud rather than assumed.

Settle:

- Which §6.6 edits are **rules** (an `Action` on `HoppaRules`) and which are plain field writes.
- What each does to an **Open Workout** in progress, since §6.6 explicitly allows editing at the rack.
- What the Re-weigh list and the stranded-Increment list **are** as values, so a screen can render
  them without re-deriving the rule.

Do not decide the screens — [The view layer around the rules](0024-the-view-layer-around-the-rules.md)
owns those, and this ticket owns what sits under them. Consult `SPEC.md` §2.8, §3.2 and §6.6,
`CONTEXT.md`, and ticket 23's resolution.


---

## Resolution

**Every §6.6 edit is an `Action` on `HoppaRules`, and nothing writes into a `Logbook` anywhere else.**
There is one door — `LogbookStore.send(Action)` — and it stays one door. `Action`'s own doc line was
wrong from the start: it says *"Everything a Workout can be told to do"*, and it becomes *everything
Hoppa can be told to do*.

Four shapes were on the table and three are refused. Plain `mutating` methods on `Logbook`, called
from a view, put the reopen rule in SwiftUI — where no test can reach it. A nested
`Action.workout(...)` / `Action.edit(...)` says the same thing as a flat enum and renames every call
in 46 green tests to say it. And a stored "editing target" on the `Logbook` is view state wearing a
domain coat: §6.6 opens the same sheet from the kitchen table and from the rack, so the target rides
on the action. **Every edit names its id.** The split lives in the file layout, `Rules+Edit.swift`
beside `Rules.swift`, not in the type.

### The sheet saves once, so the edit is one action

§6.2 is Model B — one full sheet, saved in one act — and the actions follow it:

```
case addExercise(workoutDayId: WorkoutDayID, at: Int, draft: ExerciseDraft)
case saveExercise(ExerciseID, draft: ExerciseDraft)
```

**The rules of §6.6 are a diff, not a set of field writes.** Raising the planned Sets reopens;
changing the Weight Unit clears three fields and destroys a Microload. Split those into ten
per-field actions and the order they arrive in decides the answer — a sheet that changes the unit
*and* types the new weight would clear the weight it was just given. One draft applies once, and the
old value is still in hand to diff against, which is what makes the next two rules free.

The rest, all naming their target:

| Action | Notes |
| --- | --- |
| `createProgram`, `renameProgram`, `setProgramDefaultWeightUnit` | Touch nothing that exists (§2.1, §2.7). |
| `setProgramMode(ProgramID, ProgressionMode)` | Changes the default only; an override is deliberate (§4.4). Fills the Microloading Increment on Exercises that move and have none. |
| `addWorkoutDay`, `renameWorkoutDay`, `moveWorkoutDay` | Reordering Days is cosmetic (§3.1). |
| `deleteWorkoutDay(WorkoutDayID)` | Blocked twice — see below. |
| `moveExercise(ExerciseID, to: Int)`, `deleteExercise(ExerciseID)` | Both reach into the Open Workout — see below. |
| `setPlateInventoryUnit(WeightUnit)` | The full blast radius of §6.6. |
| `setPlate(Weight, on: Bool)` | Writes nothing else. Stranding is derived. |

**Deleting a whole Program is not here.** The map left it in the fog deliberately, and this ticket
does not take it: §6.6 never specified it, so it is a gap in the spec and not a rule with nowhere to
live.

### An unset weight is not zero — the one model change

§6.6 *clears* the Working Weight, and `workingWeight` is a non-optional `Weight`, so "cleared" could
only have meant zero. **Zero is a real weight**: a Bodyweight Exercise done with no belt. A Re-weigh
list built on `== 0` would have called every beltless pull-up Exercise in the Logbook cleared.

So `Exercise.workingWeight` and `Exercise.increment` become `Weight?`, and `nil` means *the user has
not typed one*. Three things fall out of it, and each was a rule with no home before:

- **The Re-weigh list is `nil`**, not a list anyone writes down. Leave the screen, close the app,
  come back a day later — the same Exercises still have no weight, so the same list appears.
- **A new Exercise before the user types is the same state** as one §6.6 has just cleared. Flow 1
  needed that anyway and would have invented a second spelling for it.
- **No weight, no progression, and no Set.** `logSet` reads the Working Weight; with none, it
  refuses, which is exactly the condition the Re-weigh list exists to clear.

**It needs no migration step, and no `schemaVersion` bump.** Ticket 25 found that Swift's synthesised
`Codable` decodes an `Optional` with `decodeIfPresent` and everything else with plain `decode`. Read
forwards, that says **widening a field to `Optional` is the safe direction**: an old file that
carries the value still decodes, and one that does not is now legal. It is *narrowing* that breaks.
A test that loads a committed v1 file proves it, and the migration engine ticket 25 built stays
unused for one more ticket.

### The two reopen rules, and the trap under the second

§3.2 says a Completed Exercise reopens when the planned Sets rise above the Sets logged. Read
literally that reopens a **Done early** Exercise too — 2 logged of 3, raise to 4, and the Exercise
the user deliberately ended comes back. §3.2's own reason refuses it: *"otherwise the edit would take
away a progression the user earned"*, and Done early never earns one. So **a raise reopens what
Hoppa completed by itself** and leaves Done early alone. No field is needed to tell them apart — the
diff still holds the **old** planned Sets, and auto-complete means `sets.count >= oldPlannedSets`.

The mirror was missing entirely, and it is a trap: **lowering** the planned Sets to the number
already logged left an Open Exercise stuck. `logSet` refuses (the plan is full), nothing fires to
complete it, and it holds the Finish gate until the user finds *Done early* — at the rack, mid-set.
Lowering now completes it. Both landed in `SPEC.md` §3.2.

### What an edit does to the Open Workout

A `Workout` keeps its own list of Performed Exercises, and it has to: a deleted Exercise keeps its
Sets while the Workout Day no longer holds it (§6.6). So the list cannot be derived from the Day,
and **every structural edit mirrors into the Open Workout** — but only into a Workout running on
that Day.

- **Added** arrives Open, at its place in the Day and not at the end.
- **Reordered** moves in the Workout too, and **`currentIndex` follows the Exercise**, not the
  position. Otherwise a drag changes the card under the user's thumb while he stands at the rack,
  and §6.4 says Hoppa never jumps by itself.
- **Deleted** stays in the Workout with its Sets, and **stops holding the Finish gate**: with Sets
  logged it ends Completed, with none it ends Skipped. Leaving it Open gates Finish on an Exercise
  the user can no longer reach. Removing it destroys Sets the user lifted, which §6.6 forbids in as
  many words. Because the list never shrinks, `currentIndex` needs no repair here.

### Stranding was never implemented, and it is derived

`microloadingIncrement` stores a raw `Weight`, not a reference to a plate. Switch that Microplate
off and `progressionMove` **still adds it** — the weight climbs by steel the user does not own, and
§6.6 says plainly that such an Exercise must not progress. This was live in the 46 green tests and
nothing caught it, because nothing had switched a plate off yet.

A **stranded** Exercise is one whose Microloading Increment is not in `enabledMicroplates`. It is
`ResolvedExercise.isStranded`, and `progressionMove` returns `nil` for it — the same `nil` that
already covers a Dumbbell in the wrong unit and an Exercise with no Microplate on at all, so the
Summary's "did not progress" line needs no new case. **Nothing is written and nothing is cleared**:
switch the plate back on and the Exercise progresses again, with the plate the user picked. §6.6
already refuses to re-point it at another one; clearing the field would be re-pointing at nothing.

### Four pure queries, because a warning must ask before the act

§6.6 wants three counts and two blocks *before* the user commits — `THIS CLEARS THE WEIGHT ON 12
EXERCISES`, `3 EXERCISES USE THIS PLATE`, `FINISH YOUR WORKOUT FIRST`. `reduce` returns the state
unchanged when it refuses, which is silent, and a screen cannot draw a reason it never receives.

```
Rules.reweighList(in: Logbook) -> [ExerciseID]
Rules.exercisesClearedByInventoryUnit(_ unit: WeightUnit, in: Logbook) -> [ExerciseID]
Rules.exercisesUsingMicroplate(_ plate: Weight, in: Logbook) -> [ExerciseID]
Rules.deleteBlock(forWorkoutDay: WorkoutDayID, in: Logbook) -> DeleteBlock?   // .openWorkoutRunsOnIt | .lastDayInProgram
```

Each is the same rule its action enforces, asked as a question instead of as a change — so the
button can be refused with its reason where the user taps it, and the action still refuses if
anything gets past. A confirm that quietly does nothing is not a block; it is a bug the user has to
diagnose. Storing a pending list or an error string on the `Logbook` was refused for the same reason
`LogbookStore` decides nothing: it writes a screen message into the file that holds the training.

### The default Microloading Increment is the smallest plate switched on

§4.4 says Exercises moving to Microloading get *"the default Microloading Increment"* and never says
which one. It is the **smallest Microplate switched on**, and there is none when the rack has none
on — which §5.2 makes the common case, so the Exercise falls into the empty state §5.2 already
draws. The smallest is right because the smallest jump the rack can make is the point of
Microloading; the largest is Progressive Overload with extra steps. `SPEC.md` §4.4 gained it.

### What this ticket did not build

It decides; it writes no Swift. `Weight?` reaches `ResolvedExercise`, the solver, progression and
the 46 tests, and the mirroring into the Open Workout wants its own red tests. That is a session,
not a coda, and it graduates as
[Build the Program edits](0028-build-the-program-edits.md).

### Written down

`SPEC.md`: §2.3 (both weight fields may be unset), §2.8 (a new bullet — *an unset weight is not
zero*), §3.2 (the Done-early exception and the lowering mirror), §4.4 (which default Microloading
Increment), §6.6 (the user does not move on a reorder, an added Exercise arrives in place, a deleted
one stops gating Finish, cleared means unset, the Microload is really destroyed, the Re-weigh list
and stranding are derived, a block is stated before the confirm).
`CONTEXT.md`: **Working Weight** gained *unset*, **Microloading Increment** gained its default, and
two terms are new — **Stranded Exercise** and **Re-weigh list**.
