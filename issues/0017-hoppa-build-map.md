---
id: 17
title: Hoppa build map
labels: [wayfinder:map]
status: open
---

## Destination

**Hoppa on Rob's own phone, logging his real Upper / Lower program in his own gym.** A native
SwiftUI app built from [`SPEC.md`](../SPEC.md): the five flows, the domain model, the progression
rules and the Plate Rack language, running on a real device and used for real training.

Not the App Store, not TestFlight, not another user, not an account. The spec was validated on
artboards and in conversation; **training with it is the only thing that can validate it for
real**, and nothing after that is worth doing before it.

## Notes

- **Tracker**: local markdown, the same one the design map used. Issues live in `issues/`, one
  file per issue, numbered. A ticket is a child of this map via `parent: 17`. Claim a ticket by
  filling `assignee:` before any work. A ticket is blocked while any id in `blocked-by:` has
  `status: open`. The frontier = open, unassigned, unblocked tickets. Close a ticket by setting
  `status: closed` and appending a `## Resolution` section.
- **The `is-this-a-rule` test**, from
  [Name suggestions, and where a rule that needs Foundation lives](0027-name-suggestions-and-foundation.md).
  Two steps, and the second is the one this map keeps getting wrong. **1. Is it a rule?** It is, if
  it decides an outcome from the `Logbook` alone *and* two lifters with the same `Logbook` must see
  the same answer; otherwise it is a view or a service. **2. Does it need Foundation? Prove it, do
  not assume it** — write the file with no imports and run `swiftc -typecheck`. §6.3 stood recorded
  as needing Foundation in three places and one compiler run ended all three. If a rule ever really
  does need it: first push the Foundation part out to the caller as a service; only if that fails,
  add a second Foundation-importing target inside the `HoppaRules` package. No third boundary
  exists today, on purpose.
- **`SPEC.md` is the source of truth, and `CONTEXT.md` is the vocabulary.** Consult both every
  session. The *reasoning* behind every rule is in issues `0002`–`0016`; the spec deliberately
  carries none of it, so zoom a ticket when a rule looks arbitrary.
- **A settled decision stays settled.** Do not re-litigate the design map. If the build shows a
  rule to be wrong — and it will, because building is the first thing that executes them — that is
  a **finding worth its own ticket**, not a quiet fix. The design map caught four of its own
  mistakes that way.
- **Skills**: grilling tickets use grilling + domain-modeling. Where a UI question is genuinely
  open, use the prototype skill — but prefer building the real screen, because there is a
  validated artboard for almost everything.
- **Standing preferences**: domain terms, code and project documents in English; conversation
  follows Rob's CLAUDE.md (Simplified Technical English, Dutch when he writes Dutch). Rob is the
  first and only user of this map's output — put choices to him as concrete options.
- **Do not end every session with "please build this".** Rob said so plainly at
  [The Logbook on disk](0025-the-logbook-on-disk.md): *"Ik test later wel, geen zin om telkens te
  testen."* The VPS/Mac loop puts him in the critical path of every session that writes Swift, and
  that is a cost the map has to carry rather than pass on. Two consequences:
  - **Batch the Mac work.** Let hand-offs accumulate and hand over one build session covering
    several tickets, instead of one round trip each. A ticket waiting on the Mac is not a blocked
    map — pick up the next unblocked ticket and let the queue grow.
  - **Prove as much as possible here first.** A file in the app target that imports no SwiftUI can
    be type-checked on the VPS against the built modules, and so can every rules/store call a
    SwiftUI view makes. See the charter bullet on Swift on the VPS. What reaches Rob should be
    something that has already had every checkable thing checked.
  - **Batch 1 has been over, and the queue now holds batches 2 and 3.** Rob walked
    [The shell and the first run](0032-the-shell-and-the-first-run.md),
    [The Program name, the three assumptions, and the Plate Inventory
    screen](0033-the-program-name-and-the-plate-rack.md), [The Program sheet hub and the Workout
    Day screen](0034-the-program-sheet-and-the-workout-day.md) and [The Exercise sheet, and the
    name field](0035-the-exercise-sheet.md) on 2026-08-26, and the three fixes it found are
    recorded below. **Batch 2 is complete and waiting**: [The logging
    screen](0036-the-logging-screen.md) and [The weight sheet](0037-the-weight-sheet.md), both
    pushed 2026-08-26, and together they are the walkable path — start a Workout, log Sets, change
    a weight. It is Rob's to walk when he wants it; the map keeps picking up unblocked tickets
    rather than waiting on him. **[The Workout Summary](0038-the-workout-summary.md) is pushed too**
    and so is [The Ignition confetti](0039-the-ignition-confetti.md), which closes it — the path
    now runs to Finish and the Summary lands with its burst. **All three hand-offs are now queued
    and the trainable milestone is written**, so the next session's job is Rob's walk and the
    findings it produces, not another screen.
    **Batch 4 has opened anyway**, with [The Open Workout on next
    open](0040-the-open-workout-on-next-open.md) — the map picks up unblocked tickets rather than
    waiting, and this one is the shell's last unbuilt sentence. It carries a wrinkle no earlier
    batch had: **its trigger needs the phone's clock moved**, because an Open Workout only
    becomes *an earlier day* by the calendar. The hand-off must say how to reach it — start a
    Workout, force-quit, set the date forward a day, open Hoppa — or a picker that asks nothing
    will read as a defect.
    **Batch 4 carries three tickets now**:
    [A weight retyped after a unit change](0041-a-weight-retyped-after-a-unit-change.md) and
    [The numbers a mis-tap cleared](0043-the-numbers-a-mistap-cleared.md) both touch
    `ExerciseSheet` and `WorkoutDayScreen`, so they must compile in Xcode with the rest. Neither
    needs a walk of its own — their proof is 147 green rules tests plus 34 green stash checks — but
    the hand-off should name them, because together they change what the Exercise sheet does after
    a unit flip and a silent change is the kind a walk reports as a defect. Ticket 43 adds **one
    new file**, `app/Hoppa/Hoppa/UnitStash.swift`, and the target is a
    `PBXFileSystemSynchronizedRootGroup`, so `project.pbxproj` needs no edit — which is one more
    data point for the question about who owns that file.

    Before batch 1 the queue was **empty**, cleared 2026-08-20 in one session, which is the pattern
    working as intended. What that walk settled, because each answer outlives its ticket:
    - **The force-quit passes on the phone** — `Upper A`, `Sets logged 2`, `Current index 0` after a
      kill from the app switcher. [The Logbook on disk](0025-the-logbook-on-disk.md) is closed.
    - **`fold("é") == "e"` is green on Darwin.** Apple ships the Unicode name tables, so
      `Unicode.Scalar.Properties.name` is a fact a rule may read on both platforms and §6.3 keeps its
      accent folding. That was the last thing ticket 27 left unproven.
    - **Both suites run the same counts on the Mac**, 98 and 25, and the project builds — including
      the `project.pbxproj` the agent hand-patched at ticket 25. **No toolchain drift today**, which
      is what makes proving things here worth anything.
  - **The queue from here is three hand-offs, not eight.** Set at
    [Build order across the flows, and what done means for a screen](0029-build-order-and-what-done-means.md).
    A batch goes over **when the queue holds a path Rob can walk end to end**, never on a count —
    handing over a screen with no way into it wastes the expensive half of the loop.
    **Batch 1** after [The Exercise sheet, and the name field](0035-the-exercise-sheet.md): empty app
    to a real Program with real Exercises. **Batch 2** after
    [The weight sheet](0037-the-weight-sheet.md): start a Workout, log Sets, change a weight.
    **Batch 3** after [The Ignition confetti](0039-the-ignition-confetti.md): Finish, and watch the
    Summary land. Each hand-off is **one message with a numbered list**, every item *do X → expect
    Y*, item one always `git pull` plus a build, the last always `git push` if Xcode changed
    anything, and a closing note on **what is not built yet** so a missing thing is never reported as
    a defect.

