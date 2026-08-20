---
id: 24
title: The view layer around the rules
parent: 17
labels: [wayfinder:grilling]
status: open
assignee:
blocked-by: [19, 23]
---

## Question

**What sits between `HoppaRules` and a SwiftUI view?**

This graduates out of the map's fog now that
[The rules module and its oracle](0020-the-rules-module-and-its-oracle.md) has fixed the boundary.
The fog patch read: *"whether that shape survives as an `@Observable` store, one store per screen,
or something else — and it hangs on what ticket 20 decides the module's boundary is."* It has
decided, so the question is sharp.

What ticket 20 settled, and this ticket must not reopen: `HoppaRules` is a pure reducer over a
`Workout`, importing nothing. `screen`, `overlay`, `draft` and the keypad buffer were **deliberately
left out** of it and have to live somewhere. That somewhere is this ticket.

### Two of these are already answered

[Persistence and the data model](0019-persistence-and-the-data-model.md) closed while this ticket
was blocked, and it settled two of the questions this ticket was written to ask. Do not reopen them.

- **One store, not one per screen.** `@Observable final class LogbookStore` holds the whole
  `Logbook`. It loads, migrates, calls `Rules.reduce` and saves, and it owns the id counter and the
  clock. [The Logbook on disk](0025-the-logbook-on-disk.md) builds it.
- **A reduce becomes a save immediately.** Every mutation writes the file atomically. The file is
  small, and the view state below is deliberately kept out of it, so mutations stay coarse.

### What to settle


- **Where does the view state actually go?** The keypad buffer, the lowering prompt, which overlay
  is up, which Exercise is selected. Inside the store beside the `Workout`, or in `@State` on the
  view that owns it? The prototype kept them together; ticket 20 split them apart on purpose.
- **The Rest Timer.** `restStartedAt` is a `Timestamp` on the `Workout`, so it is pure and it
  survives a reduce. Turning it into a ticking count-up on screen is a view problem, and what it
  does across a lock, a background and a phone call is still fog on the map. Decide only the part
  that touches the store here; leave the backgrounding question where it is unless this answer makes
  it sharp.
- **What is testable, and does it need to be?** The rules have four layers of tests. A store that
  only forwards actions may need none. A store that makes decisions of its own has just become a
  second place where rules live, which is what ticket 20 was built to prevent.

Consult `SPEC.md` §6.4 and §3, `CONTEXT.md`, and ticket 20's resolution.
