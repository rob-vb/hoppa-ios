---
id: 48
title: A past Workout opened and deleted, and the Summary's weights that go stale doing it
parent: 17
labels: [wayfinder:task]
status: open
assignee:
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
