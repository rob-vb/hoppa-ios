---
id: 40
title: The Open Workout on next open — resume, finish, or discard
parent: 17
labels: [wayfinder:task]
status: closed
assignee: agent
blocked-by: [38]
---

## Question

**§3.3's last line has no screen, and the shell is where it has to appear.**

> An Open Workout from an earlier day is **not** closed silently. On next open Hoppa asks:
> resume, finish, or discard.

Found while building [The shell and the first run](0032-the-shell-and-the-first-run.md). The picker
is the app's home (§6.1), so *on next open* means *on the picker* — and the picker as built ignores
the Open Workout entirely. Today that is harmless, because nothing can start one: ticket 32
deliberately made a Day row push without sending `.startWorkout`. It stops being harmless the moment
ticket 36 lands, and by ticket 38 Hoppa can leave a Workout open across a night in the gym bag.

It is here and not folded into ticket 36 because **all three answers need screens ticket 36 does not
build**: `finish` runs progression and lands on the Workout Summary (ticket 38), and `discard` throws
away real Sets and asks first (§3.3).

Three things to settle, not just to draw:

- **What "from an earlier day" means.** §3.3 says *an earlier day*, and §2.4 says a Workout keeps the
  day it started even when finished the next day — so a Workout started at 22:00 and reopened at
  01:00 is on a different calendar day and the same session. Whether the prompt fires on a calendar
  boundary, on an elapsed gap, or on something else is undecided. Note that this is the same
  calendar-versus-elapsed question `RelativeDay` answered for the picker line, and it may not want
  the same answer.
- **What the picker looks like while a Workout is Open**, once the prompt is dismissed or the
  Workout is from *today*. `Rules.reduce` refuses a second `.startWorkout`, so a row that still
  looks tappable is a lie. §3.1 does not say.
- **Where the prompt lives** — a sheet over the picker, or a screen. `SPEC.md` §3.3 specifies the
  question and none of this.

Done, hand-off and testing follow ticket 29's rules.

Consult `SPEC.md` §2.4, §3.1, §3.3 and §6.1.

> **Ticket 0036 met the mid-session shape of this and answered it there.** Start Upper, press back
> to the picker, tap Lower: `Rules.reduce` refuses the second `.startWorkout`, and the logging
> screen now says which Day is running and offers the one door to it. That is **not this ticket** —
> it only has to point, because the user is standing in the Workout he just left. This ticket is
> the one that has to *ask*, about a Workout from an earlier day found at launch. Recorded so this
> ticket does not rebuild what already exists.

## Resolution

**All three settled with Rob, and the screen is built and pushed.** §3.3's last line now has a
place to appear.

**1. *An earlier day* is a calendar day.** `RelativeDay.isEarlierDay(_:than:)` in `HoppaStore`,
four lines beside the picker line and reusing its `daysBetween` — so the app holds **one** day
rule and not two. The ticket asked whether it wants the same answer as the picker line, and it
does. A calendar boundary was weighed against an elapsed gap and won on a fact the model
settles: **a `Workout` carries one clock, `startedAt`, because `LoggedSet` has no timestamp**,
so *hours since the last Set* is not a question this model can answer at all. The cost is the
one case the ticket named — start 22:00, open 01:00, same session, and Hoppa asks — and it is
**accepted and written as a test**, because the prompt destroys nothing and *resume* is one tap.
A clock that moved back reads `false`, the same way the picker line reads `Today`.

Five tests, all against a fixed calendar in `Europe/Amsterdam`: same day, yesterday-by-twenty-
minutes, the across-midnight cost, the future, and both daylight-saving boundaries. `HoppaStore`
is **36** green, up from 31; `HoppaRules` is 143, untouched.

**2. The picker marks the running Day and leaves every other row alone.** The Day whose Workout
is Open reads `Running` in `Color.go` **in place of** its last-trained line — §3.1's line reads
the newest *finished* Workout, so the two are never both interesting. The other rows stay
tappable on purpose: ticket 36 already built the arrival, a screen that names the Day that is
running and offers one door to it, and **a dead row would refuse in silence**. Silence explains
nothing; that screen explains.

**3. The prompt is a sheet over the picker**, in the sheet vocabulary the logging screen already
speaks — `SheetStack`, `SheetPrimary`, `SheetRow` — so the Program stays visible behind the
question. `Resume` is the primary, because coming back to train is the common case. Discard
carries the stop tone and reuses the logging screen's confirmation **word for word**: it is the
same question about the same Workout, and two wordings would be two promises. A Workout with no
logged Sets still discards without one (§3.3).

**Two things the question forced, which the ticket did not list.**

- **Finish takes §3.3's shortcut in place, not in a second sheet.** A forgotten Workout almost
  always has Open Exercises, so the Finish row carries *"3 exercises still open · will be
  skipped"* as its own subtitle and one tap runs `.skipRemainingAndFinish`. Nothing becomes
  ambiguous — every Exercise still ends Completed or Skipped — and the sentence stands where the
  user taps, which is what §6.1 does with `Give it a name first.`
- **Once per launch, not once per appearance.** Hoppa never ends a Workout by itself, so a swipe
  is not an answer and the question returns — at the next launch, not every time the user pops
  home from the Program sheet. `asked` is set when the sheet is *shown*, so a swipe cannot
  re-raise it inside the same run, and the `Running` line holds the fact meanwhile.

**What was proved here.** The view is SwiftUI and cannot be compiled on the VPS, so every
rules/store call it makes was lifted into a Foundation-only file and `swiftc -typecheck`'d
against the built modules — `isEarlierDay`, `RelativeDay.text`, `workoutDayName`, `startedAt`,
`workoutDayId`, `canFinish`, `hasLoggedAnything`, `openExerciseCount`, `loggedSetCount`, both
`send` calls and the finished-list read. Clean, once `@MainActor` was added, which is a fact
about the store and not about this screen. **No rule was added and no `Action` was added**: the
three answers are `.finish` / `.skipRemainingAndFinish` and `.discard`, which have existed since
ticket 20. The Xcode project needed no edit for the sixth time.

**What no type-check can judge**, and what belongs in the hand-off: whether the sheet reads as a
question and not an accusation, and whether `Running` is legible at meta size on the floor.

`SPEC.md` §3.3 carries all of it, and §3.1 carries the `Running` line.