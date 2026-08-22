---
id: 37
title: The weight sheet
parent: 17
labels: [wayfinder:task]
status: open
assignee:
blocked-by: [36]
---

## Question

**Build the bottom sheet that changes the Working Weight, and the *Just today, or from now on?*
question under it (§6.4, §4.3).**

It closes batch 2: with it, Rob can start a Workout, log Sets and change a weight.

- **A numeric keypad plus `−` / `+` stepping by the Increment.** The keypad buffer lives in `@State`
  on the view ([The view layer around the rules](0024-the-view-layer-around-the-rules.md)).
- **Raising closes the sheet at once.** Lowering raises the *Just today, or from now on?* sheet,
  **exactly once, on the way down only** (§4.3).
- **On a Machine (stack) or Cable the sheet grows a second stepper**, because a stack moves in pin
  steps and not in Increments: `PIN` steps by the Stack Step, `MICRO` by the Microloading Increment,
  and the keypad stays under them. The big number stays the Working Weight. **A bar keeps the single
  `−`/`+`.**
- **A One-off Weight is marked twice**: a steel chip `ONE-OFF · 72.5 KG STAYS` beside the unit — it
  names the Working Weight that survives, not just the fact of the one-off — and a plain `ONE-OFF`
  chip on every Set row logged under it. The chip on the row belongs to ticket 36; the state that
  drives it starts here.
- **The unreachable weight** (§5.4): `≈ CLOSEST`, what you actually load, and how far under or over.
  A tie rounds **down**. §8.2's ninth defect is that the prototype rounds the pin **up**, drawing a
  weight the user is not lifting — do not port it.
- **A weight is `Int` hundredths carrying its own unit**, never a `Double`
  ([Persistence and the data model](0019-persistence-and-the-data-model.md)). The keypad must not
  introduce a `Double` on its way in.
- The active One-off Weight **is stored** and survives a relaunch — ticket 19 found it had no field
  at all. This sheet is what writes it.

Done, hand-off and testing follow ticket 29's rules. **This ticket triggers hand-off batch 2.**

Consult `SPEC.md` §4.3, §5.3, §5.4, §6.4 and §8.2, and
`design/0007-logging/fitty-workout-logging.html`.
