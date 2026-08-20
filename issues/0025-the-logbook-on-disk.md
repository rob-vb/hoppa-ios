---
id: 25
title: The Logbook on disk
parent: 17
labels: [wayfinder:task]
status: open
assignee:
blocked-by: [23]
---

## Question

Nothing to decide — [Persistence and the data model](0019-persistence-and-the-data-model.md) and
[The view layer around the rules](0024-the-view-layer-around-the-rules.md) decided all of it.
**Build `app/HoppaStore` and prove a Logbook survives a force-quit on Rob's phone.**

Zoom both resolutions and treat them as given. Ticket 23 delivers the value types; this ticket gives
them somewhere to live.

> **This ticket was rewritten.** It used to say the store lives in the app target and therefore
> "runs on the Mac and not on the VPS". Ticket 24 found that false: `@Observable` needs only the
> `Observation` module and the file work needs only `Foundation`, and both were proved to compile
> and run on this machine. Almost all of this ticket now happens **here**, and only the last part
> needs the Mac.

### What to build — on the VPS

A second local Swift package, `app/HoppaStore`, beside `app/HoppaRules`. It imports `HoppaRules`,
`Foundation` and `Observation`, and **never SwiftUI**. That ban is load-bearing, not stylistic: it is
what stops view state from creeping back into the store.

- **`@MainActor @Observable public final class LogbookStore`**, with
  `public private(set) var state: LoadState` where
  `LoadState` is `.empty` / `.loaded(Logbook)` / `.unreadable(Error)`.
  `public init(url: URL, now: @escaping () -> Timestamp)` and **one** mutating method,
  `public func send(_ action: Action)`. No named per-action wrappers.
- **It owns the clock, not the id counter.** `nextId` is a field on `Logbook` and `Rules.reduce`
  mints from it — ticket 19 said otherwise and was superseded by ticket 23's code.
- **Synchronous atomic write after every mutation.** Encode, write to a temporary file, rename over
  the target. No background task. A crash must never leave a half-written Logbook.
- **Three load outcomes.** No file → `.empty`, which is §6.1's `KG` standard rack and nothing else,
  and which writes on the first mutation and not before. A good file → `.loaded`. A corrupt file, or
  a file whose `schemaVersion` is **newer** than this build knows → `.unreadable`, with **no
  `Logbook` in hand**, so no view can render training and no view can call `send`.
- **A file that will not decode is never written over.** The rule that protects weeks of real
  training.
- **Migration is additive by default.** A new field gets a default and needs no step. A numbered step
  exists only for a destructive change, works on decoded JSON rather than frozen per-version structs,
  and backs the file up to `logbook-v<n>-backup.json` **before** touching it. Every version bump
  commits a real old-version file as a fixture.
- **The Exercise Name Catalogue (§6.3)** lands here too: a plain Swift array, no rules, no bundle.

### What proves it — on the VPS

Four layers, and deliberately far fewer than the rules have, because the store decides nothing:

1. **Pure**: encode, decode and migrate against committed fixtures. No file touched.
2. **Loading**: missing → `.empty`; good → `.loaded`; corrupt → `.unreadable` **and the file is
   byte-identical afterwards**; newer `schemaVersion` → `.unreadable`.
3. **Writing**: after a save the file decodes back to the same `Logbook`, and no temporary file is
   left behind.
4. **Forwarding**: `send` produces what `Rules.reduce` produces, then saves. **One test, not
   thirteen.**

Run `swift test` in both packages before pushing.

### What still needs the Mac

- Add `HoppaStore` to the `Hoppa` target through Xcode's **Add Local**. Ticket 23's hand-off wrote 23
  additive lines to `project.pbxproj` and changed none; expect the same shape, and check that
  `relativePath` stays relative.
- `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace` in Info.plist, so Rob copies
  `Documents/logbook.json` off the phone through the Files app. **No export screen** — there is none
  in the five flows.
- `@State private var store` in `HoppaApp`, injected with `.environment(store)`.
- **The acceptance test, which is the point of the ticket**: start a Workout, log two Sets,
  force-quit, reopen. The Open Workout is still there, with both Sets, at the same Exercise.

### Two things this ticket must not do

- **Do not put a rule in `LogbookStore`.** The moment it decides something, rules live in two places
  and ticket 20's boundary is gone. It forwards actions; it does not judge them.
- **Do not build a screen.** The acceptance test needs the smallest possible harness, not Flow 2.
