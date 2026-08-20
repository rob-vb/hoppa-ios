---
id: 26
title: Program edits, and which of them are rules
parent: 17
labels: [wayfinder:grilling]
status: open
assignee:
blocked-by:
---

## Question

**§6.6 is full of rules, and none of them has a home.**

[Lift the rules into HoppaRules](0023-lift-the-rules-into-hopparules.md) built the logging flow's
rules and stopped at the edge of Flow 5. It landed exactly one Program edit — `.setWorkingWeight`,
because §4.3 puts it inside the Workout and three walkthroughs need it. Everything else §6.6
specifies is still nowhere:

- **Raising the planned Sets returns a Completed Exercise to Open** (§3.2). A rule about an Open
  Workout, triggered by an edit to the Program.
- **Changing a Weight Unit clears the weights** on that Exercise (§6.6).
- **Changing the Plate Inventory's unit** clears the weight on **every** plate-loaded Exercise there
  is, and produces the **Re-weigh list** (§6.6).
- **Switching a Microplate off strands** every Exercise using it as its Microloading Increment, and
  says so (§6.6).
- **Deleting** an Exercise or a Workout Day, with two blocks — and history must survive it (§2.8).
- **A Microload is destroyed and recreated at zero** when a unit changes, while a Base Weight and a
  Stack Step survive a change of Equipment Type (§2.8).

Each one is already specified. What is **not** decided is where they live, and that is a boundary
question this map has been careful about twice already:

- [The rules module and its oracle](0020-the-rules-module-and-its-oracle.md) put the rules in one
  place so they cannot be implemented twice.
- [The Logbook on disk](0025-the-logbook-on-disk.md) forbids `LogbookStore` from deciding anything:
  *the moment it decides something, rules live in two places*.

So a §6.6 edit cannot be a plain struct mutation in a view or a store without breaking one of those.
The likely answer is that these become `Action` cases on `HoppaRules` beside the logging ones — but
that makes `reduce` the entry point for editing a Program as well as performing one, and it deserves
to be said out loud rather than assumed.

Settle:

- Which §6.6 edits are **rules** (an `Action` on `HoppaRules`) and which are plain field writes.
- What each does to an **Open Workout** in progress, since §6.6 explicitly allows editing at the rack.
- What the Re-weigh list and the stranded-Increment list **are** as values, so a screen can render
  them without re-deriving the rule.

Do not decide the screens — [The view layer around the rules](0024-the-view-layer-around-the-rules.md)
owns those, and this ticket owns what sits under them. Consult `SPEC.md` §2.8, §3.2 and §6.6,
`CONTEXT.md`, and ticket 23's resolution.