- **What "done" means for a screen**, from
  [Build order across the flows, and what done means for a screen](0029-build-order-and-what-done-means.md).
  Three rules, and every screen ticket inherits them.
  - **The spec's numbers are the contract; the artboard is the reference.** §7.4 holds exactly —
    padding 20, radii 2–3, hit targets 50 and 64, safe top inset 54 with nothing drawn in it, the
    8/16 rhythm, Anton at 0.78–0.94. Arrangement, copy and palette follow the artboard. Nothing is
    measured pixel for pixel: the artboards are HTML at a fixed width and a phone is not.
    **`SPEC.md` beats the artboard wherever they disagree** — §8.2 now lists **twelve** defects in
    the logging prototype, so the artboards are a reference with known errors, not a target.
  - **A screen ticket closes when it is pushed, not when Rob has seen it.** Written, type-checked
    here against the built modules, pushed. Rob's verdict arrives out of band, and a complaint is a
    **finding with its own ticket**. The cost, stated once: a closed screen ticket is not a seen
    screen, and a screen counts toward the destination only after he looks at it.
  - **No UI tests.** XCUITest runs only on the Mac, which is the scarce resource, and it is slow and
    brittle. The view layer's proof is a type-check here plus Rob's eyes. If a screen grows logic
    worth testing, that logic does not belong in the view — it belongs in `HoppaRules` or
    `HoppaStore`, where a test is cheap and runs on this machine.

- **Charter decisions** (settled while charting, before any ticket):
  - **Local only.** No account, no sync, no server, no CloudKit. Programs and Workouts live on the
    device; an iCloud device backup is what survives a new phone. This keeps the map free of
    accounts, a privacy policy and the GDPR.
  - **The build happens on Rob's Mac.** This agent's environment is Linux, so it cannot compile,
    run a simulator or open Xcode. Swift sources, the data model and tests are written here;
    **compiling, running and looking at the app happen on the Mac**, and build errors come back
    through Rob. Plan tickets so that a session's output is something he can paste in and run.
  - **There is an earlier Hoppa, and it is a test app.** `rob-vb/hoppa` on GitHub holds a
    substantially built Expo / React Native version of *this same product* — SQLite, Zustand,
    i18n, jest, a 94 KB `PRD.md` marking most of a 7.5-week MVP as done, and a public
    `hoppa-landing` beside it. Its domain matches `SPEC.md` almost term for term (schemas →
    Program, set_logs → Set, plate calculator → Plate Breakdown), and its own `CONTEXT.md`
    reached this map's charter decision independently: no login, all data in SQLite.
    **Rob calls it a test app; this map builds the good one.** Recorded here because a session
    that meets it cold will reasonably wonder whether this whole map is a duplicate effort. It is
    not — it is the rebuild, and the Expo app is superseded, not a source of truth. `SPEC.md`
    stays the only spec.
  - **How the code travels: a private GitHub remote.** The charter above named two machines and
    never said how anything gets between them — and it turned out nothing did. The agent works on
    a **VPS**, not on the Mac, and this repo had no remote at all, so the first session that
    produced something to run had nothing to run it with. Found while working
    [An empty app on the phone](0018-an-empty-app-on-the-phone.md).
    The loop, from here on: **the agent commits and pushes on the VPS; Rob pulls on the Mac,
    builds, and pushes whatever Xcode changed; the agent pulls it back.** Two-way, because Xcode
    generates files — `project.pbxproj` above all — that the agent has to read and patch. A
    session that writes Swift is not finished until it has pushed.
    **The loop's first run failed silently.** Xcode's New Project dialog creates its own git
    repository inside the project folder unless told not to, so `app/Hoppa` was committed as a
    gitlink (mode `160000`) with no `.gitmodules`: Rob pushed, and an empty pointer arrived. A
    push that reports success is not proof the files travelled — **check that what you need is
    actually in the tree** before working from it. The same run also proved the sharper form of
    this: the wizard's own report said the bundle id was `com.robvb.hoppa` and the project said
    `Rob-van-Baaren.Hoppa`. **Read the artefact, not the report about the artefact.** Rob caught it
    by looking at Xcode; nothing on this side would have.
  - **There is Swift on the VPS now, and it is the same 6.3.3 the Mac runs.** The charter above
    said the agent cannot compile, and for anything touching SwiftUI, UIKit or a simulator that is
    still true — **the Mac still builds and runs the app**. What changed at
    [Swift on the VPS](0022-swift-on-the-vps.md) is that `app/HoppaRules`, which imports nothing,
    builds and tests *here*. Run `swift test` before every push; do not send unproven rules to the
    Mac to find out whether they parse. `swift` is on `PATH` via `/usr/local/bin`, and
    `.swift-version` pins the toolchain.
    **It reaches further than "imports nothing".** At
    [The view layer around the rules](0024-the-view-layer-around-the-rules.md) both `Foundation` and
    `Observation` were checked here — an `@Observable` class with `withObservationTracking` and a
    `FileManager` call compile and run under `-swift-version 6`. So a package is Mac-only when it
    imports **SwiftUI or UIKit**, or needs a simulator or a device; not merely because it touches
    files or state. Test that assumption before accepting it: it has now been wrong once.
    **And the line can be pushed further still.** At
    [The Logbook on disk](0025-the-logbook-on-disk.md) a file in the *app target* was type-checked
    here — `HarnessSeed.swift` imports no SwiftUI, so `swiftc -typecheck -I <the built modules>`
    compiled it against the real `HoppaRules` and `HoppaStore`. The same trick took every store and
    rules call the SwiftUI harness makes, lifted into a throwaway file, and proved the API names.
    **Being in the app target is not the same as being unprovable here**; what is genuinely Mac-only
    is the SwiftUI itself.
  - **`SPEC.md` §8.2 is the known-defect list.** The `Fitty` module in
    `design/0007-logging/fitty-workout-logging.html` predates three later tickets and is wrong in
    eight named ways. The spec is right and the code is wrong. Fix them in the lift; never port a
    defect forward.
  - ~~The app is called **Fitty** here, as a working name. The definitive name is out of scope, as
    it was on the design map.~~ **Superseded.** Rob named the app **Hoppa** while answering
    [An empty app on the phone](0018-an-empty-app-on-the-phone.md); the Xcode project, the target
    and the bundle id `com.robvb.hoppa` are already Hoppa, and the rest of the repo caught up at
    [The app is called Hoppa](0021-the-app-is-called-hoppa.md), which is where this map took its
    own title. **`Fitty` still appears, and where it does it is correct**: it names the prototype's
    JavaScript module, the `design/*/fitty-*.html` files, and the closed design-map issues. It is an
    artefact name, not the product's.

## Decisions so far

<!-- one line per closed ticket -->

- **[An empty app on the phone](0018-an-empty-app-on-the-phone.md)** — Hoppa runs on Rob's iPhone 16
  and **the build lasts a year**, not seven days: the paid Apple Developer route, profile expiring
  2027-08-20. `com.robvb.hoppa`, iOS 17.0 minimum, portrait-only iPhone, Xcode 26.6 / Swift 6.3.3.
  Anton and IBM Plex Sans are bundled and confirmed rendering on the device. No ticket has to plan
  around re-installing weekly.

- **[The rules module and its oracle](0020-the-rules-module-and-its-oracle.md)** — the rules become
  **`app/HoppaRules`**, a local Swift package that **imports nothing** (no SwiftUI, no SwiftData,
  **no Foundation**); the clock enters as a `Timestamp` argument on `reduce`, never inside an action.
  It owns the domain value types, so **storage maps to the rules**. **Swift becomes the only
  implementation** — no JavaScript oracle, because `fixture.json` predates the roll-up and is not a
  valid golden file. Proof is four layers: eight red tests for the §8.2 defects, hand-written
  invariant tests, the nine walkthroughs, and a committed 56-Workout snapshot. Swift Testing. The
  build splits into [Swift on the VPS](0022-swift-on-the-vps.md) and
  [Lift the rules into HoppaRules](0023-lift-the-rules-into-hopparules.md), because **there is no
  Swift toolchain on the VPS** and untested rules are this map's worst failure mode.

