---
id: 60
title: The unnamed plate on the pin
parent: 17
labels: [wayfinder:task]
status: closed
assignee: agent
blocked-by: []
---

## Question

Rob, walking the logging screen, 2026-09-07, on Chest fly machine at 87.5 kg:

> it just says 1 microplate? but what microplate?? 2.5kg is not a microplate...

**This is a verdict, not a question**, so it is a `task`. Ticket
[0053](0053-the-hero-and-the-load-line.md) made the load line loud so it would say *which
plates to hang*. The string that became loud was still §5.5's `1 microplate` — a count,
and a word that is wrong when Progressive Overload hangs a 2.5 kg **normal plate** on
the pin. The size was only in the dim line under it (`85 kg + 2.5`).

The artboard's mixed-unit example (`pin at 10 × 10 lbs · 1 microplate` / `100 lbs + 1.25 kg`)
is where the word came from. Rob's stacks are kg. His remainder is a 2.5.

Consult `SPEC.md` §5.3, §5.5, `PlateDrawing.swift` (`captionLeft`), `DomainCopy.swift`,
and [The weight is too big and the plates too small](0053-the-hero-and-the-load-line.md).

## Resolution

**The load line names the hanging plates by size.** `pin at 85 kg · 2.5 kg`. Never a
count of microplates. A real Microplate still prints its size (`0.5 kg`), because
"which plate" is the question either way.

The pin was already the printed label (`85 kg`), not the artboard's `10 × 10 lbs` —
the built caption had already left the block-count form. This ticket takes the hanging
half the same way: name the iron.

The qualifier is unchanged: `85 kg + 2.5`, and `100 lbs + 1.25 kg` when the units
differ. That is the math. The loud line is what to hang.

Copy lives on `StackLoad` in `DomainCopy.swift`, which imports no SwiftUI, so
`app/checks/LoadLine/run.sh` compiles the real file against `Rules.breakdown` and proves
the Chest fly case, an exact pin, two remainder plates, a 0.5 kg Microplate, and the
mixed-unit pin. The view prints `load.loadLine` / `load.qualifierLine` and decides
nothing.

`SPEC.md` §5.5's table and the sentence under it, and `CONTEXT.md`'s stack bullets,
now say plates hanging on the pin rather than Microplates-as-a-count. §5.3's solver
still hangs the remainder as plates from the Inventory the Mode allows.
