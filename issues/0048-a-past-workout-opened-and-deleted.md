---
id: 48
title: A past Workout opened and deleted, and the Summary's weights that go stale doing it
parent: 17
labels: [wayfinder:task]
status: closed
assignee: agent
blocked-by: [47]
---

## Question

**Opening a row of §6.7's Workout list does two things this app has never done: it reads a Workout
from weeks ago, and it deletes one.**

*"Opening a row shows every Set as performed, from the Set's own stored numbers (§2.5), with the
progression each Exercise earned stated beside its name."*

**Delete lives behind the Workout's `•••` menu**, and it is the one delete in Hoppa that destroys
something:

| | |
| --- | --- |
| What it removes | Every Set of that Workout |
| What it does **not** touch | Every **Working Weight**. Hoppa applied the progression at Finish and never lowers a weight by itself (§4.1); recomputing the chain would also reach past any weight the user later set by hand (§4.3) |
| The confirm | States both halves: what is removed, and that the working weights stay |

The confirm's `DELETE` uses the 25 kg plate red `#C8322B`, and §6.7 says why that is allowed: **a
plate colour is a plate only inside a Plate Breakdown.** Outside one, the palette is Hoppa's
palette. That fixes the boundary of §7.1's first rule.

**`Action.deleteWorkout` does not exist.** Every other §6.6 edit is an `Action` already; this is the
one new write in Flow 4, and ticket 26's rule holds — one door, `LogbookStore.send`.

### The thing this ticket is really for

**[The Workout Summary](0038-the-workout-summary.md) reads its `to` weight off the Exercise's
*live* Working Weight**, and that is right for the screen it was built for: the Summary appears
between Finish and `DONE`, and nothing can edit an Exercise in between. **It is silently wrong the
moment a Workout from three weeks ago can be opened** — the live weight has moved on, and the row
would claim a progression that never happened.

`ProgressionOutcome` already stores the planned Sets and the threshold for exactly this reason, so
the fix is probably one more field. What is **not** sharp, and this ticket must settle it:

- The **Went-up row** is a statement about the past, so it wants the recorded number.
- The **condition line's `→ 75 KG`** is a statement about the *future* — *next time* — and may want
  to stay live. On a Workout from three weeks ago, *next time* may already have happened.

Whether a past Workout's detail is the **same view** as the Summary or a different one is part of
the same question, and answering *different view* may dissolve the problem rather than fix it.

Consult `SPEC.md` §6.7, §6.5, §4.1, §4.3, §2.5, §7.1, `Summary.swift`, `ProgressionOutcome`,
`SummaryScreen.swift`, `Action.swift`.

## Resolution

**A different view, and the artboard is what settled it — which is the answer the ticket
guessed at when it wrote *answering "different view" may dissolve the problem rather than
fix it*.** `design/0015-history/Workout.dc.html` draws no hero count, no three sections, no
condition lines, no volume bar and no `DONE`. It draws a **record**: one Exercise after
another in the order performed, every Set with its own number, and a verdict on the right —
`STAYED`, or a green `25 → 27.5 KG`. `SummaryScreen.swift` is untouched.

### The two halves of the staleness, answered separately

The ticket split the problem correctly and the two halves came apart cleanly.

- **The condition line's `→ 75 KG` is a statement about the future, and a past Workout
  states no future.** `NEXT TIME` and `ALL 3 SETS AT 12 → 75 KG` are both about the session
  *after* this one, and three weeks later that session has already happened. §6.7 prints
  neither. So the half of the problem that was about *the future going stale* does not
  exist on this screen — it was a property of the Summary, and the Summary keeps it because
  it is right there.
- **The Went-up row wants the recorded number, and there was none.** This is the half that
  needed code. It cannot be derived: adding the Increment back reaches an Increment that is
  editable (§2.8), and any weight the user has since set by hand (§4.3) is past recomputing
  altogether. So it is stored, and `ProgressionOutcome` was already the place §2.4 stores
  exactly this kind of fact.

### One field, and it is recorded for every Exercise

`ProgressionOutcome` gained `workingWeightAfter` and `microloadAfter` — **the Working Weight
as it stood when the Workout ended**, read back out of the `Logbook` after the move is
applied rather than off the `ProgressionMove`, because the two differ on a mixed-unit pin.

It is written for **every performed Exercise and not only the ones that went up**, which the
ticket did not anticipate: §6.7's One-off row states *the Working Weight that survived*, and
that number goes stale exactly as fast as a progression's does. One field answers both.

`summary(of:in:)` now reads it too, falling back to the live weight when there is none. On
that screen the two are always the same number, so nothing on it changed — but there is one
rule for the weight a Went-up row states instead of two.

