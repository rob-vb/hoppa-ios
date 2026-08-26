---
id: 38
title: The Workout Summary, without the confetti
parent: 17
labels: [wayfinder:task]
status: closed
assignee: agent
blocked-by: [37]
---

## Question

**Build §6.5's screen. The confetti is ticket 39.**

Top to bottom: the Workout Day and a `SUMMARY` label; **the count as the hero** — one Anton numeral
in green over `EXERCISES WENT UP`; then `WENT UP`, `STAYED`, `SKIPPED`; then one steel bar with
duration, Sets and volume; then a single `DONE` button.

**The count is the hero because the count is exactly what the confetti scales to.** Build it that way
even though ticket 39 has not landed.

- **There is no Accept and no Undo anywhere on this screen.** Hoppa applied the new Working Weight at
  Finish, so the green number is a statement of fact (§7.6). That is the whole mechanism.
- **WENT UP**: a plate chip in the added plate's colour, the name, `72.5 KG → 75 KG`, and a small
  steel `NEXT TIME`.
- **STAYED states the condition**, in every state: `ALL 3 SETS AT 12 → 75 KG` — the logging screen's
  rule chip, restated. A One-off Weight replaces it with the steel `ONE-OFF · 22.5 KG STAYS` chip,
  and its meta line shows **the weight actually lifted**, not the Working Weight.
- **SKIPPED is listed plain.** No warning colour, no icon, no invitation to fix.
- **Mixed units never convert per Exercise.** Total volume is the one number that does, to the
  Program's default unit, labelled `KG VOLUME`. **Dumbbell Sets count both dumbbells.**
- **The zero-progressed screen**, approved unchanged: no confetti, the hero becomes `NOTHING WENT UP`
  in text colour, with `n Exercises performed. Every Set is logged.` under it. Every STAYED row still
  carries its condition. **It is a fact, so the screen neither scolds nor consoles.**

A Workout stores **what progression did**
([Persistence and the data model](0019-persistence-and-the-data-model.md)), so this screen reads a
recorded Progression Outcome. It must not recompute anything off an editable Rep Range — that was
§2.5's defect showing up in a second place.

**§8.2 lists two summary defects. Neither ports.**

Done, hand-off and testing follow ticket 29's rules. Batch 3 goes over after ticket 39.

Consult `SPEC.md` §2.8, §4.1, §6.5, §7.6 and §8.2, `design/0009-summary/fitty-workout-summary.html`
and `design/0009-summary/canvas/`.

## Resolution

**Built and pushed.** `Rules.summary(of:in:)` in `app/HoppaRules/Sources/HoppaRules/Summary.swift`,
`SummaryScreen.swift` in the app target, `Route.summary(WorkoutID)`, and Finish now lands on it.
`HoppaRules` is **143 tests green** on the VPS, up from 128; `HoppaStore` is 31.

### The screen is a rule with a drawing on it

Ticket 27's test answers yes: the three sections, the added plate and every condition line are
decided by the `Logbook` alone, and two lifters holding the same `Logbook` must read the same
summary. So `WorkoutSummary` is data in `HoppaRules` and the view holds no arithmetic at all —
which is also why the whole screen could be **checked here**. Fifteen tests reproduce the four
artboards of `design/0009-summary/canvas/`, and a throwaway renderer printed all four as text
before anything was drawn.

**It reads the recorded outcome.** `plannedSets` and `thresholdReps` come off the stored
`ProgressionOutcome`; a test edits the Rep Range *after* Finish and asserts the condition line does
not move. That is §2.5's defect, headed off in the second place ticket 38 warned about.

**Two weights, two sources, on purpose.** `from` is the **last logged Set's own weight** — a record
of the past that cannot move again (§2.5), and after a mid-Exercise raise it is exactly what the
Exercise stood at when Finish read it. `to` is the Exercise's **live** Working Weight, because
Finish has already written it there and this screen is what says so. That is safe here and only
here: nothing between Finish and `DONE` can edit an Exercise. See the fog note below.

