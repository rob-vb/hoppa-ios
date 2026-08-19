---
id: 18
title: An empty app on the phone
parent: 17
labels: [wayfinder:task]
status: open
assignee: henk
blocked-by: []
---

## Question

Nothing to decide. **Get a blank SwiftUI app onto Rob's actual iPhone, and find out what that
costs.** Every later ticket assumes a project exists and that its output can be run; until this is
done, none of them can be checked against a device.

This is the one ticket the agent cannot drive — Xcode is on the Mac and this environment is Linux.
The agent's job here is the checklist and the questions; Rob's job is the machine.

### The work

- Create the Xcode project in this repo, so the app and the spec live together and the existing
  `.gitignore` already covers `build/`, `DerivedData/` and `xcuserdata/`.
- Pick and record: **bundle identifier**, **minimum iOS version**, **orientation** (the spec draws
  one portrait 390 × 844 screen and never a landscape one), and the **display name**.
- Put a single screen on it that proves the toolchain: the `72.5` hero number in **Anton** on the
  `#0E0F10` floor (§7.2, §7.4). If that renders on the device, the fonts, the colours and the
  signing all work.
- Run it **on the physical phone**, not only the simulator.

### The fact this ticket exists to find

**How long does the build survive on the phone?** A free Apple ID signs an app for **seven days**;
after that it stops launching and must be re-installed from Xcode. This map's destination is
*weeks of real training*, so that matters:

- If seven days is the answer, either Rob re-installs weekly for the whole map, or the map needs
  an **Apple Developer account (€99/year)**, which signs for a year.
- Record which it is. Later tickets — and how long a testing round can run — depend on it.

Record in the resolution: the bundle id, the minimum iOS version, the orientation, the Xcode and
Swift versions, the signing route chosen and its expiry, and anything that fought back.

### Not here

Fonts are only smoke-tested here. **Licensing and bundling Anton and IBM Plex Sans properly** is
still fog on the map — a `<link>` to Google Fonts is not a licence to ship a face inside a binary.
If the smoke test needs the file on the device to render at all, note what was done and leave the
licence question to its own ticket.
