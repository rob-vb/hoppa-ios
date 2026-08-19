---
id: 14
title: Editing a Program over time
parent: 1
labels: [wayfinder:grilling]
status: closed
assignee: henk
blocked-by: []
---

## Question

Flow 5, graduated from the map's fog. The map charted a Program being **created**
([Program onboarding flow prototype](0006-program-onboarding-flow-prototype.md)) and
**performed** ([Workout logging clickable prototype](0007-workout-logging-clickable-prototype.md)),
and never charted it being **changed**. A Program is a living document — a lifter swaps an
Exercise out in week three — so this is a hole in the three validated flows, not a new feature.

Two halves. The second is the reason this is a grilling ticket and not a prototype ticket.

### The screens

- Reorder Workout Days, and reorder Exercises inside a Day.
- Add and remove a Workout Day; add and remove an Exercise.
- Change Sets, Rep Range, Increment, Equipment Type on an Exercise that already has logged Sets.
  Add and edit are the same sheet
  ([Program onboarding flow prototype](0006-program-onboarding-flow-prototype.md)), so most of
  this may already be drawn — the question is what the sheet does differently once history
  exists.
- Where editing lives: the Program sheet is the hub, but the user finds a wrong Rep Range while
  standing at the rack. Is a mid-Workout edit a Program edit, a One-off, or both?

### The data rules — widened by [Microplate accumulation](0011-microplate-accumulation.md)

These decide what a build may safely store, and none of them has an answer:

- **Changing an Exercise's Weight Unit after Workouts exist.** kg → lbs on a stack machine.
  Does the Working Weight convert, or does the user retype it? The map's standing rule is that
  units never convert, but that rule was written for *display*, and here the stored number
  itself must move or be re-entered.
- **The Microload appears and disappears with that change.** It exists only where the Exercise's
  unit differs from the Plate Inventory's. Switching the Exercise's unit to match the Inventory
  destroys the Microload; switching it away creates one from nothing. What is the weight
  immediately after?
- **Switching a Microplate off in the Plate Inventory strands every Exercise using it** as its
  Microloading Increment. Same for changing the Inventory's unit, which re-units every Barbell,
  Smith and Plate-loaded Exercise in every Program at once.
- **Deleting an Exercise deletes its name from the suggestions**
  ([Exercise name suggestions](0010-exercise-name-suggestions.md) accepted that cost). Does it
  delete its logged Sets, and what does that do to history (flow 4)?
- **Changing Sets or the Rep Range mid-Program** changes the progression threshold. An Exercise
  part-way through a Workout with 3 of 4 Sets logged, whose planned Sets drops to 3, is suddenly
  Completed. Does progression fire?

### Constraints already fixed

- Progression is per Exercise and needs **all planned Sets**
  ([Workout session lifecycle](0003-workout-session-lifecycle.md)).
- The Name is a label, not an identity, so renaming is free and costs no migration
  ([Exercise name suggestions](0010-exercise-name-suggestions.md)).
- Fitty never lowers a Working Weight by itself
  ([Progression edge cases](0004-progression-edge-cases.md)).
- The Exercise always holds both Increments, so switching Progression Mode re-asks nothing
  ([Microplate accumulation](0011-microplate-accumulation.md)).

Take the data rules first; the screens follow from them. Expect this to surface a prototype
ticket for the editing screens once the rules are settled.

## Resolution

The ticket asked what editing does to stored data. Working the first question moved the ticket:
**the model had no place to put the past.** §2.5 gave a Set the rep count only, and read the
weight live off the Exercise. Progression then raises that weight at Finish, so every past
Workout already showed the wrong number — before any edit. Editing did not create that defect,
it exposed it. Fixing it first turned three of the ticket's five data rules into consequences.

The screens half turned out to be nearly free, and the ticket's own prediction — that it would
surface a prototype ticket — was **declined**. The rules go into `SPEC.md` as text and the map
ends after [History and progression charts](0015-history-and-progression-charts.md).

### 1. A Set stores the numbers; Fitty looks up the name

**A Set holds the reps, the weight, the Weight Unit, the Microload and the One-off mark, as
performed.** No later edit changes them. Per **Set** and not per Exercise, because §6.4 lets the
user raise the weight part-way through an Exercise, so the Sets before that raise were lifted
lighter and a per-Exercise weight would lie about them.

The **Name is looked up live** while the Exercise exists, and falls back to a copy stored on the
Workout only after a delete. This keeps *the Name is a label, not an identity*
([0010](0010-exercise-name-suggestions.md)) whole: a rename fixes a typo everywhere, because a
name is not a fact of the lift. The weight is.

**A Set does not store its Plate Breakdown** — only the weight. The breakdown is a solve, not a
fact: §5.4 already logs Sets against the Working Weight and never against the load on the bar.
Storing the picture would make every Plate Inventory edit a history migration, to answer a
question nobody asked.

### 2. An edit at the rack is a Program edit

The Exercise sheet opens from the Exercise card during a Workout, and **every change sticks at
once and everywhere**. Sets, Rep Range, Increment and Equipment Type get no *Just today* question.
The weight keeps the one it already has ([0004](0004-progression-edge-cases.md), §4.3).

The reason is that the lifecycle already covers the two temporary cases: "fewer Sets today" is
ending the Exercise early ([0003](0003-workout-session-lifecycle.md)), and "lighter today" is the
One-off Weight. What is left when you edit at the rack is a real plan change. Extending the
One-off question to every field would tax every edit to serve a case that is already served.

Reorder, add and remove follow from this — mid-Workout they take effect at once, the `3 / 5 ▾`
counter renumbers, and an Exercise added mid-Workout arrives Open and gates Finish like any other.

### 3. Progression takes **at least** the planned Sets

