---
id: 24
title: The view layer around the rules
parent: 17
labels: [wayfinder:grilling]
status: closed
assignee: agent
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
  is up. Inside the store beside the `Workout`, or in `@State` on the view that owns it? The
  prototype kept them together; ticket 20 split them apart on purpose.
  **Which Exercise is selected is already answered** and is not view state:
  [Lift the rules into HoppaRules](0023-lift-the-rules-into-hopparules.md) put `currentIndex` on the
  `Workout` with a `.selectExercise` action, so the Exercise Rob was standing at survives a
  relaunch in the middle of a session. The rep counter went the other way — `.logSet(reps:)` takes
  the number, and `targetReps` is a pure query the view prefills from.
- **The Rest Timer.** `restStartedAt` is a `Timestamp` on the `Workout`, so it is pure and it
  survives a reduce. Turning it into a ticking count-up on screen is a view problem, and what it
  does across a lock, a background and a phone call is still fog on the map. Decide only the part
  that touches the store here; leave the backgrounding question where it is unless this answer makes
  it sharp.
- **What is testable, and does it need to be?** The rules have four layers of tests. A store that
  only forwards actions may need none. A store that makes decisions of its own has just become a
  second place where rules live, which is what ticket 20 was built to prevent.

Consult `SPEC.md` §6.4 and §3, `CONTEXT.md`, and ticket 20's resolution.

---

## Resolution

**Between `HoppaRules` and SwiftUI sits one package, and its defining property is what it may not
import.**

`app/HoppaStore` imports `HoppaRules`, `Foundation` and `Observation`, and **never SwiftUI**. That
ban is the whole design: ticket 20 pushed `screen`, `overlay`, `draft` and the keypad buffer out of
the rules on purpose, and a package that cannot see SwiftUI cannot quietly take them back. It is a
compiler rule, not a discipline.

The second thing it buys is bigger than this ticket. **The seam builds and tests on the VPS.** The
charter said the agent cannot compile the app, and for SwiftUI and a simulator that is still true —
but `@Observable` needs only the `Observation` module and the file work needs only `Foundation`, and
both were checked here before the question was put: a small `@Observable` class with
`withObservationTracking` and a `FileManager` call compiles and runs on this machine under
`-swift-version 6`. So the code that can erase Rob's training is provable *here*, next to the rules
it forwards to, and not only on the Mac.

### The store

```swift
@MainActor @Observable public final class LogbookStore {
    public private(set) var state: LoadState   // .empty / .loaded(Logbook) / .unreadable(Error)
    public init(url: URL, now: @escaping () -> Timestamp)
    public func send(_ action: Action)
}
```

- **One `send`, and nothing else that writes.** `Action` is the vocabulary ticket 20 fixed. Named
  wrappers — `logSet(reps:)`, `skip()` — were refused: thirteen methods are thirteen places that can
  grow an `if`, and that is exactly how a second home for rules starts.
- **`@MainActor`, and the save is synchronous** inside `send`, straight after `Rules.reduce`. Ticket
  19 measured the file at a few hundred kilobytes for five years of training; an atomic write of that
  costs about a millisecond, against one logged Set every few minutes. A background save buys nothing
  and pays in write ordering, lost writes, and the window between a mutation and its save.
- **The seam to the file is a `URL`, not a protocol.** A protocol with a real and an in-memory
  implementation would mean the tests never run the atomic write or the backup — the two pieces most
  worth running. The app passes the `Documents` URL, a test passes a temporary directory, a preview
  passes a throwaway one. Encode, decode and migrate stay **pure static functions**, testable with no
  file at all.
- **It owns the clock, and not the id counter.** Ticket 19 said it owned both. It does not:
  `nextId` is a field on `Logbook` and `Rules.reduce` mints from it, which ticket 23 built and
  ticket 19 could not have known. The clock still enters here, as ticket 20 requires.

### Loading has three outcomes, not two

Ticket 19 said a file that will not decode is reported and left alone, but never said what the views
then hold. They hold nothing:

- **No file is not a failure.** A fresh install is `Logbook.empty` — §6.1's kg Plate Inventory and
  nothing else — and it writes on the first mutation, not before.
- **A good file is `.loaded`.**
- **A corrupt file is `.unreadable`, and there is no `Logbook` at all.** The alternative — an empty
  `Logbook` plus a failure flag — makes the app look like a fresh install with every Workout gone
  while the file sits intact on disk. That is a lie told at the worst possible moment. With no
  `Logbook` in hand a view cannot render a training screen and cannot call `send`, so the only thing
  it can do is say what is true: *"Hoppa cannot read your logbook. Nothing was changed."*
