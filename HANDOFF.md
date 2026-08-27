# Hand-off — the whole app, one walk

**This document is not finished.** On 2026-08-27 Rob ended the batching rule: *"Ik wil alles op het
eind testen, en ik wil eerst alles bouwen."* So there is **one walk, at the end**, and this file
grows until then — every screen ticket appends its own items and its own *what only the phone can
answer*, and the **What is not built yet** section at the bottom shrinks as tickets land.

Items 1–38 below cover what was batches 2, 3 and 4, written 2026-08-26 against `00321d6`. Items 39
onward are appended by each screen ticket as it lands. Still to be appended: Flow 5's deleting and
the Re-weigh list; and all of Flow 4 — the history screen, a past Workout, the per-Exercise chart
and the Exercise card's doors.

**Judgment calls are marked, not asked.** Under the 2026-08-27 rule a session that would have put a
UI question to Rob decides it instead, records why on its ticket, and lists it here as something to
look at. Those items are the ones worth most of the walk.

Every item is *do X → expect Y*. Where an item says a thing is **not** a defect, it is written
down precisely so it is not reported as one.

---

1. `git pull`, open `app/Hoppa/Hoppa.xcodeproj`, build and run on the iPhone.
   → It builds with no error. **Eight files are new** since batch 1 — `LoggingScreen`,
   `PlateDrawing`, `PlateGlyph`, `WeightSheet`, `SummaryScreen`, `Confetti`, `ParticleField` and
   `UnitStash` — and seven more changed. The app target is a file-system synchronised group, so all
   eight arrive without a project edit. **If Xcode asks about any file, that is itself the
   finding.**

## Batch 2 — start a Workout, log Sets, change a weight

2. Open the app. → The Workout Day picker, with your Program. This is batch 1 territory; if it is
   wrong, stop here, because nothing after it can be trusted.

3. Tap a Day with two or more Exercises and start the Workout.
   → The logging screen: the counter `1 / n ▾` at the top, the Working Weight as the biggest number
   on the screen, a steel rule chip under it, the loaded bar, empty Set rows, and
   `−` · `LOG 12 REPS` · `+` at the bottom.

4. **Look at the loaded bar and say whether hollow steel reads at arm's length.** The collars, the
   sleeve stops, the knurled shaft and the sleeve are **1 px outlines and not filled** — a
   deliberate departure from the artboard, taken from §7.1 rule 2 (*steel is never filled*).
   → Right: the plates are solid colour, the bar is a drawn outline, and the difference is obvious
   from a metre away. Wrong: the bar reads as unfinished or as missing. **If it reads wrong that is
   a finding with its own ticket, not a bug** — the fallback is a low-opacity fill that still
   cannot be mistaken for a plate.

5. Set a Working Weight that loads four or five plates a side, e.g. **135 kg**.
   → The bar shrinks to fit the screen. Wrong: plates clipped at the edge. Unmeasured here.

6. Look at the Working Weight number itself.
   → 88 pt Anton, with the line sitting tight (§7.4 asks 0.78). Wrong: the number is clipped top or
   bottom, or the line looks loose. SwiftUI cannot state a line height below 1.0 as a number, so
   this one can only be judged by eye.

7. Log a Set with the plain `LOG n REPS`.
   → A Set row appears at the target reps, and the Rest Timer starts counting up.

8. Lock the phone, wait about 30 seconds, unlock.
   → The Rest Timer shows the real elapsed time. It reads a stored timestamp, so **a wrong number
   is the defect; a slightly late first redraw is not.**

9. Use `−` and `+` beside `LOG n REPS` to log above the Rep Range.
   → The row reads e.g. `14 reps · 8–12` — plain, no warning colour.

10. Tap the big Working Weight number.
    → The weight sheet: `CANCEL`, the number being typed at 56 px with its unit beside it, a
    `−`/`+` stepper, the `≈ CLOSEST` line, a 3 × 4 keypad, and `SET THE WEIGHT`.

11. Type a **higher** weight and `SET THE WEIGHT`.
    → The sheet closes at once, with no question, and the new weight is the hero number.

12. Type a **lower** weight and `SET THE WEIGHT`.
    → *Just today, or from now on?* appears exactly once. Pick **Just today**. → The big number
    shows the one-off weight, a steel chip beside the unit reads `ONE-OFF · <old> KG STAYS`, and
    every Set logged from now carries a plain `ONE-OFF` chip.

13. **The trap §4.3 exists for.** With that One-off still standing — say 65 on a 72.5 kg Exercise —
    open the sheet again and type **70**: higher than the one-off, lower than the Working Weight.
    → It **asks** *Just today, or from now on?*. Wrong: it sticks silently, which would erase the
    72.5 record. `Rules.weightEdit` guards this and nine tests here say it asks.

