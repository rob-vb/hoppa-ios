---
id: 35
title: The Exercise sheet, and the name field
parent: 17
labels: [wayfinder:task]
status: closed
assignee: agent
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

## Resolution

**§6.2 and §6.3 are built and pushed, and batch 1 is a path Rob can walk end to end**: empty app →
Program → rack → Days → real Exercises, with `HarnessSeed` still off. `HoppaRules` **119 green**,
`HoppaStore` 31, and `project.pbxproj` needed **no edit** — the app target is a synchronized folder
group, so one new file arrives by itself.

Nothing here is a rule. Every call the sheet makes into `HoppaRules` and `HoppaStore` was lifted
into a throwaway file and `swiftc -typecheck`ed here against the built modules under
`-swift-version 6`, which is as far as ticket 0022's line reaches: what is left is the SwiftUI.

**One finding, and it outranks the screen.** §6.6 says *"the same sheet asks for them again in the
new unit"* — and it cannot, because `Rules.edited` clears the Working Weight, the Increment and the
Stack Step **at the save**, on a comparison of the old resolved unit against the new one. Model B
saves once, so a number typed into the field the sheet just emptied arrives in that same draft and
is cleared with the stale ones. Proved on both paths — a Dumbbell flipped to kg and retyped, and a
Dumbbell turned into a Barbell over a kg rack — and it graduates as
[A weight retyped after a unit change](0041-a-weight-retyped-after-a-unit-change.md). The sheet
does not work around it, as this ticket asked: it empties the three fields the moment the unit on
screen moves, and it sends one action. **The add life never meets it** — `addExercise` compares no
units — so onboarding, which is all adds, is untouched.

**Five calls the ticket left open**, all now in `SPEC.md` §6.2:

- **The two lives leave differently.** An edit sheet has an Exercise behind it, so **closing is the
  save** and a line says so; there is no *cancel*, because the same sheet opens at the rack
  mid-Workout where §6.6 refuses to ask twice. An add sheet has nothing behind it: `SAVE AND ADD
  ANOTHER` is its save — the artboard's own control, and the tap budget's one save tap — and the
  `✕` **asks before discarding** a filled-in sheet. Neither reading survives a swipe-down, so
  interactive dismissal is off and the `✕` is the only way out.
- **`REMOVE EXERCISE` is built**, on the sheet the artboard draws it on. Wider than ticket 0034's
  cut, which left deleting an Exercise to Flow 5 — but §6.6 gives it **no block to state**, the
  action has been tested since ticket 0028, and a card that opens a sheet with no way to remove
  what it opened is a door with half a room behind it. Recorded rather than hidden, as ticket 0034
  recorded Program settings.
- **The Equipment Type really starts empty.** `ExerciseDraft` cannot hold *unpicked* — it is the
  value a rule consumes — so the question lives in view state and the save refuses until it is
  answered. The seven chips sit in §2.6's order, the four rack types first, which is the lock rule
  made visible. They wrap in a small `Layout`: `BODYWEIGHT` beside `SMITH` in equal columns is
  either clipped or four chips of white space, and SwiftUI ships no wrapping stack.
- **The carry-over crosses Workout Days** — the Exercise above it, or the last Exercise of the Day
  before it — and the very first Exercise of a Program starts at **3 × 8–12** with no `CARRIED
  OVER` mark. It is a pre-filled field and not a rule: nothing stored depends on it, and it is gone
  the moment the sheet saves.
- **The Increment chips are offers, not defaults** — 1.25 / 2.5 / 5 kg, 2.5 / 5 / 10 lbs, `…` for
  any number. Nothing is pre-selected, because an Increment the user did not pick is a weight
  Hoppa invented, and §6.2 starts the field empty on purpose.

Two smaller things the build had to answer. The **Microloading row's second clause is read out of
`Rules.progressionMove`**, probed at a zero Working Weight, so `+0.5 KG ON THE BAR` is the rule's
own doubling and not this view's multiplication — the same line ticket 0034 drew for the Exercise
card. And a **stranded** Exercise gets its own sentence rather than §5.2's `NO MICROPLATES · SET UP
YOUR RACK`: that copy is for a rack with none switched on, and printing it while the rack holds
three others would be false.

**Three things only the Mac can answer**, all in the hand-off: whether a tap on a floating
suggestion row lands (the list is an overlay that hangs past its parent's bounds, the artboard's
own `z-index`), whether the wrapping chip `Layout` really fits seven chips at 390 pt, and whether
the keyboard toolbar's `DONE` is enough to get a number pad off a scrolling sheet.