- **[Swift on the VPS](0022-swift-on-the-vps.md)** — **Swift 6.3.3 is installed here, and the drift
  the ticket braced for is zero**: the same point release the Mac runs, so `swift-tools-version: 6.0`
  straddles nothing. Installed with swiftly, symlinked into `/usr/local/bin` because a plain
  `bash -c` never reads `/root/.profile`. The install re-proved this map's own lesson: a clean
  `swift --version` printed **`libc not found … C stdlib may be unavailable`** and reported its
  version anyway — **a version string is not proof, a green test is**. Two facts ticket 0023 now
  depends on: **a red test exits `1`** (its eight deliberately-red §8.2 tests would otherwise pass
  in silence), and `swift test`'s **`Executed 0 tests`** line is the idle XCTest harness, not a
  failure. Disk: 1.2 GB free at 97%, and the bulk was in **henk's** npm cache (8.0 GB), not root's
  where the ticket pointed; `npm cache clean` on both users reclaimed 9.9 GB and touched nothing
  else. 7.3 GB free after the 3.3 GB toolchain.

- **[The app is called Hoppa](0021-the-app-is-called-hoppa.md)** — the repo says **Hoppa** for the
  product and **`Fitty` only for artefacts that still carry that name**. That split was the whole
  ticket: of 41 files holding the word, two thirds name the prototype module, the `fitty-*.html`
  paths, the design map's title or a published artboard, and a blanket `sed` would have broken five
  live links and made §8 describe a module that is not there. Swept: `SPEC.md` (57), `CONTEXT.md`
  (23), the build-map issues, and the wizard. `SPEC.md` §10 lost **"the definitive app name"** —
  it is decided — and gained **whether `Hoppa` survives an App Store name check**, which is the part
  still out of scope. Rob's three scope calls: the closed design-map issues `0001`–`0016` stay
  untouched as a record; **both GitHub repos keep their names** (this one is `rob-vb/hoppa-ios`, the
  Expo test app keeps the plain `rob-vb/hoppa`); and the VPS folder stays `/home/henk/fitty`,
  because a folder name is not a product name.

- **[Persistence and the data model](0019-persistence-and-the-data-model.md)** — **one JSON
  document**, `Logbook`, holding the value types `HoppaRules` already owns. No SwiftData: it needs
  `@Model` classes, which cannot be those value types, so it buys convenience with a second model.
  Five findings mattered more than the choice. A Workout now stores **what progression did**, because
  §6.7's green dots and Set grid were being solved live off an editable Rep Range — §2.5's defect in
  a second place. **A weight is `Int` hundredths carrying its own unit**, never a `Double`, so
  `≈ CLOSEST` stays exact and the committed snapshot stays byte-stable. The active One-off Weight and
  `restStartedAt` had **no field at all** and were lost on a relaunch. The Weight Unit of a
  plate-loaded Exercise is now **derived** from the Plate Inventory, not stored twice. Ids are a
  counter, not `UUID`, because the snapshot must be deterministic. `SPEC.md` gained §2.8 and a §2.4
  row; the glossary gained **Logbook**, **Performed Exercise** and **Progression Outcome**. The build
  splits into [Lift the rules into HoppaRules](0023-lift-the-rules-into-hopparules.md) and
  [The Logbook on disk](0025-the-logbook-on-disk.md).

- **[Lift the rules into HoppaRules](0023-lift-the-rules-into-hopparules.md)** — **`app/HoppaRules`
  is built and 46 tests are green on the VPS**, in five layers: nine defect tests, twenty invariants,
  the nine walkthroughs, a committed `Logbook` round-trip and a committed 56-Workout snapshot. Each
  defect test was proved load-bearing by re-breaking its rule. Three findings outrank the code.
  **Ticket 20's signature could not stand**: progression writes to the *Program*, so `reduce` takes
  and returns the whole `Logbook` — everything else about the boundary held. **§8.2 listed eight
  defects and there are nine**: the prototype rounds the pin *up*, drawing a weight the user is not
  lifting; `SPEC.md` gained the row. And **`gen-fixture.mjs`'s 0.25 kg Microplate did not port** —
  it was chosen to keep sixteen weeks under one Stack Step, so the Swift run uses the 1 kg plate and
  the pin moves twice, which is the whole point of committing a snapshot. Inside the lift:
  `ResolvedExercise` became the one place a derived unit is worked out, `currentIndex` went on the
  `Workout` rather than into the view, and the bar is solved on the doubled total so a per-side
  target of 20.625 never has to exist. §6.6's other Program edits are rules with nowhere to live,
  and they graduate as
  [Program edits, and which of them are rules](0026-program-edits-and-the-rules-boundary.md).

- **[The view layer around the rules](0024-the-view-layer-around-the-rules.md)** — the seam is **one
  package, `app/HoppaStore`**, defined by what it may not import: `HoppaRules`, `Foundation` and
  `Observation`, and **never SwiftUI**, so view state cannot creep back into the store by discipline
  failing. The bigger find is that **it builds and tests on the VPS** — `@Observable` and
  `FileManager` both compile and run here, checked before the question was put — so the code that can
  erase Rob's training is provable next to the rules it forwards to. `@MainActor LogbookStore` takes a
  **URL** (not a protocol, so the tests run the real atomic write), owns the clock but **not the id
  counter** — ticket 19 said it did, and ticket 23's `Logbook.nextId` had already overtaken that — and
  exposes **one `send(Action)`**. Loading has **three** outcomes: no file is `.empty`, a corrupt file
  **or one from a newer `schemaVersion`** is `.unreadable` with no `Logbook` at all, because an empty
  Logbook plus a flag looks like a fresh install with everything gone. Migration is **additive by
  default**; a numbered step works on JSON, never on frozen per-version structs, and every bump commits
  a real old file. Views keep the keypad buffer, the sheets and the `NavigationStack` path in `@State`
  and read `ResolvedExercise` directly — no screen projection, which would be a third model. The Rest
  Timer is a `TimelineView` over `now − restStartedAt`, which **closes the backgrounding fog**: elapsed
  time is subtraction, so a lock, a background and a call cost no code.
  [The Logbook on disk](0025-the-logbook-on-disk.md) was rewritten off the Mac onto the VPS.

- **[The Logbook on disk](0025-the-logbook-on-disk.md)** — **`app/HoppaStore` is built, and the
  force-quit passes on Rob's phone** (2026-08-20): kill it from the app switcher mid-Workout and
  `Upper A`, `Sets logged 2` and `Current index 0` all come back. The suite was green here first;
  a test on the VPS is not a phone, and this map checks the artefact rather than the report about
  it. The store came out as ticket 24 drew it — `send` is four
  lines, three of them guards — so the findings outrank the code. **"Additive migration needs no
  step" is only true for an `Optional` field**: Swift's synthesised `Codable` decodes an Optional
  with `decodeIfPresent` and everything else with plain `decode`, so a non-Optional property fails
  on an older file *even with a default in `init`*. A session adding `var restGoal: Int = 90` would
  have made every existing logbook `.unreadable`. Both directions are now tests. The **migration
  engine is tested with no migration to run** — `migrate` takes its step table as an argument, so
  chaining, version-stamping and a missing step are all proved before the first real bump. **`.atomic`
  *is* the temporary-file-then-rename**, done by Foundation; hand-rolling it would mean hand-rolling
  the one path that must behave the same on Darwin and on Linux. Every guard was re-broken and five
  of six turned a suite red; **the sixth says so in the code** — `send`'s no-Logbook guard cannot
  fail a test today because `Logbook.empty` is a fixed point under all twelve actions, and it stops
  being harmless the moment ticket 26 lands an action that creates a Program. The **Exercise
  Catalogue is written**: 157 names, with §6.3's order and prefix rule checked mechanically, because
  both are checkable against the list of strings alone. Its **matching and ranking are not**, and
  they graduate as
  [Name suggestions, and where a rule that needs Foundation lives](0027-name-suggestions-and-foundation.md).
  The Xcode project is **already patched** — 16 additive lines, `relativePath = ../HoppaStore`, plus
  the two Info.plist flags as build settings.

