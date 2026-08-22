---
id: 33
title: The Program name, the three assumptions, and the Plate Inventory screen
parent: 17
labels: [wayfinder:task]
status: open
assignee:
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
