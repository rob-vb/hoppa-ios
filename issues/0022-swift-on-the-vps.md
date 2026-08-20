---
id: 22
title: Swift on the VPS
parent: 17
labels: [wayfinder:task]
status: closed
assignee: agent
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

---

## Resolution

**Swift 6.3.3 is installed on the VPS and runs Swift Testing green.** `swift test` on an
import-free package now works here, so [Lift the rules into HoppaRules](0023-lift-the-rules-into-hopparules.md)
does not have to be re-planned around the Mac. The failure this ticket existed to rule out did not
happen.

### The version drift is zero

The ticket asked for the drift to be recorded and judged. **There is none.** The Mac runs Swift
6.3.3 (Xcode 26.6); `swiftly list-available` offers 6.3.3 for Linux, and that is what is installed:

```
Swift version 6.3.3 (swift-6.3.3-RELEASE)
Target: x86_64-unknown-linux-gnu
```

Both sides are the same release, down to the point version, so there is nothing for
`swift-tools-version` to straddle. `Package.swift` uses **`swift-tools-version: 6.0`** — proven to
build and test here, and comfortably below both toolchains, so it leaves room if either machine
moves first.

### What is installed, and where

| | |
|---|---|
| Installer | **swiftly 1.1.3**, the official swift.org toolchain manager, from `download.swift.org` |
| Toolchain | `/root/.local/share/swiftly/toolchains/6.3.3` — **3.3 GB** |
| On `PATH` | `/root/.profile` sources `swiftly/env.sh`, **and** `swift`, `swiftc`, `swiftly` are symlinked into `/usr/local/bin` |
| System deps | `binutils libc6-dev libcurl4-openssl-dev libgcc-13-dev libpython3-dev libstdc++-13-dev libxml2-dev libncurses-dev libz3-dev pkg-config zlib1g-dev` |
| Repo | swiftly wrote **`.swift-version`** (`6.3.3`) at the repo root; committed, because it pins the toolchain and Xcode ignores it |

The `/usr/local/bin` symlinks are deliberate. `bash -lc` reads `/root/.profile` and finds Swift;
**plain `bash -c` does not**. A tool call, hook or script that does not start a login shell would
have got "command not found" from a toolchain that was installed correctly.

### Three things that would have bitten a later session

1. **`swift --version` lied, exactly as this ticket predicted it would.** Straight after a clean
   install it printed the version *and* this:

   ```
   <unknown>:0: warning: libc not found for 'x86_64-unknown-linux-gnu'; C stdlib may be unavailable
   ```

   The binary existed and reported itself happily while being unable to compile anything. The fix
   is the apt line above — `swiftly install --post-install-file=…` writes it out rather than
   printing it into scrollback. **Proof is a green test, never a version string**, and this is the
   second time on this map that a report disagreed with the artefact it described.

2. **A red test exits `1`.** Worth proving rather than assuming, because
   [The rules module and its oracle](0020-the-rules-module-and-its-oracle.md) opens its proof with
   **eight deliberately-red tests** for the §8.2 defects; if a failure exited `0`, that whole layer
   would silently pass. It does not. The message also prints the computed value, which is what
   makes a red test readable:

   ```
   ✘ Expectation failed: (Rules.closest(…) → Weight(hundredths: 0)) == Weight(hundredths: 500)
   EXIT CODE: 1
   ```

3. **`swift test` prints `Executed 0 tests` and that is not a failure.** SwiftPM runs the XCTest
   harness alongside Swift Testing, so a package with only `@Test` functions gets an XCTest summary
   of zero next to the real results. Read the `✔ Test run with N tests` line, not the XCTest block.

### The disk, which was not where the ticket said

The ticket recorded 1.7 GB free and pointed at `/root/.npm` and `/root/.cache` for "about 3.3 GB".
Both numbers were off by the time the work ran: **1.2 GB free at 97%**, and the reclaimable bulk
was in **`henk`'s** cache, not root's — `/home/henk/.npm/_cacache` alone held **8.0 GB**.

`npm cache clean --force` for both users reclaimed **9.9 GB** and nothing else was touched. That
was more than enough, so the browser caches were left alone deliberately: `/root/.cache/puppeteer`
holds the headless Chromium the design map uses for screenshots, and `ms-playwright`, `convex` and
`pnpm` belong to Rob's other projects on this box.

| | |
|---|---|
| Before | 1.2 GB free, 97% |
| After the npm clean | 11 GB free, 70% |
| After the toolchain | **7.3 GB free, 80%** |

**Only regenerable npm caches were removed.** No project directory, no browser, no store.

### The proof

A throwaway package in the scratchpad, shaped like `HoppaRules` will be — a library target that
**imports nothing, not even Foundation**, and a test target that imports only `Testing` and the
library. It builds and two `@Test` functions pass, on `Testing Library Version: 6.3.3`. The shape
matters as much as the green: it is the shape ticket 20 committed to, and it is now known to work
on Linux.
