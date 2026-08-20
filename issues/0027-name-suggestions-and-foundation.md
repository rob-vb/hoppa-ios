---
id: 27
title: Name suggestions, and where a rule that needs Foundation lives
parent: 17
labels: [wayfinder:grilling]
status: closed
assignee: agent
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

## Resolution

**§6.3 does not need Foundation, and the ticket's premise did not survive a compiler.** Every part
of the matching and the ranking is a `HoppaRules` rule, in `HoppaRules`, importing nothing. The
third boundary this ticket was charted to draw is not drawn, because there is nothing yet to put on
the other side of it.

Four facts, each checked on the VPS before a single question was put to Rob:

- **`lowercased()` is Swift standard library, not Foundation.** A file with no imports at all
  lowercases `İ` and `ß` correctly. Case-insensitive matching costs zero imports. This is the fact
  the ticket was written without.
- **Swift's `String` equality is canonical.** `"e\u{301}" == "é"` is `true` with no imports, and so
  is `hasPrefix`. Half of "accent-insensitive" — the composed/decomposed half — was already free
  and nobody had to write it.
- **The Exercise Catalogue holds no accented letter.** 156 names; the whole character inventory is
  letters, spaces, 14 hyphens and one apostrophe. So accent folding never had a customer in the
  shipped half of §6.3 — only in a name the user types himself.
- **A hand-written fold table is not needed either.** The standard library ships the Unicode
  character names, and `Unicode.Scalar.Properties.name` reads them with no import. `é` is
  `LATIN SMALL LETTER E WITH ACUTE`, so the base letter is *in the data*: take the token after
  `LETTER`. Proved here on é è ê ë á à â ä å ø ç ñ ü İ. The ticket offered "a table someone has to
  be right about" as the price of keeping the boundary; the price is about ten lines and no table.

### The decisions

- **Accent folding is built, in `HoppaRules`, off the Unicode names.** Guard it so a base counts
  only when it is a single letter `a`–`z`: `ß` (`SHARP S`), `ı` (`DOTLESS I`) and `œ`
  (`LIGATURE OE`) then fall through unchanged, which is right — they are not accented letters, and
  folding them would be a guess. Folding runs only on scalars outside `a`–`z`, so an ASCII name
  costs nothing.
  **One risk, and it is cheap to cover.** The Unicode name tables were proved on Linux Swift 6.3.3,
  not on Apple's. A test `fold("é") == "e"` in `HoppaRules` runs on the Mac too, so the first
  `swift test` there settles it. If it fails, drop folding and keep case-insensitive only — the
  catalogue is pure ASCII, so nothing shipped regresses.

- **The Exercise Catalogue moves down into `HoppaRules`, and ticket 25's reason is reversed.**
  `ExerciseCatalogue.swift` said it lived in `HoppaStore` "because it is content, not a rule". That
  was right when nothing consumed it. The ranking rule reads *both* sources and de-duplicates
  across them, so leaving half its data one package up would split one rule over a boundary and
  make every caller pass the same constant. The file already imports nothing, so it moves unchanged.
  `CONTEXT.md`'s **Exercise Catalogue** entry carried the old package name and is corrected.

- **"Most recently used" means most recently *trained*.** Order the own names by the `startedAt` of
  the newest Workout that performed them, newest first; **the Open Workout counts**, because the
  Exercise logged ten minutes ago belongs at the top. A name on an Exercise that exists but was
  never trained has no date and sorts *under* the trained ones, in Program order. The alternative —
  ordering by position in the Programs — needs no history and answers a different question than the
  one §6.3 asks.

- **Six rows while typing too, and the own-names row wins a duplicate.** §6.3 capped only the focus
  list at six and said nothing about the typing list. Six both ways: a keyboard leaves room for
  about that many, and §6.3's own argument for a 150-name catalogue was that `press` must not
  return thirty rows — an uncapped typing list hands that failure straight back. On the duplicate,
  the own-names row survives, because it carries the recency and the user wrote it.

- **A word breaks on a space or a hyphen, not on an apostrophe.** `up` finds `Pull-up` and
  `Chin-up`, which are two words to a lifter. `s` is not a search anyone makes, so `Farmer's` stays
  one word.

### The `is-this-a-rule` test

Two steps, and **the second one is why this ticket existed**. Recorded on the map under Notes.

1. **Is it a rule?** It is, if it decides an outcome from the `Logbook` alone *and* two lifters with
   the same `Logbook` must see the same answer. Otherwise it is a view or a service.
2. **Does it need Foundation? Prove it, do not assume it.** Write the file with no imports and run
   `swiftc -typecheck`. §6.3 was recorded as needing Foundation in three places — the ticket, the
   map's fog and a doc comment in `ExerciseCatalogue.swift` — and one compiler run ended all three.

**What happens when a rule genuinely does need Foundation stays open, deliberately.** There is no
such rule today, and a third boundary drawn for zero cases costs more than it saves. When one
arrives: first try to push the Foundation part out to the caller as a service and keep the decision
in `HoppaRules`; only if that fails, add a second, Foundation-importing target inside the
`HoppaRules` package. That is a default to argue with, not a boundary.

### Where the build goes

**No new ticket.** §6.3 is one source file plus tests in `HoppaRules`, plus a file move, and
[Build the Program edits](0028-build-the-program-edits.md) is already in `HoppaRules` and already
queued for the same Mac session. It becomes piece 5 there. Rob agreed to the merge rather than a
ticket of its own.

`SPEC.md` §6.3 gains the five decisions above and loses its closing paragraph about a rule with no
home.
