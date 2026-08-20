---
id: 20
title: The rules module and its oracle
parent: 17
labels: [wayfinder:grilling]
status: closed
assignee: henk
blocked-by: []
---

## Question

**Where do Hoppa's rules live in Swift, and what proves they are right?**

Hoppa is a rules engine with a screen on it. Progression, the Plate Breakdown, the roll-up, the
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

## Resolution

**The rules become one Swift package that imports nothing, and Swift becomes the only
implementation of them.** No golden file from JavaScript, no second copy of the rules to keep in
step. What proves them right is a test target that runs the same 56 Workouts the design map ran,
in Swift, asserting the invariants at every step and committing the result as a snapshot.

The ticket asked two questions that answer each other, and the answer to the second one changed the
answer to the first. Three facts found while resolving it did that.

### The three facts

1. **There is no Swift toolchain on the VPS.** The agent has been writing Swift it cannot compile.
   The machine is Ubuntu 24.04 x86_64 with 1.7 GB free of 38 GB — but ~3.3 GB is reclaimable from
   `/root/.npm` and `/root/.cache`, so a Linux toolchain fits. **A rules target that imports nothing
   builds on Linux**, which turns "prove the rules" from a Mac round trip into a command this side
   can run.
2. **`design/0015-history/fixture.json` is not a valid golden file.** `gen-fixture.mjs` predates
   [Bounding the Microload](0016-bounding-the-microload.md) and has no roll-up code at all. Its own
   comment admits it: it chose a 0.25 kg Microplate precisely so 16 weeks of Microloading would land
   *under* one Stack Step and never expose the case. Every other rule in it is sound; the roll-up is
   simply absent.
3. **`design/0015-history/check-rollup.mjs` is the only correct roll-up code that exists**, and it
   holds four named cases with both §4.2 invariants asserted — including "the case that broke".

Fact 2 is what killed the golden-file option. Keeping JavaScript as the oracle would mean fixing the
eight defects of §8.2 **twice** — once in JS to make the fixture valid, once in Swift — and then
holding two implementations of a rules engine in step forever. That is the exact class of bug this
ticket exists to prevent.

### Where the rules live

A **local Swift package** at `app/HoppaRules`: one target `HoppaRules`, one test target
`HoppaRulesTests`. One target now — splitting is cheap later, and guessing the split before
[Persistence and the data model](0019-persistence-and-the-data-model.md) runs is not.

**`HoppaRules` imports nothing. Not Foundation.**

- The clock enters as a value: `Timestamp`, seconds since epoch as a `Double`, defined in the
  target. Foundation `Date` is mapped at the boundary by the app.
- The signature is `Rules.reduce(_ workout: Workout, _ action: Action, at: Timestamp) -> Workout`.
  `Action` is an enum with associated values. **`at` is a separate argument, not a field on the
  action**, which is stronger than the prototype: in the JS an action could forget its clock, and in
  Swift no action can. An action that cannot apply returns the state unchanged.
- No SwiftUI, no SwiftData, no date formatting, no locale. A rule you cannot break beats a rule you
  must remember.

**The reducer shape survives, but it reduces a `Workout`, not a screen.** The prototype's `reduce`
mixes real rules with pure view state — `screen`, `overlay`, `draft`, the keypad buffer, `events`.
Those stay in the SwiftUI layer and do not enter the package. A keypad buffer is not a rule, and it
must never be able to fail a rules test. `events` was narration for the prototype page and is
dropped.

**`HoppaRules` owns the domain as value types** — `Program`, `WorkoutDay`, `Exercise`, `Set`,
`PlateInventory`, `Workout`, and the enums `EquipmentType`, `ProgressionMode`, `WeightUnit`. This is
what ticket 19 was blocked waiting for: **storage maps to these types, not the other way round.**

> **A free option for ticket 19.** `Codable` lives in the *standard library*; only `JSONEncoder`
> lives in Foundation. So these types can conform to `Codable` without the rules target importing
> anything. "Plain value types written to disk" is therefore available to ticket 19 at zero cost to
> the zero-import rule — it is not an argument against SwiftData, but it is a real option that was
> not obviously on the table.

