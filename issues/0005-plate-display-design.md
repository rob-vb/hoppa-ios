---
id: 5
title: Plate display design
parent: 1
labels: [wayfinder:prototype]
status: closed
assignee: henk
blocked-by: [2]
---

## Question

How does the Plate Breakdown look and behave? Produce `/design` artboards for: per-side plates on a Barbell; Smith Machine and Plate-loaded Machine with Base Weight shown; Microplates on a stack/cable pin; Dumbbell and Bodyweight (weight only); and the unreachable case (the Plate Inventory cannot make the exact Working Weight — round which way, and how to show it?). The rounding decision is part of this ticket.

Added by [Progression edge cases](0004-progression-edge-cases.md): the Plate Inventory now carries one unit, and that unit sets the Weight Unit of every Exercise with a Plate Breakdown. Exercises on a stack, cable, dumbbell or bodyweight carry their own unit, so a mixed case must be drawn: an lbs stack machine with a kg Microplate reads **100 lbs + 1.25 kg**. Fitty never shows the converted total. The Microloading Increment is a Microplate picked from the Plate Inventory, so the artboards must show which Microplates the inventory holds.

## Resolution

Eight artboards in the "Plate Rack" direction. Asset: [Fitty Plate Breakdown canvas](https://claude.ai/code/artifact/6562a440-efd1-4f87-81b9-4630dc3c9ae6) — source artboards in `design/0005-plate-display/`.

### One drawing for every plate-loaded type

Barbell, Smith Machine and Plate-loaded Machine all draw the **same loaded bar**: plates to relative diameter and width in their real colours, mirrored around a knurled shaft. No guide rails for the Smith Machine, no carriage block for the Plate-loaded Machine — the user rejected per-type silhouettes as needless variation. The Base Weight is the only difference, and it lives in text: the meta line reads `… · BASE 15 KG`, and the caption reads `15 base + 20 + 5 + 2.5 + 1.25` on the left with `28.75 kg per side` on the right.

### The other four types

- **Machine (stack)** and **Cable**: the weight stack drawn as blocks, the loaded blocks in steel and the rest dark, with the pin below the last loaded block and the Microplate hanging on it. Caption: `pin at 10 × 10 lbs · 1 microplate` / `100 lbs + 1.25 kg`.
- **Dumbbell**: a steel dumbbell, no plate colours, because nothing is loaded. Caption: `each hand` / `2 × 22.5 kg`.
- **Bodyweight**: the added plate drawn face-on, hanging from a belt clip. Caption: `added weight only` / `1 × 15 kg on the belt`.

### Mixed units

The Weight Unit never converts. When an Exercise carries a Microloading Increment in the other unit, the screen stacks two numbers: the Working Weight big (`100` / `LBS`), the Microplate under it at 38 px (`+1.25` / `KG`). Both keep their own unit label. There is no combined total anywhere on the screen.

### Plate Inventory

One unit toggle (KG | LBS) with the line "This unit applies to every barbell, Smith machine and plate-loaded exercise in the Program." Then a list of plate sizes, each a colour chip sized to the plate, the weight, and an on/off toggle. Microplates are a second group under their own label. **On/off only — no count of pairs.** A pairs count was drawn and rejected as too much setup; Fitty accepts that it can propose a load the user cannot build from the plates they physically own.

Footer line: `Smallest jump on the bar: 0.5 kg`.

### The unreachable case — decided

Three options were drawn (A round down, B closest either way, C target stays). **C is the rule.**

The big number is always the Working Weight Fitty tracks — it never changes to fit the plate rack. Under the bar drawing, an extra caption line appears only when the exact weight cannot be built:

```
[≈ CLOSEST]  you load 62.5 kg · 0.5 over
20 + 1.25                    21.25 kg per side
```

The `≈ CLOSEST` chip is steel (`#3A3E42` border, `#9BA1A7` text), never a plate colour, so the colour-means-weight rule holds.

Rules that follow:

- The closest buildable load wins, up or down. On a tie, Fitty rounds **down**.
- Progression does **not** snap to buildable weights. The Working Weight stays exactly what the Increment makes it; only the display deals with the gap. Rejected as overengineering.
- Sets are logged against the Working Weight, not against the load actually on the bar.

Rejected artboards `UnreachableA.dc.html` and `UnreachableB.dc.html` stay in `design/0005-plate-display/` as the record of the choice, off the canvas.
