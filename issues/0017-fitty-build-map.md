---
id: 17
title: Fitty build map
labels: [wayfinder:map]
status: open
---

## Destination

**Fitty on Rob's own phone, logging his real Upper / Lower program in his own gym.** A native
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
  - **`SPEC.md` §8.2 is the known-defect list.** The `Fitty` module in
    `design/0007-logging/fitty-workout-logging.html` predates three later tickets and is wrong in
    eight named ways. The spec is right and the code is wrong. Fix them in the lift; never port a
    defect forward.
  - ~~The app is called **Fitty** here, as a working name. The definitive name is out of scope, as
    it was on the design map.~~ **Superseded.** Rob named the app **Hoppa** while answering
    [An empty app on the phone](0018-an-empty-app-on-the-phone.md); the Xcode project, the target
    and the bundle id `com.robvb.hoppa` are already Hoppa, and the rest of the repo catches up in
    [The app is called Hoppa](0021-the-app-is-called-hoppa.md). This map keeps its own title until
    that ticket runs.

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

## Not yet specified

- **Drawing the loaded bar, and the Ignition confetti, natively.** `SPEC.md` §7.5 and §6.5 specify
  both exactly, and both exist as working HTML. SwiftUI `Canvas`, plain shapes, SpriteKit or
  Core Animation — not sharp until there is a project to run them in.
- **Appearance: dark only, or a light mode too.** The whole spec is dark-first and never says
  whether light mode exists. On iOS that is a decision with real work behind it, not a default.
- **The Rest Timer across backgrounding.** §6.4 gives a count-up stopwatch that auto-starts after
  each Set. What it does when the phone locks, the app backgrounds, or a call comes in is an iOS
  question the spec never had to answer. `restStartedAt` is a pure `Timestamp` on the `Workout`
  after ticket 20, so the *state* is settled; only the iOS behaviour is still fog.
  [The view layer around the rules](0024-the-view-layer-around-the-rules.md) may sharpen it.
- **Build order across the five flows, and what "done" means for each.** Probably logging first,
  because it is the screen with the most rules behind it — but that is a guess until the model
  exists.
- **Who owns `project.pbxproj`, and what a conflict in it costs.** The VPS/Mac loop means two
  machines edit the same Xcode project file — the agent by patching it, Xcode by regenerating it.
  It is a merge conflict waiting to happen, in a file no one wants to hand-merge. Not sharp until
  the loop has run a few times and shown which edits actually collide. The loop's **first** run
  already drew blood, though in a smaller way: see the charter bullet on the nested repo.
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
