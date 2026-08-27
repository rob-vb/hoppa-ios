---
id: 45
title: Deleting an Exercise or a Workout Day, and the two blocks stated where you tap
parent: 17
labels: [wayfinder:task]
status: closed
assignee: Rob
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


## Resolution

**`REMOVE DAY` is built, with both blocks stated where the user taps.** The rules were already
there and tested — `Rules.deleteBlock(forWorkoutDay:in:)`, `Action.deleteWorkoutDay` and its own
guard, from [Build the Program edits](0028-build-the-program-edits.md). Deleting an **Exercise**
was already built too, on the Exercise sheet at
[The Exercise sheet](0035-the-exercise-sheet.md). What this ticket owed was the Day's screen and
the words.

### The three open questions, decided and not asked

Under the 2026-08-27 rule a session that would have put a UI question to Rob decides it and lists
it in `HANDOFF.md` instead. All three are there, as walk items 51–61.

**1. Where the delete control lives.** At the foot of the **Workout Day screen**, above
`DAY DONE`, drawn exactly like `REMOVE EXERCISE` — steel text in a 50 pt outlined box. The rule is
now one sentence and covers both deletes: *each delete sits at the foot of the room for the thing
it deletes.* The Exercise sheet is the room for one Exercise; `WorkoutDayScreen` is the room for
one Day, and it already speaks `RENAME` as a word for the same reason.

Rejected: a **swipe**, which hides the control, and this app has no edit mode and no long press to
hide an affordance behind ([The reorder handles](0044-the-reorder-handles.md) settled that shape).
Rejected: a **`•••` on the hub's Day row**, which already carries a reorder grip on its leading
edge and a tap through its middle — a third target on one 62 pt card. The deciding argument is
§6.6's own: **a block has to be read before it can do its job**, and a row has no space for a
sentence while a room does.

**2. How a blocked control refuses.** It stays **live** and answers **in place**. It is never
greyed out. The tap prints the reason under the button in `Color.stop`; the reason is read off
`Rules.deleteBlock` on every pass, so it disappears the moment the rule stops refusing — at Finish,
or at `ADD A DAY` — with no second tap and nothing remembered.

This is not a new shape. `NameYourProgram` already carries it, in a comment written for
`CONTINUE`: *"§5.2's principle, applied to a button instead of a switch: Hoppa never disables the
control and never hides the reason — it states the condition where the user taps."* Disabled-and-
silent was ruled out by the spec; disabled-with-the-reason-beside-it was rejected because it would
print a red line permanently on every one-Day Program, which is every Program on the day it is
made, and §7.6 keeps colour off a state the user has not caused.

The two sentences live on `DeleteBlock.reason` in `DomainCopy.swift`, beside the other domain copy
— `FINISH YOUR WORKOUT FIRST` is the spec's own, and `A PROGRAM NEEDS AT LEAST ONE WORKOUT DAY` is
the line `ProgramSheet` already prints over an empty Day list, said again at the other end of the
same rule.

**3. The Exercise deleted mid-Workout.** The logging screen **already** said something —
*that exercise is gone; what you logged is kept* — from
[The logging screen](0036-the-logging-screen.md). So the words were not the gap. **The way on
was.** Its only control was `FINISH WORKOUT`, which walks the user straight into §3.3's gate while
other Exercises are still Open, with nothing else drawn. It now shows the bottom row's own control
instead — `NEXT: <name>` while an Open Exercise is left, `FINISH WORKOUT` when none is — factored
out as `moveOn(_:)` so the dead card and the finished card answer the same question once.

**The rule was not touched, on purpose.** `Rules.reduce` leaves `currentIndex` where it stood and
says why: §6.4 keeps the user on the **Exercise**, not the position, and the Workout's list never
shrinks. Moving him automatically would have been Hoppa jumping by itself. Hoppa offers the jump.

### What changed

- `app/Hoppa/Hoppa/WorkoutDayScreen.swift` — `removeRow`, the confirm, `remove()`, and `block`
  computed off `Rules.deleteBlock` so the sentence under the control and the refusal inside the
  rule can never come apart.
- `app/Hoppa/Hoppa/DomainCopy.swift` — `DeleteBlock.reason`.
- `app/Hoppa/Hoppa/LoggingScreen.swift` — `moveOn(_:)`, used by `bottomRow` and by the
  deleted-Exercise card.
- `SPEC.md` §6.6 — the three decisions recorded under *Deleting*.
- `HANDOFF.md` — a new section, walk items 51–61, with both judgment calls marked.

### What is proved here, and what only the phone can answer

`swift test` on `HoppaRules` is **151 green**, unchanged: no rule moved. Every call the two views
added was lifted into a throwaway file and compiled against the built `HoppaRules` with
`DomainCopy.swift` beside it — `Rules.deleteBlock`, `DeleteBlock.reason`, `.deleteWorkoutDay`,
`Workout.nextOpenIndex(after:)`, `.nextOpen` — so the API names are proved on the VPS, and both
reason sentences print. No new `app/checks/` harness: the decisions here are a copy switch and a
one-line guard over a rule that already has three tests, and a fourth harness for that would be
ceremony.

The SwiftUI itself is Mac-only. What the walk must answer: whether `REMOVE DAY` reads as a way out
rather than a trap at the foot of the screen, and whether a red line that appears on tap and leaves
on its own is legible or merely surprising.
