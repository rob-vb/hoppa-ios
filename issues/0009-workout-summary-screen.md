---
id: 9
title: Workout summary screen prototype
parent: 1
labels: [wayfinder:prototype]
status: closed
assignee: henk
blocked-by: [2, 3]
---

## Question

What does the Workout Summary look like, and does the celebration land? The rules are settled in [Workout session lifecycle](0003-workout-session-lifecycle.md): progressed Exercises lead with old → new weight, duration and Sets and volume sit under them, Skipped Exercises are listed plain at the bottom, and confetti scales with the count of progressed Exercises (zero progressed = no confetti).

Produce `/design` artboards in the "Plate Rack" direction (see [Design language & visual direction](0002-design-language-and-visual-direction.md)) for at least three states: every Exercise progressed, one Exercise progressed, and nothing progressed. Confetti is motion, so the artboards must be backed by something the user can actually watch — a short clickable or animated artefact — before he approves it. The open design questions: how the confetti amount reads as "more" without becoming noise, whether the plate colours drive the confetti, and how the zero-progressed screen stays encouraging without a celebration.

Added by [Progression edge cases](0004-progression-edge-cases.md): a Program can mix units, so the old → new lines each carry their own Weight Unit, while **total volume converts to the Program's default unit** and shows as one labelled number. The Summary is also where the user first meets the new Working Weight — Fitty applies it at Finish and asks for no acceptance — so the artboards must make that read as a statement of fact, not as an offer.

## Resolution

Approved. Three confetti models and three colour rules were built into one watchable prototype and driven live; the user chose **Ignition + Rack** and approved the zero-progressed screen unchanged.

**Assets**
- [Workout Summary prototype](https://claude.ai/code/artifact/027b21df-315f-461d-a358-e511b6e5fb26) — source `design/0009-summary/fitty-workout-summary.html`. Four states × three confetti models × three colour rules, every switch replaying the motion. The rejected models stay in it as the record of the choice; the defaults are set to what was chosen.
- [Workout Summary Screens canvas](https://claude.ai/code/artifact/5b35afe6-8883-42c5-a233-242e800b4309) — source `design/0009-summary/canvas/`. The four settled states as artboards, plus the Ignition sequence at 300 / 700 / 1100 / 1600 ms.

### The screen

Top to bottom, in the "Plate Rack" direction: the Workout Day and a `SUMMARY` label; then the **count as the hero** — one Anton numeral in green over `EXERCISES WENT UP`, because the count is exactly what the confetti scales to; then `WENT UP`, `STAYED`, `SKIPPED`; then one steel bar with duration, Sets and volume; then a single `DONE` button.

A Went-up row is a plate chip in the added plate's colour, the Exercise name, and the line `72.5 KG → 75 KG` with a small steel `NEXT TIME`. **There is no Accept and no Undo anywhere on the screen** — Fitty applied the new Working Weight at Finish, so the green number is a statement of fact. That is the whole mechanism; nothing else was needed to make it read that way.

### Confetti — Ignition (chosen)

Each Went-up row lands on its own, **190 ms after the row above it**, and throws a burst of ~15 particles from its own plate chip. Particles are plate-shaped slabs — the same glyph the Plate Inventory and the rows draw — with gravity, drag and spin. The whole sequence runs **~1.4 s**, after which the screen is quiet and every number is readable. Zero progressed Exercises fires nothing at all.

"More" reads as a **count you watch land**, not a cloud you estimate, and the motion is tied to the data rather than layered over it. The named trade-off, accepted: the list is not fully readable until the last row lands.

Rejected, and why:
- **Density** (one burst, particle count scaling with the count) — at five Exercises the particles cover the numbers. This is the noise case the ticket asked about, and it is real.
- **Bursts** (one burst per Exercise from a fixed point, staggered) — reads the count fine, but the motion floats free of the list.

### Colour — Rack (chosen)

Particles take the colours of the **per-side Plate Breakdown of the weight just earned**: Smith bench at 75 kg is 20 + 10 per side, so blue + green. Colour keeps meaning weight, and a big day is genuinely multi-coloured.

Rejected: **Increment** (the plate you added) is more literal but says nothing new — every Increment in this Program is 2.5 kg, so a five-Exercise day comes out almost entirely red. **Green only** is safe but makes the celebration the one place in Fitty where colour is decoration.

### The zero-progressed screen — approved unchanged

No confetti. The hero becomes `NOTHING WENT UP` in text colour, with `n Exercises performed. Every Set is logged.` under it. What keeps it worth reading is the `STAYED` section, which **states the condition** for every Exercise that did not progress: `ALL 3 SETS AT 12 → 75 KG` — the same rule chip the logging screen shows, restated as a condition. It is a fact, not encouragement, so the screen neither scolds nor consoles.

That condition line is not special to the zero screen: **every** stayed Exercise carries it, in every state. A One-off Weight replaces it with the steel `ONE-OFF · 22.5 KG STAYS` chip from [Workout logging clickable prototype](0007-workout-logging-clickable-prototype.md), because nothing was ever going to progress; its meta line shows the weight actually lifted, not the Working Weight.

### Mixed units

Confirmed working on the realistic state. The Lat pulldown is an **lbs** Exercise with a **kg** Microplate: its line stacks two numbers with their own labels and converts nothing — `100 LBS + 1 KG → 100 LBS + 2 KG`. Total volume is the one number that does convert, to the Program's default unit, labelled `KG VOLUME`. Dumbbell Sets count both dumbbells.
