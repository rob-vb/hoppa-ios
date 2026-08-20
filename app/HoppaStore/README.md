# HoppaStore

The seam between `HoppaRules` and the screens: it holds the `Logbook`, forwards every
action to `Rules.reduce`, and saves.

**It is defined by what it may not import.** `HoppaRules`, `Foundation` and `Observation`,
and **never SwiftUI** — a compiler rule, not a discipline, and the thing that stops view
state from creeping back into the store.

It decides nothing. There is one mutating method, `send`, and its whole body is
reduce-then-save.

- `SPEC.md` is the source of truth. `CONTEXT.md` is the vocabulary.
- Decisions: [The view layer around the rules](../../issues/0024-the-view-layer-around-the-rules.md),
  [Persistence and the data model](../../issues/0019-persistence-and-the-data-model.md),
  [The Logbook on disk](../../issues/0025-the-logbook-on-disk.md).

## Run the tests

    cd app/HoppaStore && swift test

Every test that touches a file runs the **real** atomic write against a real temporary
directory. The store takes a `URL` and not a protocol on purpose: a stand-in would mean
the backup and the atomic write — the two pieces most worth running — never run.

`Tests/HoppaStoreTests/Fixtures/logbook.json` is a copy of the fixture `HoppaRulesTests`
records from a real run of the rules. Re-copy it when that one is re-recorded:

    cp app/HoppaRules/Tests/HoppaRulesTests/Fixtures/logbook.json \
       app/HoppaStore/Tests/HoppaStoreTests/Fixtures/logbook.json

## Bumping the schema

`Logbook.currentSchemaVersion` lives in `HoppaRules`. Migration is **additive by default**,
with one catch worth knowing before you rely on it:

- A new **Optional** property needs no step. Swift's synthesised `Codable` decodes an
  Optional with `decodeIfPresent`, so a file written before the field existed still reads.
- A new **non-Optional** property needs a step, *even with a default value in `init`* —
  the synthesised decoder calls plain `decode` and fails on the missing key.
- A destructive change — a field removed, or a field whose meaning changed — always needs
  a step. Steps live in `LogbookFile.steps`, keyed by the version they migrate **from**,
  and work on decoded JSON rather than frozen per-version structs.

Every bump commits a real old-version file as a fixture, ideally taken off Rob's phone.
A migration with no fixture is a migration that has never run.

## Add it to Xcode

Already added: `app/Hoppa/Hoppa.xcodeproj/project.pbxproj` carries the same 16 additive
lines Xcode's *Add Local…* writes, with `relativePath = ../HoppaStore`. If Xcode ever
disagrees, `git checkout` the project file and use
*File → Add Package Dependencies… → Add Local…* instead.
