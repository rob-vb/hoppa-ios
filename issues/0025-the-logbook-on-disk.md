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

Nothing to decide — [Persistence and the data model](0019-persistence-and-the-data-model.md)
decided all of it. **Build the app-side store and prove a Logbook survives a relaunch on Rob's
phone.**

Zoom ticket 19's resolution and treat it as given. This is the half of that answer that cannot live
in `HoppaRules`: it needs Foundation, a file system and an iOS target, so it runs on the Mac and not
on the VPS. Ticket 23 delivers the value types; this ticket gives them somewhere to live.

### What to build

- **`@Observable final class LogbookStore`**, in the app target. It holds
  `private(set) var logbook: Logbook`. It does four things and no more: load, migrate, call
  `Rules.reduce`, save. It owns the id counter (`nextId`) and the clock — every `Timestamp` the
  rules receive is minted here.
- **Atomic writes after every mutation.** Encode, write to a temporary file, rename over the target.
  A crash must never leave a half-written Logbook.
- **`Documents/logbook.json`**, with `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace`
  in Info.plist, so Rob copies the file off the phone through the Files app. **No export screen** —
  there is none in the five flows.
- **The migration chain.** Read `schemaVersion` first. If it is older, copy the file to
  `logbook-v<n>-backup.json` **before** touching it, then run one function per version step.
- **A file that will not decode is never written over.** Report it, leave it alone, do not start a
  fresh Logbook on top of it. This is the rule that protects weeks of real training, and it deserves
  a test of its own: hand the store a corrupt file and assert the file is unchanged afterwards.
- **A fresh install** writes the Plate Inventory of §6.1 — `KG`, the standard kg rack — and nothing
  else. No Program, no Workout.

### What proves it

The rules have four layers of tests already; this layer needs far less, because it makes no
decisions. Three things are worth asserting:

1. Round trip: a `Logbook` with a Program, a Plate Inventory and a few Workouts encodes, decodes and
   re-encodes identically. (Ticket 23 owns the committed fixture; this ticket runs it against the
   real file path.)
2. The corrupt-file rule above.
3. A migration from a hand-written v1 file to the current version, with the backup present
   afterwards.

Then the acceptance test on the device: start a Workout, log two Sets, force-quit the app, reopen it.
The Open Workout is still there, with both Sets.

### Two things this ticket must not do

- **Do not put a rule in `LogbookStore`.** The moment it decides something, rules live in two places
  and ticket 20's boundary is gone. It forwards actions; it does not judge them.
- **Do not build a view.** [The view layer around the rules](0024-the-view-layer-around-the-rules.md)
  owns the keypad buffer, the overlays and the draft.