14. Type a weight the rack cannot build, e.g. **61.25** on a kg rack, and watch the `≈ CLOSEST`
    line while you type. → It updates **on every keystroke**, against the number being typed and
    not the one stored.

15. Add an Exercise with Equipment Type **Machine (stack)** and a Stack Step, e.g. 5 kg, then open
    its weight sheet. → Two stepper rows: `PIN` stepping by the Stack Step and `MICRO` by the
    Microplate, with the keypad under them.
    **The `MICRO` row needs a Microplate switched on** in the Plate Inventory *and* the Exercise on
    Microloading — every Microplate ships **off** (§5.2), so with the shipped rack there is no
    `MICRO` row and that is correct.

16. Skip an Exercise from the `•••` menu, then reopen it from the `n / n ▾` drawer.
    → It comes back Open with its Sets where you left them.

17. In the drawer, tap `FINISH WORKOUT` with an Exercise still Open.
    → The Finish gate appears, names what is still open, and offers the one-tap way out. Nothing is
    silently dropped. **The Finish gate is the one thing on this screen that must never be lost** —
    if a tap does nothing, that is the defect.

## Batch 3 — Finish, and the Summary

18. On a Day with two or more Exercises, log every Set at the top of the Rep Range, then Finish.
    → The Summary replaces the screen: a green count as the hero, then `WENT UP` rows landing one
    at a time about 190 ms apart, each throwing a burst of plate-coloured slabs out of the chip at
    its left edge.

19. **Watch the burst. This is the one thing no test here can judge.**
    → Right: plates in the colours of the weight you just earned, thrown upward, falling, spinning,
    fading out at the bottom of the screen.
    Wrong: a stutter or dropped frames while they fly; particles that read as grey sparks rather
    than as plates; a burst starting anywhere other than the chip; a burst on a row that did not go
    up; steel slabs that look **filled** rather than hollow.
    **If 60 fps does not hold, that is a finding** — the fallback is fewer particles per burst,
    never lighter ones, which §6.5 rules out by name.

20. Watch the timing.
    → The screen is still and every number readable about **1.3 s** after one Went-up row, and
    about **1.75 s** after five. Measured here. A cloud that hangs around is a defect.

21. Look at the added-plate chip on each `WENT UP` row.
    → Under Progressive Overload on a bar it is **half the Increment**: a 2.5 kg Increment draws a
    **1.25 kg** plate in light grey. Wrong: a red chip on every row — that is the artboard's own
    known defect and it must not appear on the phone.

22. Look at a row that did **not** go up.
    → It states its own condition: the rep condition, or one of six named blockers where a weight
    or a Microplate is missing. Never a `→ 75 KG`.

23. **Only if you have a mixed-unit Exercise**, look at its arrow line — it is four numbers wide,
    e.g. `90 LBS + 4.5 KG → 100 LBS + 0.25 KG`. → It wraps inside the row. `FlowRow` is a
    hand-written `Layout` and is the most likely thing on this screen to need a fix.

24. Tap `DONE`. → Back to the picker. There is **no** chevron back into a finished Workout and no
    Undo. That is §6.5, not a missing screen.

25. Turn on **Settings → Accessibility → Motion → Reduce Motion** and finish another Workout.
    → The rows still land one at a time, and **no particle appears at all**.

## Batch 4 — the Open Workout on next open, and the sheet after a unit flip

26. Turn Reduce Motion back off.

27. **This one cannot be reached without moving the phone's clock.** Start a Workout and log one
    Set. Force-quit Hoppa from the app switcher. Go to **Settings → General → Date & Time**, turn
    **Set Automatically** off, and move the date **one day forward**. Open Hoppa.
    → A sheet over the picker asks about the Workout from the earlier day: **Resume** (the
    primary), **Finish** and **Discard**. With Open Exercises, the Finish row carries its own
    subtitle, e.g. *"3 exercises still open · will be skipped"*.

28. Say whether that sheet reads as a **question** and not as an accusation.
    → No type-check can judge this, which is the whole reason the item exists.

29. Swipe the sheet away without answering. Go into the Program sheet and back to the picker.
    → The sheet does **not** come back this run — it returns at the next launch, not at every
    appearance. The Day whose Workout is Open reads `Running` in green **in place of** its
    last-trained line.

30. Look at `Running` at arm's length on a dark screen. → It is legible at meta size. If it is not,
    that is a finding.

31. Tap a **different** Day's row while that Workout is Open.
    → The row is tappable, and it lands on the screen that names the Day that is running and offers
    one door back into it. A row that refused in silence would be the defect.

32. Tap `Resume`. → The logging screen comes back with the Set you logged.
    **Then put Date & Time back on Set Automatically.**

