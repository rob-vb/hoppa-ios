---
id: 27
title: Name suggestions, and where a rule that needs Foundation lives
parent: 17
labels: [wayfinder:grilling]
status: open
assignee:
blocked-by:
---

## Question

**§6.3's matching and ranking are rules, and the one package that owns rules cannot hold them.**

[The Logbook on disk](0025-the-logbook-on-disk.md) shipped the content half of §6.3 — 157 names in
`ExerciseCatalogue.swift`, order and prefix rule both checked mechanically. It deliberately shipped
none of the behaviour, because the behaviour has nowhere to go:

- **Matching starts at any word, case- and accent-insensitive.** `incline` finds both
  `Incline Dumbbell Press` and `Dumbbell Incline Press`. Folding accents means Unicode, and Unicode
  means Foundation — and `HoppaRules` [imports nothing, not
  Foundation](0020-the-rules-module-and-its-oracle.md), on purpose.
- **The own-names source is derived live, never stored**: every Exercise Name across **all**
  Programs, most recently used first. "Most recently used" is a fact about Workout history, so
  this reads the whole `Logbook` — which is rules-shaped, not view-shaped.
- **Two sources, one ranked list**, own names on top, a name in both appearing once, six at most
  on focus before typing.

So the question is not "how do I fuzzy-match strings". It is **where the third kind of code lives**:
a rule that needs Foundation. This map has drawn exactly two boundaries so far — `HoppaRules`
imports nothing, `HoppaStore` may not import SwiftUI — and this does not fit either.

Some shapes to put against each other, not a menu to pick from:

- **Fold accents by hand in `HoppaRules`.** A lookup table over the Latin-1 range is perhaps thirty
  lines and no import. It keeps the rule with the rules and keeps the boundary absolute, and it is
  a table someone has to be right about.
- **A `HoppaRules` function that takes pre-folded strings.** The ranking is the rule; folding is a
  string service the caller does. Testable without Foundation, and it moves a correctness question
  to the caller.
- **Let it live in `HoppaStore`.** The store's ban is on SwiftUI, not on deciding — but ticket 25's
  own instruction was *do not put a rule in `LogbookStore`*, and this would be the first exception.
  If it is the right exception, say why, because the next one will cite it.
- **A third package.** Honest about the shape, and a third boundary to keep straight.

Whatever the answer, it should also settle **the `is-this-a-rule` test itself** — the thing to
consult next time, since §6.3 will not be the last rule that wants Foundation.

Downstream of this: Flow 1's name field, and the edit sheet, which §6.3 says behaves the same way.
