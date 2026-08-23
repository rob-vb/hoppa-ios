---
id: 40
title: The Open Workout on next open — resume, finish, or discard
parent: 17
labels: [wayfinder:task]
status: open
assignee:
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
