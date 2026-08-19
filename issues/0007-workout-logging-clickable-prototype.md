---
id: 7
title: Workout logging clickable prototype
parent: 1
labels: [wayfinder:prototype]
status: closed
assignee: henk
blocked-by: [2, 3, 4, 5]
---

## Question

Does logging a Workout feel right under the thumb? Build one clickable HTML prototype with real logic: pick a Workout Day, walk through Exercises, one-tap set confirmation at Target Reps with quick minus-adjustment, the Plate Breakdown in view, the count-up Rest Timer auto-starting after each set, and the progression suggestion surfacing per the rules from "Progression edge cases". The user tests it phone-sized and reacts; iterate until it feels right.

Added by [Progression edge cases](0004-progression-edge-cases.md): there is no progression suggestion to surface — Fitty applies the new Working Weight at Finish and the Summary announces it. What the prototype must carry instead: changing the weight on the Exercise card, where raising it sticks silently and lowering it asks "Just today, or from now on?"; a One-off Weight that logs Sets but never writes back; reps logged above the top of the Rep Range shown plainly beside the range, with no warning colour.

## Resolution

Approved outright on the first pass — "allemaal goed". No iteration was needed.

Asset: [Fitty Workout Logging prototype](https://claude.ai/code/artifact/11e1688b-5cd9-4010-9448-53c9bdc47e53) —
source `design/0007-logging/fitty-workout-logging.html`, one self-contained file. The logic lives in a pure module
(`Fitty`: `initialState`, `reduce`, `breakdown`, `progression`), with no DOM, no timers and no `Date.now()` — every
action that needs a clock takes an `at`. That module is the part meant to lift into the real app; the page around it
is throwaway. `design/0007-logging/artifact.html` is the same file wrapped for publishing.

### Design decisions this ticket settles

Ticket 4 handed over two open questions; both are answered here.

- **Changing the weight on the Exercise card.** Tapping the big number opens a bottom sheet with a numeric keypad plus
  `−` / `+` stepping by the Increment. Raising it closes the sheet at once and writes the Working Weight. Lowering it
  raises the *Just today, or from now on?* sheet, exactly once, on the way down only.
- **Marking a One-off Weight.** A steel chip `ONE-OFF · 72.5 KG STAYS` sits beside the unit — it names the Working
  Weight that survives, not just the fact of the one-off — and every Set row logged under it carries a plain
  `ONE-OFF` chip. Steel, never a plate colour, so the colour-means-weight rule holds.

Settled while building, and approved with the rest:

- **The rule chip under the weight** replaces the artboard's `+2.5 NEXT`. Steel `+2.5 KG IF ALL 12` while logging (the
  rule, stated); green `→ 75 KG NEXT TIME` the instant the Exercise completes (the fact, stated). It reads as a
  statement, never as an offer — which is what ticket 4 requires.
- **Completing an Exercise costs no tap**, but moving on costs one: the bottom button becomes `NEXT: BARBELL ROW`,
  or `FINISH WORKOUT` when nothing is Open. Fitty does not jump by itself.
- **The exercise counter is the navigation.** `3 / 5 ▾` opens a full-screen list where every Exercise carries its
  state as a pill, under the line "Leaving an open Exercise means later, never 'not at all'".
- **Reps over the range** read `14 reps · 8–12` on the Set row, plain, no colour.
- **A Barbell prints no Base Weight.** The bar is standard; only Smith and plate-loaded name one in the meta line.

### What the prototype proves

Nine walkthroughs, all driven end to end headlessly with no errors, each one an awkward case from the map:

| Walkthrough | Outcome |
| --- | --- |
| Everything at the top of the range | 5 Exercises progress |
| Done early, 2 of 3 Sets at 12 | 0 progress — the rule from ticket 3 bites as designed |
| 14 reps against 8–12 | one Increment, never more |
| Lower to 65 → *Just today* | Working Weight stays 72.5 kg; the Summary says so |
| Raise to 75 by hand | sticks silently, then progresses to 77.5 under the normal rules |
| Skip the Barbell row, reopen it later | works inside the same Workout |
| Finish with 4 Open | the gate holds, with the one-tap way out |
| 61.25 kg on a kg rack | `≈ CLOSEST` · you load 60 kg · 1.25 under (tie rounds down) |
| lbs stack + kg microplate | `100 LBS` over `+1 KG`, never converted |

The Workout Summary is a deliberate placeholder — it belongs to
[Workout summary screen prototype](0009-workout-summary-screen.md).

### One correction to the fixture

The prototype first used a 1.25 kg Microplate, copying the `100 lbs + 1.25 kg` example from tickets 4 and 5. The user
corrected it: **they own 0.25, 0.5, 0.75 and 1 kg microplates, and 1.25 kg is a normal plate in their gym.** The Plate
Inventory and the Lat pulldown's Microloading Increment were changed to match, so the mixed-unit display now reads
`100 LBS` / `+1 KG`. The example in tickets 4 and 5 stays as written — it is the record of what was decided there, and
the rule it carries (the Increment is always a plate the user owns, kept in the inventory's unit) is unchanged.

That correction exposed a question nobody had asked: microplates accumulate on the pin forever and Fitty never rolls
them up, so a Microloading Exercise eventually shows `+1.25 KG` in microplates when a single 1.25 kg plate is sitting
on the rack. The user wants this handled. It is on the map as fog, not as a ticket.
