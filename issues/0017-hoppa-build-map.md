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

## Not yet specified

- **Drawing the loaded bar, and the Ignition confetti, natively.** `SPEC.md` §7.5 and §6.5 specify
  both exactly, and both exist as working HTML. SwiftUI `Canvas`, plain shapes, SpriteKit or
  Core Animation — not sharp until there is a project to run them in.
- **Appearance: dark only, or a light mode too.** The whole spec is dark-first and never says
  whether light mode exists. On iOS that is a decision with real work behind it, not a default.
- **Build order across the five flows, and what "done" means for each.** Probably logging first,
  because it is the screen with the most rules behind it. The model now exists and the seam is
  fixed, so this is close to ticketable — it waits on
  [The Logbook on disk](0025-the-logbook-on-disk.md), which puts a real store under a real screen for
  the first time.
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
- **Deleting a Program.** §6.6 specifies deleting an Exercise and a Workout Day, with two blocks.
  §2.1 allows more than one Program. Nothing says what a whole Program delete does, or whether the
  last Program is blocked the way the last Workout Day is. Found while working
  [Persistence and the data model](0019-persistence-and-the-data-model.md), which deliberately did
  not decide it: it is a gap in the spec, not a rule that is wrong. The model survives either way —
  a Workout keeps its Workout Day's Name — so this is a flows question, not a storage one.
  [Program edits, and which of them are rules](0026-program-edits-and-the-rules-boundary.md) takes
  deleting an Exercise and a Workout Day, which §6.6 *does* specify, and leaves this one here.
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
- **iCloud sync, accounts and any backend.** Settled at charter: local only.
- **User-set plate colours.** `SPEC.md` §10 attaches a deadline to it — before the app is public —
  and this map never goes public. It stays where the design map left it.
- **Anything the design map already ruled out** (`SPEC.md` §10): the template library, equipment
  profiles, warm-up sets, bodyweight rep-progression, deload guidance, several Plate Inventories.
  Those are new features, and this map builds the spec as it stands.
