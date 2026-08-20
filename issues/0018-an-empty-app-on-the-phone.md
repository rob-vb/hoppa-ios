---
id: 18
title: An empty app on the phone
parent: 17
labels: [wayfinder:task]
status: closed
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

## Resolution

**Hoppa runs on Rob's iPhone 16, and the build lasts a year.** The smoke screen renders the `72.5`
hero in Anton on the `#0E0F10` floor, and its own verdict block reports all three faces **LOADED** —
so the toolchain, the colours, the bundled fonts and the signing all work end to end. Nothing fought
back.

### The fact this ticket existed to find

**One year, not seven days.** Rob took the **Apple Developer Program (paid)** route, and the
provisioning profile Xcode issued expires **2027-08-20**. The map's destination — weeks of real
training — is therefore not fenced in by signing at all, and no ticket has to plan around a weekly
re-install. Read out of the profile itself (`security cms -D` → `ExpirationDate`), not from what the
dialog claimed.

This also matches the ambition Rob stated while answering: publishing to the App Store is the goal,
and *"launch soon after"* training with it himself. The paid route was the cheaper decision in both
directions.

### Recorded

| | |
| --- | --- |
| Bundle id | `com.robvb.hoppa` |
| Display name / target / project | `Hoppa` |
| Minimum iOS | 17.0 |
| Orientation | Portrait only, iPhone only |
| Signing | Apple Developer Program (paid), team *Rob van Baaren*, expires 2027-08-20 |
| macOS | 26.3.1 |
| Xcode | 26.6 |
| Swift | 6.3.3 |
| Device | iPhone 16, iOS 26.6.1 |

The minimum of iOS 17.0 leaves a wide margin under the phone's iOS 26.6.1. It was chosen for the
modern SwiftUI surface (`@Observable`, SwiftData) rather than for reach, and this map has exactly
one device to reach.

### Fonts: answered further than this ticket asked

The ticket said fonts were only smoke-tested here and left licensing to its own ticket. That fog is
now closed instead, because the answer arrived while doing the work: **Anton and IBM Plex Sans are
both SIL OFL 1.1**, which permits bundling a face inside an app binary provided the licence text
ships with it. `app/bootstrap/Fonts/` carries both `.txt` licences and the wizard copies them into
the app. Two details worth keeping:

- **The PostScript names are not the filenames.** They are `Anton-Regular`, `IBMPlexSans` and
  `IBMPlexSans-Medm`. A guess would have compiled, run, and silently fallen back to the system face.
- **Registration is at runtime**, via `CTFontManagerRegisterFontsForURL`, not `UIAppFonts`. Modern
  Xcode generates its `Info.plist` from build settings, so there is no plist file to hand-edit.
- IBM ships only a variable `IBMPlexSans[wdth,wght].ttf` through Google Fonts. The static Regular
  and Medium came from `github.com/IBM/plex`.

### What fought back: the bundle id was not what the facts file said

The wizard reported the bundle id as `com.robvb.hoppa` and it was `Rob-van-Baaren.Hoppa`. Rob caught
it in Xcode's Identity panel. Three defects stacked up, and each one alone would have been harmless:

1. **Xcode pre-fills the Organization Identifier with the account holder's name.** The wizard printed
   `com.robvb` as the value to type; the field already had `Rob-van-Baaren` in it, and a pre-filled
   field does not read as a field waiting for input.
2. **The `sed` was anchored on a guess.** It matched the literal `com.robvb.Hoppa`, i.e. the value it
   expected Xcode to derive *if step 1 went as instructed*. A patch that assumes its own precondition
   is not a patch. It now matches any prefix, and it handles the quoted form — Xcode wraps the value
   in quotes when it contains a hyphen, which a later test showed would have defeated the first fix
   too.
3. **The wizard wrote its intention into the facts file, not the file's contents.** `write_env
   BUNDLE_ID "$BUNDLE_ID"` ran whether or not the patch took, so `ticket-0018-facts.env` asserted a
   value the project never held — and this resolution was written from it. The wizard now reads all
   three settings back out of `project.pbxproj` and records what it finds.

The check between 2 and 3 *did* fire: `grep -q` failed, the wizard warned, and it pushed a
`bundle identifier — set it by hand` line onto its skipped list. The warning was correct and got
lost in the run. **A warning is not a result.** The value went into the facts file anyway, and the
facts file is what the agent trusted.

All three targets now read `com.robvb.hoppa`, `com.robvb.hoppaTests` and `com.robvb.hoppaUITests`,
patched on the VPS. Verified by re-reading the project file, not by re-running the wizard.

Rob rebuilt from the corrected project and confirmed the app launches on the phone under the new
identifier, so automatic signing registered the new App ID without complaint.

This was cheap only because it was caught now. A bundle identifier is fixed forever once the app is
submitted to the App Store, and Rob has said that is where this is going. `Rob-van-Baaren.Hoppa` is
also not reverse-DNS: `com.robvb` is a domain he controls, and a personal name is not.

The other three patches did take, confirmed the same way: `IPHONEOS_DEPLOYMENT_TARGET = 17.0`,
`INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = UIInterfaceOrientationPortrait`,
`TARGETED_DEVICE_FAMILY = 1`.

### What fought back: the project did not travel

Xcode's New Project dialog **created a git repository inside `app/Hoppa/`**, so the outer repo
recorded the folder as a gitlink (mode `160000`) with no `.gitmodules` behind it. Rob pushed, and
nothing but an empty pointer arrived on the VPS — no `project.pbxproj`, no sources. The wizard's
`ticket-0018-facts.env` travelled fine, which is why this ticket could still be resolved.

The nested repo has to go, and the fix is four commands on the Mac. This is a transport defect, not
a question this ticket had to answer, and it is recorded on the map so the next session does not
meet it cold.

### How this was done

`app/bootstrap/setup-hoppa.sh`, an eight-stage wizard, drove the Mac half. Only two steps needed a
human in Xcode: the New Project dialog, and picking the Team. Everything after project creation —
bundle id, deployment target, orientation, device family — the wizard patched into
`project.pbxproj` by `sed`, verified with `grep`, and fell back to printed instructions where a
patch did not take. Hand-writing a `.pbxproj` was considered and rejected: a malformed one would
have stranded Rob in a debug loop on the machine the agent cannot see.