### Three things the spec did not decide, and now does

`SPEC.md` §6.5 carries all three.

1. **What "the added plate" is.** Under Microloading the Increment already *is* a plate. Under
   Progressive Overload it is a total, so a bar takes half of it — a 2.5 kg Increment is a **1.25 kg
   plate**, light grey `#70767C`, not the mid grey of the 2.5. Where the rack has no colour the chip
   is hollow steel (§7.1 rule 2). **The `Main` artboard's chips do not port**: it paints every bar
   row red, which is §8.2's *invented colours* defect, and its Microloading row steel, which is
   §8.2's first summary defect showing up on the chip instead of the burst. Ticket 39 fires its
   burst from this same rectangle, so chip and burst now agree by construction.
2. **Nowhere to put the plate is not one sentence.** `Progression.swift` recorded an assumption
   that the Summary "states one condition for all four"; §6.6 says the opposite — an Exercise
   waiting for a weight and one stranded by a switched-off Microplate send the user to two
   different screens, and §5.2's principle is that Hoppa states its condition where the user
   stands. So there are **six** named blockers, the rep condition still reads, and only the
   `→ 75 KG` is replaced. A mixed-unit pin with no Stack Step was the sixth, found by writing them
   out.
3. **Volume prints whole.** A converted volume lands on hundredths — `8022.6 kg` on the fixture —
   and every artboard shows a whole number. Volume is a rough progress number, not a loading
   instruction, so the decimal is noise; the rounding is the screen's and `Rules.totalVolume` stays
   exact. Grouped with a thin space: `8 023`.

### Two colour roles, both derived

§7.2's escalation rule ran again and, as at ticket 32, nothing is a finding. `Row text` `#C9CCCF`
and `Hairline` `#1E2123` both sit on `Steel`'s hue 210° / 6.4% ramp, at lightness 0.800 and 0.1275;
`hairline` reproduces the artboard exactly and `rowName` lands within 2/255. They exist because the
Summary draws two sections of different weight — `WENT UP` is the loud one — and borrowing `Text`
or `Line` makes the quiet section as loud as the loud one. `SPEC.md` §7.2 carries both rows.

### Finish now branches

`LoggingScreen.finish(_:)` told Finish and Discard apart by **the finished list growing**, not by
the `Action`: a Finish the gate refuses must not push a Summary either, and one test covers both.
A Finish **replaces** the path rather than pushing onto it — §6.5 has no Accept, no Undo and no way
back, so `DONE` is the only exit and there is no chevron to a finished Workout.

### What is not built

The confetti — that is [The Ignition confetti](0039-the-ignition-confetti.md), which is now
unblocked, and the screen was built count-first so it has something to scale to.

### Proven here

- `HoppaRules` 143 tests, `HoppaStore` 31, both green under `swift test`.
- `SteelRamp.swift` compiled and run on the VPS: `hairline` is `#1E2123` exactly, `rowName` is
  `#C9CCCF`, and `shaft` still reproduces §7.2's `#9BA1A7`.
- Every `HoppaRules` and `HoppaStore` call the two SwiftUI files make, lifted into a throwaway file
  and `swiftc -typecheck`-ed against the built modules under `-swift-version 6`. Clean.
- The four artboards rendered as text from the real rules, which is how the copy and the added
  plate were checked without a phone.
- **The SwiftUI itself is unproven**, as always. `SummaryScreen.swift` is 400 lines including a
  small `Layout` — `FlowRow`, because `HStack` cannot wrap and a mixed-unit arrow line is four
  numbers wide. That `Layout` is the most likely thing on this screen to need a fix.
- Nothing to patch in `project.pbxproj`: the target uses file-system-synchronized groups, so a new
  file in `app/Hoppa/Hoppa/` needs no entry.