33. Open an Exercise sheet on an Exercise that has a Working Weight, and change the **unit** row.
    → The numbers leave the screen and a note says **where they went and how to get them back**.
    It must not say *cleared* — nothing is cleared.
    On an **edit** sheet closing **is** the save and there is no `CANCEL`; that is §6.2, decided at
    ticket 26, and not a missing button. Only an **add** sheet has a `SAVE` and a `✕`.

34. Tap the unit row back. → **Every number comes back exactly as typed.** This is a full undo and
    it costs one tap.

35. Flip the unit, type a different weight, flip back, then flip forward again.
    → Both numbers live, each under its own label. Nothing is converted and nothing is merged.

36. Flip the unit, retype the weight in the new unit, and `SAVE`.
    → **The retyped weight survives the save.** Wrong: the field is empty afterwards. That was the
    defect ticket 41 closed; 147 rules tests say it is fixed.

37. On an **add** sheet, type a weight and then tap `✕`.
    → It asks before it throws the numbers away — including numbers held under the other unit.

38. `git push` if Xcode changed anything, `project.pbxproj` above all.
    → Six hand-offs in a row have needed no project edit and `UnitStash.swift` should make it
    seven, because the app target is a `PBXFileSystemSynchronizedRootGroup`. **If Xcode did write
    to that file, say so** — the map has an open question about who owns it, and one more instance
    settles a lot.

---

## Flow 5 — the reorder handles (ticket 0044)

39. Open the Program sheet. → **Every Workout Day row has a grip on its leading edge** — three
    short bars — and the position number now sits to the right of it. Two files are new,
    `ReorderColumn` and `ReorderDrag`; the app target is a file-system synchronised group, so both
    should arrive with no project edit. **If Xcode asks about either file, that is the finding.**

40. Tap a Day row anywhere **except** the grip. → It opens the Day, exactly as before. The grip
    and the tap target are siblings, not stacked, so this must not have changed. A row that stopped
    opening is a defect.

41. Drag a Day by its grip, one row down, and let go.
    → The card follows your thumb, the row it passes slides up, **the numbers renumber while you
    are still holding it**, and the drop confirms what was already on the screen. A number that only
    corrects itself after the drop is a defect.

42. **Say whether a 36 pt grip beside a 62 pt card is enough thumb and not too much furniture.**
    A judgment call, taken and not asked. No measurement can answer it; that is why this item is
    here. Nothing else on the screen can be shrunk to pay for it, so if it reads wrong the fallback
    is a narrower grip, not a rearranged row.

43. Drag a card **slowly** and stop with it about a third of the way over its neighbour, then let
    go. → It goes back where it was. Cross **half** a row and it takes the new place. The tipping
    point is half a row on purpose; if it feels late or twitchy, say so.

44. Drag a card down past three rows in one go. → Exactly **one** hole opens, and it travels with
    your thumb. Three rows sliding at once is a defect.

45. Try to **scroll** the list with your finger on a grip, then with your finger on the card.
    → The grip drags and does not scroll. The card scrolls and does not drag. Neither steals the
    other.

46. Open a Day with several Exercises. → The same grips, on the Exercise cards. Reorder two.
    → The order sticks, and reopening the Day shows it.

47. **Start a Workout**, walk to exercise `3 / 5`, then leave the logging screen, open that same
    Day and drag exercise 1 down to the end.
    → Come back to the Workout: **you are still on the same exercise**, and the counter reads
    `2 / 5`. §6.4's promise is that a drag never changes the card under your thumb — only its
    number. 151 rules tests say the rule holds; this item is the one that says the screen agrees.

48. In that same Open Workout, drag **the exercise you are standing on** somewhere else.
    → You go with it. The counter changes, the card does not.

49. **The list does not scroll while you drag a card past the top or bottom edge.** No autoscroll
    was built, because five to eight rows fit on a screen. **This is not a defect.** If one of your
    Days is long enough that it bites, say so and it becomes a ticket.

50. `git push` if Xcode changed anything.

---

## Flow 5 — deleting a Workout Day (ticket 0045)

Deleting an **Exercise** has been on the Exercise sheet since ticket 0035 and is not new here.
What is new is the Day, and **the hard half is the block, not the delete**.

**Two judgment calls, decided and not asked**, under the 2026-08-27 rule. Both are worth most of
the walk:

- **Where `REMOVE DAY` lives**: at the foot of the Workout Day screen, above `DAY DONE` — the room
  for one Day, the mirror of `REMOVE EXERCISE` in the room for one Exercise. §6.6 does not say. Not
  a swipe and not a `•••` on the hub's row: a swipe hides the control, the hub's row already has a
  grip on its leading edge and a tap through its middle, and a block has to be **read** before it
  can work. A word in a room has space for a sentence beside it; a gesture has none.