- **[Program edits, and which of them are rules](0026-program-edits-and-the-rules-boundary.md)** —
  **every §6.6 edit is an `Action` on `HoppaRules`**, flat beside the logging ones, each naming its
  target id; the split lives in `Rules+Edit.swift`, not in the type. The sheet is Model B and saves
  once, so an Exercise edit is **one action carrying a draft**, and §6.6's rules are the **diff** —
  ten per-field actions would let a sheet clear the weight it was just given. One model change:
  `workingWeight` and `increment` become `Weight?`, because **an unset weight is not zero** and zero
  is a real Bodyweight lift; the Re-weigh list is then `nil` rather than a list anyone writes down.
  It needs **no migration step** — ticket 25's finding read forwards says widening to `Optional` is
  the safe direction — but a committed v1 file proves it. §3.2 was wrong twice: read literally it
  reopens a **Done early** Exercise, which its own reason refuses, and it never said that
  **lowering** the planned Sets completes an Open Exercise — without which the Exercise is stuck
  Open and holds the Finish gate at the rack. **Stranding was never implemented**: a switched-off
  Microplate still moves the weight today, a live defect the 46 green tests never met. It is derived,
  like the Re-weigh list and the counts — four pure queries, because a warning must ask **before**
  the act and a silent no-op is not a block. Every structural edit **mirrors into the Open Workout**,
  and `currentIndex` follows the `ExerciseID`, not the position. The build graduates as
  [Build the Program edits](0028-build-the-program-edits.md).

- **[Name suggestions, and where a rule that needs Foundation lives](0027-name-suggestions-and-foundation.md)**
  — **the third boundary is not drawn, because §6.3 never needed Foundation.** Four facts, all
  checked before a question was put: `lowercased()` is standard library and folds `İ` and `ß`
  correctly with no imports; Swift already compares `é` and `e`+combining-acute as equal, so half of
  "accent-insensitive" was free; the 156-name catalogue holds **no accented letter at all**; and the
  base letter behind an accent is readable from the Unicode names the standard library ships
  (`é` → `LATIN SMALL LETTER E WITH ACUTE`), so folding is ten lines and **no hand-written table** —
  guarded to a single-letter base, so `ß`, `ı` and `œ` fall through. The ticket existed because
  nobody had compiled the claim; that is now step 2 of the **`is-this-a-rule` test** in Notes. So all
  of §6.3 is a rule in `HoppaRules`, and **the Exercise Catalogue moves down to join it** — ticket
  25's "content, not a rule" is reversed, because the ranking reads both sources and de-duplicates
  across them. Four rules the spec left loose: **most recently used means most recently *trained***,
  `openWorkout` included, never-trained names under them; **six rows while typing too**, not only on
  focus; a duplicate **keeps its own-names row**; a word breaks on a space or a hyphen, **not** on an
  apostrophe. One risk carried forward: the Unicode name tables are proved on Linux, and
  `fold("é") == "e"` is the Mac's own check — red there means drop folding and keep `lowercased()`.
  The build **merged into** [Build the Program edits](0028-build-the-program-edits.md) as piece 5,
  rather than taking a ticket: same package, same Mac session.

- **[Build the Program edits](0028-build-the-program-edits.md)** — **§6.6 and §6.3 are built, and
  `swift test` is green here: 98 tests in `HoppaRules`, 25 in `HoppaStore`.** Every guard was
  re-broken and **36 of 36 turned a suite red**; the committed 56-Workout snapshot did not move a
  byte, which is what proves widening two fields to `Optional` changed nothing that was already set.
  Four findings outrank the code. **§6.6 says "the four Equipment Types that carry their own unit"
  and names Bodyweight — there are three**, and §2.3, §5.1, §6.6's own next paragraph and its
  Microload table all always said so; the code had to pick, so the spec is fixed. **A change of
  Equipment Type is a change of unit**: the unit is derived, so a Dumbbell in lbs turned into a
  Barbell now reads a kg rack and its `100` means something nobody typed — the clearing rule watches
  the unit the Exercise *resolves to*, and the mirror of that is writing a Base Weight back **only
  where the new type shows the row**, so `nil` never means *cleared* when it meant *absent*.
  **`isStranded` is a fact about the Increment, not about progression** — ticket 26 read literally
  stops a Progressive Overload Exercise for a Microplate it never uses, so the guard sits inside the
  Microloading branch. And §6.3 had three rules nobody had needed until now: **trained means at
  least one logged Set**, the fold must **drop a combining mark** or `é` matches `e` in one spelling
  and not the other, and a word-start match is a match **at** a word start, so `bench p` finds
  `Barbell Bench Press`. Ticket 25's sixth guard is paid off: `createProgram` at an `.unreadable`
  store writes nothing, and the same action on a fresh install lands. `project.pbxproj` needed no
  edit.

- **[Build order across the flows, and what done means for a screen](0029-build-order-and-what-done-means.md)**
  — **the way to the destination is eight tickets and three hand-offs.** Build order is
  **shell + Flow 1 → Flow 2 → Flow 3**, the *trainable* milestone, chosen by what the destination
  is rather than by which screen has the most rules under it: Flow 2 is the screen at the rack, but
  it can only log against `HarnessSeed` until Flow 1 exists, and **a fake Program is not the app**.
  Flow 4 goes last because **a chart needs weeks of Workouts to be testable at all**. The eight are
  [the shell](0032-the-shell-and-the-first-run.md),
  [the name and the rack](0033-the-program-name-and-the-plate-rack.md),
  [the hub and the Day](0034-the-program-sheet-and-the-workout-day.md),
  [the Exercise sheet](0035-the-exercise-sheet.md),
  [the logging screen](0036-the-logging-screen.md), [the weight sheet](0037-the-weight-sheet.md),
  [the Summary](0038-the-workout-summary.md) and [the confetti](0039-the-ignition-confetti.md) —
  one screen plus the sheets only it opens, a linear chain because each screen needs its own way in.
  **The whole chain is blocked today**, so the frontier is
  [Dark only, or a light mode too](0030-dark-only-or-a-light-mode.md) and
  [Drawing the loaded bar and the Ignition confetti](0031-drawing-the-bar-and-the-confetti.md) and
  nothing else. Three rules now live in Notes: **`SPEC.md` beats the artboard** (§8.2 lists nine
  defects, so an artboard is a reference with known errors), **a screen ticket closes when pushed,
  not when Rob has seen it** — otherwise his build sessions sit on the map's critical path, the exact
  cost he refused at ticket 25 — and **no UI tests**, because XCUITest spends the scarce resource and
  every rule under every screen is already green. Two spec gaps closed on the way: **the first run
  had no screen** and is now the empty picker with `CREATE A PROGRAM`, not a jump into step 1, so the
  picker keeps one role (`SPEC.md` §6.1); and **the Program sheet is in two flows at once**, so
  ticket 34 builds only what onboarding needs and leaves everything carrying a warning or a mirror
  into the Open Workout to Flow 5. `AcceptanceHarness` dies at ticket 32; **`HarnessSeed` survives
  behind a debug switch**, because Flow 4 needs sixteen weeks of history and typing that on a phone
  is not a test.

- **[Dark only, or a light mode too](0030-dark-only-or-a-light-mode.md)** — **dark only, locked in
  both places**, because `.preferredColorScheme(.dark)` pins the SwiftUI hierarchy and nothing else;
  `UIUserInterfaceStyle = Dark` is now on both configurations so the launch screen agrees. **Dynamic
  Type is ignored too**, and that is not free: `Font.custom(_:size:)` **scales by default** and only
  `fixedSize` does not, so §7.4's fixed points need `.dynamicTypeSize(.large)` at the root and a
  `Typography.swift` no view may bypass. A light mode is **out of scope, not fog** — §7.3's plate
  colours are physical and cannot invert, so it is a design effort riding with the launch. Two
  findings outrank the decision. **The word *steel* had two values in two files**: `PlatePalette`
  called `#3A3E42` steel and §7.2 calls `#9BA1A7` steel — the plate one was the **chip border**. The
  boundary that settles it is **the rules own a fact about a plate, the app owns a surface role**, so
  `PlatePalette` is now `hex(for:)` and nothing else; a floor colour fails the `is-this-a-rule` test's
  *must* clause, and a plate colour does not. 98 green. And **the artboard uses 38 hexes where the
  spec names 16**, which is why §7.2 now bans a literal in a view and makes a **new hue a finding
  with a ticket** — a rule that fires **zero times** on the logging artboard: the gold is the deleted
  15 kg plate, the amber is the `PROTOTYPE — THROWAWAY` banner, the red pair contradicts §7.1's
  `#C8322B` DELETE, and the rest are tints of a named role.

