---
id: 56
title: Native behaviour, own look
parent: 17
labels: [wayfinder:task]
status: closed
assignee: agent
blocked-by: []
---

## Question

Rob, on the walk, 2026-08-28:

> Ook ziet de app er niet iOS native uit. Kun jij door de app heen om te kijken of je het meer
> als een native app kunt krijgen en ook kijken of je de gebruiksvriendelijk en design wat
> beter/mooier kan krijgen?

**This ran into a settled decision**, §7's Plate Rack language from
[Design language & visual direction](0002-design-language-and-visual-direction.md), so it went
to Rob as three options rather than into a build: keep the look and add native *behaviour*;
hybrid with system chrome; or fully native, which would be a new design map. **He chose the
first, and asked for it built directly** under the 2026-08-27 rule — decide, record, put it on
the walk.

The question, then: **what makes an app feel native when it does not look like the system?**
The answer this ticket takes is that it is almost entirely what happens under the thumb, and
Hoppa had none of it.

## Resolution

**Four things, three of them in this ticket and one already landed.**

| What a native app does | Hoppa before | Now |
| --- | --- | --- |
| Swipes back from the left edge | Off on every screen | [Ticket 0055](0055-the-swipe-back.md) |
| A button reacts while held | Nothing — `.plain` on all 43 | `PressableButtonStyle`: dims to 0.55 and scales to 0.985 for 0.12 s |
| The phone ticks at the moments that matter | One tick, on the reorder handle | Nine sites, four named ticks |
| A sheet shows its grabber | None of eight | `.presentationDragIndicator(.visible)` on all eight |

**1. The press.** `.buttonStyle(.plain)` is what SwiftUI gives a custom-drawn button that does
not want the system's blue text — and it also gives *no pressed state at all*. A tap on a 64 pt
`PrimaryButton` produced nothing until the next screen arrived, which is the single largest
reason a hand-drawn app feels like a web page. `Pressable.swift` holds one `ButtonStyle`, and
every `.plain` in the target became `.pressable` — 43 sites, zero left. Nothing about any label's
drawing changed; this is `.plain` with a pressed state.

**2. The ticks.** `Haptic` is four static functions named by *what happened*: `logged()`
(medium impact — the tap the whole screen is for), `finished()` (success — the Summary lands on
it), `stepped()` (selection — the weight sheet's `−`/`+`, held and tapped fast), `destroyed()`
(warning — delete an Exercise, a Day, a past Workout, or discard a Workout). UIKit generators
rather than `.sensoryFeedback`, because these moments are lines inside an action function and
not a value a view could watch. The reorder handle keeps its `.sensoryFeedback(.selection)`,
which is the right tool there because `landing` *is* a value that changes. Haptics are not
motion, so Reduce Motion does not reach them — §6.5's own line.

**3. The grabber.** Every sheet already set a floor background or a detent, and none showed the
system's drag indicator. It is now visible on all eight, at the site that already carried the
sheet's presentation modifiers. This is the one visible change in the ticket, and it is the
system's own mark on the system's own sheet — not a §7 decision.

**What was looked at and left alone, and why.** `confirmationDialog` for the small confirms is
already native. `.scrollBounceBehavior(.basedOnSize)` and `.scrollDismissesKeyboard(.interactively)`
are already there. The keypad in the weight sheet gets no tick — the system keyboard's own
haptic is off by default, and matching that is the native choice. No SF Symbols, no system
navigation bars, no `List`: those are §7 and Rob kept §7.

**What "mooier" got, and what it did not.** Rob's message also asked for the design to be
better-looking. This ticket answers that *within* §7 — the press, the ticks and the grabber
are what a polished app has and a prototype does not — and it does not touch a single colour,
face, radius or layout. Ticket 0053 already moved three of those on the logging screen; if the
walk finds more, each is its own finding against a specific screen, which is the only way a
"make it prettier" resolves without a new design map.

**Unproven here**, all of it, and by nature: press states, haptics and a grabber are exactly the
three things this machine cannot feel. `HANDOFF.md` items 126–128.
