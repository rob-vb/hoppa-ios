---
id: 38
title: The Workout Summary, without the confetti
parent: 17
labels: [wayfinder:task]
status: open
assignee:
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
