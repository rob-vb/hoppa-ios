---
id: 3
title: Workout session lifecycle
parent: 1
labels: [wayfinder:grilling]
status: closed
assignee: henk
blocked-by: []
---

## Question

How does a Workout live from start to finish? To settle: how the user picks the next Workout Day (free pick vs. suggested rotation); starting a Workout; finishing early or abandoning one; skipping sets or exercises mid-workout; what a partially completed Workout means for progression; whether a Workout can be resumed later the same day.

## Resolution

Settled over three grilling rounds. The glossary terms are in `CONTEXT.md` (Workout, Finish, Discard, Workout Summary, Exercise State). This section holds the behaviour those terms do not carry.

### Picking and starting

- **Free pick, always.** Fitty never chooses the Workout Day and never pre-selects one. No rotation, no suggestion.
- The Workout Day list shows **when the user last did each Day** ("Push — 4 days ago"). That is information, not a suggestion.
- A Workout starts on an **explicit action**. It does not start when the first Set is logged. This gives a warm-up window before Set 1 and makes the start moment unambiguous for duration.
- **One Open Workout at a time.**

### Exercise states

Three states: Open, Completed, Skipped. The distinction the user insisted on: **navigating past an Exercise means "later"; skipping means "not at all"**. These must never be conflated in the UI.

- An Exercise becomes Completed **automatically** when the user logs all planned Sets. This is the normal path and costs no taps.
- A **"Done early"** action completes an Exercise with fewer Sets. It exists because stopping at 2 of 3 Sets is real work, and calling it Skipped would be a lie.
- A Skipped Exercise can be **reopened** in the same Workout (the busy-rack case).

### Ending a Workout

- **Finish is gated**: Fitty allows it only when no Exercise is Open.
- The gate has a **shortcut**, because the gate would otherwise bite hardest when the user wants to leave. Tapping Finish with Open Exercises left prompts: "3 Exercises are still open. Skip them and finish?" One tap skips them all and finishes. Nothing becomes ambiguous — every Exercise still ends Completed or Skipped.
- **Discard** exists. It sits in a menu, never beside Finish, and asks for confirmation. A Workout with no logged Sets discards without a question.
- Fitty **never ends a Workout by itself**, at any time interval.
- An **Open Workout from an earlier day** is not closed silently. On next open Fitty asks: resume, finish, or discard. A Workout finished the next day still belongs to **the day it started**.

### Progression

Evaluated **per Exercise, never per Workout**. An Exercise progresses only when the user logged all planned Sets and every Set met the threshold of its Progression Mode.

Deliberate consequence, accepted by the user with the trade-off named: **"Done early" never progresses**, even when every logged Set hit the top of the Rep Range. Two Sets at 12 reps out of a planned three does not raise the weight. The reason: otherwise the user progresses by doing less, and the weight climbs faster than the strength. The user is the first test user and expects this rule to bite; revisit if it does.

### Workout Summary

Shown after Finish.

- **Leads with the Exercises whose Working Weight went up**, each as old → new weight. That is the reason for the celebration, so it is the thing the user reads first.
- Duration, total Sets, and total volume sit under it, smaller.
- **Skipped Exercises are listed plain at the bottom** — no warning colour, no icon, no invitation to fix. The screen shows what happened; it does not scold.
- **Confetti scales with the count** of progressed Exercises, not a percentage. One Exercise gives a small burst; every Exercise in the Workout gives a full screen. **Zero progressed means no confetti** — the screen stays calm.

The screen itself is not designed here. See [Workout summary screen prototype](0009-workout-summary-screen.md).