- **A file from a newer `schemaVersion` is `.unreadable` too.** It is the one case where Hoppa must
  refuse a file it could technically parse: an older build that decodes a newer file drops the fields
  it does not know, and the save writes that loss back permanently — with a backup from the same
  moment, which does not help. One guard: `schemaVersion > current` stops.

### Migration is additive by default

- **A new field gets a default and needs no step.** Most model changes on this map will be additive,
  and paying for a migration each time is paying for the rare case always.
- **A numbered step exists only for a destructive change** — a field removed, or a field whose
  meaning changed — and it works on decoded **JSON**, not on frozen per-version structs. Freezing
  `LogbookV1`, `LogbookV2` … copies 26 files of value types per bump; it is type-safe and unaffordable.
- **Every version bump commits a real file of the old version as a fixture**, ideally taken off Rob's
  phone. A migration with no fixture is a migration that has never run.
- Ticket 19's rule stands unchanged: back up to `logbook-v<n>-backup.json` **before** migrating.

### What stays in the views

`@State`, on the view that owns it: the keypad buffer, which sheet is up, the *Just today, or from
now on?* prompt, and the `NavigationStack` path. None of it is a fact about training, and none of it
should survive a relaunch — a half-typed number least of all. The *Just today* sheet is the clean
test of the boundary: the sheet is `@State`, and the answer chooses between `.setOneOffWeight` and
`.setWorkingWeight`, both of which the `Workout` already stores.

Views read derived values **directly** — `logbook.resolvedExercise(id)`, `Solver.solve(...)`,
`resolved.thresholdReps`, `resolved.targetReps`. No per-screen slice on the store, and no pure
`loggingScreen(from:) -> LoggingScreenModel` projection either, tempting as the second is for making
§6.4's chip copy testable. `ResolvedExercise` is that layer already and is already tested; a screen
projection is a third model of one set of data, which this map has now refused three times.

The store reaches the views as `@State private var store` in `HoppaApp`, injected once with
`.environment(store)`. There is one store and every screen needs it, so threading it through
initializers is carrying without gain.

### The Rest Timer, and the fog it closes

A `TimelineView(.periodic)` in the view renders `now − restStartedAt`. The store never ticks, so no
timer can drift, leak or outlive its screen.

That all but closes the map's fog patch on backgrounding. **Elapsed time is subtraction**, so a lock,
a backgrounded app and an incoming call need no code whatsoever: the number is simply correct when
the screen comes back, because `restStartedAt` is a pure `Timestamp` that ticket 23 put on the
`Workout`. Only a Live Activity, a notification or a sound would need real work, and the spec asks
for none of the three. The patch is removed from the map rather than sharpened.

### What is tested, and what it does not test

The store decides nothing, so it earns far fewer tests than the rules — but it is the only code on
this map that can destroy weeks of training, so it earns these four:

1. **Pure**: encode, decode and migrate against committed fixtures. No file needed.
2. **Loading**: no file → `.empty`; good file → `.loaded`; corrupt file → `.unreadable`, **and the
   file is byte-identical on disk afterwards**; newer `schemaVersion` → `.unreadable`.
3. **Writing**: after a save the file decodes back to the same `Logbook`, and no temporary file is
   left behind.
4. **Forwarding**: `send` produces what `Rules.reduce` produces, and then saves. **One test, not
   thirteen** — the actions are already tested four ways over in `HoppaRules`.

### Consequences outside this ticket

- **[The Logbook on disk](0025-the-logbook-on-disk.md) moves off the Mac.** It was written as
  Mac-only work in the app target. Everything above builds and tests on the VPS; what stays on the
  Mac is the two Info.plist flags, adding the package in Xcode, and the only proof that matters — an
  Open Workout surviving a force-quit on Rob's phone. The ticket has been rewritten.
- **The Exercise Name Catalogue (§6.3) lands in `HoppaStore`.** Ticket 19 put it vaguely in "the app
  layer"; that layer now exists as a package, and static data with no rules in it belongs there where
  it is testable here. A third package for one array is not worth it.
- **`CONTEXT.md` does not change.** `LogbookStore`, `LoadState` and the package split are
  construction, not domain language, and the glossary stays free of implementation.
- **No ADR.** This ticket is the decision record; the map already does that job.

### Rob's answers

Rob took every recommendation across all three rounds, and confirmed the shared understanding
before any of it was written down.
