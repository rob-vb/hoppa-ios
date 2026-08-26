---
id: 43
title: The numbers a mis-tap cleared, and the unit that came back
parent: 17
labels: [wayfinder:task]
status: open
assignee:
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
