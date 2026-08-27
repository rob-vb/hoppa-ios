---
id: 50
title: The Exercise card's two doors, and the sparkline that announces one of them
parent: 17
labels: [wayfinder:task]
status: closed
assignee: claude
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

## Resolution

**The sparkline is the door.** The rest of the Exercise card still opens §6.2's Exercise sheet, and
an Exercise with nothing to plot draws no mark and offers no second door at all. Built:
`ExerciseChart.sparkline` and `ExerciseChart.hasSpark` in `HoppaRules`, `Sparkline.swift` in the
app target, and a third region on the trailing edge of `WorkoutDayScreen`'s card. 218 rules tests
(up from 211) and 41 checks in `app/checks/Chart` (up from 34). `HANDOFF.md` items 111–118.

**With this the build map is finished**: every screen in `SPEC.md` exists and every door between
them is open.

### The judgment call, and the two shapes it refused

Three reasons the sparkline is the door and not the whole card:

1. **An Exercise card is edited far more often than it is charted.** Every Exercise in a Program is
   opened at least once while it is being built, and none of them has a chart then. Making the
   chart the whole card would put `NOTHING HERE YET` behind the tap onboarding uses five times in a
   row.
2. **§6.7's own sentence makes the mark the announcement** — *the card carries a sparkline, so the
   door announces itself*. Reading that literally, the announcement and the door are one object,
   which is the only shape that needs no third affordance to explain.
3. **No sparkline, no door.** The ticket's own objection — *a sparkline with no data announces a
   door to an empty room* — is answered by not drawing one. `hasSpark` is `!points.isEmpty`, so the
   door appears the first time the Exercise is trained and never before it.

**The `•••` was refused** because it would hold exactly one item, and
[the chart](0049-the-per-exercise-chart.md) already refused a menu of nothing on the screen itself
— a menu of one is the same control with an extra tap in front of it. **The swap was refused**
because it spends the frequent path's target on the rare one; it is what
`design/0015-history/Program.dc.html` draws, and `SPEC.md` beats the artboard.

### Two gates, deliberately not one

§6.7 gates the **line** at two sessions and ticket 0049 built the one-session screen — heroes, chip
and `NOTHING HERE YET`. So the **door** is gated at one, not two: gating it at two would have built
a screen with no way to reach it, and one session is still worth the hero and the condition for the
next step. At one session the mark is a single dot, which is what one session honestly looks like.

### What the mark is, and what it leaves out

**The chart's own line** — same points, same padded `ChartScale`, same real-time x axis — so the
card and the screen it opens can never draw two different climbs. **2 px steel**, because §7.1's
rule that no plate colour enters a chart does not stop at the chart's edge; no green either, since
on the chart green marks *one session* and a lone green dot on a card would read as a verdict on
the whole Exercise.

It draws **no** One-off marker and **no** dashed `NEXT` step. A hollow marker is a smudge at
44 × 16, and the step's destination is already the big Working Weight printed beside the mark on the
same card — drawing it twice would make it the only thing on the card stated twice.

### Where §6.7's "Program sheet" actually is

§6.7 puts the Exercise card in the Program sheet. In this app the Program sheet lists Workout
**Days**; Exercise cards live one room down, on the Workout Day screen. The artboard settles it —
`design/0015-history/Program.dc.html` is headed `‹ Upper / Lower · Upper A · 5 exercises`, which is
that screen. `SPEC.md` §6.7 carries the correction, and §6.7 now also carries the door rule above.

### Three regions on one card, none over another

The card is **grip · sheet · chart**, left to right. The chart door sits *beside* the sheet's
Button, the same arrangement `ReorderColumn` gives the handle and for the same reason: two views
that never overlap need no gesture priority, so neither can swallow the other's tap. The mark is
44 × 16; its target is the whole trailing column, 66 × 62, which clears §7.4's 50.

### What is proved here, and what is not

`app/checks/Chart/run.sh` now prints the Day screen's cards as text — the name, the Working Weight,
the mark, and whether the card carries a door at all — from the shipping `Rules.exerciseChart`. So
**which cards get a door and what their marks plot are both walked on the VPS**, on sixteen weeks
of seeded Workouts and on an untrained Program:

```
  ┌──────────────────────────────────────────────────────────────┐
  │ SMITH MACHINE BENCH PRESS                                    │
  │                                                       ─────● │
  │ 97.5 kg                                        ───────       │
  │                                       ─────────              │
  │                                                              │
  └───────────────────────────────────────────────────── → chart ┘
  ┌──────────────────────────────────────────────────────────────┐
  │ SMITH MACHINE BENCH PRESS                                    │
  │                                                              │
  │ 72.5 kg                                                      │
  │                                                              │
  │                                                              │
  └─────────────────────────────── no door — nothing plotted yet ┘
```

**What is not proved**: whether a 44 × 16 mark reads at arm's length in gym light, and whether it
reads as a door rather than as decoration. That is items 114 and 116, and it needs a phone.
