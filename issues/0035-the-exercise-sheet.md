---
id: 35
title: The Exercise sheet, and the name field
parent: 17
labels: [wayfinder:task]
status: open
assignee:
blocked-by: [34]
---

## Question

**Build §6.2 and §6.3 together: the full sheet, and the name field with its suggestions.**

This is the largest screen in Flow 1 and the one Flow 5 reuses whole, so it gets a ticket of its own.
It is also **the ticket that closes batch 1** — when it lands, Rob can walk from an empty app to a
real Program with real Exercises, and `HarnessSeed` stops being the only way to have one.

**Model B, the full sheet** (§6.2), chosen for the audience and not for the tap count — 400 taps
against Model A's 287, buying explicit control over every field that changes how an Exercise behaves.
The floor is **14 taps per Exercise**.

- **Add and edit are the same sheet.**
- **Sets and Rep Range carry over** from the previous Exercise, marked `CARRIED OVER`. **Every other
  field starts empty** — Equipment Type, Working Weight, Increment and Base Weight are picked by hand
  every time.
- **The sheet grows with the Equipment Type.** Base Weight appears only after Smith or plate-loaded;
  Stack Step only for Machine (stack) or Cable. **It never grows for a Barbell.**
- **The Increment row swaps with the Progression Mode**: `INCREMENT · +2.5 KG`, or
  `MICROLOADING INCREMENT · 0.25 KG MICROPLATE · +0.5 KG ON THE BAR`. With no Microplate switched on
  it reads `NO MICROPLATES · SET UP YOUR RACK` and taps through to ticket 33's Microplate group.
- **The Weight Unit is locked** for the Equipment Types loaded off the user's own rack, with a steel
  lock line saying why. §6.6 said "the four" and named Bodyweight; **there are three**, and
  [Build the Program edits](0028-build-the-program-edits.md) fixed the spec. Read §2.3 and §5.1.
- **The sheet saves once** ([Program edits, and which of them are rules](0026-program-edits-and-the-rules-boundary.md)):
  one action carrying a draft, never ten per-field actions.
- **An unset weight is `nil`, not zero.** Zero is a real Bodyweight lift.
- **A change of Equipment Type is a change of unit**, and the clearing rule watches the unit the
  Exercise *resolves to*. That rule is built; this sheet must not work around it.

**The name field** (§6.3). `Rules.nameSuggestions(in:query:)` is built and tested — this ticket
draws it and does not re-decide it.

- **Six rows at most, on focus and while typing alike.**
- On focus, before typing: the user's own names, most recently trained first, no catalogue entries
  mixed in. On a first run it shows nothing.
- **Free text always wins**, and **a suggestion sets the Name and nothing else** — never the
  Equipment Type, never the Increment. This holds on the edit sheet too.

Done, hand-off and testing follow ticket 29's rules. **This ticket triggers hand-off batch 1**:
one numbered list, `git pull` and a build first, `git push` last if Xcode changed anything, and a
closing note on what is not built yet.

Consult `SPEC.md` §2.3, §2.6, §5.1, §6.2 and §6.3, `design/0006-onboarding/`, and
`app/HoppaRules/Sources/HoppaRules/Suggestions.swift`.
