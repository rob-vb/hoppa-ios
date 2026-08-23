---
id: 34
title: The Program sheet hub and the Workout Day screen
parent: 17
labels: [wayfinder:task]
status: closed
assignee: agent
blocked-by: [33]
---

## Question

**Build onboarding step 3 — the Program sheet, which §6.1 calls the hub — and the Workout Day screen
under it.**

Scope was cut at ticket 29 and the cut matters: **build only what onboarding needs.**

In:

- The **Workout Days with their Exercise counts**, `ADD A DAY`, and a link to Program settings.
- **Naming a Workout Day.** The budget is 40 taps for four Days (§6.2).
- Opening a Day: its **Exercise list**, and `ADD AN EXERCISE`, which opens ticket 35's sheet.
- The **sparkline on an Exercise card** (§6.7) is a door to a chart that does not exist yet. Leave
  it out and say so in the hand-off note; it arrives with Flow 4.
- Empty states come from §6.2 and §5.2 — §6.6 says only three screens in that section have no
  precedent.

Out, and each for a reason: **reorder handles, deleting an Exercise, deleting a Workout Day, the two
warning dialogs, and the Re-weigh list.** Every one of them carries a warning or mirrors into the
Open Workout — the counts, stranding, `currentIndex` following the `ExerciseID` and not the
position. That is
[Program edits, and which of them are rules](0026-program-edits-and-the-rules-boundary.md)'s work,
already built in `HoppaRules` and waiting for its own flow. None of it is needed to put a first
Program on the phone, and folding it in makes this ticket too big for one session.

Also out for now: **deleting a whole Program**, which the spec has never specified. It sits in the
map's **Not yet specified** and is a decision, not a build.

Done, hand-off and testing follow ticket 29's rules. Batch 1 goes over after ticket 35.

Consult `SPEC.md` §2.1, §2.2, §6.1 and §6.6, and `design/0006-onboarding/`.

## Resolution

**Step 3 and the Workout Day screen are built and pushed.** `ProgramSheet` is §6.1 step 3 and
Flow 5's hub — **one screen with two lives**, like `PlateRackScreen` before it — and
`WorkoutDayScreen` is the room under it. `swift test` is green here: **119 in `HoppaRules`** (up
from 118) and **31 in `HoppaStore`** (unchanged). `project.pbxproj` needed no edit; the app target
is a `PBXFileSystemSynchronizedRootGroup`. Per ticket 29 this closes because it is **pushed, not
because Rob has seen it**; batch 1 goes over after ticket 35.

Four findings.

**1. The hub's two lives cannot be derived from the Logbook, so the route carries them.** A Program
reached from the picker and a Program made a minute ago are the same value the moment the first Day
is added, so `Route.programSheet` gained `onboarding: Bool`. It buys two words of chrome and
nothing else: the step count, and `START A WORKOUT` against `DONE`. **Both taps do the same
thing** — go home to the picker — because §3.1 picks a Workout at the picker and never here. The
artboard's button promises a screen it cannot open; the honest reading is that it ends onboarding.
§6.1 carries it.

**2. `Route.plateRack(nil)` had no door, and the rack's own `DONE` branch was unreachable.**
Ticket 33 built one screen for two jobs and only wired the onboarding one. The artboard's
`Program settings — unit, progression, plate rack` row is that door, so the ticket's *link to
Program settings* was built as a real screen rather than a `NotBuiltYet`: the Name, the Weight
Unit, the Progression Mode, the Plate Rack. **This is wider than the ticket's cut and it is
recorded rather than hidden** — every one of the four is an `Action` `HoppaRules` already owns and
tests, and step 1 tells the user *"You can rename it later"*, which until now was a promise with no
screen behind it. §6.6 carries the screen.

**3. §6.7 and the Day artboard disagree about what an Exercise card opens, and nothing settles it
today.** §6.7 says an Exercise card in the Program sheet opens **that Exercise's chart**; the Day
artboard's own caption says **tap a row to open it**, meaning §6.2's sheet. Flow 4 is not
scheduled, so the card opens the sheet and the sparkline is not drawn — the door without the room
is the one thing ticket 32 refused. When Flow 4 lands the card carries two doors and somebody has
to say which is the whole card. It is on the map's **Not yet specified**, not fixed here.

**4. A Workout Day is named before it exists.** `.addWorkoutDay` takes the name, so `ADD A DAY`
opens a one-field sheet and the Day arrives named — a Day with no name is a row the user cannot
read. `NameSheet` serves the add and both renames, which is §6.2's *add and edit are the same
sheet* applied to the smallest thing there is. The tap budget holds: `ADD A DAY`, seven letters,
`ADD THE DAY` is **9 taps** against §6.2's 10.

### What was built