**Old history decodes and reads.** An absent key is `nil`, so a Workout finished before this
build reads back with its verdict and without its numbers: the row says `WENT UP` rather
than inventing a weight. `Fixtures/logbook-before-0048.json` is the pre-change fixture,
committed on purpose, and a test opens it. Walk item 90 says so in Rob's words.

### The delete

`Action.deleteWorkout(WorkoutID)` — the one delete in Hoppa that destroys something, and
**the whole rule is two lines**: the Workout leaves `workouts`, and nothing else happens.
No `updateExercise` call, so no Working Weight can move by accident, which is the second
sentence of the confirm and the reason §4.1 and §4.3 both forbid recomputing the chain.

### The four judgment calls, decided rather than asked

Under the 2026-08-27 rule these are decided here, recorded, and written into
[`HANDOFF.md`](../HANDOFF.md) as items 87–97.

1. **The confirm is Hoppa's own sheet, not a `confirmationDialog`.** Every other confirm in
   the app is the system's, because §6.6 does not paint them. §6.7 paints this one: the
   `DELETE` wears the 25 kg red `#C8322B`, deliberately, to fix the boundary of §7.1's first
   rule. A system dialog cannot carry that colour, and the artboard draws a Hoppa sheet. So
   this one confirm is drawn and the other four stay as they are. Walk item 94 puts the
   trade to Rob directly.
2. **A Skipped Exercise reads `SKIPPED` with no Set rows.** The artboard's Workout has none
   in it. §6.5 lists a skip plain — no warning colour, no icon, no invitation to fix — and
   this is that rule in a second place.
3. **The `•••` menu holds one item rather than becoming a `DELETE` button.** §6.7 gives it
   nothing else, but a destructive action one tap from a scrolling list is not what §6.6
   does anywhere.
4. **The date is composed field by field**, `3 AUG 2026`, and always carries the year. The
   list's own date drops the year in the current one; a screen showing one Workout has
   nothing to compare against, so the shorthand has nothing to lean on. Composing the three
   fields rather than asking for `.day().month().year()` is not cosmetic — that formatter
   orders itself by the phone's locale and answers `Aug 3, 2026` on a US one. `app/checks/Past`
   caught it, on the VPS, before it reached a phone.

**One thing the ticket asked for turned out to be already true.** A rename after a Workout
reads through to the past detail; a *delete* after a rename falls back to the Name the
Workout started under, not the rename. That is §2.4's own clause — the Name **as it read at
the time** — and it is what `Summary` and `Rules.history` already do. A test states it,
because it looks like a bug and is not.

### What is green, all of it on this machine

| Suite | Count | New |
| --- | --- | --- |
| `app/HoppaRules` — `swift test` | 187 | +19, `PastWorkoutTests` |
| `app/HoppaStore` — `swift test` | 49 | unchanged |
| `app/checks/Past/run.sh` | 66 | new |
| `app/checks/UnitStash`, `Reorder`, `Reweigh`, `History` | 34, 25, 34, 33 | unchanged |

`PastWorkoutTests` is built around the one thing this ticket exists for: most of its cases
run a Workout and then **change the world underneath it** — two more progressions, a
re-weigh by hand, an edited Rep Range, a moved Increment, a rename, a delete — and read the
detail again. It also walks all fifty-six Workouts of the snapshot.

`app/checks/Past` is the thin ring `0046` established and `0047` extended: the header's meta
line, the verdict, the One-off chip, the weight text, the date and the confirm's two
sentences, with the SwiftUI dropped. It runs the sixteen-week seed and reads **every one of
its thirty Workouts** back through the screen's own English, so no row on a phone can be the
first one anybody looked at.

Two fixtures were re-recorded on purpose and the diffs reviewed: the rules' `logbook.json`
(the new keys, and `100 lbs + 1 kg` keeping its two units) and the store's copy of it, which
had drifted out of step since 20 August.

### What is left, and where it goes

`Route.pastWorkout` no longer lands on `NotBuiltYet`; `HoppaApp` swaps one `case`, which is
what ticket 0032's spine promised. `SPEC.md` gained the recorded weight in §2.4 and a
**The Workout detail is not the Summary** subsection in §6.7.

Nothing here graduated new fog and nothing was ruled out of scope. One thing carries
forward: [the per-Exercise chart](0049-the-per-exercise-chart.md) fills its Set grid with
**the same fact** `PastSet.metThreshold` holds — read off the recorded threshold, never
green on a One-off — so it should call the rule rather than write the comparison a second
time.

Pushed. A screen ticket closes when it is pushed, not when Rob has seen it (ticket 0029).
