---
id: 28
title: Build the Program edits
parent: 17
labels: [wayfinder:task]
status: closed
assignee: agent
blocked-by: [26]
---

## Question

**Build what [Program edits, and which of them are rules](0026-program-edits-and-the-rules-boundary.md)
decided, and §6.3's name suggestions with it.** No decision is open; this ticket writes the Swift
and the tests, on the VPS, and pushes. Zoom ticket 26's resolution for the reasoning behind pieces
1–4, and
[Name suggestions, and where a rule that needs Foundation lives](0027-name-suggestions-and-foundation.md)
for piece 5 — this is the checklist, not the argument.

**Piece 5 was merged in rather than ticketed.** §6.3 turned out to be one source file, its tests and
a file move, all inside `HoppaRules`, which this ticket is already opening — and it goes to the same
Mac session either way.

Five pieces. Take 1–4 in order, because each one's tests need the one before it; piece 5 is
independent of them and can go first or last.

1. **`workingWeight` and `increment` become `Weight?`.** Through `Exercise`, `ResolvedExercise`,
   `progressionMove` (no weight → no move) and `logSet` (no weight → no Set). `resolved`'s
   `relabelled` calls become optional-chained. The solver keeps taking a concrete `Weight`; the
   caller unwraps. **No `schemaVersion` bump and no migration step** — widening to `Optional` is the
   safe direction of ticket 25's `decodeIfPresent` finding — but commit a **real v1 file** and a
   test that loads it, because that claim is exactly the kind this map has been wrong about before.

2. **Stranding.** `ResolvedExercise.isStranded` — the Microloading Increment is not in
   `enabledMicroplates` — and `progressionMove` returns `nil` for it. **This is a live defect**, not
   a new feature: today a switched-off Microplate still moves the weight. Write the red test first
   and watch it fail against the current code.

3. **`Rules+Edit.swift`**: the edit cases on `Action`, the `ExerciseDraft`, and the four pure
   queries (`reweighList`, `exercisesClearedByInventoryUnit`, `exercisesUsingMicroplate`,
   `deleteBlock(forWorkoutDay:in:)`). The diff rules live in `saveExercise`: the §3.2 reopen (only
   what Hoppa auto-completed) and its lowering mirror, the §6.6 unit clear, and the real destruction
   of a stored `microload`.

4. **The mirroring into the Open Workout**: add in place, reorder with `currentIndex` following the
   `ExerciseID`, delete without shrinking the list and without holding the Finish gate. Only into a
   Workout running on that Day.

5. **§6.3's name suggestions.** Move `ExerciseCatalogue.swift` from `HoppaStore` into `HoppaRules`
   unchanged — it imports nothing already — **and its tests with it**, so the curated order and the
   equipment-prefix check keep running. Drop the doc comment that says the matching has no home,
   because this piece is that home. Neither package changes its dependencies and `project.pbxproj`
   needs no edit: the app target already links both. Then one new file beside it:
   - **`fold`**: lowercase, then, for each scalar outside `a`–`z`, read
     `Unicode.Scalar.Properties.name` and take the token after `LETTER`; **accept the base only
     when it is a single letter `a`–`z`**, so `ß`, `ı` and `œ` fall through unchanged. Test it on
     é è ê ë á à â ä å ø ç ñ ü İ, and **keep one test for `ß`, `ı` and `œ` staying put**.
     `#expect(fold("é") == "e")` is also the Mac's proof that Apple ships the Unicode name
     tables — if it goes red there, drop folding, keep `lowercased()`, and say so on the map.
   - **`Rules.nameSuggestions(in: Logbook, query: String) -> [String]`**: own names first, then the
     catalogue, a duplicate keeping its own-names row, **six at most whether or not `query` is
     empty**. Own names come from the Exercises that exist right now across **all** Programs, sorted
     by the `startedAt` of the newest Workout that performed them — **`openWorkout` included** —
     with never-trained names under them in Program order. An empty `query` returns own names only,
     no catalogue. A non-empty `query` matches at the start of any word, where a word breaks on a
     space or a hyphen and **not** on an apostrophe.

Proof, in the shape ticket 23 set: every guard re-broken to show a test goes red, or a comment in
the code saying why it cannot. `swift test` green on the VPS before the push — the whole point of
this package is that it imports nothing.

**Ticket 25's sixth guard comes due here.** `send`'s no-`Logbook` guard could not fail a test while
`Logbook.empty` was a fixed point under all twelve actions. `createProgram` ends that, so
`HoppaStore`'s suite gains the test the comment promised.

Two things this ticket does **not** touch: the screens (ticket 24 owns those, and this is what sits
under them), and deleting a whole Program (still fog on the map — §6.6 never specified it).


---

## Resolution

**All five pieces are built, and `swift test` is green on the VPS: 98 tests in `HoppaRules`, 25 in
`HoppaStore`.** Every guard the ticket added was re-broken one at a time and put back —
**36 of 36 turned a suite red**, so not one of them rests on a test that would pass without it. The
committed 56-Workout snapshot did not move a byte, which is the evidence that widening two fields to
`Optional` changed no behaviour anywhere it was already set.

Four findings outrank the code.

### §6.6 says "four Equipment Types that carry their own unit" and names Bodyweight. There are three

