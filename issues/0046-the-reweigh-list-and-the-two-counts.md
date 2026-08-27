---
id: 46
title: The Re-weigh list, and the two warnings that count before they fire
parent: 17
labels: [wayfinder:task]
status: closed
assignee: agent
blocked-by: []
---

## Question

**§6.6's two rack switches each warn with a count, and one of them lands on a screen that does not
exist.**

- **Changing the Plate Inventory's unit** clears the Working Weight, Increment and Base Weight of
  every Barbell, Smith, plate-loaded and Bodyweight Exercise in **every** Program, resets every
  Microloading Increment, and creates or destroys a Microload on every Machine (stack) and Cable.
  It warns first — `THIS CLEARS THE WEIGHT ON 12 EXERCISES` — and the confirm leads to
  **one Re-weigh list**: every affected Exercise on one screen, each with an empty weight field.
- **Switching a Microplate off** warns with `3 EXERCISES USE THIS PLATE`, and the stranded
  Exercises fall into the empty state §6.2 already draws.

**The Re-weigh list is not a list anyone writes down.** *"The Re-weigh list is every Exercise with
no Working Weight, which is what the switch has just made them. Leave the screen, close the app,
come back a day later, and the same Exercises still have no weight — so the same list appears,
without anything having to remember it."* Ticket 26 made that possible by turning
`Exercise.workingWeight` into a `Weight?`, and it named this as the first thing that falls out.

**Both counts are rules by the map's own test** — they are decided by the `Logbook` alone and two
lifters with the same `Logbook` must read the same number — and **the count is the same rule as the
list**, asked before the switch instead of after. So one rule answers both, and it needs tests.

`Action.setPlateInventoryUnit` and `Action.setPlate` are built and green; nothing here is a new
write. What is open:

- The rule that answers *which Exercises*, in `HoppaRules`, with the count falling out of it.
- The Re-weigh list screen, and **how a weight is typed on it** — the weight sheet of §6.4 is built
  for a Workout, and this is the kitchen table.
- **Where it appears from**: after the confirm, and again on its own the next time the user opens
  the app with weights still missing. §6.6 says the list simply *is*; the door to it is not
  specified, and it must be, or a user who leaves the screen never finds it again.

Consult `SPEC.md` §6.6, §5.1, §5.2, §2.8, `Rules+Edit.swift`, `PlateRackScreen.swift`,
[Program edits, and which of them are rules](0026-program-edits-and-the-rules-boundary.md).

## Resolution

**The rule half was already standing. The screen, the way a weight is typed on it and the two doors
are this ticket's work — and a fourth thing the ticket did not name: a stale One-off Weight the
unit switch left in an Open Workout.**

### What was already there, and what it cost to check

`Rules.reweighList`, `Rules.exercisesClearedByInventoryUnit` and `Rules.exercisesUsingMicroplate`
were built at ticket 45's *four questions a screen asks before the act*, and
[The Program name, the three assumptions, and the Plate Rack screen](0033-the-program-name-and-the-plate-rack.md)
had already wired both warnings — count and copy — into `PlateRackScreen`. Both were green. So the
ticket's first claim, *the count is the same rule as the list*, needed no new rule: it needed the
screen the count leads to.

### The one new write, and why it is not one of the two that exist

`Action.reweigh(ExerciseID, Weight)`.

- **Not `.setWorkingWeight`.** That is *an edit at the rack*: it reads the Open Workout's current
  Exercise, refuses without one, and clears the One-off standing on it. The Re-weigh list is the
  kitchen table — twelve Exercises across every Program, none being performed — and can borrow none
  of it.
- **Not `.saveExercise`.** That carries a whole sheet through §6.6's diff. This list shows one
  field, and assembling a draft from stored fields would make every re-weigh a full save of rows
  the user never saw.
- **It accepts zero, and that is the point of it.** Zero is a real weight (§2.8) — a Bodyweight
  Exercise done with no belt — and it is the only true answer for a chin-up the switch has just
  cleared. `.setWorkingWeight` refuses zero because a weight at the rack always had one; the
  kitchen table is where an Exercise gets its first. Refuse it here and that row can never leave
  the list.
- It stores under the unit the Exercise **resolves to**, so a mislabelled `Weight` is relabelled,
  never converted (§5.1).

### The defect the ticket walked into

