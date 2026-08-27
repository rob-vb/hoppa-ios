---
id: 44
title: The reorder handles, and the card that stays under your thumb
parent: 17
labels: [wayfinder:task]
status: open
assignee:
blocked-by: []
---

## Question

**§6.6 gives Exercises and Workout Days reorder handles, and gives reordering one rule that is
harder than the drag: mid-Workout the user does not move with it.**

*"Reorder takes effect at once, and the `3 / 5 ▾` counter renumbers with it. **The user does not
move with it**: Hoppa keeps him on the Exercise he was standing at, not on the position he was
standing in, so a drag never changes the card under his thumb (§6.4)."*

**The rules are already built.** `Action.moveExercise(ExerciseID, to: Int)` and
`Action.moveWorkoutDay(WorkoutDayID, to: Int)` landed at
[Build the Program edits](0028-build-the-program-edits.md), and ticket 26 recorded that
`moveExercise` reaches into the Open Workout. So this ticket is **SwiftUI and a check**, not a rule:

- The handles themselves, in the Program sheet's Day list and the Workout Day screen's Exercise
  list, in a way that does not fight the row's existing tap target (§6.2's card opens a sheet).
- **Prove the thumb rule holds.** `currentIndex` is a position; the promise is about an identity.
  Whether `moveExercise` already keeps the user on his Exercise is a question for the existing
  tests, and if it does not, that is a rule fix with its own tests here.
- Reordering Days is **cosmetic** (§3.1, free pick, no rotation), so the Day list needs no
  mid-Workout thought at all.

Consult `SPEC.md` §6.6 and §6.4, `Rules+Edit.swift` (`moveExercise`, `moveWorkoutDay`),
`ProgramSheet.swift`, `WorkoutDayScreen.swift`, and
[Program edits, and which of them are rules](0026-program-edits-and-the-rules-boundary.md).
