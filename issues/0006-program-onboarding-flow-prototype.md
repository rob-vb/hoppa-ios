---
id: 6
title: Program onboarding flow prototype
parent: 1
labels: [wayfinder:prototype]
status: closed
assignee: henk
blocked-by: [2]
---

## Question

What does entering a Program feel like, and is it fast enough? Produce `/design` artboards for the first-run flow: create a Program; pick unit and Progression Mode; add Workout Days; add Exercises with sets, Rep Range, Working Weight, Increment, Equipment Type (plus Base Weight where relevant); set the Plate Inventory. The core question: how few taps can a full Program take, and where does smart defaulting remove input?

Added by [Progression edge cases](0004-progression-edge-cases.md): the unit is no longer one Program-level pick. The Program holds a default unit for new Exercises, and each Exercise carries its own Weight Unit — except Barbell, Smith Machine and Plate-loaded Machine, which take it from the Plate Inventory and offer no choice. Working Weight and Increment accept any typed number, so the presets are defaults only. The Microloading Increment is picked from the Microplates in the Plate Inventory, not typed. The flow must make the common case (one unit everywhere) cost nothing, while the mixed gym stays reachable.

## Resolution

Seven artboards in the "Plate Rack" direction. Asset: [Fitty Program Onboarding canvas](https://claude.ai/code/artifact/cdf0fcb9-5c71-4bfa-b7f1-ac64e1f480ca) — source artboards in `design/0006-onboarding/`.

Test case for every count below: the user's own Program — **Upper / Lower, 4 Workout Days, 22 Exercises, empty start, standard kg rack**. A tap is anything you touch, keystrokes included.

### The flow — three steps to owning a Program

1. **Name the Program.** Under the name field, a card shows the three decisions Fitty makes at Program level: Weight Unit `KG`, Progression Mode `Progressive Overload`, Plate Rack `standard kg`. They are pre-answered and visible, each one tap away from being changed. Nothing else is asked at Program level.
2. **Your plate rack.** The Plate Inventory from [Plate display design](0005-plate-display-design.md), with the standard kg defaults already correct (25 kg off, the rest on, both Microplates on). One confirm if the rack matches.
3. **The Program sheet** — the hub: the Workout Days with their Exercise counts, `ADD A DAY`, and a link to Program settings.

Fitty starts **empty**. No starter skeleton, no template, no Workout Days invented for the user.

### The entry model — Model B, the full sheet, chosen

Two models were drawn and counted against each other:

- **Model A — fast list** (~287 taps): you never leave the Workout Day. Type four letters, tap the match, type the weight, confirm. An Exercise catalogue sets Equipment Type and Increment; Sets, Rep Range and Base Weight default. Six values arrive filled in, printed on the row in steel.
- **Model B — full sheet** (~400 taps): one sheet per Exercise with all nine fields on screen.

**The user chose Model B.** The reason is the audience, not the count: *"Deze app is niet voor de beginner, maar iemand die er al wel wat verstand van heeft."* Someone who knows a Smith machine from a cable stack does not want the app to decide for them. The 113-tap difference buys explicit control over every field that changes how an Exercise behaves.

Two follow-up choices settled the sheet's behaviour:

- **Sets and Rep Range carry over** from the Exercise before it, and are marked `CARRIED OVER` on the sheet. Every other field starts empty — Equipment Type, Working Weight, Increment and Base Weight are always picked by hand.
- **The name field proposes known Exercises, and free text always wins.** The user can type `Smith incline 30°` and keep it. The suggestion sets the name and **nothing else** — it never fills the Equipment Type. So the catalogue is a typing aid, not an inference engine.

Add and edit are the **same sheet**. Base Weight appears only after Smith or plate-loaded machine is picked. The Weight Unit is locked for the three plate-loaded types, with a steel lock line that says why.

### The count — the ticket's core question

**14 taps per Exercise is the floor**, 400 for the whole Program:

| Step | Taps |
| --- | --- |
| Program name and the three assumptions | 16 |
| Plate rack — standard kg, one confirm | 3 |
| 4 Workout Days, named | 40 |
| 22 Exercises at 14 taps each | 308 |
| Base Weight on the 5 machine Exercises | 15 |
| Rep Range changed on 6 of them | 18 |
| **Total** | **400** |

Of the nine fields, only three cost nothing: Sets and Rep Range (carried over) and Progression Mode (from the Program, override on the same sheet). Where smart defaulting was allowed to remove input, it was removed at **Program level** — one unit, one Progression Mode, one plate rack, decided once and never asked again per Exercise.

Model A's artboards stay in `design/0006-onboarding/` as `DayA.dc.html`, `DayAFilled.dc.html`, `DetailA.dc.html` and `DayB.dc.html`, off the canvas, as the record of the choice.

### Surfaced

The name catalogue now needs a source: see [Exercise name suggestions](0010-exercise-name-suggestions.md).
