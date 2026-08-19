---
id: 8
title: Assemble the spec
parent: 1
labels: [wayfinder:task]
status: closed
assignee: henk
blocked-by: [3, 4, 5, 6, 7, 9, 10, 11]
---

## Question

Consolidate every decision on this map into one build-ready spec document: the domain model (from `CONTEXT.md`), the progression and plate rules, the validated screen designs (linked prototypes), and the open items left in the fog. The spec is the destination artifact this map exists to produce; the build phase starts from it as a fresh effort.

## Resolution

**[`SPEC.md`](../SPEC.md)** — the destination artefact. Eleven sections: the product and its
three governing rules, the domain model as fields per entity, the Workout lifecycle, the
progression rules, weight and the Plate Breakdown, the three validated flows screen by screen,
the "Plate Rack" visual language, the prototype code and its known defects, the open items, what
is out of scope, and a decision index back to all eleven tickets.

Written so a build team that has read nothing else can build flows 1–3 from it. `CONTEXT.md`
stays the single home of the glossary and is referenced, not copied; the ticket files stay the
single home of the reasoning and are linked from every section. Where the spec and `CONTEXT.md`
appear to disagree, `CONTEXT.md` wins on what a term means and the spec wins on what the app
does.

### Two things assembly surfaced

**A conflict between two closed tickets, now a ticket of its own.**
[Workout summary screen prototype](0009-workout-summary-screen.md) chose confetti colour rule
**Rack** — the per-side Plate Breakdown of the new weight — and rejected rule **Increment**,
because a five-Exercise day came out almost one colour.
[Microplate accumulation](0011-microplate-accumulation.md), fixing the stack machine that has no
per-side breakdown, wrote "the burst throws the plates that changed, not the whole load". Read
generally that is Increment under another name, and the real rack makes it worse than when it
was rejected: 2.5 kg is grey. Raised as [Confetti plate source](0012-confetti-plate-source.md)
with a recommendation — keep Rack where a per-side breakdown exists, use "the plates that
changed" only where it does not. `SPEC.md` §6.5 marks the point open and §9 states the case.

**Three details no ticket ever fixed**, recorded in `SPEC.md` §9 rather than invented here:

- The 25 kg plate ships in the default kg list, switched off, and has no colour since the
  palette amendment moved red to the 1 kg microplate.
- The lbs Microplate defaults were never specified; the kg set is 0.25 / 0.5 / 0.75 / 1.
- [Program onboarding flow prototype](0006-program-onboarding-flow-prototype.md) confirms the
  plate rack with "both Microplates on", written before the rack held four.

### Scope

The spec covers the three flows this map charted and validated. Flows 4 (history and charts) and
5 (editing a Program over time) are named as open, not specified — they were fog when this
ticket was written and they still are. That is what the ticket asked for: "the open items left
in the fog" are §9.
