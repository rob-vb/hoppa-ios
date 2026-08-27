---
id: 44
title: The reorder handles, and the card that stays under your thumb
parent: 17
labels: [wayfinder:task]
status: closed
assignee: Rob
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

## Resolution

**The thumb rule already held. What was missing was the handle, and a way to prove the drag.**

### The check the ticket asked for

`moveExercise` was written correctly at ticket 0028 and one test guarded it. Four more were
written here, and every one passes **unchanged** — no rule fix was needed:

- the Exercise that moves **carries the user with it**, when it is the one he is standing on;
- an Exercise dragged **past** him renumbers the `3 / 5 ▾` counter and never moves him;
- a drag on a Day the Open Workout does **not** run on never reaches the Workout;
- a drop past the end of the list is clamped, and a drop on the same place writes nothing.

`HoppaRules` 147 → **151**, green on the VPS.

### The handle

`ReorderColumn` — one column of cards with a grip on the **leading** edge, used by both lists.
Three judgment calls, taken rather than asked (the 2026-08-27 rule):

- **Not `List` + `.onMove`.** `.onMove` shows a grabber only in `EditMode.active`, and a row in
  edit mode stops answering taps — which costs both lists the one thing they are for (*tap a row
  to open it*). A `List` reordered by long press instead has **no visible handle at all**, and
  this app already refused that trade: `RENAME` is a word on the screen and not a long press.
- **No edit mode.** Hoppa has none anywhere, so one here would need a `DONE` that means nothing.
  The handles are on every row, always.
- **Leading, not trailing.** The trailing edge already carries the row's hero — the Working
  Weight on a Day row, the `›` on a Program row. The grip is three drawn `Capsule`s and not an
  SF Symbol, like every other glyph in this app (§7.1).

The handle sits **beside** the row's `Button`, not over it, so no gesture has to be given priority
over another: the grip drags, the rest of the card taps, and the `ScrollView` keeps what is
neither. The Program sheet's position number stays — it is what the handle is *seen* to change,
and it renumbers under the finger, because the row builder is handed the **previewed** position
and not the stored one.

### The arithmetic left the view, so it could be run here

A hand-rolled drag whose maths nobody can run is exactly what comes back off the Mac as a defect.
So the arithmetic is `ReorderDrag` — `landing`, `shift`, `position`, `preview` — in the app target,
**importing nothing**, the trick ticket 0043 used for `UnitStash`. It is not a rule: it decides
nothing from the `Logbook`, and two lifters with the same `Logbook` and different fingers are owed
different answers.

`app/checks/Reorder/` walks it: **25 checks, all green**, compiled against the real file. The one
that matters most compares `preview()` against **remove-then-insert** — the two lines
`Rules.moveExercise` runs — for all 25 start/landing pairs in a five-row list. A preview that
disagreed with the rule would leave the user watching one order and getting another, and no rules
test can catch that, because the preview is not a rule.

### What was built

- `ReorderDrag.swift` (new): the drag in list positions, importing nothing.
- `ReorderColumn.swift` (new): the card column, the grip and the `DragGesture`.
- `WorkoutDayScreen.swift`, `ProgramSheet.swift`: the two lists go through it; both row builders
  give up the card chrome they used to draw and keep their content.
- `EditTests.swift`: four tests, 147 → **151**.
- `app/checks/Reorder/` (new): 25 checks, `./run.sh`.
- `SPEC.md` §6.6: a paragraph saying what the handle is, since §6.6 specified the reorder and left
  the handle undrawn.

### What only the phone can answer

Three items are in `HANDOFF.md`. In short: whether a 36 pt grip beside a 62 pt card is enough
thumb and not too much furniture; whether the drop lands where the eye says (the tipping point is
**half a row**); and that **the list does not scroll while a card is dragged past its edge** — no
autoscroll was built, because five to eight rows fit on a screen. If a Day ever holds more than
fits, that is a ticket and not a bug.