**A rack unit switch left the Open Workout's One-off Weights standing.** A One-off is a number for
today in the Exercise's unit (§4.3), and `logSet` prefers it to the Working Weight — so a One-off
that survives the switch is exactly the stale number §6.6 exists to prevent, and the next Set would
have been written at the old number under the new label. `setPlateInventoryUnit` now clears it, on
the four types that read the rack only: a Dumbbell in lbs was never touched by the switch. **The
Sets already logged are not touched and must not be** — a Set records the weight as performed
(§2.4), and those really were lifted. Walk item 75.

### The three §6.6 left open, decided rather than asked

Under the 2026-08-27 rule these went onto the walk list, not to Rob.

1. **The weight is typed inline, one decimal field per row — not in §6.4's `WeightSheet`.** §6.6's
   own argument for this screen is that *paying its cost once at the kitchen table beats meeting it
   twelve times at the rack*; twelve full-screen keypads, each opened and dismissed, puts the twelve
   back. The Exercise sheet is the other kitchen-table screen that asks for a Working Weight and it
   asks with a decimal field, so this is the idiom the user already has. **§5.4's closest line comes
   along anyway**, drawn under a row the moment its number parses — a weight the new rack cannot
   build is precisely what a change of gym produces. The field **writes when it is left**, never per
   keystroke: a write per digit sends `13` to disk on the way to `135`, and each of those is a
   Working Weight a Summary could progress from. Walk items 65 and 67.
2. **The list is frozen while the screen is open.** The rule is *has no Working Weight*, so a row
   would leave the list on its first digit and the rows under the user's thumb would move. Ids are
   read once, on open; each keeps its place until the screen is left; re-entering re-derives. Walk
   item 66.
3. **Two doors, and the second is a banner and not a sheet.** The confirm leads to the list, as
   §6.6 says. The second is a card at the **top** of the picker — `3 EXERCISES HAVE NO WEIGHT` ·
   *They log no sets until you weigh them* — for as long as the condition is true. Without it a user
   who leaves the screen never finds it again, because nothing wrote the list down. **A sheet at
   launch was rejected**: the list holds *every* Exercise with no Working Weight, including one
   added last night on purpose, so a modal would ambush the user with his own decision. §7.6 —
   Hoppa states its condition where the user stands. The **foot** of the picker stays §6.7's History
   door, which is ticket 47's. Walk items 71–73.

A fourth, smaller: **a row states what else the switch cleared, and the statement is the door.** The
switch clears the Increment and the Base Weight too, and this list shows one field. An Exercise
re-weighed but still without an Increment does not progress (§4.1), so the note under the name reads
`no base weight`, `no increment` or `no microplate` and taps through to the Exercise sheet. Stating
it beats filling it quietly, and it beats growing this screen into a second Exercise sheet. Walk
item 68.

### What landed

- `app/HoppaRules/Sources/HoppaRules/Action.swift` — `case reweigh(ExerciseID, Weight)`.
- `app/HoppaRules/Sources/HoppaRules/Rules+Edit.swift` — its reducer, and the One-off fix inside
  `setPlateInventoryUnit`.
- `app/Hoppa/Hoppa/ReweighScreen.swift` (new) — the screen.
- `app/Hoppa/Hoppa/Route.swift`, `HoppaApp.swift` — `case reweigh`, carrying **nothing**: a route
  holding the ids would be a copy that goes stale on the first weight typed, and it could not serve
  the second door, which opens days later with nothing in hand.
- `app/Hoppa/Hoppa/PlateRackScreen.swift` — the confirm pushes the list; the dialog's last sentence
  now says the next screen asks.
- `app/Hoppa/Hoppa/WorkoutDayPicker.swift` — the banner.
- `SPEC.md` §6.6 — *The list has two doors, and it asks for one field*, plus the One-off paragraph.
- `HANDOFF.md` — walk items 62–75.

### Green on the VPS

`HoppaRules` **156** (was 151; five new — the write, zero, the relabel, a refused id, and the stale
One-off), `HoppaStore` **36**, `UnitStash` **34**, `Reorder` **25**, and **`app/checks/Reweigh`
(new) 34** — the screen's ring without SwiftUI: freeze, typed, commit, missing, the intro line and
the banner's copy, every write going through `Rules.reduce`. `swiftc -parse` is clean on all five
touched app files. **What only the phone can answer** is on the walk list: whether the inline field
beats a keypad, whether the closest line reads as useful or as noise, and whether the banner is loud
enough where it stands.
