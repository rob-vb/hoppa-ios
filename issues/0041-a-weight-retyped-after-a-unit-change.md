---
id: 41
title: A weight retyped after a unit change, on the sheet that cleared it
parent: 17
labels: [wayfinder:grilling]
status: closed
assignee: agent
blocked-by: []
---

## Question

**§6.6 says the sheet asks for the cleared weights again, in the new unit. It cannot, because the
rule clears them at the save.**

`SPEC.md` §6.6: *"changing the Weight Unit clears the Working Weight, the Increment and the Stack
Step, and **the same sheet asks for them again in the new unit**."* Model B saves once (§6.2), so
that retyped number arrives in the **same** `ExerciseDraft` as the unit change — and
`Rules.edited` nils all three whenever the unit the Exercise *resolves to* has moved, without
looking at what the draft carries.

Proved on the VPS while building [The Exercise sheet](0035-the-exercise-sheet.md), on both paths
into the rule:

- a Dumbbell in lbs, flipped to kg and retyped as `45 kg` in one save → `workingWeight: nil`;
- a Dumbbell in lbs turned into a **Barbell** over a kg rack and typed as `60` in one save →
  `nil`. §6.6 calls the change of Equipment Type the same event, and it is.

The sheet does **not** work around it: it empties the three fields the moment the unit on screen
moves, so the user is never typing under a label that has changed, and it sends one action.

**What is open is where the fix goes and what it may read.** `ExerciseDraft` carries `Weight`, and
a `Weight` carries its unit, so *the draft's number is labelled in the new unit* is a signal the
rule could read — but a stored label can be stale by design (§2.8 makes the unit derived), so
whether that signal is trustworthy is exactly the question. Alternatives to weigh: the draft
carrying the unit it was shown in; the rule taking the old and new units as arguments; or the
sheet's own clear being the only clear, with the rule dropping the field writes.

**Consequences to state either way**: the Re-weigh list is `workingWeight == nil` (§6.6), the
Microload is created or destroyed on the same edge (§2.8), and 119 rules tests currently pass
with the clearing as it stands — including several that assert the fields come back empty.

Consult `SPEC.md` §6.2 and §6.6, `Rules+Edit.swift` (`edited(_:with:inventory:)`),
[Program edits, and which of them are rules](0026-program-edits-and-the-rules-boundary.md) and
[Build the Program edits](0028-build-the-program-edits.md), which is where the clearing was built.


## Resolution

**The draft carries the unit its numbers are written in, and the clearing rule reads that instead
of asking whether the unit moved.** `ExerciseDraft` gains `shownUnit: WeightUnit`, and
`Rules.edited` clears a field when `shownUnit` is not the unit the Exercise now resolves to. §6.6's
promise — *the same sheet asks for them again in the new unit* — holds from here.

**Why not the number's own label.** `Weight` carries a unit, so the label was the cheapest signal
available. It is the wrong one: `Weight.relabelled` exists precisely because a stored label may be
stale where the unit is derived (§2.8), `resolve()` relabels defensively everywhere, and
`ExerciseDraft(_:in:)` opens a sheet by copying stored labels. Reading the label would turn a
documented *may be stale* into a load-bearing invariant, and a sheet opened on an Exercise with a
stale label would clear a weight nobody touched.

**Why not the sheet alone.** Dropping the field writes from the rule and trusting the sheet moves
§6.6 out of `HoppaRules` and into a view. It is a rule by the map's own test: it decides an outcome
from the `Logbook`, and two lifters with the same `Logbook` must see the same answer. What is *not*
in the `Logbook` is which unit the user was looking at — and that is why it belongs in the draft,
which is the sheet as the user left it, not in the rule's arguments.

**Two triggers, where there was one.** The single `if newUnit != oldUnit` did two jobs, and they
came apart here:

- the three typed fields (Working Weight, Increment, Stack Step) go when **the draft was typed in
  another unit**;
- the **Microload** goes when **the Exercise's unit moves**, retyped or not. It is not a number the
  sheet asks for; it is a state that belongs to a unit, and that unit has left. Retyping the weight
  does not save it.

**Exactly the three fields §6.6 names.** The Microloading Increment keeps the Plate Inventory's
unit whatever the Exercise does (§5.1), so it is never stale here. The Base Weight is in the rack's
unit too, and that unit moves only when the rack moves — `setPlateInventoryUnit`, which does its
own clearing. All four type changes were walked: no edit to an Exercise can leave a Base Weight
labelled wrong. One clause had to be kept by hand: a Stack Step on an Exercise that loses its pin
*and* changes unit has no row to be retyped in, so it is still dropped there.

**The add path is guarded by the same call.** `draft.exercise(id:inventory:)` runs
`withoutStaleWeights(resolvingTo:)` too. An add sheet can type a weight and then pick another
Equipment Type, and a rule that defended only the edit path leaves the other half of the same sheet
open.

**`shownUnit` has no default, on purpose.** Five places build a draft. A default would make *in
which unit are these numbers* the one thing a caller can forget, which is the bug itself;
`ownWeightUnit` cannot stand in for it, because the four types loaded off the rack ignore that
field. `ExerciseDraft(_ exercise:, in inventory:)` takes the `PlateInventory` because the resolved
unit cannot be derived without one.

**In the sheet, the label moves before the guard.** `clearForUnitChange` writes `draft.shownUnit`
first and unconditionally. Under the early-return it would miss the case that matters most on an
add sheet: pick a Cable in lbs while every field is still empty, type the first number, and the
save would clear it.

### What was built

- `Rules+Edit.swift`: `ExerciseDraft.shownUnit`, `ExerciseDraft(_:in:)`,
  `ExerciseDraft.weightUnit(in:)`, `withoutStaleWeights(resolvingTo:)`, the split triggers in
  `edited`, and the shared guard on `exercise(id:inventory:)`.
- `ExerciseSheet.swift`: `clearForUnitChange` moves `shownUnit` with the unit on screen.
- `WorkoutDayScreen.swift`: both drafts state the unit they open in.
- `SPEC.md` §6.6: the *cannot yet* note is replaced by the rule that makes the promise true.
- **147 rules tests pass** (143 before), including four new ones: a retyped weight survives; a
  retyped Stack Step survives while the Microload dies anyway; a number typed before the flip is
  still cleared; and the add path refuses a weight in the wrong unit. Every existing clearing test
  passes **unchanged** — a draft that flips the unit and leaves the numbers alone is exactly *the
  user did not retype*.
- The two app-target call sites were lifted into a throwaway file and type-checked here against the
  built `HoppaRules`. The SwiftUI itself still needs the Mac.

### What this opened

[The numbers a mis-tap cleared, and the unit that came back](0043-the-numbers-a-mistap-cleared.md).
On an edit sheet closing **is** the save, so one wrong tap on the unit row destroys three numbers
with no way back. That is sheet work, not a rule, and it is blocked by this ticket because it
changes the same function.
