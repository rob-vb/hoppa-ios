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
  - **`SPEC.md` §8.2 is the known-defect list.** The `Fitty` module in
    `design/0007-logging/fitty-workout-logging.html` predates three later tickets and is wrong in
    eight named ways. The spec is right and the code is wrong. Fix them in the lift; never port a
    defect forward.
  - The app is called **Fitty** here, as a working name. The definitive name is out of scope, as
    it was on the design map.

## Decisions so far

<!-- one line per closed ticket -->

## Not yet specified

- **How the logging screen's state machine becomes SwiftUI.** The prototype's `Fitty` module is a
  reducer with `initialState`/`reduce`. Whether that shape survives as an `@Observable` store, one
  store per screen, or something else is a real decision — and it hangs on what
  [The rules module and its oracle](0020-the-rules-module-and-its-oracle.md) decides the module's
  boundary is.
- **Drawing the loaded bar, and the Ignition confetti, natively.** `SPEC.md` §7.5 and §6.5 specify
  both exactly, and both exist as working HTML. SwiftUI `Canvas`, plain shapes, SpriteKit or
  Core Animation — not sharp until there is a project to run them in.
- **Appearance: dark only, or a light mode too.** The whole spec is dark-first and never says
  whether light mode exists. On iOS that is a decision with real work behind it, not a default.
- **The Rest Timer across backgrounding.** §6.4 gives a count-up stopwatch that auto-starts after
  each Set. What it does when the phone locks, the app backgrounds, or a call comes in is an iOS
  question the spec never had to answer.
- **Fonts.** Anton and IBM Plex Sans (§7.4). Both need licence-checking and bundling in an app
  binary, which is not the same as a `<link>` to Google Fonts.
- **Build order across the five flows, and what "done" means for each.** Probably logging first,
  because it is the screen with the most rules behind it — but that is a guess until the model
  exists.
- **What happens the first time real training disagrees with the spec.** The destination is a
  working app in a gym, so this map should expect findings from the rack and have somewhere to put
  them.

## Out of scope

- **The App Store, TestFlight and other users** — with everything they drag in: the definitive
  name, an icon, screenshots, a privacy policy, a support address, App Review. A later effort, and
  a much easier one once one lifter has trained with the app for a month.
- **iCloud sync, accounts and any backend.** Settled at charter: local only.
- **User-set plate colours.** `SPEC.md` §10 attaches a deadline to it — before the app is public —
  and this map never goes public. It stays where the design map left it.
- **Anything the design map already ruled out** (`SPEC.md` §10): the template library, equipment
  profiles, warm-up sets, bodyweight rep-progression, deload guidance, several Plate Inventories.
  Those are new features, and this map builds the spec as it stands.
