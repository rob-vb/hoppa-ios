---
id: 33
title: The Program name, the three assumptions, and the Plate Inventory screen
parent: 17
labels: [wayfinder:task]
status: closed
assignee: agent
blocked-by: [32]
---

## Question

**Build onboarding steps 1 and 2 (§6.1): naming a Program, and confirming the rack.**

Build:

- **Step 1 — name the Program.** A name field, and under it **one card showing the three decisions
  Hoppa makes at Program level**: Weight Unit `KG`, Progression Mode `Progressive Overload`, Plate
  Rack `standard kg`. They are **pre-answered and visible**, each one tap from being changed.
  Nothing else is asked at Program level. Smart defaulting was allowed here and **only** here —
  one unit, one Mode, one rack, decided once and never asked again per Exercise.
- **Step 2 — the Plate Inventory** (§5.2), with the standard defaults already correct, so a matching
  rack costs **one confirm**. It is a toggle list for any gym, not a picture of one rack: the 25 kg
  ships in the list but switched off, and there is **no 15 kg plate**. The Microplate group is a
  real destination — §6.2's `NO MICROPLATES · SET UP YOUR RACK` row taps straight into it.
- The tap budget this is measured against: **16 taps for step 1, 3 for step 2** (§6.2's table).

Two things this screen must get right because later screens read them:

- A **Microplate switched off still moves the weight today** unless `isStranded` is honoured — see
  [Program edits, and which of them are rules](0026-program-edits-and-the-rules-boundary.md) and
  [Build the Program edits](0028-build-the-program-edits.md). The rule is built; this screen is
  where the user switches the plate off, so it is where the warning has to appear.
- The **Weight Unit of a plate-loaded Exercise is derived** from the Plate Inventory, never stored
  twice ([Persistence and the data model](0019-persistence-and-the-data-model.md)). Changing the
  rack's unit therefore changes what those Exercises resolve to.

Done, hand-off and testing follow ticket 29's rules. Batch 1 goes over after ticket 35.

Consult `SPEC.md` §5.2, §6.1, §7.3 and §7.4, and `design/0006-onboarding/`.

## Resolution

**Steps 1 and 2 are built and pushed.** `NameYourProgram` names the Program and shows the three
assumptions; `PlateRackScreen` is §5.2's Inventory, and it is **§6.1 step 2 when a draft arrives
with it and the rack on its own when it does not** — one screen, because Hoppa holds one Plate
Inventory and it belongs to no Program. `swift test` is green here: **118 in `HoppaRules`** (up
from 112) and **31 in `HoppaStore`** (unchanged). `project.pbxproj` needed no edit — the app target
is a `PBXFileSystemSynchronizedRootGroup`, so Xcode picks the two new files up by itself. Per
ticket 29 this closes because it is **pushed, not because Rob has seen it**; batch 1 goes over
after ticket 35.

Four findings outrank the code.

**1. The footer is a rule, and the map's own test says so at the first clause.** `Smallest jump on
the bar: 2.5 kg` falls out of the Plate Inventory alone, and two lifters holding the same rack must
read the same number — so it is not view arithmetic. It is
`PlateInventory.smallestJumpOnTheBar(for:)` in `HoppaRules`, six tests, re-broken three ways (one
plate instead of a pair, the biggest plate instead of the smallest, zero instead of `nil`) and all
three turn the suite red. **The jump is twice the plate** because a bar has two sides —
`EquipmentType.barbell.platesPerProgression`, not a literal 2, so the fact is stated once.

**2. §5.2 had no answer for a rack with nothing switched on, and the screen can reach it.** Every
plate is a toggle, so a user can switch them all off. `smallestJumpOnTheBar` returns `nil` there and
the footer reads `No plate is switched on.` — with only Microplates on, the first half reads
`nothing`. **Printing `0 kg` would claim the bar moves in steps of nothing**, which is a different
claim from *it does not move*. §5.2 now carries both lines.

**3. The Program is created at step 2's confirm, not at step 1's `CONTINUE`.** The ticket did not
say when, and the two answers are not equivalent. Creating it at step 1 strands a Program with
**no Workout Days** the moment the user backs out of step 2 — and `WorkoutDayPicker` renders
`programs.first`, so `CREATE A PROGRAM` is gone and there is no way back in until ticket 34 lands.
One `.createProgram` at the confirm, carrying the name, unit and Mode as one value. The rack goes
the other way and writes through at once, because it is Logbook-level. §6.1 carries this.

**4. §7.1's size law does not bind this screen, and that is what makes the list drawable.** Rule 1
says colour plus size means weight and §7.3 puts a microplate at *roughly a quarter of the smallest
normal plate* — which in a toggle row is under 3 pt of colour, a chip that tells the reader nothing.
§7.1 states its own boundary: *"Both rules are rules about the Plate Breakdown"*, and a toggle list
is not one. So the chips are scaled **by rank inside their own group** — 26→11 pt for the normal
plates, 10→7 pt for the Microplates, which is what the artboard draws. By rank and not by weight, so
it holds for an lbs rack and for a rack the user has taken plates out of.

### What was built

- **`NameYourProgram.swift`** — `STEP 1 OF 3`, the two-line `NAME YOUR PROGRAM`, an Anton name
  field with the artboard's green caret, and the card of three. **One tap flips a row**: §5.2 calls
  the Mode row *"one tap away"* in those words, and a picker for two values is ceremony. Choosing
  Microloading with no Microplate on opens the Microplate group **as a sheet, in place** — which on
  a fresh install is every time, because every Microplate ships off. It also holds `ProgramDraft`,
  and `StepHeader` and `PrimaryButton`, which both steps and the picker share.
- **`PlateRackScreen.swift`** — the `KG | LBS` toggle, the two groups, the footer, and both of
  §6.6's warnings, because **this is where the switch is**: `3 EXERCISES USE THIS PLATE` before a
  Microplate goes off, `THIS CLEARS THE WEIGHT ON 12 EXERCISES` before the unit changes. Both counts
  come from the rules (`exercisesUsingMicroplate`, `exercisesClearedByInventoryUnit`) and both
  dialogs are skipped when the count is zero, which at onboarding it always is. The strand dialog is
  **not** `.destructive`: §6.6 writes nothing and clears nothing, and switching the plate back on
  un-strands exactly what switching it off stranded. The unit dialog **is**. It also holds
  `MicroplateSheet`, `RackFooter`, `PlateChip` and `RackSwitch` — the switch is drawn rather than a
  `Toggle`, because a `Toggle` bound to the store has already switched by the time anyone could ask
  a question.
- **`Route.plateRack(ProgramDraft?)`**, and `HoppaApp` lands both screens. Two of the four
  `NotBuiltYet` doors are now rooms.
- **`Typography.input` and `Typography.listValue`** — Anton without the uppercase transform, for a
  field that must show the characters that were typed, and Plex at the artboards' 500 for a number
  that **is** a row. **`Color.chipBorder`** names §7.2's second Steel value; it is not a new role
  and not a new hue, it is the value the Steel row already carries.

### Three decisions the ticket left open

- **A Program must be named, and Hoppa says so where the user taps.** `CONTINUE` on an empty field
  is live and answers `Give it a name first.` under the field. Disabling the button was rejected on
  §5.2's own principle — *the user always learns the reason where they stand* — which the spec
  states about the Mode but argues generally.
- **The Weight unit row follows the rack until a hand touches it.** A lifter who switches the rack
  to lbs at step 2 is standing in an lbs gym, and §2.1's default is for the new Exercises they are
  about to add. §6.1 allowed smart defaulting at Program level and this is it. One deliberate tap
  ends the following, and `ProgramDraft` carries that one bit.
- **Both steps draw their own back chevron and hide the navigation bar.** §7.4 leaves the safe top
  inset empty and a navigation bar draws in it; both onboarding artboards draw the way back in
  content. Step 1's artboard draws no back control at all — it gets one anyway, because otherwise
  leaving the screen depends on the swipe-back gesture surviving a hidden bar, which is not
  something this side can test.

### What the Mac has to answer

- **`Font.leading(.tight)` on two lines of Anton.** Ticket 32 flagged it and named this ticket:
  `NAME YOUR PROGRAM` is the first multi-line display text in the app. §7.4 wants 0.78–0.94 and
  SwiftUI cannot state a line-height below 1.0 as a number.
- **Whether step 1 fits with the keyboard up.** The card of three and the caption sit in a
  `ScrollView` with `CONTINUE` pinned, so it should compress rather than clip, but nothing here
  can measure it.
- **`monospacedDigit()` on IBM Plex Sans**, still open from ticket 32 — the plate list is the first
  column of figures in the app, which is where a missing `tnum` would show.
- **The lbs rack draws ten steel chips.** `PlatePalette.hex(for:)` paints kg only (§7.3 is one
  gym's iron rack), so an lbs rack falls back to steel and the colour half of §7.1's first rule is
  gone there; only the height ramp survives. Rob's rack is kg, so this costs nothing today. It is
  named so it is not read as a defect.

### What was proved here

The SwiftUI is Mac-only; nothing else about this ticket is.

- `HoppaRules` **118 green**, `HoppaStore` **31 green**.
- **Every rules and store call the two screens make was lifted into a throwaway and compiled and
  run** against the built modules — the pattern from
  [The Logbook on disk](0025-the-logbook-on-disk.md). It printed step 1 on a fresh install
  (`kg` · `Progressive overload` · `Standard kg`, and the sheet opening because no Microplate is
  on), step 2's whole list with every §7.3 hex and every chip height, the footer gaining its second
  clause when the 0.5 kg goes on, the rack row turning from `Standard kg` to `Custom kg`, the
  `.createProgram` landing `Upper / Lower · kg · microloading · 0 days`, both warning counts on a
  Logbook with three Exercises (`3 EXERCISES USE THIS PLATE`, `THIS CLEARS THE WEIGHT ON 2
  EXERCISES` — two, because only the barbells read their unit off the rack), the emptied rack, and
  the lbs rack.
- **One thing the run surfaced that nobody had looked at**: in the shipped **lbs** rack, `2.5 lbs`
  sits in *both* groups — `PlateInventory` documents it and `plates(for:)` already de-duplicates it
  for the solver. `setPlate` switches a size *in whichever group holds it*, so tapping one of those
  two rows moves both. It is arguably right — it is one physical plate — and it is on a branch Rob
  never walks, so it is recorded rather than changed. It sits with the palette gap in the map's
  **Not yet specified**.
