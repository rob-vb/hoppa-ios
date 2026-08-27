---
id: 29
title: Build order across the flows, and what done means for a screen
parent: 17
labels: [wayfinder:grilling]
status: closed
assignee: agent
blocked-by:
---

## Question

**Everything under the screens is built. What is left is SwiftUI, and nothing says which screen
first.**

The map has held this since charting, and it was fog for a stated reason: it waited on the store
being proved on a real device. [The Logbook on disk](0025-the-logbook-on-disk.md) passed its
force-quit test on Rob's phone on 2026-08-20, so the condition is met.

What exists now:

- `HoppaRules` — every rule of §3, §4, §5, §6.3 and §6.6, 98 tests green.
- `HoppaStore` — one door, `send(Action)`, 25 tests green, proved on the phone.
- An Xcode project that builds and installs, with the fonts and the palette in it.
- `AcceptanceHarness.swift` and `HarnessSeed.swift`, which are scaffolding the first real screen
  deletes.
- Validated artboards for almost every screen, and `SPEC.md` §6 describing all five flows.

Settle:

- **Which flow is built first, and why.** Flow 2 (logging) is the screen Rob stands in front of at
  the rack and the one with the most rules behind it. Flow 1 (creating a Program) is what makes
  `HarnessSeed` deletable and is the only honest way to get a real Program onto the phone. Flow 5
  shares the Exercise sheet with Flow 1, so those two may be one build rather than two.
- **What "done" means for a screen**, precisely enough that a ticket can be closed. Faithful to the
  artboard, or working and roughly right? The artboards are HTML at a fixed width; a phone is not.
- **How big a screen ticket is**, given that one agent session is 100K tokens and the Mac is a batched
  hand-off. What does a single ticket hand Rob to look at, and how many tickets does a flow take?
- **What the Mac has to see each round**, so the queue in the map's Notes stays one session per
  batch and not one per screen.

Do not decide the drawing technique — [Drawing the loaded bar and the Ignition
confetti](0031-drawing-the-bar-and-the-confetti.md) owns that — and do not decide the appearance —
[Dark only, or a light mode too](0030-dark-only-or-a-light-mode.md) owns that. Both may run in
parallel with this.

Consult `SPEC.md` §6 and §7, `CONTEXT.md`, and the map's Notes on batching the Mac work.

## Resolution

**The way to the destination is eight tickets, and the map's job after this is to hand Rob a
walkable route three times.**

### Build order — the trainable milestone

**Shell + Flow 1 → Flow 2 → Flow 3.** That set is what lets Rob train, and nothing after it is
worth doing first. Flow 5 and Flow 4 come after.

The order was decided by what the destination actually is — *training in his own gym* — and not by
which screen has the most rules behind it. Flow 2 is the screen at the rack, but a logging screen
with no Program in it can only log against `HarnessSeed`, and a fake Program is not the app. **Flow 1
is the only honest way to get a real Program onto the phone**, and it is what makes `HarnessSeed`
deletable. Flow 1 also builds the Exercise sheet, which Flow 5 reuses whole (§6.2 opens from both).

Flow 4 goes last for a second reason that has nothing to do with priority: **a chart needs weeks of
Workouts, so it is not testable before there are any.** Building it first would mean building it
blind and looking at it seeded.

### What "done" means for a screen

**The spec's numbers are the contract; the artboard is the reference.** §7.4 is the part that holds
exactly — padding 20, radii 2–3, hit targets 50 and 64, safe top inset 54 with nothing drawn in it,
the 8/16 rhythm, Anton at line-height 0.78–0.94. Arrangement, copy and palette follow the artboard.
Nothing is measured pixel for pixel, because the artboards are HTML at a fixed width and a phone is
not.

Three readings were on the table and the two rejected ones are worth naming. *Match the artboard*
fails on its own terms: §8.2 already lists **nine** defects in the logging prototype, so the
artboards are a reference with known errors and not a target. *Working and roughly right* fails the
other way — it defers every §7.4 constant to a polish pass that this map has no ticket for.

So, added to the standing rules: **`SPEC.md` beats the artboard wherever they disagree.**

### A screen ticket closes when it is pushed, not when Rob has seen it

This was the process fork, and it decides whether the map keeps moving.

A screen ticket is done when the Swift is written, **every checkable thing is type-checked here**
against the built modules, and it is pushed. Rob's verdict arrives later, out of band. If he dislikes
something, that is a **finding and it takes its own ticket** — the same rule this map already applies
to a rule that turns out wrong.

