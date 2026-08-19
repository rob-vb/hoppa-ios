---
id: 16
title: Bounding the Microload
parent: 1
labels: [wayfinder:grilling]
status: closed
assignee: henk
blocked-by: []
---

## Question

**Nothing ever stops a Microload.** Surfaced by
[History and progression charts](0015-history-and-progression-charts.md), which ran Fitty's real
progression rules forward over sixteen weeks — the first time anything in this map looked further
than one Workout ahead.

[Microplate accumulation](0011-microplate-accumulation.md) left one case where a second number
survives: an Exercise whose Weight Unit differs from the Plate Inventory's carries a **Microload**
in the Inventory's unit. Microloading then adds a Microplate to the Microload at every
progression, and **nothing ever moves the pin**. The Microload only grows.

With the user's own gym — a 90 lbs stack and a 1 kg Microplate — the rules reach a Microload of
**+11 kg** in fifteen weeks. No hook carries 11 kg of microplates. Before that it is already
wrong in a smaller way: the solver draws every gram from the biggest Microplate down, with no
count of pairs, so `+4.25 kg` draws as five plates on a pin the user probably owns two of.

### The constraint that makes this hard

The obvious fix is a **roll-up**: when the Microload passes one Stack Step, move the pin one step
and subtract. It cannot be done. The Stack Step is in the Exercise's unit and the Microload is in
the Inventory's, so every comparison between them is a **unit conversion** — and *units never
convert* is load-bearing across
[Progression edge cases](0004-progression-edge-cases.md),
[Plate display design](0005-plate-display-design.md),
[Workout summary screen prototype](0009-workout-summary-screen.md) and
[Editing a Program over time](0014-editing-a-program-over-time.md).

**So the answer cannot be arithmetic.** It has to be a boundary Fitty can state, and a weight
change the user makes.

### Recommendation to argue with

A **ceiling from the Plate Inventory, and the pin is the user's move.** The Microload may not pass
the sum of the Microplates the Inventory has switched on, counted once each — the most Fitty can
draw on a hook without inventing plates nobody owns. With the whole kg group on, that is
`0.25 + 0.5 + 0.75 + 1 = 2.5 kg`. At the ceiling the Exercise stops raising the Microload and
**states its condition**, which is the move Fitty already makes everywhere else, and the user
moves the pin one Stack Step and clears the Microload to zero. The pin moves in lbs, the Microload
resets to 0 kg: nothing converts.

### What to settle

- Is the ceiling the Inventory sum, a number the user types, or something else?
- What does the Exercise say at the ceiling, and where — the logging screen's rule chip, the
  Exercise card, or both? It must state, not advise.
- Is clearing the Microload one tap, or a plain weight edit through the machinery
  [Progression edge cases](0004-progression-edge-cases.md) already built?
- Does the same ceiling belong on **every** Equipment Type, or only the pin? A bar sleeve really
  does hold a stack of microplates, so a Barbell may need no ceiling at all.
- Does anything change for the same-unit case, where Microloading raises the Working Weight and
  the solver may already hang four microplates on a bar?

Consult `CONTEXT.md`, `SPEC.md` §4.2 and §5.2–5.3. This changes progression, the Plate Inventory
and the logging screen, so it changes `SPEC.md` — not the charts.

## Resolution

**The pin moves.** A Microload that reaches one Stack Step rolls into the pin, so the hook never
carries more than one pin step of iron and the number is bounded forever.

### The ticket's own premise was wrong

This ticket was written on the claim that *a roll-up would have to convert kg into lbs, and this
map forbids that everywhere, so the answer cannot be arithmetic*. It is wrong. `SPEC.md` §4.2
already says:

> Fitty does the mixed-unit arithmetic itself and never shows the result of it; the user never
> types 2.76 lbs.

**The prohibition is on showing a converted number, not on computing one.** Fitty has always
converted internally. That reopened the option the ticket had ruled out, and it turned out to be
the best one — so the recommendation this ticket argued for lost to the option it wrongly
dismissed.

Two smaller errors went with it. The recommended ceiling — the sum of the switched-on Microplates
— **breaks for anyone who owns one size**: switch on only the 1 kg plate and the ceiling is 1 kg,
so Microloading gives exactly one progression and then stops. And the finding contradicts §5.3,
which had already looked at this and dismissed it: *"one pin step is about eighteen microplates
away, so the case is theoretical."* Eighteen assumed the 0.25 plate. With the 1 kg plate it is
five progressions.

### The rule

At every Microloading progression on a mixed-unit stack:

1. The Microload goes up by one Microplate, as always.
2. **While** the Microload is at or past one Stack Step: add one Stack Step to the **Working
   Weight**, and keep the remainder as the new Microload, **rounded up** to a weight the Plate
   Inventory can build.

Two invariants carry the whole design:

- **The Microload is always less than one Stack Step.**
- **The weight never goes down.** The round-up is what guarantees it. It costs at most one
  Microplate more than the user asked for — inside the promise that the user never meets a weight
  they did not choose (§4.2), and far better than a progression that silently drops.

Both were checked against real cases in `design/0015-history/check-rollup.mjs`, over 40
progressions each: an lbs stack in a kg gym with a 0.25 and with a 1 kg Microplate, a kg stack in
an lbs gym, and the degenerate case where the Microplate is bigger than the Stack Step. They hold
in every one. The case that opened this ticket — `+11 kg` on a pin — now tops out at 4 kg against
a 4.54 kg step.

The screen says what it always says: two numbers with their own labels, no total, no explanation.
`90 LBS + 4.5 KG → 100 LBS + 0.25 KG`. A `PIN MOVED UP ONE STEP` line was drafted and rejected —
a pin step is not a concept the user should have to hold, and the numbers already say it.

### Where a Microload can exist at all

Settling the roll-up settled the scope with it: **a Microload exists only where there is a Stack
Step** — Machine (stack) and Cable. That is the only place with somewhere to hang it *and*
something to roll it into. Two consequences:

- **Bodyweight takes the Plate Inventory's unit**, joining Barbell, Smith and Plate-loaded. Its
  added weight *is* a plate off the user's own rack hanging from a belt, so the rack names the
  unit — the same "you cannot load a plate you do not own" rule, which §2.6 and §5.1 had simply
  never applied here. A Bodyweight Microload can no longer arise, so that hole closed itself
  rather than needing an answer.
- **A Dumbbell whose unit differs from the Inventory's cannot use Microloading.** No pin, no Stack
  Step, nowhere to put the plate. Fitty states it on the Exercise sheet where the user stands, the
  way [Plate Inventory shipped defaults](0013-plate-inventory-shipped-defaults.md) states the
  empty Microplate group. This narrows *Microloading is available on every Equipment Type* by one
  combination only: a Dumbbell in the **same** unit still microloads, and the plate the user tapes
  to it raises the Working Weight as before.

### What this changes

`SPEC.md` §2.3 (the Microload field), §2.6 (Bodyweight's group, the Dumbbell refusal), §4.2 (the
roll-up), §5.1 (where the unit lives), §5.3 (the retracted "never rolls" paragraph).
`CONTEXT.md` gains **Roll-up** and amends Microload, Microloading, Weight Unit, Equipment Type,
Bodyweight and Stack Step. No screen changes: the Summary already stacks two numbers, and there is
nothing new to draw.
