---
id: 47
title: The history screen — the streak, the Workout list, and the door at the foot of the picker
parent: 17
labels: [wayfinder:task]
status: open
assignee:
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
