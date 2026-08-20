---
id: 22
title: Swift on the VPS
parent: 17
labels: [wayfinder:task]
status: open
assignee:
blocked-by: []
---

## Question

Nothing to decide. **Install the Swift toolchain on the VPS, so the agent can compile and test the
Swift it writes.**

[The rules module and its oracle](0020-the-rules-module-and-its-oracle.md) found that this side of
the loop has no Swift at all. Every session so far has written Swift blind and sent it to the Mac to
find out whether it even parses. The resolution of ticket 20 makes `HoppaRules` a package that
**imports nothing** — no SwiftUI, no SwiftData, no Foundation — and a package like that builds and
tests on Linux exactly as it does on macOS. So the round trip is avoidable for the one module where
correctness matters most.

This does not move the build to Linux. **The Mac still builds and runs the app**; that stays true
for anything that touches UIKit, SwiftUI or a simulator. What changes is that `swift test` on
`app/HoppaRules` runs here, before every push.

### The work

- **Reclaim disk first.** `/` is at 96% — 1.7 GB free of 38 GB. About 3.3 GB sits in `/root/.npm`
  and `/root/.cache`. A Swift toolchain needs roughly 2–3 GB unpacked, so the cleanup is a
  precondition, not a tidy-up. Check what is actually safe to remove before removing it.
- **Install Swift 6.x for Ubuntu 24.04 x86_64.** Ubuntu 24.04.3 LTS, x86_64, 3.7 GB RAM. Prefer the
  official toolchain over a distro package. Note the exact version installed.
- **Prove it.** A throwaway package that builds and runs one Swift Testing `@Test` green. Not
  `swift --version` — that only proves the binary exists.
- **Record the version drift.** The Mac has Swift 6.3.3 (Xcode 26.6). If the Linux toolchain is a
  different point release, say so in the resolution and say whether it matters. A package that
  imports nothing has a small surface for drift, but `Package.swift`'s `swift-tools-version` has to
  be a version both toolchains accept.

### Why this blocks the lift rather than riding with it

Ticket 20 refused to write the package while nothing here could run it. If the install turns out to
be impossible on this machine — disk, RAM, or an architecture problem — that is a **finding**, and
[Lift the rules into HoppaRules](0023-lift-the-rules-into-hopparules.md) has to be re-planned around
the Mac instead. Better to learn that in a session that installs one toolchain than in a session
that has just written 800 lines of Swift.

AFK: the agent drives this alone and reports what it found.