- **[Drawing the loaded bar and the Ignition confetti natively](0031-drawing-the-bar-and-the-confetti.md)**
  — **plain `Shape`s for the bar, `Canvas` + `TimelineView` for the confetti**, which is the reverse
  of the reflex. One fact read twice: **`Canvas` gives you a draw call and takes away layout.** The
  bar is layout and no animation — it is an `HStack` of rounded rectangles, and §7.1 rule 2 becomes
  a fill/stroke distinction the type system carries. The confetti is a **physics integration**
  (gravity, drag, spin), which no animation curve expresses, so something steps state per frame
  whichever technique wins — and then one `Canvas` draws ~75 slabs with no view identity to keep.
  `SpriteKit` and `CAEmitterLayer` both need a bespoke image for a hollow steel particle; `Canvas`
  strokes a rounded rect. **No Mac session of its own**: Rob folded both drawings into the existing
  batches, so the bar rides Batch 2 and the confetti rides Batch 3. The one thing argument cannot
  settle — whether ~75 particles hold 60 fps — is answered there for free.
  **Reduce Motion is honoured**, unlike Appearance and Dynamic Type: the 190 ms row sequence stays
  and the burst does not fire, because the sequence is *why* Ignition won and the cloud is the part
  that causes trouble.
  **Which plates a burst throws is a rule**, and the line is: the `Logbook` decides the colours, and
  the arc is random by design. `Rules.burstSource(_:)` returns the sampling list, one entry per
  plate, so §6.5's proportional-by-count falls out of uniform picking for free. It kills §8.2's
  first summary defect — the prototype threw the Increment plate for every non-plate-loaded type.
  **107 green**, up from 98. Two edges stated: everything on the pin throws, not just the Microload;
  and an empty source throws steel, because every Went-up row must land.
  **The steel of a drawing is one hue at seven lightnesses.** Measured: every grey in §7.2 *and*
  both prototypes sits on **hue 210° at 4–10% saturation**, so `Steel.hex(lightness:)` derives them
  all from §7.2's `#9BA1A7` — **zero new hues, zero findings**, the second time ticket 30's
  escalation rule has fired nothing. It imports nothing, so it was compiled and run here, and the
  run caught what no reading would: **`Double.rounded()` is libm, and libm is not linked without
  Foundation.** The `is-this-a-rule` test's step 2 now bites *view* files too.

- **[The shell and the first run](0032-the-shell-and-the-first-run.md)** — **the picker is the app's
  home and `AcceptanceHarness` is dead.** 112 green in `HoppaRules`, 31 in `HoppaStore`, and
  `project.pbxproj` needed **no edit** — the app target is a synchronized folder group, so Xcode
  finds four new files and one deleted one by itself. Four findings outrank the code. **"4 days ago"
  is not a rule**: the *instant* is (`Logbook.lastTrained`), but the phrasing needs a calendar and a
  zone, and two lifters in two zones may correctly disagree — 21:00 read at 07:00 is ten hours ago
  and reads `Yesterday`, 00:10 read at 07:00 is seven and reads `Today`. **It still went below the
  view**, because ticket 29 says logic worth testing belongs in a package, so `RelativeDay` sits in
  `HoppaStore` with nine cases including the 25-hour DST day and a clock that moved back. **§3.1 had
  no answer for a Day never done** — `Never`, and it is the common first case, not an edge, because
  every Day of a fresh Program is in it; the spec also gained *newest **finished** Workout, by the
  day it **started***, since counting the Open Workout would claim the user trained the moment he
  tapped a row. And **ticket 30's escalation rule fired for the first time and added a role, not a
  finding**: the artboards use two text greys where §7.2 named one, and `#55595D` measures hue 210°
  at 4.5% — the same spine, within 2/255 of `Steel.hex(lightness: 0.349)`. §7.2 is seven roles now.
  Three calls the ticket left open: a door to an unbuilt screen is **live and lands on
  `NotBuiltYet`** rather than disabled, because a disabled row proves nothing about the spine and
  ticket 29 wants *what is not built yet* stated; **tapping a Day does not start the Workout**, so a
  tap cannot strand an Open Workout with no screen to end it; and the **`•••` is the door to Flow 5's
  hub**, since §6.7's *two doors* counts the doors into History. Two things only the Mac can answer:
  `Font.leading(.tight)` approximates §7.4's 0.78–0.94 and **ticket 33's `NAME YOUR PROGRAM` is the
  first multi-line display heading**, and `monospacedDigit()` falls back silently if Plex has no
  `tnum`. §3.3's *resume, finish, or discard* had no screen and graduates as
  [The Open Workout on next open](0040-the-open-workout-on-next-open.md).
- [The Program name, the three assumptions, and the Plate Inventory screen](0033-the-program-name-and-the-plate-rack.md)
  — **onboarding steps 1 and 2 are built and pushed.** `HoppaRules` **118 green**, `HoppaStore` 31.
  Four findings. **§5.2's footer is a rule** — `Smallest jump on the bar` falls out of the rack alone
  and every lifter holding that rack must read the same number, so it is
  `PlateInventory.smallestJumpOnTheBar(for:)` with six tests, and **the jump is twice the plate**
  because a bar has two sides. **§5.2 had no answer for a rack with nothing switched on**, which the
  screen can reach: the footer reads `No plate is switched on.`, never `0 kg`, which would claim the
  bar moves in steps of nothing. **The Program is created at step 2's confirm, not step 1's
  `CONTINUE`** — creating it early strands a Program with no Days the moment the user backs out, and
  the picker's `CREATE A PROGRAM` is gone with it; the rack goes the other way and writes through at
  once, because it is Logbook-level and belongs to no Program. And **§7.1's size law does not bind
  this screen**: it states its own boundary — *both rules are rules about the Plate Breakdown* — and
  a toggle list is not one, so the chips scale by **rank inside their group** rather than at §7.3's
  quarter-of-the-smallest, which in a row would be 3 pt of colour. Three calls the ticket left open:
  a Program **must be named** and `CONTINUE` says so under the field rather than going grey; the
  **Weight unit row follows the rack** until a hand touches it, which is §6.1's Program-level
  defaulting; and **both steps draw their own back chevron** with the navigation bar hidden, because
  §7.4 leaves the safe top inset empty. §5.2 and §6.1 carry the first three.
- [The Program sheet hub and the Workout Day screen](0034-the-program-sheet-and-the-workout-day.md)
  — **§6.1 step 3 and the room under it are built and pushed.** `HoppaRules` **119 green**,
  `HoppaStore` 31, and `project.pbxproj` needed no edit. Four findings. **Step 3 and Flow 5's hub
  are one screen with two lives**, and the difference cannot be derived from the Logbook — a
  Program made a minute ago and one trained on for a year are the same value — so
  `Route.programSheet` carries `onboarding:`, worth exactly two words of chrome: the step count,
  and `START A WORKOUT` against `DONE`. **Both taps go home to the picker**, because §3.1 picks a
  Workout there and never here. **`Route.plateRack(nil)` had no door** — ticket 33 built one screen
  for two jobs and wired only the onboarding one — so the artboard's settings row was built as a
  real **Program settings** screen (Name, unit, Mode, rack) rather than a `NotBuiltYet`: wider than
  the ticket's cut, recorded rather than hidden, and every one of the four is an `Action`
  `HoppaRules` already tests. It also pays step 1's promise that *you can rename it later*.
  **§6.7 and the Day artboard disagree about what an Exercise card opens** — the chart, or §6.2's
  sheet — and Flow 4 is not scheduled, so the card opens the sheet, the sparkline is not drawn, and
  the collision sits in **Not yet specified**. And **a Workout Day is named before it exists**:
  `.addWorkoutDay` takes the name, so `ADD A DAY` opens a one-field sheet and the Day arrives named
  — 9 taps against §6.2's 10. Three calls the ticket left open: the empty hub **states the rule**
  (`A program needs at least one workout day.`) rather than instructing; a **stranded Exercise says
  so on its card**, in steel and never in a warning colour; and **no SF Symbols** — the `+` is Plex,
  because importing a symbol set is a §7 decision nobody has made. All four of ticket 32's
  `NotBuiltYet` doors are rooms now; the only one left names ticket 35. §6.1 and §6.6 carry the
  first two findings.
