---
id: 43
title: The numbers a mis-tap cleared, and the unit that came back
parent: 17
labels: [wayfinder:task]
status: closed
assignee: agent
blocked-by: [41]
---

## Question

**On an edit sheet, closing is the save (§6.2). One wrong tap on the unit row wipes the Working
Weight, the Increment and the Stack Step, and there is no cancel to take it back.**

`ExerciseSheet.clearForUnitChange` empties the three fields the moment the unit on screen moves —
correctly, because the user must never type under a label that has changed (§6.6). Tapping the unit
row back does not put them back: the sheet has no memory of what it opened with, so the numbers are
gone. An edit sheet has no `✕` that discards, so the only way out is the save, and the save writes
the emptiness.

Build the sheet's own memory of the three numbers it opened with, and put them back when the unit
returns to the unit at open. **Both lives of the sheet**, edit and add — the edit life is where the
loss hurts, but an add sheet that eats a typed number is the same surprise.

Points to settle while building:

- **What counts as *the unit at open*** on an add sheet, whose Equipment Type starts unpicked and
  whose unit therefore moves once before the user has typed anything.
- **Whether a number typed *after* the flip survives a flip back.** Two numbers now compete for the
  same field: the one from before the flip and the one typed after it. The later one is the
  user's more recent intent, but it is labelled in the unit that is leaving.
- **Whether the `unitChanged` note still reads true** once the numbers can come back. It says the
  weights *are cleared*; after a restore that is no longer what happened.

This is sheet work, not a rule: nothing here is decided from the `Logbook`, and two lifters with
the same `Logbook` are not owed the same answer — it is the state of one visit to one sheet. It
does not touch `Rules.edited`.

Blocked by [A weight retyped after a unit change](0041-a-weight-retyped-after-a-unit-change.md),
which changes the same function: the draft now carries the unit its numbers are written in, and a
restore has to move that label back with them.

Consult `SPEC.md` §6.2 and §6.6, and `ExerciseSheet.swift` (`clearForUnitChange`, `close`,
`unitChanged`).

## Resolution

**The numbers are filed under the unit they were typed in, and they come back when that
unit does.** `UnitStash` — a plain value in the app target, importing no SwiftUI — holds
one `TypedWeights` per unit. A unit change hands it what is on the screen and draws what
it hands back. Tapping the unit row again is a full undo, and it costs one tap.

**A file per unit, not a memory of the unit at open.** That was the shape the ticket's
three questions all turned on, and it answers them together:

- **The unit at open needs no privileged status.** An add sheet moves its unit once before
  anything is typed, and under a per-unit stash that move carries an empty screen, so it
  files nothing and says nothing. Every later move is the same operation as the first.
- **A number typed after the flip survives a flip back** — under **its own** label, not the
  other one. Both numbers live, each filed where it was typed. Nothing is converted and
  nothing is merged, which is §5.1 holding inside the sheet as well as inside the rule.
- **The `unitChanged` note is gone**, because it said *cleared* and nothing is. `UnitStash`
  writes the note now, and it says where the numbers went and how to get them back. Both
  halves can be true at once — flip, retype, flip back — and the sentence carries both.

**One case the ticket did not name, found while building: the add sheet was already losing
a weight at the save.** `WorkoutDayScreen` opened an add draft with `shownUnit: rack.unit`,
but the sheet draws the **Program's default** until an Equipment Type is picked (§2.1, a
ticket 0035 decision). In a Program whose default is not the rack's unit, a weight typed
before the first pick was typed under one label and judged against another, and
`withoutStaleWeights` threw it away. The draft now opens on `program.defaultWeightUnit` —
**the unit the sheet actually draws at open**, which is the only thing `shownUnit` ever
meant. Two checks cover it: a Dumbbell picked in lbs keeps the number, a Barbell files it.

**Why the logic left the view.** Ticket 0029 says logic worth a test does not belong in a
view, and this is not a rule — it decides nothing from the `Logbook`, and two lifters with
the same `Logbook` are not owed the same answer, because it is the state of one visit to
one sheet. So it went to neither: a plain value in the **app target** that imports no
SwiftUI, which `swiftc` reaches here against the built `HoppaRules`. The sheet keeps none
of the reasoning — it hands over what is on the screen and draws what comes back.

**`hasContent` counts the stash.** An add sheet's `✕` asks before it throws away numbers
held under the other unit; without it the mis-tap this ticket closed just moves to a
different control.

**The stash dies with the sheet, and never reaches the save.** What the save writes is what
is on the screen. `Rules.edited` is untouched, and the 147 rules tests are unchanged.

### What was built

- `UnitStash.swift` (new): `TypedWeights`, `UnitStash.move(from:to:onScreen:)`, `forget()`,
  `hasNumbers` and `note(showing:)`.
- `ExerciseSheet.swift`: `clearForUnitChange` files and restores through it, `show(_:)` and
  `weight(_:)` put a restored set on the screen, the note reads off the stash, `hasContent`
  counts it, and `weightBox` now parses through the same `weight(_:)` a restore uses.
- `WorkoutDayScreen.swift`: an add draft opens on `program.defaultWeightUnit`.
- `SPEC.md` §6.6: a paragraph saying the numbers are held while the sheet is open, and that
  this is the sheet's memory of one visit and not a rule.
- `app/checks/UnitStash/` (new): **34 checks, all green on the VPS**, compiled against the
  real `UnitStash.swift` and saving through `Rules.reduce`. `./run.sh` runs them; a red
  check exits `1`, proved by breaking one.