The sentence has been wrong since the spec was assembled, and nothing else in the spec agrees with
it: §2.3 **locks** the Weight Unit row for Bodyweight, §5.1 gives it the Plate Inventory's unit
because its added weight is a plate off that same rack, §6.6's own next paragraph clears it *with*
the three rack types, and the Microload table two paragraphs below calls the Dumbbell **"the only
other type that can change unit"**. A Bodyweight Exercise has no unit of its own to change.

It surfaced because the code had to answer *which* Exercises a unit change clears, and the two
answers in §6.6 disagreed. `SPEC.md` now says three, with the four places that always said so.

### A change of Equipment Type is a change of unit, and §6.6 never said it

§6.6 puts the clearing rule under *"changing a Weight Unit"*, which reads as the unit control on the
sheet. But the unit is **derived** (§5.1): a Dumbbell in lbs that the user turns into a Barbell now
reads its unit off a kg rack, and its `100` means something it was never typed to mean — the exact
harm the clearing rule exists to prevent, arrived by a different door. So the rule watches the unit
the Exercise **resolves to**, before and after, however the user changed it. `SPEC.md` §6.6 gained
the paragraph, and `EditTests` has the case.

The mirror of that is the field this must *not* touch. §2.3 refuses to re-ask a fact about a
machine, so a Base Weight and a Stack Step survive a change of Equipment Type — but a sheet on a
Barbell shows no Base Weight row, so its draft carries `nil`. The draft is written back **only where
the new Equipment Type shows the row**, which is what keeps `nil means the row was absent` from
being read as `nil means the user cleared it`.

### `isStranded` is a fact about the Increment, so it must not be read as a fact about progression

Ticket 26 defined a stranded Exercise as one whose Microloading Increment is not in
`enabledMicroplates`, and said `progressionMove` returns `nil` for it. Read literally, that stops a
**Progressive Overload** Exercise progressing because a Microplate it is not using was switched off
— and every Exercise in the fixture names a Microplate, so this was not a corner. The guard belongs
*inside* the Microloading branch: `isStranded` states the fact, and only Microloading acts on it.
Both directions are tests.

### Three of §6.3's rules had no answer until the code needed one

- **Trained means at least one logged Set.** The recency sort reads "the newest Workout that
  performed them"; a Workout the user opened and walked away from, and one where the Exercise was
  Skipped, performed nothing. Neither lifts a name to the top. `SPEC.md` §6.3 gained the line.
- **The fold drops a combining mark**, or "accent-insensitive" is only half true. `İ`.lowercased()
  is `i` + `COMBINING DOT ABOVE`, and the decomposed spelling of `é` is `e` + `COMBINING ACUTE
  ACCENT` — both keep a scalar with no `LETTER` in its Unicode name, so the base-letter rule alone
  leaves them unfolded and `é` matches `e` in one spelling and not the other.
- **A word-start match is a match at a word start, not a match of one word.** `bench p` finds
  `Barbell Bench Press`: the folded query is looked for at position 0 and after every space or
  hyphen, which is the same rule for one word and for several.

### What is in the code

1. **`Weight?`** on `Exercise.workingWeight` and `.increment`, through `ResolvedExercise`,
   `progressionMove` (no weight *or* no Increment → no move) and `logSet` (no weight → no Set). The
   solver kept its concrete `Weight`: `breakdown(for:at:inventory:)` takes one and
   `breakdown(for:performedAt:inventory:)` unwraps once and returns `nil`. No `schemaVersion` bump —
   and a committed v1 Exercise, weights present, decodes in a test beside one that carries neither.
2. **Stranding**, as `ResolvedExercise.isStranded`, derived and reversible: switch the plate back on
   and the Exercise progresses with the plate the user picked.
3. **`Rules+Edit.swift`** — fourteen `Action` cases, `ExerciseDraft`, `DeleteBlock` and the four pure
   queries. `reduce` routes to it by listing every edit case rather than by `default:`, so a new one
   cannot land unhandled. The diff rules live in `edited(_:with:inventory:)`.
4. **The mirroring**: added in place and Open, reordered with `currentIndex` following the
   `ExerciseID`, deleted without shrinking the list and without holding the Finish gate.
5. **§6.3**: `ExerciseCatalogue.swift` and its four tests moved into `HoppaRules` unchanged, joined
   by `Suggestions.swift` — `fold`, `matches`, `ownNames`, `nameSuggestions`. No `project.pbxproj`
   edit: both packages are path references and SPM globs their sources, so a file moving **between**
   two linked packages is invisible to Xcode.

**Ticket 25's sixth guard is paid off.** `send`'s no-`Logbook` guard now has the test its comment
promised: a `createProgram` sent at an `.unreadable` store leaves the bytes on disk untouched, and
the same action on a fresh install lands — so the first test is proving the guard and not the
absence of an effect.

### What the Mac still has to say

One `#expect`, and it is the one ticket 27 flagged: `fold("é") == "e"` proves Apple ships the
Unicode name tables. It was green on Linux and the risk was that Darwin ships no such table, which
would have cost §6.3 half of its accent clause.

**It is green on Darwin too** (Rob, 2026-08-20). Both suites run the same counts on the Mac — 98 and
25 — and the Xcode project builds. So `Unicode.Scalar.Properties.name` is a fact a rule may read on
both platforms, folding stays, and nothing this ticket wrote is Linux-only.
