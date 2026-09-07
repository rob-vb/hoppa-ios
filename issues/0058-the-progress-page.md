---
id: 58
title: The Progress page — a sibling of History, and the chart door that leaves the Exercise card
parent: 17
labels: [wayfinder:task]
status: closed
assignee: agent
blocked-by: []
---

## Question

**The chart door is in the wrong room.**

§6.7 put the per-Exercise chart behind a sparkline on the Workout Day's Exercise card. Ticket
[0050](0050-the-exercise-cards-two-doors.md) made the mark the door, for three reasons that still
hold for *which half of a card* should open the sheet: an Exercise card is edited far more often
than it is charted, the mark announced itself, and a card with nothing to plot offered no empty
room. What they do not hold is *where the chart is reached from*.

The Workout Day screen is the room for building a Day. The card already has a grip and a sheet.
Putting the climb on the trailing edge of that card hides it in a place nobody looks for a
statistic, and it splits Flow 4 across two kinds of door that do not rhyme. History is a row at
the foot of the picker. The chart is a sliver on a card one room down.

Rob's words: *net zoals dat we een History pagina hebben ook een Statistics pagina.* The word
**Statistics** does not earn its place. §6.7 already refused volume and estimated 1RM. Hoppa
states the climb, not a dashboard. The sibling of History is **Progress**.

This ticket takes that page, moves the chart door onto it, and takes the sparkline off the
Exercise card. The card goes back to one door, the sheet.

Consult `SPEC.md` §6.7, §7.6, `HistoryScreen.swift`, `WorkoutDayPicker.swift`,
`WorkoutDayScreen.swift`, `ExerciseChartScreen.swift`, `History.swift`, `Chart.swift`, and
tickets [0015](0015-history-and-progression-charts.md), [0047](0047-the-history-screen.md),
[0049](0049-the-per-exercise-chart.md), [0050](0050-the-exercise-cards-two-doors.md).

## Resolution

**Two doors at the foot of the picker, no tab bar, and the Exercise card is a sheet again.**

History stays. Progress sits under it, the same `DoorRow`. A row of Progress is an Exercise that
has been performed at least once. Tapping it opens the chart that already exists. The sparkline
leaves the Workout Day card and sits on the Progress row as a mark, not as a nested button. The
whole row is the door, the way a History row is.

### Why not Statistics, and why not on History

Statistics names aggregates Hoppa does not keep. Progress names the climb §6.7 already draws.

Folding the list into History was the other shape. It lost because History is a list of Workouts.
An Exercise across every Workout it has been in is a different question, and mixing the two on
one screen would make History's empty state, its streak, and its reverse-date order answer two
jobs at once. A second page, reached the same way, keeps each list one kind of row.

### What the rule answers

`ProgressRow` is the named shape, a typed list in program order, not a scan of charts at the
view. `Rules.progress(in:)` walks Programs, then Days, then Exercises, and keeps a row only
where `ExerciseChart.hasSpark` is true. Charts still never join by Name (§2.7). Two Exercises
called `Barbell Bench Press` sit apart, each labelled with its Workout Day.

The Open Workout is not progress, for the same reason it is not history. A deleted Exercise
drops out of the list, because `exerciseChart` is already `nil` then. A renamed Day or Exercise
reads live. A Skipped-only Exercise makes no row, because a skip makes no point.

`hasSpark` stays the gate. One session is still enough to reach the chart. Two sessions still
make the line. The two gates were never the same gate, and moving the door does not join them.

Each row carries the Exercise's id, its live Name, the live Day Name, the session count, how
many times it went up, and the sparkline the chart already computes. The view prints English
and dates. It does no arithmetic.

### What the picker says

The Progress `DoorRow` reads `N exercises`, singular at one, and `0 exercises` before the first
session, the same shape as History's workout count. It does not print a went-up total. That
would be an aggregate across Exercises, which §6.7 refused.

First run still has neither door. A Progress row with no Program behind it would be furniture,
the same clause History already uses.

### What the screen draws

`ProgressScreen` is History's arrangement with a different list. Program name in the chevron,
title `Progress`, then either the empty state or a table. Rows separated by a rule, not cards,
so the two pages rhyme. Each row: the Name, the Day and the session count as the meta line, the
green went-up line only where there were any, the sparkline, a chevron.

Empty state, before the first session:

> Nothing here yet
> Finish a workout and every exercise you trained lands here.

History's empty state drops the sentence about an Exercise getting a line. That sentence
belonged to the chart door, and the chart door does not live there any more.

### What leaves the Exercise card

The trailing-edge button goes. The card is grip and sheet again. `Sparkline.swift` stays,
because the Progress row still draws the mark. The mark is no longer a door of its own. Tapping
it on a Progress row is tapping the row.

`ExerciseChartScreen`'s back label becomes `Progress`. The Day Name moves into the meta line
ahead of equipment, so two Exercises with the same Name still read apart once the chart is
open.

### What this ticket does not do

It does not add a tab bar. It does not plot volume or 1RM. It does not join charts by Name. It
does not keep a second door on the card. The chart screen itself is unchanged in what it
states.
