---
id: 37
title: The weight sheet
parent: 17
labels: [wayfinder:task]
status: closed
assignee: agent
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

## Resolution

**Built, type-checked here, pushed. `WeightSheet.swift` is the sheet; §4.3's decision under it
turned out to be a rule, and it is `Rules.weightEdit` now.**

### What the sheet is

A header with `CANCEL`, the number being typed at 56 px with its unit beside it, the stepper, §5.4's
`≈ CLOSEST` line, the 3 × 4 keypad, and `SET THE WEIGHT` at §7.4's 64 pt. The keypad buffer is a
`String` in `@State` and becomes a `Weight` exactly once, through `Weight(decimalString:unit:)` —
**no `Double` appears anywhere on the way in**. A third decimal keystroke never reaches the buffer:
a `Weight` is hundredths, so refusing the key beats accepting it and refusing the save.

- **Raising closes at once; lowering raises *Just today, or from now on?*** — `LoggingSheet` gained
  `.lower(Weight)`, and the weight sheet is **gone** by the time the question is asked. `.sheet(item:)`
  swaps one for the other, which is the pattern ticket 0036 already proved for the menu and the
  Finish gate; a sheet stacked on a sheet would let the user step the number behind the question.
- **A One-off Weight is marked twice**, and both marks were already ticket 0036's. What this ticket
  added is the state that drives them: `.setOneOffWeight` from *Just today*, `.setWorkingWeight`
  from *From now on* and from every raise. Ticket 0019 gave `PerformedExercise.oneOffWeight` its
  field, so it survives a relaunch with the rest of the Open Workout.
- **The `≈ CLOSEST` line is live**, against the number being typed rather than the one stored.
  `ClosestLine` came out of `PlateBreakdownView` for it — **one copy of §5.4, two callers**.

### The step is what the rule moves, not what the field holds

§6.4 says the `−` / `+` step by *the Increment*. A bar under Microloading has no Increment field at
all — it has a Microplate, and a bar takes a **pair**, so it moves by twice the plate (§4.2).
Stepping by the plate would walk the user onto weights the bar cannot build.

So the step is `Rules.progressionMove` **probed at zero** — the same trick §6.2's Increment clause
uses. It costs nothing, it cannot drift from §4.2, and it makes the stepper and the rule chip above
it print the same number, which they must. Where the Exercise has nowhere to move — no Increment, no
Microplate on, or a stranded one — there is no stepper and the keypad stands alone.

**A stack grows the second stepper** (§6.4): `PIN` by the Stack Step, `MICRO` by the Microplate.
On a **mixed-unit pin** the `MICRO` row is absent, and that is a gap and not a choice —
[The MICRO stepper on a mixed-unit pin](0042-the-micro-stepper-on-a-mixed-unit-pin.md) owns it.

### §4.3's decision was in a view, and the view had it wrong

**Found while building, and it is the tenth row of §8.2.** The prototype decides *raise or lower*
against the **performed** weight. That is the same number as the Working Weight right up until a
One-off Weight stands — and then it is not:

> A One-off of 65 kg on a 72.5 kg Exercise. Type 70. Against the big number that is a **raise**, so
> it sticks with no question — and sticking means `.setWorkingWeight`, which clears the One-off and
> writes 70. **The record has gone 72.5 → 70 with nothing asked**, which is the exact case §4.3
> exists to prevent: *without the prompt, dropping 100 → 90 because of illness erases the record
> of 100*.

The question guards the **Working Weight**. And by the map's own `is-this-a-rule` test it *is* a
rule: it falls out of the `Logbook` alone, and two lifters with the same `Logbook` typing the same
number must be asked the same question. So it is `Rules.weightEdit(_:performed:exercise:)` →
`.unchanged` / `.sticks` / `.asks`, and `LoggingScreen` switches on it rather than deciding.

It needed no `Foundation`: `WeightEdit.swift` imports nothing, like the rest of `HoppaRules`.

### Proven here

- **`HoppaRules` 128 green** (was 119), **`HoppaStore` 31 green**. Nine new, in
  `WeightEditTests.swift` — the three plain answers, the One-off case above from all three sides,
  the first weight an Exercise ever gets, zero, what each answer writes, and the bar-under-
  Microloading step.
- **Every rules and store call the two views make was type-checked on the VPS** against the built
  modules — `swiftc -typecheck -swift-version 6 -I …/Modules`, ticket 0025's trick. The SwiftUI
  itself is the Mac's; nothing else in these files is.
- **The Xcode project needed no edit.** `app/Hoppa/Hoppa` is a file-system synchronised group, so a
  new file in the app target is not in `project.pbxproj` to begin with — and the two new package
  files are SPM globs. The third clean instance of the map's open `project.pbxproj` question.

### Three smaller things

- `performedWeight` now **relabels**. The Weight Unit is derived (§2.8), so a One-off stored before
  a unit change carries a stale label — and every comparison and subtraction around it *traps* on a
  mismatch rather than converting. A latent trap, not a behaviour change.
- **§8.2 gained rows eleven and twelve** as well: the prototype steps by the Stack Step under
  Microloading whatever the Equipment Type, and its keypad buffer and `NUDGE` sit inside
  `Fitty.reduce` beside the real rules. The twelfth is what let the tenth survive.
- `Cancel` on the *Just today* question closes the whole flow rather than returning to the keypad,
  as the prototype does.

### This closes hand-off batch 2

Rob can now start a Workout, log Sets and change a weight. The hand-off covers
[The logging screen](0036-the-logging-screen.md) and this ticket.
