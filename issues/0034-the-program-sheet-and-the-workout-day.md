---
id: 34
title: The Program sheet hub and the Workout Day screen
parent: 17
labels: [wayfinder:task]
status: open
assignee:
blocked-by: [33]
---

## Question

**Build onboarding step 3 — the Program sheet, which §6.1 calls the hub — and the Workout Day screen
under it.**

Scope was cut at ticket 29 and the cut matters: **build only what onboarding needs.**

In:

- The **Workout Days with their Exercise counts**, `ADD A DAY`, and a link to Program settings.
- **Naming a Workout Day.** The budget is 40 taps for four Days (§6.2).
- Opening a Day: its **Exercise list**, and `ADD AN EXERCISE`, which opens ticket 35's sheet.
- The **sparkline on an Exercise card** (§6.7) is a door to a chart that does not exist yet. Leave
  it out and say so in the hand-off note; it arrives with Flow 4.
- Empty states come from §6.2 and §5.2 — §6.6 says only three screens in that section have no
  precedent.

Out, and each for a reason: **reorder handles, deleting an Exercise, deleting a Workout Day, the two
warning dialogs, and the Re-weigh list.** Every one of them carries a warning or mirrors into the
Open Workout — the counts, stranding, `currentIndex` following the `ExerciseID` and not the
position. That is
[Program edits, and which of them are rules](0026-program-edits-and-the-rules-boundary.md)'s work,
already built in `HoppaRules` and waiting for its own flow. None of it is needed to put a first
Program on the phone, and folding it in makes this ticket too big for one session.

Also out for now: **deleting a whole Program**, which the spec has never specified. It sits in the
map's **Not yet specified** and is a decision, not a build.

Done, hand-off and testing follow ticket 29's rules. Batch 1 goes over after ticket 35.

Consult `SPEC.md` §2.1, §2.2, §6.1 and §6.6, and `design/0006-onboarding/`.
