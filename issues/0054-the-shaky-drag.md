---
id: 54
title: The block shakes while it is dragged
parent: 17
labels: [wayfinder:task]
status: closed
assignee: agent
blocked-by: []
---

## Question

Rob, on the walk, 2026-08-28:

> reordering van dagen werkt, maar het blok wordt heel shaky tijdens het slepen

**The arithmetic is not the suspect.** `ReorderDrag` imports nothing and
`app/checks/Reorder/run.sh` walks 25 cases of it here, green — where a card lands, which rows
displace, what the previewed order is. A shake is not a wrong landing; it is the same landing
drawn twice per frame. So this is in `ReorderColumn`, the SwiftUI half, which is the half no
check on this machine can reach.

## Resolution

**Two independent causes, and either one alone would shake.**

### 1. The drag measured itself

`DragGesture` reports `translation` as `location - startLocation`, and **both are read in the
gesture's coordinate space**. The default is `.local` — the space of the view the gesture is
attached to. Here that is the handle, which sits inside the card, and **the card is offset by
`travel`, which is the number being measured**.

That is a loop, and it runs at frame rate:

| Frame | Card offset before the event | Finger, on screen | `translation.height` | `travel` becomes |
| --- | --- | --- | --- | --- |
| 1 | 0 | +10 | 10 | 10 |
| 2 | 10 | +10 (still) | 10 − 10 = **0** | 0 |
| 3 | 0 | +10 (still) | **10** | 10 |

The card flips between two positions while the finger holds still. **That is the shake**, and it
is exactly what "heel shaky" describes.

Fixed by `DragGesture(minimumDistance: 2, coordinateSpace: .global)`. The screen does not move, so
it cannot feed back into what is measured against it. Nothing else in the gesture changes — only
`translation.height` is read, and a delta is a delta in any fixed space.

### 2. The list scrolls while the card is dragged

Both call sites put `ReorderColumn` inside a vertical `ScrollView` — `ProgramSheet.days` and
`WorkoutDayScreen.list`. A vertical drag on a child of a vertical scroll view is a **competition**,
and this one was entered with a plain `.gesture`, which does not win it. When the ScrollView takes
some of the movement, the content slides under the finger while the card offsets against it: a
second shake, on top of a list that scrolls when the user meant to reorder.

**The file's own header said this could not happen** — *"the ScrollView keeps every pixel that is
neither"* — which is true of the pixels and false of the gesture. The header is corrected.

Two changes, because the competition has two ends:

- **`.highPriorityGesture`** rather than `.gesture`, so the handle owns the finger from the first
  event rather than sharing it.
- **`.scrollDisabled(isReordering)`** at both call sites, so the list is pinned for the whole
  drag. A reorder and a scroll must never run at the same time, and high priority alone settles
  only the start.

`isReordering` is a new `Binding` on `ReorderColumn`, defaulting to `.constant(false)`. **It is
derived, never set by hand**: `.onChange(of: dragging) { isReordering = $1 != nil }`. Writing it
from the gesture's two callbacks would have meant two places that can leave it `true`, and **a
ScrollView stuck at `scrollDisabled(true)` is a worse defect than the shake** — the screen would
simply stop scrolling, with nothing on it to explain why. `dragging` is the one truth and the lock
follows it. A `.onDisappear` clears the drag as well, because a cancelled gesture does not always
call `onEnded`.

### 3. One thing that was not a cause, fixed anyway

`.shadow(color: .black.opacity(lifted ? 0.45 : 0), radius: 10, y: 4)` ran on **every** card. A
shadow is an offscreen blur pass, and a transparent one still costs it — on every row, on every
frame of the drag. It is now `radius: 0` and `.clear` unless the card is lifted, which lets the
pass be skipped entirely. This would not produce a two-position flip; it can cost frames, and a
drag that drops frames looks unsteady in its own way.

## What is proved, and what is not

`app/checks/Reorder/run.sh` is still green at 25 — untouched, because none of this is arithmetic.
`app/checks/AppTarget/run.sh` is green. **Neither proves the shake is gone**: all three changes are
SwiftUI behaviour on a real touchscreen, which is the one thing this machine has none of.

Cause 1 is a mechanism, not a guess — the loop is in the table above, and `.global` breaks it.
Cause 2 is a competition whose outcome depends on the ScrollView, so it is the less certain of the
two; it is closed from both ends for that reason. If the card still shakes after this, the next
suspect is `.animation(lifted ? nil : .easeOut, value: shift)` on the lifted card, and the test is
whether it shakes with the list too short to scroll — which separates cause 2 from everything else.

`HANDOFF.md` items 122–123.
