---
id: 20
title: The rules module and its oracle
parent: 17
labels: [wayfinder:grilling]
status: open
assignee:
blocked-by: []
---

## Question

**Where do Fitty's rules live in Swift, and what proves they are right?**

Fitty is a rules engine with a screen on it. Progression, the Plate Breakdown, the roll-up, the
Exercise States and the Finish gate are the app; the views only show their output. Those rules are
also the part this project has been wrong about most often — the design map found four defects in
its own rules, and **every one was found by executing them, never by reading them**.

So this ticket is really two questions that answer each other.

### Where the rules live

`SPEC.md` §8.1: `design/0007-logging/fitty-workout-logging.html` holds a pure module `Fitty` —
`initialState`, `reduce`, `breakdown`, `progression` — with no DOM, no timers, and no `Date.now()`;
every action that needs a clock takes an `at`. **It was written to lift.**

- Does it become its own **Swift Package target** that imports nothing — no SwiftUI, no SwiftData,
  no Foundation date handling — so it can only be tested and never accidentally reach a screen or a
  database? That is the strongest version and it costs a mapping layer against
  [Persistence and the data model](0019-persistence-and-the-data-model.md).
- Does the reducer shape survive at all in Swift, or does `@Observable` want something else? Note
  what is load-bearing: **no hidden clock** is, because it is what makes the rules testable.
- §8.2 lists **eight defects** in that module, plus two in the summary prototype. The spec is right
  and the code is wrong. They get fixed in the lift, not ported.

### What proves them right

`design/0015-history/gen-fixture.mjs` already runs these rules forward over **four Workout Days, 18
Exercises, 56 Workouts, 16 weeks** — and it is the only thing that ever ran them further than one
Workout. It is what found the unbounded Microload. `design/0015-history/check-rollup.mjs` does the
same for the roll-up's two invariants across four gyms.

- Do those become **Swift tests**? The generator is a ready-made oracle: port it, and any drift in
  the ported rules shows up as a diff over 56 Workouts instead of as a bug in the gym six weeks
  later.
- Or does the JS stay the oracle, emitting a **golden file** the Swift tests assert against? That
  keeps one implementation of the truth, at the cost of a build step in another language.
- The logging prototype also has **nine walkthroughs** driven headlessly. Are those the acceptance
  tests for the logging flow, or does that flow get its own?
- Which rules deserve a test that is not a golden file — the roll-up's *never goes down*
  invariant (§4.2), *at least the planned Sets* (§4.1), the Mode-scoped solver (§5.3),
  `≈ CLOSEST` (§5.4)?

### The thing worth being stubborn about

This map's destination is real training. A progression bug does not crash — it quietly puts the
wrong weight on the bar, and Rob finds out weeks later with no way to tell what the number should
have been. **The rules deserve tests before any screen does.**

Consult `SPEC.md` §4, §5, §8, and the two generators. The answer becomes a Swift target and a test
target Rob can paste into the project.
