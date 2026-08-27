---
id: 47
title: The history screen — the streak, the Workout list, and the door at the foot of the picker
parent: 17
labels: [wayfinder:task]
status: closed
assignee: agent
blocked-by: []
---

## Question

**§6.7's first door, and the first Flow 4 screen. Two views on one screen, and both are rules.**

*"Hoppa has **no tab bar**. History is reached from the two places the user already stands"* — a
`HISTORY` row at the foot of the Workout Day picker opens **the streak, then the Workout list**.
This ticket takes that door and that screen; the Exercise card's door is
[The Exercise card's two doors](0050-the-exercise-cards-two-doors.md).

**The streak.** One block per week, and *"a week counts as soon as it holds one Workout"* — the
question is whether the user went, so a busy week with one session does not wipe the run. Above the
strip, the current run as a figure: `9` · `WEEKS IN A ROW`. A week with no Workout is a **darker
block and nothing else**: no flame, no warning, no notification, no *streak lost*, and deliberately
**no best-ever number**, which would make the current run read as a shortfall. §7.6's rule — Hoppa
states and never advises — is what the absence of a comparison protects.

**The Workout list.** Reverse date order. Each row: the date, the Workout Day's Name, the count of
Exercises and Sets, any skips, and — where there were any — how many Exercises went up, in green.

**The empty state**, before the first Workout: `NOTHING HERE YET`, and one line saying a Workout
lands here when it is finished, and an Exercise gets a line once it has two.

**Both are rules**, by the map's test: a week's blocks and a row's counts fall out of the `Logbook`
alone, and two lifters with the same `Logbook` must read the same streak. So they go in
`HoppaRules` with tests, the way [The Workout Summary](0038-the-workout-summary.md) put a whole
screen there — which is also what makes this screen checkable on the VPS.

**A week needs a calendar, and `HoppaRules` imports nothing.** `RelativeDay` in `HoppaStore` already
owns the calendar for §3.1's picker line and ticket 40's *earlier day*. Apply the map's
`is-this-a-rule` test properly here: **prove what needs `Foundation` with a compiler run, do not
assume it.** Whichever way it lands, the app must hold **one** week rule and not two.

Consult `SPEC.md` §6.7, §7.6, §2.4, `Summary.swift` for the shape a screen-as-a-rule takes,
`RelativeDay.swift`, `WorkoutDayPicker.swift`, and
[History and progression charts](0015-history-and-progression-charts.md).

## Resolution

**Both halves are rules, and the map's test sorted them into two different modules — which is the
whole of what this ticket had to decide.** The Workout list is `Rules.history`, in `HoppaRules`. The
streak is `Streak`, in `HoppaStore`, beside `RelativeDay`. The screen computes neither.

### Where the week rule went, and why the compiler settled it

The ticket asked for the `is-this-a-rule` test applied properly, so: **a week fails the second half
of the clause.** Which Workouts there are falls out of the `Logbook` alone; which *week* one of them
fell in does not — it needs a calendar, a first weekday and a time zone, and two lifters in two
zones may then correctly disagree about the same instant. That is word for word the reason ticket
0032 left `RelativeDay` out of `HoppaRules`, and this is the same question about a larger bucket.

The compiler agrees the only way it could have gone the other way is a wrong one. `Calendar` is
`Foundation`, so a week boundary is unreachable inside `HoppaRules`; what *would* compile there is
`Int(timestamp / 604_800)`, and that fixes every week to a Thursday in UTC, which is nobody's week.
So the arithmetic that compiles is the arithmetic that lies, and the map's rule — push the
`Foundation` part out to the caller rather than add a second target — lands it in `HoppaStore`.

**One week rule and not two, as the ticket demanded.** `Streak.read` answers the strip, the two
dates under it and the figure above it in one value, and the picker's `HISTORY` row now calls the
same function — where it used to state the workout count alone, because the streak was a rule nobody
had written, it now reads `12 workouts · 2 weeks in a row`.

### What the rules answer

- `Rules.history(in:)` — §6.7's list, **reverse date order**, newest first. Each row carries the
  `startedAt` (§2.4 — the day it began, not the day it was finished), the Day's Name, the Exercises
  **performed**, the Sets, the skips counted separately, and how many went up. `Rules.historyRow(_:in:)`
  finds one by id, which is ticket 0048's way in.
- **The Open Workout is not history** — the same clause `Logbook.lastTrained` applies: it has been
  started, not done.
- **Went-up is read off the recorded `ProgressionOutcome`** and never re-derived, for the reason
  `Summary.swift` states: §2.4 stores the planned Sets and the threshold because both are editable.
- **The Day's Name is live while the Day exists, stored after a delete** — word for word the rule
  the Summary applies to an Exercise Name (§2.7). A rename corrects one Day's name rather than
  inventing a second, so a renamed Day reads its new Name all the way down the list; a deleted one
  keeps what it had, because nothing else can say what was trained.
- `Streak.read` — one block per week, **lit by one Workout**, ending on the week that holds *now*,
  with the run counted over all of history and not only the blocks on screen.

### The five judgment calls, decided rather than asked

Under the 2026-08-27 rule these are decided here, recorded, and written into
[`HANDOFF.md`](../HANDOFF.md) as items 76–86 to look at.

1. **The strip starts at the first Workout, never sixteen weeks before it.** A lifter three weeks in
   sees three blocks. Thirteen dark ones would be thirteen weeks he did not own the app, and drawing
   them is the comparison §6.7 removed the best-ever number to avoid.
2. **A week that has not ended does not break the run.** The run counts back from the week holding
   *now* when that week has a Workout, and from the week before it when it does not. Otherwise the
   figure falls to zero every Monday morning and climbs back on the first session, which reports the
   day of the week and not the run.
3. **No streak card at all before the first Workout.** §6.7 gives the streak no empty state of its
   own, and a card reading `0` over sixteen dark blocks is exactly the shortfall §7.6 forbids. The
   empty state is the whole screen.
4. **The run is dropped from the picker's row where it is zero**, rather than printed as
   `0 weeks in a row`. The count on its own is still true.
5. **The year joins the month once the date leaves the current one** — `18` over `AUG`, and
   `29` over `DEC 25`. The artboard writes no year, and at eight months back two rows would read
   the same.

One value was added to the palette and it is a derivation, not a hue: `weekOff` `#191B1D`, the
artboard's dark block, on §7.2's own 210° spine and darker than the card it sits on so it can never
read as a warning.

### The fixture problem the map wrote down, paid off

The map recorded Flow 4's cost plainly: *§6.7 needs weeks of Workouts to say anything and the
Logbook has none.* [Build order across the flows](0029-build-order-and-what-done-means.md) kept
`HarnessSeed.swift` alive for exactly this. So it now carries a second switch, `seedsHistory`, and
with it on the starter Program is **trained forward through `Rules.reduce`** — sixteen weeks, two
Days a week, one week missed and one Exercise skipped. Nothing writes a `Workout` by hand, so the
weights on screen are the weights §4.1 actually makes. The starter grew a second Workout Day with
it: a history built on one Day is a list that reads `Upper A` fifty times.

Both switches ship `false`. The seed is walk item 84, and it costs the app's data.

### What is green, all of it on this machine

| Suite | Count | New |
| --- | --- | --- |
| `app/HoppaRules` — `swift test` | 168 | +12, `HistoryTests` |
| `app/HoppaStore` — `swift test` | 49 | +13, `StreakTests` |
| `app/checks/History/run.sh` | 33 | new |
| `app/checks/UnitStash`, `Reorder`, `Reweigh` | 34, 25, 34 | unchanged |

`HistoryTests` reads the list twice: once against a Workout built tap by tap, where every figure can
be counted by hand, and once against the **56-Workout snapshot**, which is the only fixture in the
effort with a missed week, a skip and a One-off in it. `StreakTests` runs every case against a fixed
Amsterdam calendar and checks the Sunday-first one too, because the first weekday is the calendar's
and not Hoppa's opinion.

`app/checks/History` is the thin ring ticket 0046 established — the screen's meta line, the picker's
row and the dates, with the SwiftUI dropped. It goes one step further than its predecessors:
`HarnessSeed.swift` imports no SwiftUI, so the **sixteen-week seed is compiled and run here**, and
the strip it produces is asserted — sixteen blocks, exactly one dark, a run of nine — before it ever
reaches a phone.

### What is left, and where it goes

`Route` gained `.pastWorkout(WorkoutID)`, carrying the Workout's id and not the Day's for the reason
`.summary` does. It lands on `NotBuiltYet` naming ticket 0048, which is ticket 0032's own answer to
a door with no room. **Ticket 0048 swaps one `case`.**

Nothing here graduated new fog and nothing was ruled out of scope. One thing worth carrying forward:
[the per-Exercise chart](0049-the-per-exercise-chart.md) has the same fixture problem this ticket
had, and `HarnessSeed.trained` is now the answer to it.

Pushed. A screen ticket closes when it is pushed, not when Rob has seen it (ticket 0029).
