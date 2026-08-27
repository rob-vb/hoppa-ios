---
id: 45
title: Deleting an Exercise or a Workout Day, and the two blocks stated where you tap
parent: 17
labels: [wayfinder:task]
status: open
assignee:
blocked-by: []
---

## Question

**§6.6's delete table is built as rules and has no screen.** `Action.deleteExercise` and
`Action.deleteWorkoutDay` landed at [Build the Program edits](0028-build-the-program-edits.md),
including both refusals. What is missing is where the user taps and what they read.

| Action | Hoppa does |
| --- | --- |
| Delete an Exercise | Leaves the Program from today forward. Past Workouts keep their Sets under the stored Name (§2.4). |
| Delete a Workout Day | The same, and the Workout keeps the Day's name. |
| Delete the Day the Open Workout runs on | **Blocked**: `FINISH YOUR WORKOUT FIRST`. |
| Delete the last Workout Day in a Program | **Blocked.** A Program with no Days cannot be started. |
| Confirm | Plain, with **no** count of destroyed Sets — because nothing is destroyed. |

**The hard half is the block, not the delete.** *"A block is stated **before** the user commits: the
delete control refuses with its reason where the user taps it. A confirm that quietly does nothing
is not a block, it is a bug the user gets to diagnose."* That is §5.2's principle again — Hoppa
states its condition where the user stands — and the app already speaks it twice, at
`NameYourProgram`'s `CONTINUE` and at the Exercise sheet's save.

Open here, and to be **decided and written into `HANDOFF.md`** rather than asked:

- **Where the delete control lives.** A swipe, a `•••` on the row, or a control inside the Exercise
  sheet. §6.6 does not say, and the sheet is the one place that already knows which Exercise it is.
- **How a blocked control refuses.** Disabled with the reason beside it, or tappable and answering
  in place. Disabled-and-silent is the one thing the paragraph above rules out.
- **The Exercise-deleted-mid-Workout case has a rule and no words yet** — it keeps its logged Sets,
  stops holding the Finish gate, and ends Completed or Skipped. Whether the logging screen says
  anything when a card disappears under the user is a real question.

Consult `SPEC.md` §6.6, §2.4, §3.2, §5.2, `Rules+Edit.swift`, `ProgramSheet.swift`,
`WorkoutDayScreen.swift`, `ExerciseSheet.swift`.
