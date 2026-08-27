---
id: 50
title: The Exercise card's two doors, and the sparkline that announces one of them
parent: 17
labels: [wayfinder:task]
status: open
assignee:
blocked-by: [49]
---

## Question

**§6.7 gives the Exercise card a second door, and the card already has one.**

*"Any **Exercise card** in the Program sheet → That Exercise's chart. The card carries a sparkline,
so the door announces itself."* But the Day artboard's own caption says **tap a row to open it**,
meaning §6.2's sheet — and that is the only room that existed when
[The Program sheet hub and the Workout Day screen](0034-the-program-sheet-and-the-workout-day.md)
built the card, so it built one door to the sheet and drew no sparkline.

With [the chart](0049-the-per-exercise-chart.md) built, the card carries two doors and **somebody
has to say which one is the whole card**. Three shapes, and none is written down:

- **The sparkline alone opens the chart**, the rest of the card opens the sheet. Two targets on one
  row, and the smaller one is the new one.
- **A `•••`**, the way §6.7 hangs delete off a Workout row.
- **A swap**: the card opens the chart, and the sheet moves behind something else.

**This is a judgment call, and under the map's 2026-08-27 rule it gets decided here rather than
asked** — decided, with the reasoning recorded, and written into `HANDOFF.md` as something for Rob
to look at on the walk. Two facts to weigh: an Exercise card is edited far more often than it is
charted, at least until there is a climb worth looking at; and a sparkline with no data — which is
every card in this app today — announces a door to an empty room.

The sparkline itself is the other half: **2 px steel**, like the chart's own line, because §7.1's
rule that no plate colour enters a chart does not stop at the chart's edge.

Consult `SPEC.md` §6.7, §6.2, §7.1, `ProgramSheet.swift`, `WorkoutDayScreen.swift`,
and the chart ticket above.