The alternative — closing only on Rob's eyes — puts his build sessions on the map's critical path,
which is the exact cost he refused at
[The Logbook on disk](0025-the-logbook-on-disk.md) (*"Ik test later wel, geen zin om telkens te
testen."*). Tickets would pile up open and the frontier would stall behind a queue.

The cost of the choice, stated so nobody has to rediscover it: **a closed screen ticket is not a seen
screen.** The map's Notes carry the hand-off queue, and a screen counts toward the destination only
after Rob has looked at it.

### The eight tickets

One ticket = **one screen plus the sheets only that screen opens**. That grain was chosen against
one-ticket-per-flow, which gives four tickets that no longer fit in a 100K session and hand Rob four
large lumps instead of eight small ones.

| # | Ticket | Flow | Blocked by |
| --- | --- | --- | --- |
| 32 | The shell — first run, Workout Day picker, empty state, harness retired | shell | 30 |
| 33 | The Program name, the three assumptions, and the Plate Inventory screen | 1 | 32 |
| 34 | The Program sheet hub and the Workout Day screen | 1 | 33 |
| 35 | The Exercise sheet — §6.2 and §6.3 together | 1 | 34 |
| 36 | The logging screen | 2 | 35, 31 |
| 37 | The weight sheet | 2 | 36 |
| 38 | The Workout Summary, without confetti | 3 | 37 |
| 39 | The Ignition confetti | 3 | 38, 31 |

The chain is linear on purpose: each screen needs the route into it to exist before it can be
reached, so there is nothing here to run in parallel. **The whole chain is blocked today** — 32 waits
on [Dark only, or a light mode too](0030-dark-only-or-a-light-mode.md), because that ticket decides
the *shape* the colours take in code and every screen after it would otherwise hard-code a hex.
36 and 39 wait on
[Drawing the loaded bar and the Ignition confetti](0031-drawing-the-bar-and-the-confetti.md).
**So the frontier after this ticket is 30 and 31, and they are the only two things standing between
this map and eight sessions of SwiftUI.**

### Three hand-offs, and what triggers one

A batch is handed over **when the queue holds a path Rob can walk end to end**, never on a count.
Handing over a screen with no way into it wastes the expensive half of the loop.

| Batch | After | What Rob can walk |
| --- | --- | --- |
| 1 | ticket 35 | From an empty app to a real Program with real Exercises |
| 2 | ticket 37 | Start a Workout, log Sets, change a weight |
| 3 | ticket 39 | Finish, and watch the Summary land |

Each hand-off is **one message with a numbered list**. Every item reads *do X → expect Y*. Item one
is always `git pull` plus a build. The last item is always `git push` if Xcode changed anything.
Underneath sits **what is not built yet**, so a missing thing is never reported as a defect.

### No UI tests

`HoppaUITests` stays as an empty target and nothing is written into it. XCUITest runs only on the
Mac, which is the scarce resource this map spends carefully, and it is slow and brittle. Every rule
under every screen is already tested — 98 in `HoppaRules`, 25 in `HoppaStore`.

**The view layer's proof is two things: a type-check here against the real modules, and Rob's eyes on
the phone.** The rule that keeps that honest is the one this map already has — if a screen grows
logic worth testing, that logic does not belong in the view. It belongs in `HoppaRules` or
`HoppaStore`, where testing is cheap and runs on this machine.

The target is not deleted. Deleting it means editing `project.pbxproj`, which is the one file this
map treats as fragile, and an unused empty target costs nothing.

### Two spec gaps closed on the way

**The first run had no screen.** §6.1 says Hoppa starts empty and §3.1 says the Workout Day list is
home, but nothing said what home shows when there is no Program. It is now **the picker, with
`NOTHING HERE YET` and one `CREATE A PROGRAM` button** — not a jump straight into onboarding. The
picker keeps one role, onboarding becomes an ordinary route to it, and the app never has to decide at
launch which screen is home. §6.6 forbids deleting the last Workout Day, so this empty state is
mostly a first-run state anyway. `SPEC.md` §6.1 gained the paragraph.

**The Program sheet is in two flows at once.** §6.1 step 3 calls it the hub; §6.6 does its edits in
the same screen. Ticket 34 builds **only what onboarding needs** — the Workout Days with their
Exercise counts, `ADD A DAY`, opening a Day, adding an Exercise, the link to Program settings.
Everything left out carries a warning or mirrors into the Open Workout: the two dialogs, stranding,
the Re-weigh list, `currentIndex` following the `ExerciseID`. That is
[Program edits, and which of them are rules](0026-program-edits-and-the-rules-boundary.md)'s work,
none of it is needed to get a first Program onto the phone, and folding it in would have made ticket
34 too big for one session.

### What stays in the fog, and why

Flow 5's remaining screens and all of Flow 4 are **fully specified** in §6.6 and §6.7 — they are
sharp enough to ticket today. They stay in **Not yet specified** anyway, and that is a deliberate
scheduling choice rather than a gap: **their slicing changes with what real training teaches.** This
map already expects findings from the rack, and the history screen and the Program edits are exactly
where those findings land hardest. They graduate after Rob has trained with Flow 1–3.

### Scaffolding

`AcceptanceHarness` is deleted at ticket 32, which replaces it. **`HarnessSeed` survives, behind a
debug switch** — Flow 4 will need sixteen weeks of history to look at, and typing that on a phone is
not a test.

## Superseded on the scheduling half — 2026-08-27

**The build order stands. The hand-off rule does not.**

This ticket said a batch goes over *when the queue holds a path Rob can walk end to end*, and it
sliced the route into three hand-offs for that reason. Rob ended it on 2026-08-27: *"Ik wil alles
op het eind testen, en ik wil eerst alles bouwen. Ik vind namelijk dat onze wayfinder veel te lang
duurt."*

**The evidence is on his side.** Batches 2, 3 and 4 were pushed and none of them was walked, so the
rule bought nothing it promised — an early hand-over only helps if it is taken up. What this ticket
got right is the *order*: shell + Flow 1 → Flow 2 → Flow 3 → Flow 5 → Flow 4, and that order is
untouched, including the reason Flow 4 goes last.

What changes: **the batch is the whole app**, there is one walk, and
[`HANDOFF.md`](../HANDOFF.md) is one growing document rather than a message per batch. The three
rules of *what done means for a screen* — the spec's numbers are the contract, a screen ticket
closes when it is pushed, and no UI tests — all stand exactly as written.

**One rule is added by the change**, and it lives in the map's Notes: a session that would have
asked Rob a UI question now decides it, records why, and writes it into `HANDOFF.md` as something
to look at. Building everything first only saves time if it does not become a question round.