- **`ProgramSheet.swift`** — the hub: the Program's Name, `4 days · 22 exercises · kg · progressive
  overload`, the numbered Day rows with their Exercise counts, the dashed `ADD A DAY`, the settings
  row and the bottom control. It also holds **`ProgramSettings`** (§6.6's Program-level edits, and
  the door to the rack), **`SettingRow`**, **`AddRow`** and **`NameSheet`**.
- **`WorkoutDayScreen.swift`** — the Day: the Program's Name in the header band, the Day's Name with
  `RENAME`, the Exercise cards, the dashed `ADD AN EXERCISE`, and `DAY DONE`. The card's meta line
  is `barbell · base 15 · 3 × 8–12 · +2.5`, every clause a stored field — **the Increment is printed
  as it is held, never as a jump the view worked out**, because a bar takes a pair (§4.2) and
  `Progression.progressionMove` is where that lives. An unset Working Weight draws `—` and **no
  unit**: unset is not zero (§2.8), and there is no number for a unit to qualify.
  It also holds **`ExerciseSheetTarget`**, which is a `sheet(item:)` and not a `Route`, because
  §6.2's sheet **is a sheet** — pushing it would put a second back chevron in front of the same Day.
- **`DomainCopy.swift`** — `ProgressionMode.screenName`, `EquipmentType.screenName`,
  `WorkoutDay.exerciseCountText`. **Copy is a view thing** (§7.6): `rawValue` is a storage key, and
  `machine-stack` is not a thing to show a lifter.
- **`Logbook.workoutDay(_:)`** in `HoppaRules` — the Day **with the Program that holds it**, because
  a screen showing a Day needs both and two lookups could disagree about which Program owns it. One
  test.
- **`Route`** gained `workoutDay` and `programSettings`, and `programSheet` gained its flag.
  `StepHeader` gained an `init(label:)` — the Day screen draws the Program's Name where onboarding
  draws the step count. **All four `NotBuiltYet` doors from ticket 32 are now rooms**; the only one
  left in the app is the Exercise sheet, and it names ticket 35.

### Three decisions the ticket left open

- **The empty hub states the rule, not an instruction.** A Program with no Days reads
  `A program needs at least one workout day.` — which is the block §6.6 already enforces at the
  other end, said before the user meets it, and not *"add a day to get started"* (§7.6).
- **A stranded Exercise says so on its card**, in the meta line, in steel and never in a warning
  colour — §7.6 keeps colour off anything the user did, and switching the Microplate back on ends
  it. It costs one clause and it is the difference between an Exercise that will progress and one
  that will not.
- **No SF Symbols.** The `+` on both dashed rows is Plex, and the chevrons stay `›` / `‹`. Every
  glyph the app draws comes out of a bundled face; importing a symbol set is a §7 decision nobody
  has made, and this ticket is not the place to make it.

### What the Mac has to answer

- **`.sheet(item:)` over a hidden navigation bar.** Three sheets land in this ticket — add a day,
  rename, and ticket 35's placeholder — and every screen here hides the bar (§7.4). Nothing on this
  side can see a detent.
- **`.presentationDetents([.height(280)])` with the keyboard up.** `NameSheet` focuses its field on
  appear, so the keyboard and a 280 pt sheet arrive together.
- **The Day title at 31 pt over two lines**, which is `Font.leading(.tight)` again — the same
  question ticket 33 left open for `NAME YOUR PROGRAM`, now on a name the user typed.
- **A long Exercise name against the weight**: the card gives the name `lineLimit(1)` and the meta
  line `minimumScaleFactor(0.8)`, which is a guess about a 390 pt phone and not a measurement.

### What was proved here

The SwiftUI is Mac-only; nothing else about this ticket is.

- `HoppaRules` **119 green**, `HoppaStore` **31 green**. Every app source **parses** under
  `-swift-version 6`, and `DomainCopy.swift` imports no SwiftUI, so it **type-checks against the
  built module**.
- **Every rules and store call the two screens make was lifted into a throwaway and compiled and
  run** against the built modules — ticket 25's pattern, third outing. It printed the empty hub,
  the four Days added through `.addWorkoutDay` and their counts, the Day header pair
  (`Upper / Lower / Upper A`), both renames, all four settings rows including the Microplate sheet
  opening on a rack with none on, the three Exercise cards (`smith · base 15 · 3 × 8–12 · +2.5`,
  the barbell with `—` and no unit, the stranded cable), the hub's counts after the Exercises
  landed, and both *gone* branches returning `nil`.
- **One thing the run surfaced.** Building `HoppaStore` with `-enable-library-evolution` makes every
  exhaustive `switch` over a `HoppaRules` enum an error — a resilient enum needs `@unknown default`.
  The app does **not** build the packages that way, so `DomainCopy.swift` is correct as it stands;
  it is recorded because the flag is one build setting away and the failure would arrive as thirty
  errors in a file nobody changed.
