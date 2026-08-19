---
id: 11
title: Microplate accumulation
parent: 1
labels: [wayfinder:grilling]
status: closed
assignee: henk
blocked-by: [4, 5, 7]
---

## Question

Microloading adds one Microplate per progression and Fitty never rolls them up, so a Microloading Exercise
accumulates microplates until they equal — or pass — a plate the user already owns. The user's rack: microplates
0.25, 0.5, 0.75 and 1 kg; 1.25 kg and up are normal plates. Four progressions at +0.25 kg put `+1.25 KG` on the pin
as microplates while a single 1.25 kg plate hangs on the rack.

Decide:

1. Does Fitty roll accumulated microplates up into the largest plate that fits, or does the Plate Breakdown simply
   always solve the whole load from the Plate Inventory, greedy, so the question never arises?
2. Does a stack or cable machine behave differently — the pin steps in fixed jumps, so microplates hang beside a
   stack number that Fitty does not choose?
3. What does the Plate Breakdown draw and caption while microplates and normal plates sit on the same side?
4. Does the Microloading Increment stay a fixed Microplate forever, or may it change as the Working Weight climbs?

Surfaced by [Workout logging clickable prototype](0007-workout-logging-clickable-prototype.md); the user asked for it
to be handled. Constrained by [Plate display design](0005-plate-display-design.md): the big number is always the
Working Weight, `≈ CLOSEST` names an unbuildable load, and progression never snaps to buildable weights.

## Resolution

The accumulation was a symptom, not the disease. Fitty carried **two** models of Microloading: `CONTEXT.md` said the
Working Weight goes up by the Microloading Increment, while the prototype held the Working Weight still and counted
microplates (`ex.microplates += 1`, `fromPlates`/`toPlates`). Only the counter can accumulate. Collapsing the two
models into one removes the question rather than answering it.

### One model

**Microloading raises the Working Weight, like every other progression.** The counter is deleted.

The mixed-unit case is the one place a single number cannot carry the load: an lbs stack machine with a kg microplate
on the pin is `100 lbs + 1 kg`, and the two units never convert. For that case the Exercise carries a second weight —
the **Microload**, a weight in the Plate Inventory's unit. It exists **only** when the Exercise's Weight Unit differs
from the Plate Inventory's unit; when the units match, the Microload is zero and Microloading simply moves the Working
Weight. So there is exactly one two-number screen, and it is the one
[Plate display design](0005-plate-display-design.md) already drew.

**Fitty stores a weight, never a count.** The Plate Breakdown solves that weight greedily against the Plate Inventory,
so `1.25 kg` of microload draws as one 1.25 kg plate and never as five 0.25 microplates. There is nothing left to roll
up: identical plates were never stacked in the first place. Four progressions at `+0.25` land on `+1 kg` — one 1 kg
microplate — and the fifth lands on `+1.25 kg`, one normal plate.

**A bar takes a pair.** Only the Barbell, Smith Machine and Plate-loaded Machine have two sides, so a 0.25 kg
Microloading Increment moves the Working Weight by **0.5 kg** there. Every other Equipment Type takes one plate, so
the same Increment moves it by 0.25 — the pin, the belt, and the dumbbell (the user notes people tie microplates to
dumbbells, so Fitty blocks no Equipment Type). The picker names the plate and the effect together:
`0.25 kg microplate · +0.5 kg on the bar`.

**A stack machine never rolls into the next pin step.** Fitty does not choose the pin — the user sets the Working
Weight and the pin follows, taking the largest step at or under it with the remainder hanging on it. One pin step is
about eighteen microplates away, so the case is theoretical.

**The Microloading Increment is a plain field.** The user changes it whenever they like, with no migration and no
warning. The next progression uses the new plate.

### Which plates the solver may use — decided against my recommendation

I argued that microplates should enter the plate solve for every Exercise, because
[Plate display design](0005-plate-display-design.md) already prints `Smallest jump on the bar: 0.5 kg`. **The user
overruled it, and the reason is sound: Microloading is rare and Progressive Overload is the common case, so a normal
barbell exercise must never be told to hang a 0.5 kg microplate.**

**The Progression Mode decides which plates the solver may use.** Progressive Overload solves from normal plates only.
Microloading solves from the whole Plate Inventory, microplates included.

Consequences, accepted knowingly:

- Ticket 7's walkthrough stands unchanged: `61.25 kg` still reads `you load 60 kg · 1.25 under`. Nothing in that
  prototype needs re-testing for this.
- The same Working Weight can draw two different loads on the same bar, depending on the Exercise's mode.
- An Exercise switched from Microloading to Progressive Overload can land on a weight the coarse rack cannot build, so
  `≈ CLOSEST` appears. That is correct; the user rounds the weight themself if they want to.
- The Plate Inventory footer is Program-level and knows no Exercise's mode, so it states both:
  `Smallest jump on the bar: 2.5 kg · 0.5 kg with Microloading`.

### A missing field: Stack Step

The prototype carries a stack's step size per Exercise (`ex.blockSize`), but
[Program onboarding flow prototype](0006-program-onboarding-flow-prototype.md) asks nine fields and this is not one of
them. It becomes a **tenth field, shown only for Machine (stack) and Cable** — the same shape as Base Weight, which
shows only for Smith and plate-loaded. The sheet never grows for a Barbell.

