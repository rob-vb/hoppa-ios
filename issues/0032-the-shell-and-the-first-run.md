---
id: 32
title: The shell and the first run
parent: 17
labels: [wayfinder:task]
status: closed
assignee: Rob
blocked-by: [30]
---

## Question

**Build the app's home: the Workout Day picker, and what it shows before there is anything to pick.**

The first of eight screen tickets from
[Build order across the flows, and what done means for a screen](0029-build-order-and-what-done-means.md).
It is the one that turns the app from a harness into an app.

Build:

- **The Workout Day picker** (§3.1). Free pick, no rotation, no pre-selection, no suggestion. Each
  row shows the Workout Day's Name and **when it was last done** — "Push — 4 days ago" — which is
  information and not advice (§7.6). A Workout starts on an explicit action.
- **The empty state**, decided at ticket 29 and now in §6.1: `NOTHING HERE YET` and one
  `CREATE A PROGRAM` button. The picker is always home; onboarding is a route to it.
- **A `HISTORY` row at the foot** (§6.7). It is a door to a screen that does not exist yet — build
  the row disabled or absent, and say which in the hand-off note. Hoppa has **no tab bar**.
- **The navigation spine.** §6.7 names two doors and no tab bar, so the shape is a `NavigationStack`
  whose path lives in `@State` on the view, per
  [The view layer around the rules](0024-the-view-layer-around-the-rules.md).
- **The colour tokens** in whatever shape [Dark only, or a light mode too](0030-dark-only-or-a-light-mode.md)
  settles. `Palette.swift` exists from ticket 18 and this ticket is the first real user of it.
- **Retire the scaffolding.** Delete `AcceptanceHarness.swift`; this screen replaces it. **Keep
  `HarnessSeed`** behind a debug switch — Flow 4 needs sixteen weeks of history to look at, and
  typing that on a phone is not a test.

Done means, per ticket 29: §7.4's constants hold exactly (padding 20, radii 2–3, hit target 50,
safe top inset 54 with nothing in it, the 8/16 rhythm); the artboard is the reference for
arrangement and copy; **`SPEC.md` beats the artboard** wherever they disagree. No UI tests — the
view reads `ResolvedExercise` and calls `store.send`, and any logic worth testing belongs below the
view.

Type-check the file here against the built modules before pushing — see the map's Notes on what
reaches further than "imports nothing". This ticket does **not** hand over to the Mac on its own:
batch 1 goes over after ticket 35, when there is a path from an empty app to a real Program.

Consult `SPEC.md` §3.1, §6.1, §6.7 and §7.4, and `design/0006-onboarding/`.

## Resolution

**The shell is built and pushed: `WorkoutDayPicker` is the app's home, `AcceptanceHarness` is
deleted, and the navigation spine is a `NavigationStack` over a four-case `Route`.**
`swift test` is green here — **112 in `HoppaRules`** (up from 107) and **31 in `HoppaStore`**
(up from 25). `project.pbxproj` needed **no edit**: the app target is a
`PBXFileSystemSynchronizedRootGroup`, so Xcode picks up the four new files and the deleted one by
itself. Ticket 29's rule applies — **this ticket is closed because it is pushed, not because Rob has
seen it**; batch 1 still goes over after ticket 35.

Four findings outrank the code.

**1. "4 days ago" is not a rule, and the `is-this-a-rule` test says so at the second half of its
first clause.** The *instant* a Workout Day was last done falls out of the Logbook alone and every
lifter holding that Logbook must read the same one, so `Logbook.lastTrained(_:)` is a rule and lives
in `HoppaRules`. The **phrasing** needs a calendar and a time zone, and two lifters in two zones may
then correctly *disagree* about whether the same instant was yesterday — the *must* clause fails, so
it is not a rule. The pair of cases that proves it: a Workout at 21:00 read at 07:00 the next morning
is **ten hours** ago and reads `Yesterday`; one at 00:10 read at 07:00 is **seven** hours ago and
reads `Today`. Elapsed time cannot separate them.

**2. It went into `HoppaStore` anyway, and ticket 29 is why.** It was written in the app target,
where it type-checks here but can never be *tested* here. Ticket 29 already ruled that **logic worth
testing does not belong in the view — it belongs in `HoppaRules` or `HoppaStore`** — and
`RelativeDay` is the whole of what the picker computes, so it is the whole of what can be wrong. It
moved to `HoppaStore` the same session and took nine cases with it, including the DST fall-back
(25 hours long and still exactly one day) and a clock that moved backwards (`Today`, never a minus).
Three re-breaks, three red suites: elapsed-over-86400 fails eight tests. The store's charter survives
— *it decides nothing* is about training, and a calendar is not a rule about training.

**3. §3.1 had no answer for a Day that has never been done, and it is the common first case.** Every
Day of a Program the user just created is in that state, so it is not an edge. It reads `Never`, and
`SPEC.md` §3.1 now carries the whole line: newest **finished** Workout, by the day it **started**
(§2.4), the Open Workout not counting, and the phrasing in calendar days. The Open Workout exclusion
is load-bearing in a way nothing else here is: a picker that counted it would say the user trained
today the moment he tapped a row, **before he lifted anything**.

