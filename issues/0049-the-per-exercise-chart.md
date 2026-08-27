---
id: 49
title: The per-Exercise chart, the Set grid under it, and the dashed step that has not been lifted
parent: 17
labels: [wayfinder:task]
status: closed
assignee: claude
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

## Resolution

**Built. `Rules.exerciseChart(_:in:)` is the series, `ExerciseChartScreen.swift` draws it, and
`app/checks/Chart/run.sh` prints sixteen weeks of it as text on the VPS** — which is what the whole
rule/view split was for. 24 new tests in `HoppaRulesTests` (211 green, up from 187) and 34 checks in
the new `app/checks/Chart`. Nothing on the phone yet: the room is `Route.exerciseChart`, and
[the doors](0050-the-exercise-cards-two-doors.md) is the ticket that opens it.

### What the rule answers

`ExerciseChart` — the heroes, the chip, the points, the scale, the dashed step, the totals. Every
figure falls out of the `Logbook` alone; only the pixels, the English and the dates are the view's.
Written the way `Summary.swift`, `History.swift` and `PastWorkout.swift` are: **recorded outcomes,
re-derived never**, because the Rep Range and the Increment are editable and a chart that solved
them live would repaint fifteen weeks of Set cells at the next edit.

| Element | Where it comes from |
| --- | --- |
| The line | The weight the session was **performed at**, off the Set (§2.5). Not the weight it earned — that step shows on the next session, and the dashed step covers the last one |
| A **One-off** | The line holds `outcome.workingWeightAfter`, the Working Weight that survived; the hollow marker holds the Set's own weight. **The line walks straight through it** |
| A **Skipped** Exercise | No point. The real-time x axis already spaces it |
| The Set grid | `Rules.met(_:threshold:)`, which is now the **one** copy of that fact — `PastSet.metThreshold` calls it too, so §6.7's two screens cannot disagree about one Set |
| The chip | Live, from `Rules.progressionMove`; the blocker from `Rules.progressionBlocker`, made public so §6.5 and this screen cannot name one stopped plate twice |
| The y axis | `ChartScale` — everything a marker can reach, padded 18%, with gridlines on clean steps of the unit, four at most |

### Four judgment calls, taken here under the map's 2026-08-27 rule

1. **The dashed step is drawn whenever the hero and the end of the line differ — green where Hoppa
   moved the weight at Finish, steel and labelled `NOW` where the user set it by hand (§4.3).**
   §6.7 wrote only the green case, but a hand edit opens the same gap for a reason no green step
   should claim credit for. Steel is already this chart's word for *not a progression*. `SPEC.md`
   §6.7 carries the amendment.
2. **`Last sessions` marks the reps Set by Set, not row by row.** The artboard colours the whole row
   when every Set met the threshold; marking each Set is the same fact the grid column above draws,
   and §6.7's own rule is that the two views can never disagree about one Set.
3. **No `•••` on this screen.** The artboard draws one; §6.7 gives it nothing, and a menu of nothing
   is a control that does not work.
4. **One session is not a chart.** §6.7's empty state says an Exercise gets a line once it has two,
   so a single dot keeps the heroes and the chip and says `NOTHING HERE YET` where the plot would be.

### The mixed-unit half, and the open item it exposed

Built, and **unreachable on Rob's phone** — his rack is kg and his stacks are kg, the same class as
the lbs rack and as [the MICRO stepper](0042-the-micro-stepper-on-a-mixed-unit-pin.md).
`HANDOFF.md` item 109 says so, so its absence is never read as a defect.

Walking it here found something §6.7 did not write down. **§6.7 chose the Microload as the line for
a reference case whose pin has not moved in fifteen weeks** — and the artboard fixture picked a
0.25 kg Microplate on purpose so it never would. Run the same screen on the 1 kg plate the rules
actually ship with and the roll-up fires: the Microload empties into the pin (§4.2) and **the line
falls while the weight on the machine rises**, which is exactly the shape §6.7 refused *volume* for.

Not solved, and deliberately: the chart draws what it plots, and the sentence under it states why
the line drops (`The line is the microload. The pin has gone from 90 lbs to 110 lbs, and the line
drops back each time the microload rolls onto it. Nothing here converts.`). `SPEC.md` §6.7 carries
it as an open item, and it waits for a lifter who can reach it.

### The seed grew a One-off

`HarnessSeed.oneOffWeek` — week 9's Upper A, the Smith bench 7.5 kg light. A One-off is reachable on
Rob's phone and §6.7's hollow marker is one of the three things on this screen worth looking at, and
a seed with none in it cannot show it. `HANDOFF.md` item 84.

### What sixteen weeks looks like on the VPS

```
── SMITH MACHINE BENCH PRESS ───────────────────────────────
   Smith · 3 × 8–12 · Progressive overload
   97.5 kg   WORKING WEIGHT
   [ ALL 3 SETS AT 12 → 100 KG ]

        │                                                              
    100 │······························································
        │                                                    ─*───# + O
        │                                                ─#──          
     90 │···········································───#─··············
        │                                     ─#────                   
        │                             ─:───#──                         
        │                        ───#─ :                               
     80 │··············─*───#────······:·······························
        │          ─#──                o                               
        │#───*───#─                                                    
     70 │······························································
        │                                                              
        │MAY        JUN                JUL             AUG             
   SETS │■   □   ■  ■   □   ■       ■  □   ■   ■       ■  ■   □   ■    
        │■   □   ■  ■   □   ■       ■  □   ■   ■       ■  ■   □   ■    
        │■   □   ■  ■   □   ■       ■  □   ■   ■       ■  ■   □   ■    

   LAST SESSIONS
    24 AUG  *12 ·*12 ·*12   95 kg
    17 AUG   8 · 8 · 8   95 kg
    10 AUG  *12 ·*12 ·*12   92.5 kg
     3 AUG  *12 ·*12 ·*12   90 kg

   72.5 kg ON 11 MAY   |   +25 kg SINCE THEN   |   10 TIMES UP
```

`#` went up · `*` stayed · `o` a One-off, off the line, with its `:` drop · `+ … O` the dashed NEXT
step · `■`/`□` the Set grid. The wide gap in the middle is the missed week; the hollow `o` under the
line is week 9's One-off, and its grid column is empty.

### What this does not prove

**Nobody has watched this screen fill up.** It is proved against a fixture and against sixteen weeks
of the shipping rules, which is the most this side of the wall can do. Whether a fifteen-session
plot reads at arm's length in a gym is item 98 onward, and it needs a phone with weeks on it.
