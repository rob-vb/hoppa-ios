---
id: 51
title: The walk, and the findings it produces
parent: 17
labels: [wayfinder:task]
status: open
assignee:
blocked-by: []
---

## Question

**Everything is built and nothing has been seen.** With
[the Exercise card's two doors](0050-the-exercise-cards-two-doors.md) closed, every screen in
`SPEC.md` exists and every door between them is open. No decision is left to make on this side of
the wall.

**This is a `task` and not a decision**, and it earns its place the way §-ticket 0029 said a screen
ticket does not: *a closed screen ticket is not a seen screen, and a screen counts toward the
destination only after he looks at it.* Ten screen tickets closed without one walk between them,
which is the trade Rob took on 2026-08-27 — *"Ik wil alles op het eind testen, en ik wil eerst
alles bouwen."* This is the end.

**The checklist is [`HANDOFF.md`](../HANDOFF.md)**, complete at 118 items, every one *do X →
expect Y*: item 1 is `git pull` and a build, item 118 the last judgment call, and the last item is
the `git push` if Xcode touched `project.pbxproj`. Nothing needs writing for this ticket — the
document is the ticket's whole body, and it was written a screen at a time as each landed.

**HITL, and only Rob can do it.** The agent runs on a VPS with no Mac, no simulator and no phone;
211 of the 218 rules tests and all 233 checks are green here and prove everything provable here.
What is left is SwiftUI, a thumb and gym light.

**What this ticket unblocks.** Every finding. The map's rule since ticket 0029 is that a complaint
is a **finding with its own ticket**, and the map's own fog says so in as many words: *what happens
the first time real training disagrees with the spec.* Batch 1's walk cost three fixes across four
screens; this one covers ten screens at once, and some findings will be the same mistake repeated
in several places. Those tickets cannot be written before the walk, which is why they are fog and
this is a task.

**How it resolves**: Rob walks `HANDOFF.md` and says what is wrong. The answer records what he
found, and each finding graduates into its own ticket.

Consult [`HANDOFF.md`](../HANDOFF.md) and
[Build order across the flows, and what done means for a screen](0029-build-order-and-what-done-means.md).