**4. Ticket 30's escalation rule has fired for the first time, and it added a role rather than a
finding.** The artboards use **two** text greys and §7.2 named one: `#8D9296` for a meta line a user
reads, and `#55595D` for the tiny uppercase labels above a block, which are furniture. Both
`design/0006-onboarding/` and `design/0015-history/` use it, so it is a role and not noise — and it
is **not a new hue**: it measures hue 210° at 4.5% saturation, the same spine as every grey in §7.2
and every grey in `Steel`, landing within 2/255 of `Steel.hex(lightness: 0.349)`. §7.2's table gained
a seventh row and its prose now says seven.

### What was built

- **`WorkoutDayPicker.swift`** — three states off one screen, because §6.1 says the picker is always
  home and onboarding is a route to it: the **first run** (`NOTHING HERE YET` and one
  `CREATE A PROGRAM`), the **picker** (the Program's Name, `•••`, a row per Day with its last-done
  line, and the `HISTORY` row at the foot), and **`.unreadable`**, whose copy is kept word for word
  from ticket 25's harness.
- **`Route.swift`** — four cases, one per screen ticket, plus `NotBuiltYet`. A ticket lands its
  screen by replacing its own `case` in `HoppaApp`'s `destination(_:)` and touching nothing else.
- **`Typography.swift`** — §7.4 as four roles (display, label, meta, body), every face `fixedSize`,
  every letter-spacing computed from the artboards' em, tabular figures on the Plex roles. **A view
  never calls `.custom`.** With `.dynamicTypeSize(.large)` at the root, that is ticket 30's items 1
  and 2 done.
- **`Palette.swift`** — `Color.labelText`, and `Color(plateHex:)`, ticket 30's item 3.
- **`LogbookLocation.swift`** — `Logbook.fileURL` moved out of `HoppaApp`, which imports SwiftUI,
  onto the checkable side. It names the single path every byte of Rob's training goes through.
- **`HarnessSeed.isEnabled = false`** — the debug switch ticket 29 asked for. Off, so a new phone
  opens on §6.1's real first run.
- **`AcceptanceHarness.swift` is deleted.**

### Three decisions the ticket left open

- **A door to an unbuilt screen is live and lands on `NotBuiltYet`**, not disabled and not absent —
  a third answer to the ticket's *disabled or absent*, taken on purpose. A disabled row proves
  nothing about the spine, and the spine is what this ticket is for; ticket 29's hand-off rule wants
  **what is not built yet** stated so a missing thing is never read as a defect, and a screen that
  says so in its own words is the shortest way to keep that promise. By batch 1 the only stub left is
  History.
- **Tapping a Day does not start the Workout.** It pushes `Route.logging(dayId)` and sends nothing.
  `.startWorkout` belongs to ticket 36, and sending it here would strand an Open Workout on the phone
  with no screen able to finish or discard it.
- **The `•••` is the way into the Program sheet.** §6.7's *two doors* counts the doors into
  **History**; Flow 5's hub needs its own, and §6.1 step 3 already draws it.

### Two things the Mac has to answer

Neither can be checked here, and both are named so they are not read as defects.

- **Tight leading on multi-line display text.** §7.4 asks for a line-height of 0.78–0.94 and SwiftUI
  cannot state that as a number — `lineSpacing` only ever *adds*. `Font.leading(.tight)` is the
  native way to pull it in, and it approximates the artboard rather than measuring it. The picker has
  no multi-line display text; **ticket 33's `NAME YOUR PROGRAM` is the first that does.**
- **`monospacedDigit()` on IBM Plex Sans.** §7.4 wants tabular figures. The modifier asks the face
  for them and falls back silently if it has no `tnum`. The picker's figures are single-line, so a
  fallback costs nothing there and would show up first in a column.

### What was proved here

The SwiftUI is Mac-only; nothing else about this ticket is.

- `HoppaRules` **112 green**, `HoppaStore` **31 green**. `lastTrained` re-broken four ways (oldest
  instead of newest, counting the Open Workout, reading `finishedAt`, ignoring the Day) and all four
  turn the suite red. `RelativeDay` re-broken three ways, all three red.
- Every rules and store call the two SwiftUI files make was lifted into a throwaway and **compiled
  and run** against the built modules — the pattern from
  [The Logbook on disk](0025-the-logbook-on-disk.md). It printed the picker for three states: a
  fresh install (`Nothing here yet`), a Program with four Days (`6 days ago` · `2 days ago` ·
  `Yesterday` · `Never`, and `3 workouts`), and a corrupt file (`unreadable`). The `Never` row is a
  Day with no Workout on it, beside three that have one.
- `HarnessSeed.swift` and `LogbookLocation.swift` type-check here against the built modules.