- [The Exercise sheet, and the name field](0035-the-exercise-sheet.md) — **§6.2 and §6.3 are built
  and pushed, and batch 1 is a path Rob can walk end to end.** `HoppaRules` 119 green, `HoppaStore`
  31, `project.pbxproj` untouched. **One finding outranks the screen**: §6.6 promises that *the same
  sheet asks for the cleared weights again in the new unit*, and it cannot — `Rules.edited` clears
  them **at the save**, so the number typed into the field the sheet just emptied is cleared with
  the stale ones. Proved on both paths, and it graduates as
  [A weight retyped after a unit change](0041-a-weight-retyped-after-a-unit-change.md); the sheet
  does not work around it, and the **add** life never meets it, so onboarding is untouched. Five
  calls the ticket left open, all now in §6.2. **The two lives leave differently**: an edit sheet
  has an Exercise behind it, so **closing is the save** — no *cancel*, because the same sheet opens
  at the rack where §6.6 refuses to ask twice — while an add sheet's save is the control that says
  so and its `✕` asks before discarding; a swipe-down serves neither, so it is off.
  **`REMOVE EXERCISE` is built** on the sheet the artboard draws it on, wider than ticket 0034's cut
  and recorded rather than hidden: §6.6 gives it no block to state, and a card that opens a sheet
  with no way to remove what it opened is half a room. **The Equipment Type really starts empty** —
  `ExerciseDraft` cannot hold *unpicked*, so the question lives in view state and the save refuses
  until it is answered — and the chips wrap in a small `Layout`, because SwiftUI ships no wrapping
  stack and equal columns clip `BODYWEIGHT`. **The carry-over crosses Workout Days**, and the first
  Exercise of a Program starts at 3 × 8–12 with no `CARRIED OVER` mark. And **the Increment chips
  are offers, not defaults**, because an Increment the user did not pick is a weight Hoppa invented.
  The Microloading row's `+0.5 KG ON THE BAR` is **read out of `Rules.progressionMove`**, probed at
  a zero Working Weight, so the doubling stays in the rule that owns it.

