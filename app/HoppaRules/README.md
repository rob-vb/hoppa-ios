# HoppaRules

The progression rules, the domain value types and the Plate Breakdown solver, as one
local Swift package that **imports nothing** — not Foundation.

- `SPEC.md` is the source of truth. `CONTEXT.md` is the vocabulary.
- Decisions: [The rules module and its oracle](../../issues/0020-the-rules-module-and-its-oracle.md),
  [Persistence and the data model](../../issues/0019-persistence-and-the-data-model.md),
  [Lift the rules into HoppaRules](../../issues/0023-lift-the-rules-into-hopparules.md).

## Run the tests

    cd app/HoppaRules && swift test

Re-record the committed 56-Workout snapshot and the Logbook round-trip fixture:

    HOPPA_RECORD=1 swift test

Only re-record when a rule changed on purpose. The diff is the review.

## Add it to Xcode

*File → Add Package Dependencies… → Add Local…* → pick `app/HoppaRules`, then add the
`HoppaRules` library to the **Hoppa** target.
