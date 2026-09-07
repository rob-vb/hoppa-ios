---
id: 59
title: The native tab bar — Home, History, Progress, Settings
parent: 17
labels: [wayfinder:task]
status: closed
assignee: agent
blocked-by: []
---

## Question

Rob, 2026-09-07:

> Ik wil de History en Progress buttons veranderen in een native bar van iOS

Then:

> Wat dan ook in de native bar moet is de mogelijkheid om weer naar "Home" te gaan, en naar "Settings"

§6.7 had named **two doors and no tab bar**. Ticket 0015 refused a tab bar because Hoppa was
one screen deep and a bar would be permanent chrome on an app built for big numbers and
thumbs. Ticket 0058 then put a second `DoorRow` under History at the foot of the picker.
That is more chrome than a tab bar, and it is the wrong chrome: four peer rooms reached by
pushing off the picker.

This ticket takes the native bar. Four tabs. Home, History, Progress, Settings.

Consult `SPEC.md` §6.1, §6.7, `HoppaApp.swift`, `Route.swift`, `WorkoutDayPicker.swift`,
`HistoryScreen.swift`, `ProgressScreen.swift`, `ProgramSheet.swift`, and tickets
[0015](0015-history-and-progression-charts.md), [0032](0032-the-shell-and-the-first-run.md),
[0056](0056-native-behaviour-own-look.md), [0057](0057-the-wordmark.md),
[0058](0058-the-progress-page.md).

## Resolution

**Four tabs, each a `NavigationStack` with its own path.** `HoppaTab` is the named shape:
`home`, `history`, `progress`, `settings`. History, Progress and Settings leave `Route`
because they are roots, not pushes. `.pastWorkout` and `.exerciseChart` still push on their
tab's stack. The store still holds no view state.

The bar is UIKit's. Opaque `floor`, selected tint `text`, unselected `labelText`. SF Symbols
live in the bar and nowhere else. Ticket 0056 kept §7's glyphs for Hoppa's own drawing;
this chrome is not Hoppa's drawing.

The picker loses the two `DoorRow`s and the gear. Settings is the Program sheet, the same
hub the gear opened. Outside onboarding it has no chevron and no `DONE`: the Home tab is
the way out. Onboarding still pushes the hub on the home stack with `START A WORKOUT`.

The bar hides when there is no Program, during onboarding, and on the logging screen and
the Summary. A workout is not a room you switch out of with a thumb on the foot.

`GearGlyph` went with the gear. The wordmark and the Program name stay on Home.

### Why a tab bar, and not a toolbar on the picker

A bottom toolbar on the picker cannot hold Home as a destination while you are already on
Home. Four peer rooms is the domain `UITabBar` exists for. Each tab keeps its own stack, so
a chart opened from Progress is still there when you come back from Home.