- **What the phone said about the sheet** (2026-08-26, after batch 1 — three fixes, no ticket,
  because none of them touched a rule). A chip could **wrap**: in the Increment row the label takes
  its ideal width and the `Spacer` gives the rest away, so `1.25` broke as `1.` / `25`; chips are
  text and their widths are their own. A tap beside a field **left the keyboard up**: the catcher
  has to live *inside* the `ScrollView`, which hit-tests its own bounds, so a tap never reaches the
  floor behind it. And **`SAVE AND ADD ANOTHER` became `SAVE`, which closes the sheet** — the
  reopened empty sheet read as work thrown away, and the Day screen behind it is the confirmation
  the sheet cannot give. It costs one tap per Exercise (§6.2's budget is now 15 and 422), the
  carry-over is unharmed because it is read off the Day, and the lesson is worth more than the tap:
  **a tap saved that costs the user their confidence is not saved.**

- **[The logging screen](0036-the-logging-screen.md)** — §6.4 is built and pushed: the screen, the
  exercise-list drawer, the `•••` menu and the Finish gate, plus §7.5's loaded bar, the stack, the
  dumbbell and the belt. **§7.1 rule 2 is taken at its word, and the bar does not look like the
  prototype**: steel is a 1 px border and never a fill, so every collar, sleeve stop, knurl, stack
  block and belt clip is a hollow outline where the prototype fills it — the first thing to look at
  on the phone, and a finding with its own ticket if it reads as unfinished. It is also what makes
  an **lbs plate** draw correctly for free: no palette → steel → hollow, at its right size.
  `PlateGlyph` is shaped like `PlatePalette` — a **kg table** at ticket 0031's measured sizes plus a
  microplate step at a quarter of the 1.25, then a **ramp with no cliff** for everything else,
  because `2.5 lbs` is both a normal plate and a Microplate and no weight alone can say which is on
  the bar. It **imports only `HoppaRules`, so it was compiled and run here**. §7.3's rim is real and
  derived (+30/255 per channel), so ticket 0030's escalation rule fires nothing for the third time.
  The **rep counter is view state**, the **Rest Timer holds no clock**, and the **rule chip asks
  `Rules.evaluateProgression`** — including the four cases where a Completed Exercise does not move.
  Three things the ticket did not name are built anyway: the menu (§3.3 puts Discard in one), the
  pop to the picker (ticket 0038 takes it), and a screen for **one Open Workout at a time reached
  mid-session** — which is not ticket 0040 and now says so on ticket 0040.

- **[The weight sheet](0037-the-weight-sheet.md)** — §6.4's sheet is built and pushed, and
  **batch 2 is closed**: start a Workout, log Sets, change a weight. The keypad buffer is a `String`
  in `@State` and becomes a `Weight` once, so **no `Double` reaches the way in**; a third decimal
  keystroke never reaches the buffer at all. §5.4's `≈ CLOSEST` came out of `PlateBreakdownView` as
  `ClosestLine` and now runs live against the number being typed — **one copy of §5.4, two callers**.
  **The `−` / `+` step by what `Rules.progressionMove` moves, probed at zero**, not by the Increment
  field: a bar under Microloading has no Increment and moves by *twice* its Microplate (§4.2), and
  probing keeps the stepper and the rule chip above it printing the same number. And the big finding:
  **§4.3's decision was in a view, and the view had it wrong** — deciding *raise or lower* against
  the performed weight lets a number typed above a standing One-off Weight take the Working Weight
  *down* with no question asked, which is the exact case §4.3 exists to prevent. It is a rule by the
  map's own test, so it is now `Rules.weightEdit`, and §8.2 carries it as row ten of twelve. 128 + 31
  green; the Xcode project needed no edit for the third time.

- **[The Workout Summary](0038-the-workout-summary.md)** — §6.5 is built and pushed, without ticket
  39's confetti, and **count-first so the confetti has something to scale to**. The whole screen is
  a rule with a drawing on it: `Rules.summary(of:in:)` decides the three sections, the added plate
  and every condition line, the view holds no arithmetic, and **fifteen tests reproduce the four
  artboards** — so a screen was checked here for the first time end to end, and a throwaway renderer
  printed all four as text before anything was drawn. §2.5's defect is headed off in the second
  place ticket 38 warned about: the condition line reads the **recorded** outcome, and a test edits
  the Rep Range after Finish to prove it does not move. Three things the spec did not decide, and
  `SPEC.md` §6.5 now does. **"The added plate" is half the Increment on a bar** — a 2.5 kg Increment
  is a 1.25 kg plate — so the `Main` artboard's red chips do not port; they are §8.2's *invented
  colours*, and the Microloading row's steel is §8.2's first summary defect showing up on the chip
  instead of the burst. **"Nowhere to put the plate" is not one sentence**: `Progression.swift`
  recorded an assumption that the Summary states one condition for all four, and §6.6 says the
  opposite, so there are **six named blockers** and writing them out found the sixth. And **volume
  prints whole** — a converted volume lands on hundredths and every artboard shows an integer.
  Two colour roles were needed and both **derive** off `Steel`'s ramp, so ticket 30's escalation
  rule fires nothing for the fourth time. Finish now **replaces** the path rather than popping it,
  and tells Finish from Discard by the finished list growing rather than by the `Action`. 143 + 31
  green; the Xcode project needed no edit for the fourth time.

- **[The Ignition confetti](0039-the-ignition-confetti.md)** — §6.5's burst is built and pushed, and
  **batch 3 is closed**: Finish, and watch the Summary land. The split is the map's own trick pushed
  one step further — **`ParticleField.swift` imports `Foundation` and nothing else**, so gravity,
  drag, spin, the sampling, the fade and the cull were *run* on the VPS, and `Confetti.swift` is left
  with the two lines §7.1 rule 2 turns on. Measured here, not argued: `20 + 10` per side throws
  **3021 blue / 2979 green** over 6000 particles and `20 + 10 + 2.5 + 2.5` throws half grey, which
  are §6.5's own two worked examples; the screen goes quiet at **1.27 s at one Went-up row and
  1.75 s at five**, so the spec's "~1.4 s" is right at the small counts and stretches at the big
  ones. Two things in the prototype do not port. **Its constants are per frame and its browser ran
  at 60 Hz**, so the field steps a fixed 1/60 s off the real clock — a 120 Hz phone must not fall
  twice as fast. And **its 34 x 12 spawn box is variant B's jitter left in place**; §6.5 fires from
  the row's own chip, so the particles spawn across the chip's 9 x 34 rectangle. The chip hands its
  rectangle to the canvas through a `PreferenceKey` in a shared coordinate space, because
  `onGeometryChange` is iOS 18 and this app is iOS 17. **No rule was added** — ticket 31 had already
  written `Rules.burstSource(_:)` and its nine tests — so 143 + 31 green, unchanged, and the Xcode
  project needed no edit for the fifth time. What no type-check can judge is now the whole of batch
  3: **whether ~75 particles hold 60 fps on the phone**, and whether the burst reads as plates.

- **[The Open Workout on next open](0040-the-open-workout-on-next-open.md)** — §3.3's last line
  has a screen, and it is a sheet over the picker. **An *earlier day* is a calendar day**, and
  it is `RelativeDay.isEarlierDay` beside the picker line rather than a second day rule: the
  ticket asked whether it wants the same answer as `RelativeDay` and it does. What settled it was
  a fact about the model, not a preference — **a `Workout` carries one clock, `startedAt`,
  because a `LoggedSet` has no timestamp**, so *hours since the last Set* is not a question this
  model can answer. The one cost is written down as a test rather than discovered later: a
  session across midnight is a new calendar day, so Hoppa asks, and *resume* is one tap.
  `HoppaStore` 31 → **36**, `HoppaRules` 143 unchanged. On the picker the running Day's line
  reads `Running` **in place of** its last-trained line, and **the other rows stay tappable** —
  ticket 36 already built the arrival that explains, and a dead row would refuse in silence.
  Two things the question forced that the ticket had not listed: **Finish takes §3.3's shortcut
  in place**, carrying *"3 exercises still open · will be skipped"* as the row's own subtitle so
  one tap finishes and no second sheet stacks on the picker; and the question **returns at the
  next launch, not at every glance** home from the Program sheet, because Hoppa never ends a
  Workout by itself but must not stand in the way of an edit either. No rule and no `Action` was
  added — the three answers have existed since ticket 20 — and the Xcode project needed no edit
  for the sixth time. **This opens batch 4**, and it comes with a wrinkle ticket 29's hand-off
  rule has not met before: **the trigger cannot be walked without moving the phone's clock**, so
  the hand-off has to say so rather than let a quiet picker read as a defect.
- [A weight retyped after a unit change, on the sheet that cleared it](0041-a-weight-retyped-after-a-unit-change.md)
  — **the draft carries the unit its numbers are written in**, and `Rules.edited` clears a field
  when that unit is not the one the Exercise now resolves to. §6.6's promise that *the same sheet
  asks for them again* holds from here. The number's own label was the cheapest signal and the
  wrong one: `Weight.relabelled` exists because a stored label **may be stale by design** (§2.8),
  and the sheet opens by copying stored labels — reading it would make a documented *may be stale*
  load-bearing. The fix stays a rule rather than moving to the view, because it decides an outcome
  from the `Logbook`; what is **not** in the `Logbook` is which unit the user was looking at, which
  is why it rides in the draft — *the sheet as the user left it* — and not in the rule's arguments.
  **One `if` became two triggers**: the three typed fields go when the draft was typed in another
  unit, the **Microload** goes when the Exercise's unit moves, retyped or not. Exactly §6.6's three
  fields; the Microloading Increment and the Base Weight are in the rack's unit and only the rack
  can move them. The **add path runs the same guard**, because an add sheet can type a weight and
  then pick another Equipment Type. `shownUnit` takes **no default** — a default makes *in which
  unit are these numbers* the one thing a caller can forget. `HoppaRules` 143 → **147**, and every
  existing clearing test passes **unchanged**: a draft that flips the unit and leaves the numbers
  alone is exactly *the user did not retype*. It opened
  [The numbers a mis-tap cleared](0043-the-numbers-a-mistap-cleared.md) — on an edit sheet closing
  **is** the save, so one wrong tap on the unit row destroys three numbers with no way back.
- [The numbers a mis-tap cleared, and the unit that came back](0043-the-numbers-a-mistap-cleared.md)
  — **a file per unit, and not a memory of the unit at open.** The three fields §6.6 takes off the
  screen go into `UnitStash` under the unit they were typed in, and come back when that unit does;
  tapping the row again is a full undo. That one shape answered all three of the ticket's
  questions: the add sheet's free first move carries an empty screen and so files nothing, a number
  retyped after the flip survives **under its own label** with nothing converted or merged (§5.1
  inside the sheet), and the note no longer says *cleared* because nothing is — it says where the
  numbers went and how to get them back, in both directions at once. **The logic left the view**:
  it is not a rule, since it decides nothing from the `Logbook` and is the state of one visit to
  one sheet — so it went to neither `HoppaRules` nor the view, but to a plain value in the **app
  target** that imports no SwiftUI and is therefore provable here. That is ticket 29's *no UI
  tests* rule doing what it was written for, and it bought **34 checks** in
  `app/checks/UnitStash/`, compiled against the real file and saving through `Rules.reduce`.
  Building it found a second defect the ticket had not named: an add draft opened on `rack.unit`
  while the sheet drew the **Program's default**, so a weight typed before the first Equipment Type
  pick was judged against a label it was never typed under and thrown away at the save.

## Not yet specified

- **Who owns `project.pbxproj`, and what a conflict in it costs.** The VPS/Mac loop means two
  machines edit the same Xcode project file — the agent by patching it, Xcode by regenerating it.
  It is a merge conflict waiting to happen, in a file no one wants to hand-merge. Not sharp until
  the loop has run a few times and shown which edits actually collide. The loop's **first** run
  already drew blood, though in a smaller way: see the charter bullet on the nested repo.
  **The first deliberate hand-off ran clean.** Adding `app/HoppaRules` through *Add Local* wrote
  **23 additive lines** and changed none: a `PBXBuildFile`, one entry in each of `files`,
  `packageProductDependencies` and `packageReferences`, and two new sections at the end. The line
  that decides whether this file survives two machines is
  `relativePath = ../HoppaRules` — **relative, not absolute**, so the reference needs no edit on
  either side. One clean run is not a rule, but it narrows the question: the risk is concurrent
  *additions* landing in the same list, not a path that only works on one machine.
  **The second hand-off went the other way: the agent wrote it.** At
  [The Logbook on disk](0025-the-logbook-on-disk.md) `HoppaStore` was added by patching
  `project.pbxproj` here rather than by *Add Local…* on the Mac — 16 additive lines in the same six
  places Xcode used, plus two `INFOPLIST_KEY_*` build settings. It saves a round trip, which is this
  loop's expensive unit, and it is unverified until Rob opens the project. Whether the agent *should*
  own this file is the live half of this question, and there is now one instance of each direction
  to judge it on. **Xcode accepted the hand-patched file** when Rob opened it on 2026-08-20 — the
  project builds and the store runs on the phone — so the agent-written direction has now run clean
  as well, and neither direction has yet cost anything.
  **A third hand-off needed no edit at all.** [Build the Program edits](0028-build-the-program-edits.md)
  moved a source file *between* the two packages and added four more, and Xcode never has to know:
  both are path references and SPM globs their sources, so the file list is not in `project.pbxproj`
  to begin with. The question is narrower again — it is about **adding a package or a target**, and
  nothing else.
- **Deleting a Program.** §6.6 specifies deleting an Exercise and a Workout Day, with two blocks.
  §2.1 allows more than one Program. Nothing says what a whole Program delete does, or whether the
  last Program is blocked the way the last Workout Day is. Found while working
  [Persistence and the data model](0019-persistence-and-the-data-model.md), which deliberately did
  not decide it: it is a gap in the spec, not a rule that is wrong. The model survives either way —
  a Workout keeps its Workout Day's Name — so this is a flows question, not a storage one.
  [Program edits, and which of them are rules](0026-program-edits-and-the-rules-boundary.md) settled
  deleting an Exercise and a Workout Day, which §6.6 *does* specify, and deliberately left this one
  here — it is a gap in the spec, so it needs a decision and not a build.
- **Flow 5's remaining screens, and all of Flow 4.** Reorder handles, deleting an Exercise or a
  Workout Day, the two warning dialogs and the Re-weigh list (§6.6); the history list, the streak and
  the per-Exercise chart (§6.7). **These are fully specified and sharp enough to ticket today** —
  they sit here as a scheduling choice, not a gap. Their slicing changes with what real training
  teaches, and this map already expects findings from the rack; the history screen and the Program
  edits are where those land hardest. They graduate once Rob has trained with Flow 1–3. Held at
  [Build order across the flows, and what done means for a screen](0029-build-order-and-what-done-means.md).
- **What an Exercise card opens, once the chart exists.** §6.7 says an Exercise card in the Program
  sheet opens **that Exercise's chart**, and gives it a sparkline so the door announces itself. The
  Day artboard's own caption says **tap a row to open it**, meaning §6.2's sheet, which is the only
  room that exists today — so
  [The Program sheet hub and the Workout Day screen](0034-the-program-sheet-and-the-workout-day.md)
  built the card as a door to the sheet and drew no sparkline. When Flow 4 lands the card carries
  two doors and somebody has to say which one is the whole card: the sparkline alone into the chart
  and the rest into the sheet, a `•••`, or a swap. Not sharp until the chart is being built, and it
  graduates with §6.7. Found while building.

- **Increase Contrast, and the rest of the accessibility settings.** [Dark only, or a light mode
  too](0030-dark-only-or-a-light-mode.md) settled the two that reach every screen — Appearance and
  Dynamic Type — and **Reduce Motion is now settled too**, at
  [Drawing the loaded bar and the Ignition confetti](0031-drawing-the-bar-and-the-confetti.md): the
  rows still land, the particles do not. Increase Contrast is left because §7.2's
  dim text `#8D9296` on the `#0E0F10` floor is the only place it plainly bites, and nobody has
  looked at that ratio yet. Not sharp until a screen exists to look at. VoiceOver and the rest have
  not been considered at all, which is a statement of fact rather than a decision.
- **More than one Program, and which one the picker shows.** §2.1 allows more than one and §6.3
  reads Exercise names across all of them, but nothing says how the user holds two, switches between
  them, or what the picker's header names. [The shell and the first
  run](0032-the-shell-and-the-first-run.md) reads `programs.first` and is correct today, because the
  only way to create a Program is onboarding and onboarding is only reachable from the empty state.
  It is silently wrong the day a second one can exist. Sits beside **Deleting a Program** above —
  both are the same gap in §2.1 seen from two sides, and they may well graduate as one ticket.
