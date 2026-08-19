---
id: 4
title: Progression edge cases
parent: 1
labels: [wayfinder:grilling]
status: closed
assignee: henk
blocked-by: []
---

## Question

The happy-path progression rules are settled (see `CONTEXT.md`). What happens at the edges? To settle: the user manually overrides the Working Weight; the user logs more reps than the top of the Rep Range (the logging screen now has a `+` button, so this is reachable by design — decided in ticket 2; what it means for progression, and how the screen signals it, is settled here); a long gap between Workouts; switching Progression Mode mid-Program; switching the unit (kg ↔ lbs) with existing weights; whether the progression suggestion is applied automatically next Workout or offered as a one-tap accept.

## Resolution

Settled over three grilling rounds. The unit question reshaped the domain model, so the biggest outcome of this ticket is not an edge case at all — it is that the weight unit belongs to the Exercise, not the Program. New and changed glossary terms are in `CONTEXT.md` (Weight Unit, One-off Weight, Working Weight, Increment, Microloading Increment, Plate Inventory, Equipment Type, Program, Exercise). This section holds the behaviour those terms do not carry.

### Applying a progression

- **Fitty applies the new Working Weight at Finish.** There is no pending suggestion and no acceptance step. The Workout Summary announces the change as old → new, so the user sees it at the moment they can still react.
- Rejected: holding the progression and offering it next Workout. That puts a decision in front of the user in the gym — cold, between Sets, with the bar waiting — and it creates two truths, the stored weight and the pending one.
- Trade-off, named and accepted: a user who progressed by luck must lower the weight themself next time. That makes the manual weight change the escape hatch, so it must be fast.

### Reps above the Rep Range

- Logging more reps than the top of the Rep Range **counts the same as reaching the top**: the weight goes up by the Increment, once. The extra reps are recorded as performed.
- Rejected: a larger jump for more reps. Progression must stay predictable; the user must never meet a weight they did not choose.
- On screen the logged count shows plainly beside the range (`14` · 8–12), with no warning colour. The rule from ticket 3 holds here: the screen shows what happened; it does not scold.

### Changing the Working Weight by hand

- The user changes the weight **inside the Workout**, on the Exercise card. That is where they stand when they find out the weight is wrong.
- **Raising the weight always sticks**, with no question.
- **Lowering it asks once**: "Just today, or from now on?" *From now on* writes the new Working Weight. *Just today* creates a One-off Weight: Fitty logs its Sets, but it never becomes the Working Weight and it never progresses.
- The prompt appears only on the way down, which is the rare direction, so the common edit still costs one tap.
- Reason for the prompt: a bad day is real. Without it, dropping 100 → 90 because of illness erases the record of 100, and Progression climbs back 2.5 kg at a time.
- **A changed weight progresses under the normal rules in the same Workout.** All planned Sets, all at threshold, weight goes up. There is no "unless you edited it" clause: one rule, nothing to remember. (A One-off Weight is the exception by definition — it never writes back.)
- How the Exercise card shows the edit, and whether it marks a One-off Weight in the log, is design: it belongs to [Workout logging clickable prototype](0007-workout-logging-clickable-prototype.md).

### Long gap between Workouts

- **Fitty does nothing.** No deload, no prompt, no confirmation round. The Working Weight after six weeks off is the Working Weight from before.
- Reason: Fitty has no data to pick the right deload; that is a coaching decision. The Workout Day list already shows "Push — 6 weeks ago", which is information, not advice (ticket 3).
- The user lowers the weight themself, which is why the manual change above had to be settled with it.

### Switching Progression Mode mid-Program

- Changing the Mode on the Program **changes the default only**. Exercises without an override follow the new Mode from the next evaluation; Exercises with an override keep theirs. An override is a deliberate act and a Program-level change must not undo it silently.
- A Mode switch **never changes the current Working Weight**. It changes only the rule for next time.
- Exercises that move to Microloading get the default Microloading Increment filled in.
- The Mode that counts is the one in effect **at Finish**, when Fitty evaluates progression.

### Where the Weight Unit lives

The question started as "what happens when the user switches kg ↔ lbs" and became a model change. The user's gym has kg plates, but its machines step in lbs, so a 2.5 kg rise on a stack machine is really 2.3 kg. `CONTEXT.md` said a Program holds one unit and never mixes them. That sentence was wrong.

- **The Weight Unit sits on the Exercise.** The Program keeps a unit as the default for new Exercises only. Barbell work stays kg; the lat pulldown is 100 lbs, +5 lbs. Each screen shows the number the machine shows.
- Rejected: one unit per Program with converted values. 2.3 kg is a number no machine in that gym displays, and rounding it makes the Plate Breakdown lie.
- Rejected: a weight ladder entered per Exercise. A pin stack is evenly spaced, so "Base Weight plus n × Increment" already describes the ladder without the data entry.
- **The Plate Inventory decides the unit** for Barbell, Smith Machine and Plate-loaded Machine — the three Equipment Types with a Plate Breakdown. The user gets no choice there, because you cannot load a plate you do not own. Dumbbell, Machine (stack), Cable and Bodyweight carry their own unit.
- **Working Weight and Increment accept any number** the user types. The presets (2.5 kg, 5 kg for legs) are defaults, nothing more.
- Consequence, accepted: **total volume on the Workout Summary converts** every Exercise to the Program's default unit and shows one labelled number. Volume is a rough progress number, not a loading instruction, so a conversion misleads nobody there — unlike the Plate Breakdown, which stays exact. This lands on [Workout summary screen prototype](0009-workout-summary-screen.md).

### Microloading across units

- The **Microloading Increment is a Microplate the user owns**, not a free number. The user picks it from the Plate Inventory, so an impossible value cannot be entered.
- It keeps the Plate Inventory's unit even when the Exercise uses the other one. A lbs stack machine with a kg microplate displays the instruction as the user performs it: **100 lbs + 1.25 kg**.
- Fitty does the mixed-unit arithmetic itself and never shows the result of it. The user never types 2.76 lbs.
- Progression in Microloading mode adds **one Microplate at a time**.
- The mixed display is [Plate display design](0005-plate-display-design.md)'s to draw.
