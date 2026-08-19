---
id: 10
title: Exercise name suggestions
parent: 1
labels: [wayfinder:grilling]
status: closed
assignee: henk
blocked-by: []
---

## Question

[Program onboarding flow prototype](0006-program-onboarding-flow-prototype.md) settled that the Exercise name field proposes known names while free text always wins, and that a suggestion sets the name and nothing else. Where do those suggestions come from?

Options to put to the user: a fixed list Fitty ships; the Exercise names the user already created in this Program or an earlier one; both, in one ranked list. Each answer changes what a first-run user sees, because on an empty start there is no history to draw on.

Around that sit the questions the answer drags in: does a shipped list need categories or search beyond a prefix match; does a user-typed name like `Smith incline 30°` become a suggestion for the next time; what happens to a name the user renames after Workouts already exist; and does the list need to be per Weight Unit or per Equipment Type at all, given the suggestion sets neither.

## Resolution

**Two sources, one ranked list.** Fitty ships an **Exercise Catalogue** of about 150 names, and derives a second source from the names the user already created. Own names always sit above catalogue names; a name that appears in both is shown once. The catalogue answers the empty first run — with an own-names-only list, the first Program means typing all 22 names in full. Own names answer every run after that, because once the user has typed `Smith incline 30°` it is the best prediction there is.

Nothing here changes the two rules [Program onboarding flow prototype](0006-program-onboarding-flow-prototype.md) already set: free text always wins, and choosing a suggestion sets the name and **nothing else**. That holds on the edit sheet too — add and edit are the same sheet, so the field behaves identically, and picking a suggestion while editing never touches Equipment Type, Working Weight or Increment.

### The name is a label, not an identity

`Barbell Bench Press` in Day A and in Day C are two Exercises with two Working Weights, and Fitty never ties them together through their names. The alternative — one movement appearing in two Workout Days — would have broken the model that already stands: progression is per Exercise, and a lifter deliberately presses heavier on one day than the other.

Two things follow:

- The own-names source is a **set of strings with the duplicates removed**, not a list of movements.
- **Renaming is free.** The name carries no meaning, so a rename keeps the Exercise's logged Sets and its Working Weight. There is nothing to migrate.

History charts (still fog) can group by name later if they want to; this decision does not force them to and adds no new domain term for it.

### The own-names source is derived, never stored

Fitty reads the names off the Exercises that exist **right now, across all of the user's Programs**. There is no second store of names ever typed.

- Correct a typo, and the wrong name is gone from the suggestions at once.
- Delete an Exercise, and its name goes with it — the one cost, and it is one retype.
- No cleanup screen is ever needed, which a stored name history would have required.

The scope is all Programs, not just the current one, because a new Program is exactly where the old names are worth the most — otherwise the second start is as empty as the first, which is the problem the catalogue was brought in to fix.

### Matching and the empty state

- **Match at the start of any word**, case-insensitive and accent-insensitive. `incline` finds both `Incline Dumbbell Press` and `Dumbbell Incline Press`. Matching only at the start of the string fails exactly where it is needed, because a name often opens with the equipment; loose fuzzy matching (`idp` → `Incline Dumbbell Press`) only adds noise for a user who knows the name and is typing it.
- **On focus, before any typing: the user's own names**, most recently used first, six at most, with no catalogue entries mixed in. By Exercise 7 of a Program the names resemble each other, so this is the cheapest route in the flow — zero letters, one tap. On a first run it shows nothing, and the user types.
- **The catalogue is never browsable.** A browse list would need categories (Chest, Back, Legs …) and a screen of its own, which costs more than typing two letters for a user who already knows the movement they want. The catalogue stays a typing aid.
- **No filter by Weight Unit or Equipment Type.** A suggestion sets neither, so there is nothing to filter on. Filtering by Equipment Type would force every catalogue name to claim one, which is the inference engine [Program onboarding flow prototype](0006-program-onboarding-flow-prototype.md) explicitly rejected. Weight Unit belongs to the rack and the Exercise, never to a name.

### The catalogue itself

- **About 150 names.** A ~50-name core leaves the user typing in full too often, and that first run is what the catalogue exists for. 500+ works against word-start matching: `press` would return thirty rows. At ~150 every match stays short enough to read at a glance.
- **Order is curated and fixed**, shipped with the list — `Barbell Bench Press` above `Barbell Bench Press Close Grip`. Alphabetical order puts variants above the movement they vary, which is almost always wrong. The order never changes between two sessions.
- **Equipment appears in the name only where it distinguishes**, by a mechanical rule: the equipment goes in front as soon as the same movement exists in the catalogue on more than one Equipment Type. `Bench Press` exists as barbell, dumbbell and Smith, so all three carry a prefix; `Leg Press` exists only as plate-loaded, so it stays bare. The rule is checkable against the list, so two people extending the catalogue land on the same name — the reason a per-name judgement call was rejected. Bodyweight follows the same rule: `Pull-up` stays bare while it is the only version in the list, because the added weight lives on the Exercise and not in the name.
- Adding a variant later can force a bare catalogue name to gain a prefix. That never touches existing Exercises: a suggestion **copies** the name at the moment it is picked, and no link survives.

Writing the ~150 names out is content work for the build phase; this ticket fixes the rules that govern them.

### CONTEXT.md

Added **Exercise Catalogue**, and made the Exercise **Name** an explicit term so its label-not-identity status is on the record.