- **How a blocked control refuses**: it stays live and answers in place. It is never greyed out.
  §5.2 and `NameYourProgram`'s `CONTINUE` set the shape — *Hoppa never disables the control and
  never hides the reason.*

51. Open a Program with **one** Day, open that Day, and scroll to the foot. → `REMOVE DAY`, drawn
    exactly like `REMOVE EXERCISE`: steel text in a 50 pt outlined box, above the black
    `DAY DONE`.

52. Tap it. → **No confirm appears.** A red line appears under the button:
    `A program needs at least one workout day.` The button is **not** greyed out, and tapping it
    again says the same thing. A greyed-out button, or a confirm that appears and does nothing, is
    the defect §6.6 is written against.

53. Go back, `ADD A DAY`, then open the first Day again and tap `REMOVE DAY`.
    → The red line is **gone before you tap** — the rule stopped refusing, so the reason stopped
    being printed — and the tap now opens *Remove this day?* with `REMOVE` and `CANCEL`.

54. Read the confirm's message. → *It leaves the program from today. Finished workouts keep their
    name and the sets you logged.* **No count of destroyed sets**, because nothing is destroyed
    (§6.6).

55. `CANCEL`. → Nothing happens, and you are still on the Day.

56. Tap `REMOVE DAY` again and confirm. → The Day screen closes and you land on the Program, with
    that Day gone from the list and the summary line recounted.

57. **The other block.** Start a Workout on a Day, leave the logging screen with `‹`, walk to that
    same Day through the Program, and tap `REMOVE DAY`.
    → `Finish your workout first.` in red, no confirm. This is the one a user meets by accident.

58. Finish or discard that Workout, come back to the same Day, tap `REMOVE DAY`.
    → It asks. The block cleared itself with no tap of its own.

59. **A Day deleted from under a finished Workout.** After item 56 or 58, look at a finished
    Workout that ran on the deleted Day — for now the Summary is the only place a Workout is read,
    so this is a Flow 4 item and it is listed under *not built yet*. What you **can** check today:
    the app does not crash and the Program screen is correct.

60. **An Exercise deleted while you stand on it.** In an Open Workout, open the card's Exercise
    sheet and `REMOVE EXERCISE`. → The sheet closes and the card reads *That exercise is gone. It
    was removed from the program. What you logged is kept.*
    **Changed at ticket 0045**: the button under it is now `NEXT: <the next exercise>` when
    something is still Open, and `FINISH WORKOUT` only when nothing is. Before this it was always
    `FINISH WORKOUT`, which put the user behind the §3.3 gate with no drawn way past it.
    → The counter `n / m ▾` still reads the same `m`: the Workout's list does not shrink, on
    purpose (§6.4). **That is not a defect.**

61. In that same Open Workout, tap `NEXT` from the gone card. → You land on the next Open Exercise
    and the counter moves. Log a Set there to prove nothing came unhooked.

---

## What is not built yet

None of this is a defect.

- **Flow 4 entirely** — the history list, the streak, the per-Exercise chart. An Exercise card in
  the Program sheet opens the Exercise **sheet**, and it draws no sparkline.
- **The rest of Flow 5** — the two warning dialogs and the Re-weigh list after a Plate Inventory
  unit change. Reorder handles landed at ticket 0044, deleting an **Exercise** has been on its own
  sheet since ticket 0035, and deleting a **Workout Day** landed at ticket 0045.
- **Autoscroll while dragging a card past the edge of the list.** Deliberate: a list that fits on
  one screen does not need it (item 49).
- **Deleting a whole Program**, and holding more than one. The picker reads the first Program;
  today onboarding is the only way to make one, so there is only ever one.
- **A light mode.** Dark only, on purpose.
- **The `MICRO` stepper on a mixed-unit pin** — decided, not missing. Ruled out of scope: your rack
  is kg and your stacks are kg, so the case cannot arise.
- **Colour on an lbs rack.** §7.3 paints one gym's rack in kg, so an lbs plate falls back to hollow
  steel at its right size. Known, and it costs nothing while your rack is kg.
- **Increase Contrast, VoiceOver and the rest of the accessibility settings.** Appearance, Dynamic
  Type and Reduce Motion are settled; these have not been looked at.

## What is green on the VPS

So a failure on the Mac is toolchain drift and not code.

| Suite | Count |
| --- | --- |
| `app/HoppaRules` — `swift test` | 151 |
| `app/HoppaStore` — `swift test` | 36 |
| `app/checks/UnitStash/run.sh` | 34 |
| `app/checks/Reorder/run.sh` | 25 |