### What proves them right

Four layers, weakest last on purpose.

1. **One failing test per defect, first.** `SPEC.md` §8.2 lists eight defects in the logging module.
   The list is already exact — it names the wrong behaviour and the right one — so each becomes a
   named test that fails against the lifted code, and the lift makes it pass. The two summary
   defects ride with the summary screen, not here.
2. **Hand-written invariant tests** for the rules that deserve more than a snapshot: the roll-up's
   *never goes down* and *Microload < one Stack Step* (§4.2), ***at least*** *the planned Sets*
   (§4.1), the **Mode-scoped solver** (§5.3), and `≈ CLOSEST` **rounding down on a tie** (§5.4).
   Plus: a One-off Weight never progresses, and reps above the top raise the weight **once**.
   `check-rollup.mjs`'s four cases port straight across as data.
3. **The nine walkthroughs become the acceptance tests of the logging flow.** All nine, minus their
   UI-only steps (keypad taps, overlays). They are the only validated record of how logging behaves,
   and each was written to demonstrate one rule.
4. **The 56-Workout snapshot.** The lifter simulation in `gen-fixture.mjs` is deterministic — a
   seeded LCG plus a rep model — so it ports into `HoppaRulesTests` and Swift runs the four Workout
   Days, 18 Exercises, 56 Workouts and 16 weeks forward itself. Invariants are asserted at every
   progression. The output is written to `HoppaRulesTests/Snapshots/history.json` and **committed**,
   so drift shows up as a diff in review rather than as a wrong weight in the gym six weeks later.
   One flag re-records it.

**A snapshot proves nothing changed. It does not prove anything is right.** That is why layers 1–3
exist and why they come first. The eight defects are precisely the places where the current code is
wrong, and a snapshot taken of wrong code merely freezes it.

`HoppaRulesTests` **may** import Foundation — it computes calendar dates for the 16 weeks and writes
JSON. The rule that matters is that the *rules* carry no hidden clock; a test that computes a date
does not break it.

**Framework: Swift Testing** (`@Test`, `#expect`), which ships in the toolchain and runs on Linux.
Its parameterized tests turn the nine walkthroughs and the four roll-up cases into data instead of
thirteen near-identical functions.

### The JavaScript, from here on

`design/0007-logging/fitty-workout-logging.html`, `gen-fixture.mjs` and `check-rollup.mjs` stay in
`design/` as **the record of what was validated**. They are a source to lift from, never a build
step and never an oracle. Nothing in the app's build touches Node.

### Naming, which ticket 21 was waiting on

The Swift target is **`HoppaRules`**. [The app is called Hoppa](0021-the-app-is-called-hoppa.md)
said it would take whatever this ticket landed on; it has landed. The prototype's `Fitty` module
keeps its name where it sits, because it is a published artefact and `SPEC.md` §8.3 links it.

### This ticket decides; it does not build

The ticket text asked for "a Swift target Rob can paste into the project", and the map's charter
asks every session to produce something runnable. **Both are refused here, deliberately**, because
of fact 1: with no toolchain on this side, building now means writing several hundred lines of
uncompiled, untested Swift into the one module this ticket calls the part the project has been
wrong about most often. Untested rules do not crash. They quietly put the wrong weight on the bar.

So the build splits into two tickets, and the toolchain goes first:

- **[Swift on the VPS](0022-swift-on-the-vps.md)** — reclaim the disk, install the toolchain, prove
  `swift test` runs green on Linux.
- **[Lift the rules into HoppaRules](0023-lift-the-rules-into-hopparules.md)** — blocked by it, and
  it delivers every test green, not a paste.

**Rob adds the package to Xcode himself**, through *File → Add Package Dependencies → Add Local*.
The agent does not patch `project.pbxproj` for this. It is four clicks against a merge nobody wants
to resolve by hand, and it is the first real exercise of the map's open question about who owns that
file.
