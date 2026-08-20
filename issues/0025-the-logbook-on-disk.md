---
id: 25
title: The Logbook on disk
parent: 17
labels: [wayfinder:task]
status: open
assignee: rob
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

## Resolution

> **This ticket stays open, and it is claimed by Rob.** Its stated deliverable is *prove a Logbook
> survives a force-quit on Rob's phone*, and that is not proven: the VPS has no SwiftUI, so the app
> target is written and pushed but never compiled. Everything below is done; the last section is
> the hand-off. Close it when the force-quit test passes on the device.

**`app/HoppaStore` is built and 27 tests are green on the VPS.** The half of the ticket that
needs the Mac is prepared but unproven, and the ticket is not finished until Rob runs it — see
**What is waiting on the Mac** below.

The store came out as ticket 24 drew it, and the code is unremarkable, which is the point: `send`
is four lines, and three of them are guards. Four things are worth more than the code.

### `nextId` was not the only thing ticket 19 got wrong — but the rest of the seam held

The one correction is in the fog patch that had been sitting under "additive migration", and it is
a Swift fact rather than a design one:

**"A new field gets a default and needs no step" is only true for an `Optional` field.** Swift's
synthesised `Codable` decodes an `Optional` property with `decodeIfPresent` and every other
property with plain `decode` — so a **non-Optional** property fails on a file written before it
existed, *even when `init` gives it a default value*. Ticket 24 stated the rule without that
qualifier, and a session six months from now would have added `var restGoal: Int = 90`, shipped it,
and made every existing logbook `.unreadable`.

Two tests pin it down in both directions: a file with `openWorkout` removed decodes and yields
`nil`; a file with `nextId` removed does not decode. The sharpened rule is in
`app/HoppaStore/README.md`, next to the step table, which is where someone bumping the schema will
be looking.

### The migration engine is tested, and there is nothing to migrate

`LogbookFile.steps` is empty and `currentSchemaVersion` is still 1, so the engine had no real work
to prove it on. Machinery whose first run is on Rob's phone is machinery that has never run, so
`migrate` takes a step table as an argument and the tests supply a synthetic one: steps chain,
each stamps its own `schemaVersion` so a step cannot forget to, a missing step is an error rather
than a silent skip, and a throwing step stops the chain.

The backup is checked with a real file too — a v0 logbook is copied to `logbook-v0-backup.json`
**before** the load discovers it has no path forward. That ordering is the whole point: the copy
happens before anything can go wrong, not after.

### `.atomic` is the temporary-file-then-rename, and hand-rolling it would have been worse

The ticket said "write to a temporary file, rename over the target". `Data.write(to:options:.atomic)`
*is* that, done by Foundation: a sibling temporary and a `rename(2)`. Writing it out by hand would
mean hand-rolling the one code path that must behave identically on Darwin, where it ships, and on
Linux, where it is tested — `replaceItemAt` being the obvious candidate and the obvious risk. The
test asserts the directory holds `logbook.json` and nothing else, and re-breaking the write into a
leaky rename fails four tests.

### One guard is deliberately un-provable today, and says so

`send` refuses when there is no `Logbook`. No test can currently fail if that guard is replaced by
a fallback to `Logbook.empty` — because **`Logbook.empty` is a fixed point under every action there
is**: all twelve need an Open Workout or a Program, and an empty Logbook has neither. It stops
being harmless the moment
[Program edits, and which of them are rules](0026-program-edits-and-the-rules-boundary.md) lands an
action that creates a Program: then the fallback writes a brand-new Program over a logbook Hoppa
merely failed to *read*. The guard and its test both carry that note, so ticket 26 inherits a test
to write rather than a hole to find.

The neighbouring property **is** load-bearing: `logbook` returns `nil` for `.unreadable`, and
re-breaking it to return `Logbook.empty` fails six tests. Every guard was re-broken; five of six
turned a suite red, and the sixth is the one above.

### The Exercise Catalogue is written

157 names in `ExerciseCatalogue.swift`, a plain array of strings and nothing else, curated by body
region with the base movement above its own variants. §6.3's two conventions are both checkable
against the list of strings alone — which is why the spec chose them — so both are tests:

- **The prefix rule.** A bare name is never the tail of a prefixed one. `Bench Press` bare beside
  `Barbell Bench Press` fails six tests; that is exactly the mistake §6.3's mechanical rule exists
  to make impossible.
- **The order.** A name that extends another by trailing words is listed below it.

`SPEC.md` §6.3 and `CONTEXT.md` now point at the file. §10 keeps its entry unchanged: it is the
design map's record of what it handed to the build, and the build has now done it.

**What is not built is the matching and ranking** — word-start, case- and accent-insensitive, own
names first, six on focus. Those are rules, they need Foundation to fold accents, and `HoppaRules`
imports no Foundation. They have no home, and this ticket did not invent one. It graduates as
[Name suggestions, and where a rule that needs Foundation lives](0027-name-suggestions-and-foundation.md).

### Ticket 23's fixture is the store's fixture

`Tests/HoppaStoreTests/Fixtures/logbook.json` is a copy of the one `HoppaRulesTests` records from a
real run of the rules: two Workouts, both units, a Microload on a pin, an Open Workout mid-Set. A
hand-written fixture would only have proved that the store can read what the store wrote.

## What is waiting on the Mac

Everything below is written and pushed but **not compiled** — the VPS has no SwiftUI. Rob pulls,
builds, and reports back.

- **The Xcode project is already patched.** `project.pbxproj` carries the same **16 additive lines**
  that *Add Local…* writes, with `relativePath = ../HoppaStore` — relative, like ticket 23's — plus
  `INFOPLIST_KEY_UIFileSharingEnabled` and `INFOPLIST_KEY_LSSupportsOpeningDocumentsInPlace` on both
  configurations, so `Documents/logbook.json` comes off the phone through the Files app. This
  project generates its Info.plist from build settings, so there is no plist file to edit. Nothing
  was changed, only added. If Xcode disagrees: `git checkout` the project file and use *Add Local…*.
- **The app target.** `ContentView.swift` is gone; `BundledFonts` and the palette moved into files
  of their own, unchanged. `HoppaApp` holds `@State private var store` and injects it with
  `.environment(store)`. `AcceptanceHarness.swift` is the smallest thing that can prove the claim —
  not Flow 2, and none of its layout is a design decision. It keeps ticket 18's font verdict block
  so the faces stay checkable on the device.
- **`HarnessSeed.swift` is scaffolding, and the only piece here not meant to last.** The acceptance
  test needs a Program, and **no `Action` creates one** — ticket 26 owns that. So the harness writes
  a starter Upper A **only when there is no file at all**, and never touches an existing one. Flow 1
  deletes the file.
- **Type-checked, not guessed.** `HarnessSeed.swift` imports no SwiftUI, so it was compiled here
  against the real modules. Every store and rules call the harness makes was lifted into a throwaway
  file and type-checked the same way. What is unproven is the SwiftUI around them — most likely
  `@State private var store = LogbookStore(...)`, where the initialiser is `@MainActor`.

**The acceptance test, which is the point of the ticket:** launch, tap `START WORKOUT`, tap
`LOG SET` twice, force-quit from the app switcher, reopen. `Upper A` is still on screen, `Sets
logged` still reads 2, `Current index` still reads 0, and `logbook.json` reports a byte count. The
same claim is already green here as `A relaunch sees exactly what the last send left`, against a
real file — but a test on the VPS is not a phone, and this map's own charter says to check the
artefact rather than the report about it.
