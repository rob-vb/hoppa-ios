---
id: 52
title: Two files, one PlateChip
parent: 17
labels: [wayfinder:task]
status: closed
assignee: agent
blocked-by: []
---

## Question

**The first finding of the walk, and it is item 1.** Rob pulled, opened
`app/Hoppa/Hoppa.xcodeproj`, hit build, and got three errors on `SummaryScreen`:

```
Missing arguments for parameters 'weight', 'isOn', 'width', 'height' in call
Extra argument 'plate' in call
Invalid redeclaration of PlateChip
```

Nothing else in `HANDOFF.md` can be walked until the target compiles, so this blocks all 118
items.

**What is to decide, and it is not the rename.** The rename is obvious. The question this ticket
carries is *why the VPS said green while the Mac would not build*, and what the map does about a
whole class of error it cannot see. Three sessions each wrote a correct file; the module they
share is what was wrong, and nothing on this machine was looking at the module.

## Resolution

**One name, two files, three errors.** `PlateChip` was declared twice in the app target:

| File | Ticket | What it draws |
| --- | --- | --- |
| `PlateRackScreen.swift:398` | 0033 | The rack toggle-list chip — `weight`, `isOn`, `width`, `height`, plus a `height(rank:of:tallest:shortest:)` ramp |
| `SummaryScreen.swift:478` | 0038 | The 9 × 34 added-plate slab at the head of a Went-up row — `plate` only |

Xcode compiles the app target as **one module**, so the second declaration is
`Invalid redeclaration of PlateChip`, and the compiler then resolves
`PlateChip(plate: row.addedPlate)` at `SummaryScreen.swift:290` against the *rack* initialiser —
which is where the other two errors come from. **One collision, three errors, and the two loudest
ones point at a call site that was never wrong.**

**The rack chip keeps the name.** It came first (ticket 0033 against 0038), it has three call
sites across two files (`PlateRackScreen` twice, `NameYourProgram` once), and it carries a static
member. The Summary slab is renamed **`AddedPlateChip`** — one declaration and one call site, and
the name is better besides: it is the plate the progression put on, not a plate in a rack.

**Why the VPS could not see it, which is the part worth keeping.** Every check on this machine
compiles *one thing at a time*: `HoppaRules` and `HoppaStore` are real modules and `swift test`
builds them whole, and the six `app/checks/*` scripts each hand `swiftc` a single app-target file
that imports no SwiftUI. **No check ever looked at the app target as a module**, because SwiftUI
does not exist on Linux and `swiftc -typecheck` can never run over these files. Ticket 0029 wrote
that down as *no UI tests* and left the view layer to Rob's eyes — but a redeclaration is not a UI
question. It is bookkeeping, it is mechanical, and **it is exactly what the machine should have
caught.**

**So the target now gets the two checks it can have**, as `app/checks/AppTarget/run.sh`:

1. **No top-level name is declared in two files.** A column-0 scan of every `struct`, `class`,
   `enum`, `actor`, `protocol`, `typealias`, top-level `func`/`var`/`let`, and every member of an
   `extension` keyed by the type it extends (`Color.floor`). A name in **one** file may be
   overloaded freely — that is Swift — so it is the file column that is counted. Today: **101
   names across 30 files, none twice.** Reverting the rename makes it fail with exactly this
   collision, which is how it was proved.
2. **Every file parses.** `swiftc -parse` is purely syntactic and needs no SwiftUI, so it runs
   here over all 30 files. It cannot catch a type error, but a file that cannot be read at all
   should never cost a Mac build.

Neither is a type-check and neither pretends to be. The honest statement is narrower than the one
the map has been making: *everything provable here is proved* was true of the rules and the store
and false of the app target, which had **no** check at all. It has two now.

**What this does not fix.** A signature that drifts, a member that moves, a call that passes the
wrong type — all of that still waits for Xcode, and always will while SwiftUI is Mac-only. This
closes one class of error, the class where **two sessions cannot see each other's file**, and that
is the class the build-everything-first rule makes most likely: ten screens written in eight days,
each session seeing its own screen.

**The build is not proved.** The rename clears the three errors Rob photographed, and the module
scan says no second collision is waiting. Xcode may still find something after `SummaryScreen`,
because a compiler stops where it stops. `HANDOFF.md` item 1 now says so.

Pushed as part of this session's commit. Rob restarts the walk at item 1.