§4.1's first condition changes from *all planned Sets* to **at least the planned Sets**, evaluated
at Finish against the Exercise as it stands then. One word, and the whole class of arithmetic
surprises goes away:

| Case | Result |
| --- | --- |
| 3 of 4 logged at the top, planned Sets dropped to 3 | Progresses. Three Sets at the top, and the plan asks for three. |
| 3 logged at 12 under 8–12, range changed to 8–10 | Progresses. Every Set beat the range that now stands. |
| 4 logged, planned Sets dropped to 3 | Progresses. *At least* covers it; *exactly* would not. |

**Raising planned Sets reopens a Completed Exercise** when it holds fewer logged Sets than the new
plan. Finish is gated again and the user logs the missing Set or ends early. The alternative —
Completed stays Completed — takes away a progression the user earned and offers no way to earn it
back the same day. Nothing fires mid-Workout: the rule chip restates the condition the moment the
edit lands (`+2.5 KG IF ALL 3` → `+2.5 KG IF ALL 4`), so the cost of the edit is visible before
Finish.

### 4. Changing a Weight Unit clears the weights

For the four Equipment Types that carry their own unit — Dumbbell, Machine (stack), Cable,
Bodyweight — **changing the Weight Unit clears the Working Weight, the Increment and the Stack
Step**, and the same sheet asks for them again in the new unit. The Microloading Increment
survives untouched: it keeps the Plate Inventory's unit whatever the Exercise does.

Converting was rejected because it produces numbers no machine can make. `100 lbs` on a 10 lbs
stack becomes `45.4 kg` in steps of `4.54 kg`, with an Increment of `2.27 kg`. The map's rule
*units never convert* was written for display; this extends it to the stored number, which is the
honest reading of it.

The **Microload follows as a consequence and never carries across**. Match the Plate Inventory's
unit and the Microload is deleted. Differ from it and an empty Microload appears at zero, for the
next Microloading progression to fill.

### 5. Changing the Plate Inventory's unit hands over a Re-weigh list

The same rule at full blast radius. One switch clears the Working Weight, Increment and Base
Weight of **every** Barbell, Smith and plate-loaded Exercise in every Program, resets every
Microloading Increment (the other unit's Microplates all ship off, §5.2), and creates or destroys
a Microload on every remaining Exercise.

So Fitty warns with the count — `THIS CLEARS THE WEIGHT ON 12 EXERCISES` — and confirming leads to
**one Re-weigh list**: every affected Exercise with an empty weight field, on one screen. The user
changes this switch when they change gym or country, so it is rare and deliberate; letting it
ambush them across twelve future sessions at the rack is the worse cost. Blocking it locks a real
event out of the app.

**Fitty holds one Plate Inventory.** Several saved racks, one per gym, is ruled out of scope.

### 6. Switching a Microplate off strands, and says so

The switch warns with the count — `3 EXERCISES USE THIS PLATE` — and the affected Exercises fall
into the empty state §6.2 already draws: `NO MICROPLATES · SET UP YOUR RACK`, tapping through to
the Inventory. Such an Exercise does not progress until a plate is picked, and the Summary states
that condition in place of the green line.

Fitty **never re-points to the nearest remaining Microplate**, which would change the steel the
user hangs on the bar without telling them, and it never blocks the switch, which would lock a
rack the user owns out of their own settings.
[0013](0013-plate-inventory-shipped-defaults.md) fixed the principle: Fitty states its condition
where the user stands, and never makes them hunt for a reason. The screen already exists, so this
costs one warning string and no new design.

### 7. A delete cannot destroy history

Decision 1 makes every Set hold its own numbers, so this is only about what Fitty shows and what
it refuses.

- **Delete an Exercise**: it leaves the Program from today forward. Past Workouts keep their Sets,
  labelled by the Name stored at the time. The Name leaves the suggestions — a cost
  [0010](0010-exercise-name-suggestions.md) already accepted.
- **Delete a Workout Day**: the same, and the Workout stores the Day's name too.
- **Delete an Exercise with Sets in the Open Workout**: those Sets stay and the Summary counts
  them. The user lifted them.
- **Refusals**: Fitty blocks the delete of the Workout Day the Open Workout runs on
  (`FINISH YOUR WORKOUT FIRST`), and the delete of the last Workout Day in a Program, which could
  not be started.
- **Confirm** is plain, with no count of destroyed Sets, because nothing is destroyed.

**Deleting a past Workout** — a bad record, a session logged twice — is a history screen, and
history has no screens yet. It moves to [History and progression charts](0015-history-and-progression-charts.md).

### 8. What follows from rules already fixed, with nothing to decide

- The Program's Weight Unit is a default for new Exercises only, so changing it touches nothing
  that exists.
- Changing the Program's Progression Mode changes every Exercise that does not override it, which
  re-solves their Plate Breakdowns ([0011](0011-microplate-accumulation.md)). With no Microplate
  on, [0013](0013-plate-inventory-shipped-defaults.md) already opens the Microplate group in
  place.
- Reordering Workout Days is cosmetic: a Workout records which Day was performed, and picking is a
  free pick with no rotation ([0003](0003-workout-session-lifecycle.md)).

### 9. No prototype ticket

Add and edit are the same sheet (§6.2) and the empty states come from §6.2 and §5.2, so the only
screens without precedent are the Re-weigh list, the two warning dialogs and the reorder handles.
The user chose to spec them rather than draw them. The map's frontier is therefore
[History and progression charts](0015-history-and-progression-charts.md) alone.

### Written to

- `SPEC.md` §2.4, §2.5, §4.1, §5.2, **new §6.6 (flow 5)**, §9, §10, §11.
- `CONTEXT.md`: **Set**, **Workout**, **Progression**, **Exercise State**, **Plate Inventory**.
