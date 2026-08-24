---
id: 41
title: A weight retyped after a unit change, on the sheet that cleared it
parent: 17
labels: [wayfinder:grilling]
status: open
assignee:
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
