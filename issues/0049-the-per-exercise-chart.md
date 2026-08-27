---
id: 49
title: The per-Exercise chart, the Set grid under it, and the dashed step that has not been lifted
parent: 17
labels: [wayfinder:task]
status: open
assignee:
blocked-by: []
---

## Question

**§6.7's chart, which is the last screen in `SPEC.md` and the only one that draws a series.**

The line is the **Working Weight** — what Hoppa tracks and what progression moves. Estimated 1RM
and volume per session are refused by name: both are guesses about a lift Hoppa does not track, and
volume *falls* when the weight rises and the reps reset, so a progression would read as a loss.

| Element | Rule |
| --- | --- |
| The line | 2 px, **steel** `#9BA1A7`. **No plate colour ever enters a chart** — a coloured line would claim to be a plate (§7.1) |
| Progressed | Filled green dot |
| Stayed | Filled steel dot |
| A **One-off Weight** | Hollow marker **off** the line, at the weight actually lifted, tied to its session by a dotted drop, labelled `ONE-OFF`. **The line itself never dips** — a One-off never became the Working Weight (§4.3) |
| A **Skipped** Exercise | Nothing at all. No point, no gap marker |
| The x axis | **Real time**, not the session number, off the date the Workout started (§2.4), so a missed week is already a wider gap |
| The **NEXT** step | Where the last session progressed, a **dashed green step** to a hollow marker at the current Working Weight. **Solid is lifted; dashed is applied but not yet performed.** Without it the hero number contradicts the end of the line |

**The reps are a Set grid, not figures on the points.** One column per session, one cell per Set,
filled where that Set met the threshold of its Progression Mode — so *three filled cells* **is**
§4.1, and the grid answers *why did it not go up* with no words and no advice. **A One-off's column
is never filled**, whatever the reps: it could not have progressed, and a full green column beside a
step that never came would be a lie. Figures over every point were drawn and rejected: at fifteen
sessions they collide.

Under the grid, a **Last sessions** list gives exact rep counts for the four most recent sessions,
so nothing lives only in a picture. The screen ends on three figures: the first weight with its
date, the total gain, and the number of times the Exercise went up.

**Charts never join by Name** (§2.7): `Barbell Bench Press` in Upper A and in Upper B are two
Exercises, and joining them splices two lifts into a line where no point is true.

**Mixed units.** A mixed-unit pin has no single number to plot, so **the chart plots whichever
number actually moves** — for §6.7's reference case, a 90 lbs stack whose pin has not moved in
fifteen weeks, that is the **Microload**, and the axis reads `+ KG`. The two heroes stack as
`90 LBS` and `+ 3 KG`, converting nothing. **Rob's rack is kg and his stacks are kg, so this half
is unwalkable for him** — the same class as the lbs rack and as
[the MICRO stepper](0042-the-micro-stepper-on-a-mixed-unit-pin.md). Build it, test it here, and say
in `HANDOFF.md` that it cannot be reached on his phone, so its absence is never read as a defect.

**The whole series is a rule** by the map's test, and that is the point: it makes a screen with
fifteen sessions of data **checkable on the VPS**, the way [The Workout Summary](0038-the-workout-summary.md)
was. A throwaway renderer printing the series as text beats a phone here, because the phone has no
data yet.

**Which is this screen's real cost, and it must be written down rather than solved**: §6.7 needs
weeks of Workouts to say anything, and the Logbook has none. What ships is a screen proved against
a fixture, not a screen anyone has watched fill up.

Consult `SPEC.md` §6.7, §4.1, §4.3, §2.4, §2.7, §7.1, §7.2, `Summary.swift`, `PlateGlyph.swift`,
`SteelRamp.swift`, and [History and progression charts](0015-history-and-progression-charts.md).
