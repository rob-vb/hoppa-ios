---
id: 30
title: Dark only, or a light mode too
parent: 17
labels: [wayfinder:grilling]
status: open
assignee:
blocked-by:
---

## Question

**`SPEC.md` is dark-first from end to end and never says whether a light mode exists.**

§7.2 puts the app on a `#0E0F10` floor, §7.3 gives the plates the colours of real iron, and every
artboard the design map produced is dark. None of that states a decision — it states a default that
was never questioned, because a static artboard has no system setting to obey.

On iOS it is a decision with real work behind it, and the work is not symmetrical:

- **Dark only** means locking the app with `.preferredColorScheme(.dark)`, and that has a real cost:
  the app ignores the phone's own setting, which iOS users notice. It is one line, and it is a
  promise that every future screen may hard-code a colour.
- **A light mode** means every colour becomes a token with two values, and it reaches further than a
  palette swap. The plate colours are **physical** — a blue 20 kg plate is blue in the gym — so they
  cannot invert. The Anton hero, the steel of the loaded bar and the Ignition confetti (§7.1's rule
  that steel particles are not filled) all read against a dark floor by design.

Settle:

- Does Hoppa have a light mode, now or ever?
- If not: is it locked to dark, or does it merely look dark and drift when someone changes a
  setting? Say which, because they are different builds.
- If so: what does §7.3's physical plate palette do on a light floor, and who decides the token
  values — this map, or the launch effort?
- Either way: **what shape do the colours take in code**, so the first screen does not hard-code a
  hex that a later decision has to hunt down. `Palette.swift` already exists from ticket 18.

This blocks nothing today, and it gets much more expensive after three screens are written. Consult
`SPEC.md` §7, and the map's Out-of-scope note on user-set plate colours — a related question that
stays out.