The Exercise **always holds both** an Increment and a Microloading Increment, and the sheet shows only the row the
current mode uses: `INCREMENT · +2.5 KG`, or
`MICROLOADING INCREMENT · 0.25 KG MICROPLATE · +0.5 KG ON THE BAR`. Switching the mode swaps the row and keeps the
other value, so nothing is re-asked. The field count on the sheet stays where ticket 6 left it.

### Setting the weight on a stack

A stack does not move in Increments, it moves in pin steps, so the weight sheet from
[Workout logging clickable prototype](0007-workout-logging-clickable-prototype.md) grows a second stepper for Machine
(stack) and Cable: `PIN` steps by the Stack Step (`− 100 LBS +`), `MICRO` steps by the Microloading Increment
(`− +1 KG +`), and the keypad stays under them for typing a number by hand. The big number is still the Working
Weight, so nothing else on the screen changes. A bar keeps the single `−`/`+` at the Increment, as approved.

### The palette — this ticket amends [Design language & visual direction](0002-design-language-and-visual-direction.md)

The user gave the real colours of their gym's rack. These replace the invented palette in the prototype:

| Plate | Colour | Note |
| --- | --- | --- |
| 20 kg | blue | |
| 10 kg | green | |
| 5 kg | black | darkest of the three greys |
| 2.5 kg | black | |
| 1.25 kg | black | lightest of the three greys |
| microplate 1 kg | red | |
| microplate 0.75 kg | blue | |
| microplate 0.5 kg | green | |
| microplate 0.25 kg | white | |

Where the colour repeats, **shades separate the sizes, and the lighter shade is the lighter weight**. Three black
plates cannot sit flat on the `#0E0F10` floor, so the black family lifts into greys that survive it: `5 kg` `#33373A`,
`2.5 kg` `#4E5358`, `1.25 kg` `#70767C`, each with a 1 px rim one step lighter than its face.

There is no 15 kg plate — that was my invention in the prototype fixture, and it goes. The 25 kg stays in the shipped
default list but switched off, because the Inventory is a toggle list for any gym, not a picture of this rack.

**Two rules of the design language change, because the real rack breaks the old one.** Blue is now 20 kg *and* the
0.75 microplate; green is 10 kg *and* the 0.5 microplate.

- Ticket 2's *colour only ever means weight* becomes **colour plus size means weight, and size is never decorative**.
  A microplate draws at roughly a quarter of the smallest normal plate, so a blue disc that small can only be the 0.75.
- The half that must not bend gets its own rule: **a plate is always a filled shape, and steel is never filled** —
  steel is text and a 1 px border, always. This is what keeps the 1.25 kg grey (`#70767C`) from reading as the steel
  of the `≈ CLOSEST` and `ONE-OFF` chips. No colour has to move; form carries the separation, and it holds for any
  palette a later gym brings.

### How Microloading states its rule

Same shapes as [Workout logging clickable prototype](0007-workout-logging-clickable-prototype.md) and
[Workout summary screen prototype](0009-workout-summary-screen.md), different numbers — Microloading fires at the
**bottom** of the Rep Range, not the top.

- Logging, steel: `+0.5 KG IF ALL 8`; mixed: `+0.25 KG IF ALL 8`.
- Completed, green: `→ 73 KG NEXT TIME`; mixed: `→ 100 LBS +1.25 KG NEXT TIME`.
- Summary, went up: `72.5 → 73 KG · NEXT TIME`; mixed: `+1 → +1.25 KG · NEXT TIME` under the `100 LBS` it belongs to.
- Summary, stayed: `ALL 3 SETS AT 8 → 73 KG`.

Ticket 9 throws confetti shaped from the per-side Plate Breakdown of the new weight, which a stack machine does not
have. **The burst throws the plates that changed, not the whole load**: a bar that went 72.5 → 73 throws one 0.25
microplate per side, a stack that went `+1 → +1.25 kg` throws one 1.25 kg disc, and a stack with no microplates throws
its pin step in steel. Every particle carries the plate's rim at 1.5 px, so a dark plate reads as a moving ring rather
than a hole; the face is never brightened, because the face is the weight. A burst that still reads as nothing is
fixed with more particles, never with lighter ones. A small jump gets a small burst, which is honest — the count of
Exercises is still the hero.

### What the prototype now has wrong

Not fixed here — this map plans, and the build starts from the spec. Recorded so
[Assemble the spec](0008-assemble-the-spec.md) carries it:

- `Fitty.progression()` returns `to: ex.weight` with `fromPlates`/`toPlates` under Microloading. It must return a new
  Working Weight, or a new Microload where the units differ.
- `ex.microplates` (a count) is replaced by a Microload (a weight).
- `greedy()` must take the plate list the Progression Mode allows, not `inv.plates` unconditionally.
- The fixture holds a 15 kg plate that does not exist, and `PLATE` holds the invented colours.
- `ex.blockSize` needs the name **Stack Step** and a place on the Exercise sheet.
