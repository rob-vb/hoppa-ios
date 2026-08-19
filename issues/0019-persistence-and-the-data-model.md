---
id: 19
title: Persistence and the data model
parent: 17
labels: [wayfinder:grilling]
status: open
assignee:
blocked-by: [20]
---

## Question

**How does `SPEC.md` §2 become types that survive the app closing?** The biggest architectural
decision on this map, and the one hardest to walk back: it decides the shape of every screen's
data and every migration for the life of the app.

`SPEC.md` §2 is unusually specific for a spec — fields per entity, and three rules that are really
storage requirements in disguise. Those three are the test any answer has to pass.

### The three rules that constrain the model

1. **A Set is a record of the past (§2.5).** It stores its own reps, weight, Weight Unit, Microload
   and One-off mark *as performed*, and **no later edit to the Exercise, the Program or the Plate
   Inventory changes it**. The design map found this the hard way: before ticket 14 a Set held the
   rep count only and read the weight live off the Exercise, so every finished Workout displayed a
   weight that progression had since moved. A model that lets a Set point at a mutable Exercise
   weight reintroduces that bug.
2. **A Set stores no Plate Breakdown (§2.5).** It is a solve, not a fact. Storing the picture would
   make every Plate Inventory edit a history migration.
3. **The Name is looked up live, and stored only as a fallback (§2.4, §2.7).** A Workout keeps the
   Name of its Workout Day and every Exercise, but Fitty shows the **live** Name while the Exercise
   exists and falls back to the kept one **only after a delete** — so a rename still fixes a typo
   everywhere in history. That is a relationship that must survive the deletion of its target,
   which is exactly where an ORM's cascade rules bite.

### What to settle

- **SwiftData, Core Data, or Codable value types written to disk?** SwiftData is the modern default
  and the least code; it is also young, opinionated about mutability and object identity, and its
  migration story is thinner than Core Data's. Plain `Codable` structs in a file are trivially
  testable and make rule 1 nearly free — a stored Set is a value, so nothing can mutate it from a
  distance — at the cost of writing the querying and loading by hand. Weigh them against the three
  rules above, not against fashion.
- **How do the stored types meet the rules module?** This ticket is **blocked by** [The rules
  module and its oracle](0020-the-rules-module-and-its-oracle.md) for exactly this reason: the two
  would contradict each other if worked in parallel. The rules operate on domain values that exist
  whatever the storage is, so the module's boundary is the stronger constraint and gets decided
  first. **Storage maps to the rules, not the other way round** — start by zooming ticket 20's
  resolution and treating it as given. If it turns out to make storage unreasonable, that is a
  finding, not a licence to reopen it quietly.
- **What identifies an Exercise?** §2.7 is explicit that the **Name is a label, not an identity**:
  two Exercises may share a Name and still be two Exercises with their own Working Weight. So
  identity is a stored id, and history points at it — but see rule 3 for what happens when it is
  gone.
- **What does a delete actually do**, given §6.6 says a delete can no longer destroy history?
- **Migration.** The model will change during this map. Decide now what happens to Rob's real
  logged Workouts when it does, because by then the data is weeks of actual training and there is
  no seed script to re-run.

Consult `SPEC.md` §2 in full, §4.1, §6.6, and `CONTEXT.md`. The answer becomes a Swift file Rob can
paste into the project, plus whatever `SPEC.md` needs to say about storage that it does not say yet.