- **The lbs rack, which nothing has painted and nothing has walked.** Two facts have now piled up
  behind the `KG | LBS` toggle, and neither is sharp enough to ticket. **§7.3 paints one gym's iron
  rack in kg only**, so `PlatePalette.hex(for:)` answers `nil` for every lbs plate and the Plate
  Inventory draws ten steel chips — the colour half of §7.1's first rule is simply absent there, and
  only the height ramp survives. And **`2.5 lbs` sits in both the normal and the Microplate group**
  of the shipped rack; `PlateInventory` documents it and `plates(for:)` de-duplicates it for the
  solver, but `setPlate` switches a size *in whichever group holds it*, so tapping one of those two
  rows moves both. That is arguably right — it is one physical plate — which is exactly why it is a
  question and not a defect. Both found while building [The Program name, the three assumptions, and
  the Plate Inventory screen](0033-the-program-name-and-the-plate-rack.md), and neither costs
  anything today: Rob's rack is kg. This graduates if the destination ever moves to a second lifter,
  which today it does not.
- **A weight sheet for a mixed-unit pin.** Now a sharp enough question to be a ticket, and it is
  one: [The MICRO stepper on a mixed-unit pin](0042-the-micro-stepper-on-a-mixed-unit-pin.md). It
  sits beside **the lbs rack** above for the same reason — Rob's rack is kg, his stacks are kg, and
  the case costs nothing today.
- **Where a *provable* piece of a screen goes, now that there is a third place to put it.**
  [The numbers a mis-tap cleared](0043-the-numbers-a-mistap-cleared.md) put `UnitStash` in the app
  target with no SwiftUI import and walked it here — neither a rule nor a view, and the first time
  this map has done that deliberately rather than as a throwaway. It is a good answer for that
  ticket and it may be a pattern or may be a one-off; nobody has looked at the other screens to
  see how much of them would come out the same way, and a third home is a cost as well as a gain.
  Not sharp until a second screen wants it. Found while building.
- **What a past Workout's Summary reads its weights off, once Flow 4 can open one.** §6.5's
  Went-up row is `72.5 KG → 75 KG`, and [The Workout Summary](0038-the-workout-summary.md) reads
  the `from` off the last logged Set — a record, safe forever — and the `to` off the Exercise's
  **live** Working Weight. That is exactly right for the screen this map built, which appears
  between Finish and `DONE` with nothing able to edit an Exercise in between. It is **silently wrong
  the day a Workout from three weeks ago can be reopened**, which is §6.7's Workout list: by then
  the live weight has moved on and the row would claim a progression that never happened. The fix is
  probably one field on `ProgressionOutcome` — it already stores the planned Sets and the threshold
  for the same reason — but whether the same is true of the condition line's `→ 75 KG`, which is a
  statement about the *future* and may want to stay live, is the part that is not sharp. It
  graduates with §6.7, and it sits beside **Flow 5's remaining screens, and all of Flow 4** above.
  Found while building.

- **What happens the first time real training disagrees with the spec.** The destination is a
  working app in a gym, so this map should expect findings from the rack and have somewhere to put
  them.

## Out of scope

- **The App Store, TestFlight and other users** — with everything they drag in: an icon,
  screenshots, a privacy policy, a support address, App Review, and whether the name `Hoppa`
  survives an App Store name check. A later effort, and a much easier one once one lifter has
  trained with the app for a month.
  **Rob has stated that publishing is the goal**, and *"launch soon after"* training with it
  himself. That does not move this map's destination — it is why the paid Apple Developer route
  was taken at [An empty app on the phone](0018-an-empty-app-on-the-phone.md) rather than a free
  Apple ID, and it is a reason for later tickets not to paint the launch into a corner. The launch
  itself stays a fresh effort with its own map.
- **A light mode.** Ruled out at
  [Dark only, or a light mode too](0030-dark-only-or-a-light-mode.md), and ruled *out of scope*
  rather than into the fog on purpose: fog gathers toward the destination, and the destination is
  Rob training in his own gym on a dark floor. A light mode serves the second lifter in a bright
  gym, who first appears at the launch. Rob's words were "dark locked **for now**", and what keeps
  the "for now" honest is §7.2's one-file rule — a light mode later is a second value per role, not
  a hunt through the screens. `SPEC.md` §10 carries it.
- **iCloud sync, accounts and any backend.** Settled at charter: local only.
- **User-set plate colours.** `SPEC.md` §10 attaches a deadline to it — before the app is public —
  and this map never goes public. It stays where the design map left it.
- **Anything the design map already ruled out** (`SPEC.md` §10): the template library, equipment
  profiles, warm-up sets, bodyweight rep-progression, deload guidance, several Plate Inventories.
  Those are new features, and this map builds the spec as it stands.
