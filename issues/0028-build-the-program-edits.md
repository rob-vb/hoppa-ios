---
id: 28
title: Build the Program edits
parent: 17
labels: [wayfinder:task]
status: open
assignee:
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
