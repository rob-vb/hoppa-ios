---
id: 46
title: The Re-weigh list, and the two warnings that count before they fire
parent: 17
labels: [wayfinder:task]
status: open
assignee:
blocked-by: []
---

## Question

**§6.6's two rack switches each warn with a count, and one of them lands on a screen that does not
exist.**

- **Changing the Plate Inventory's unit** clears the Working Weight, Increment and Base Weight of
  every Barbell, Smith, plate-loaded and Bodyweight Exercise in **every** Program, resets every
  Microloading Increment, and creates or destroys a Microload on every Machine (stack) and Cable.
  It warns first — `THIS CLEARS THE WEIGHT ON 12 EXERCISES` — and the confirm leads to
  **one Re-weigh list**: every affected Exercise on one screen, each with an empty weight field.
- **Switching a Microplate off** warns with `3 EXERCISES USE THIS PLATE`, and the stranded
  Exercises fall into the empty state §6.2 already draws.

**The Re-weigh list is not a list anyone writes down.** *"The Re-weigh list is every Exercise with
no Working Weight, which is what the switch has just made them. Leave the screen, close the app,
come back a day later, and the same Exercises still have no weight — so the same list appears,
without anything having to remember it."* Ticket 26 made that possible by turning
`Exercise.workingWeight` into a `Weight?`, and it named this as the first thing that falls out.

**Both counts are rules by the map's own test** — they are decided by the `Logbook` alone and two
lifters with the same `Logbook` must read the same number — and **the count is the same rule as the
list**, asked before the switch instead of after. So one rule answers both, and it needs tests.

`Action.setPlateInventoryUnit` and `Action.setPlate` are built and green; nothing here is a new
write. What is open:

- The rule that answers *which Exercises*, in `HoppaRules`, with the count falling out of it.
- The Re-weigh list screen, and **how a weight is typed on it** — the weight sheet of §6.4 is built
  for a Workout, and this is the kitchen table.
- **Where it appears from**: after the confirm, and again on its own the next time the user opens
  the app with weights still missing. §6.6 says the list simply *is*; the door to it is not
  specified, and it must be, or a user who leaves the screen never finds it again.

Consult `SPEC.md` §6.6, §5.1, §5.2, §2.8, `Rules+Edit.swift`, `PlateRackScreen.swift`,
[Program edits, and which of them are rules](0026-program-edits-and-the-rules-boundary.md).
