---
id: 53
title: The weight is too big and the plates too small
parent: 17
labels: [wayfinder:task]
status: closed
assignee: agent
blocked-by: []
---

## Question

**Three findings from the walk, all on the logging screen, and all about hierarchy.** Rob, walking
`HANDOFF.md` on 2026-08-28:

> Op het scherm als je een workout begonnen bent en op het oefening's scherm zit, dan zie je in het
> groot het aantal kilo + de stang en de plates. Dit ziet er gaaf uit, maar ik vind dat de tekst
> van het gewicht een te grote lettertype heeft en teveel ruimte inneemt. Ik wil de
> "11.3 base + 20 + 5 + 2.5" wat nu in het klein staat veel zichtbaarder. Dat is wat ik handig vind
> om te zien.

and, on the drawing itself:

> bij de barbell preview heb ik een preview met 4 schijven, maar dat laatste dingentje (zwart
> dingetje) lijkt ook net een plate. die mag weg

**This is a verdict, not a question**, so it is a `task`. What it costs deciding is only *how far*
to move each number, and that is written below.

**The screen was right on the artboard and wrong in the gym**, which is the one thing an artboard
cannot tell you. §6.4 called the Working Weight the hero and the artboard drew it at 88 px, and
both are defensible: the weight is the number you are about to lift. But **Rob already knows the
weight** — he is standing at the bar because of it. What he does not know, and what he came to the
screen for, is *which plates to hang*. The hero was answering a question he had not asked, in a
type size that pushed the answer he had asked for down to 11 px.

## Resolution

**Three changes, all in the view layer, no rule touched.**

**1. The hero, 88 → 64 px** (`LoggingScreen.weightBlock`). The Microload beside it goes 38 → 30 to
keep the step between them. It is **still the hero**: the next biggest thing on the screen is the
31 px Set number, so the order is unambiguous. §7.4 pins the *small* sizes — labels at 10–11 px,
letter-spacing, the 8/16 rhythm — and **never named this one**; 88 came from the artboard, and
§8.2 already lists twelve defects in that prototype. The map's own rule applies: *`SPEC.md` beats
the artboard wherever they disagree*, and here neither had it, so Rob does.

**2. The caption stacks, and the loud half is the one that says what to hang**
(`PlateBreakdownView.caption`). It was §5.5's two halves side by side, both at 11 px, the left one
dim. It is now a **load line at 17 px in full text colour** over a **qualifier line at 11 px dim**.

| Type | Load line (17 px) | Qualifier (11 px) |
| --- | --- | --- |
| Barbell, Smith, Plate-loaded | `11.3 base + 20 + 5 + 2.5` | `27.5 kg per side` |
| Machine (stack), Cable | `pin at 10 × 10 lbs · 1 microplate` | `100 lbs + 1.25 kg` |
| Dumbbell | `2 × 22.5 kg` | `each hand` |
| Bodyweight | `15 kg on the belt` | `added weight only` |

**The strings are §5.5's, unchanged.** What changed is size and arrangement — and note the last two
rows **swap sides**. §5.5 fixed the halves by position, left and right, but position is not the
same thing as job: `each hand` hangs nothing, so on a Dumbbell and a belt the *right* half is what
says what to load. The view now names them `loadLine` and `qualifierLine`, by job, and maps each
Equipment Type onto them.

They stack rather than sit side by side because at 17 px they do not both fit one line on a 390 pt
phone. The load line is `lineLimit(1)` with `minimumScaleFactor(0.6)` — **it shrinks, it does not
wrap**, because a line that reflows changes the block's height between Exercises and would move
every Set row under it. A six-plate bar is the worst case and lands near 11 px, which is where it
started; Rob's four-plate bar reads at 17.

**3. The collar is gone** (`LoadedBar`). It was an 8 × 40 outline outboard of the last plate, in
the darkest steel on the ramp (`Steel.hex(lightness: 0.453)`) — plate-shaped, plate-sized, and
sitting exactly where a fifth plate would sit. **§7.1 rule 2 was supposed to keep them apart** —
*a plate is always a filled shape, and steel is never filled* — and at arm's length on a phone it
did not: a thin dark outline beside four filled plates reads as one more plate. The rule is not
wrong; it just cannot carry a distinction this fine at this size, next to this neighbour.

Nothing is lost. §7.5 asks for *plates, mirrored around a knurled centre shaft* and names no
collar. The **sleeve stops stay** — they are the parts that say where the loading zone ends, they
are inboard of the plates where nothing can mistake them for one, and they are two ramp steps
lighter. `Color.collar` stays in the palette: the Dumbbell's sleeve still wears it, with no plate
anywhere near it. `naturalWidth` drops `collarWidth * 2` and two gaps, so a five-plate bar now has
**24 pt more room before it starts scaling down**, which is a second small win.

**What is proved and what is not.** `app/checks/AppTarget/run.sh` is green — the target parses and
no name is declared twice — and the `switch` expression the two new computed properties use was
compiled standalone here to be sure of its syntax. **None of this is a type-check**, because
SwiftUI is Mac-only, and **none of it is a look**: three type sizes and a deleted shape are exactly
the kind of change only the phone can judge. `HANDOFF.md` items 119–121 are the re-look.

`SPEC.md` corrected in three places: §5.5 (the stacked caption and which half is loud, and the
Microload's 30 px), §7.4's sibling text on the hero size, and §7.5 (no collar).
