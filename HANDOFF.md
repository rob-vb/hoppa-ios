# Hand-off — the whole app, one walk

**Every ticket has landed.** On 2026-08-27 Rob ended the batching rule: *"Ik wil alles op het
eind testen, en ik wil eerst alles bouwen."* So there is **one walk, at the end** — every screen
ticket appended its own items and its own *what only the phone can answer*, and the **What is not
built yet** section at the bottom shrank as they landed. This is that walk.

Items 1–38 below cover what was batches 2, 3 and 4, written 2026-08-26 against `00321d6`. Items 39
onward are appended by each screen ticket as it lands. **It is finished as of ticket 0050**, the
last on the build map: items 111–118 are the Exercise card's two doors, and with them every screen
in `SPEC.md` exists and every door between them is open. **This document is now the walk.**

**Judgment calls are marked, not asked.** Under the 2026-08-27 rule a session that would have put a
UI question to Rob decides it instead, records why on its ticket, and lists it here as something to
look at. Those items are the ones worth most of the walk.

Every item is *do X → expect Y*. Where an item says a thing is **not** a defect, it is written
down precisely so it is not reported as one.

---

1. `git pull`, open `app/Hoppa/Hoppa.xcodeproj`, build and run on the iPhone.
   → It builds with no error. **This failed on the first attempt and is fixed** — see
   [Two files, one `PlateChip`](issues/0052-two-files-one-plate-chip.md). `SummaryScreen` and
   `PlateRackScreen` both declared a `PlateChip`, which is one redeclaration and two bogus errors
   at the call site; the Summary one is now `AddedPlateChip`. A new check,
   `app/checks/AppTarget/run.sh`, scans the whole target for a name declared in two files, and it
   is green. **That check is not a type-check** — SwiftUI cannot compile on the VPS — so Xcode may
   still stop somewhere after `SummaryScreen`. If it does, send the errors the same way and the
   walk restarts here. **Eight files are new** since batch 1 — `LoggingScreen`,
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

## The two rack warnings, and the Re-weigh list (ticket 0046, §6.6)

**Do this last, or on a phone you are willing to re-weigh.** Item 63 clears the Working Weight on
every barbell, Smith, plate-loaded and Bodyweight Exercise you have, in every Program. It is the
real event and there is no undo — that is §6.6, not a defect. Items 64–70 put the numbers back.

**One file is new**, `ReweighScreen.swift`, and the app target is a file-system synchronised group,
so it should arrive with no project edit. **If Xcode asks about it, that is the finding.**

62. **The strand warning.** Program `•••` → `PLATE INVENTORY`, and switch **off** a Microplate that
    an Exercise uses as its Microloading Increment.
    → `3 EXERCISES USE THIS PLATE`, and under it *They stop progressing until you pick another
    plate. Nothing is cleared: switch the 0.25 kg back on and they progress again.* The count is
    the real one. Confirm, then switch the same plate **back on** → no warning at all, and the
    Exercise sheet's Microloading row reads that plate again. **Nothing was written either way.**

63. **The clear warning.** On the same screen tap the other unit, `LBS`.
    → `THIS CLEARS THE WEIGHT ON n EXERCISES`, with the same count the list will hold. `CANCEL` →
    nothing happens and the rack is still kg. **Do that once before you commit.**

64. Tap `LBS` again and confirm with `SWITCH TO LBS`.
    → **The Re-weigh list opens by itself.** That is the first of its two doors. Heading
    `RE-WEIGH`, then *An exercise with no weight logs no set and does not progress*, then one row
    per cleared Exercise, grouped under its Workout Day, in Program order.
    → The rack screen behind it now reads `LBS`, and every plate on it is an lbs size.

65. **Judgment call — the field, not a keypad.** Each row has a small decimal field on the right
    with the Exercise's unit beside it, and you type straight into it. §6.4's full keypad sheet was
    the alternative and it was **rejected**: twelve of those, each opened and dismissed, is the
    twelve-times cost the kitchen table exists to avoid.
    → **Say whether typing eight or ten weights this way is quicker than eight keypads.** If it is
    not, that is the finding.

66. Type a weight into one row and tap the next row's field.
    → The first number is written when you **leave** the field, not per keystroke. The row **stays
    where it is** and does not vanish — deliberate, so rows do not move under your thumb — and the
    line under the heading recounts: `1 of 8 done. 7 still have no weight.`

67. **Judgment call — the closest line.** Type a weight your lbs rack cannot build exactly, e.g.
    `137` on a barbell. → A `≈ CLOSEST` chip appears under that row: *you load 135 lbs · 2 under*.
    Nothing is refused; §5.4 is stated where you type. **Say whether it is useful here or noise.**

68. **Judgment call — the note under the name, which is a door.** Every row shows its Equipment
    Type, and where something else is still missing it reads `Barbell · no increment`,
    `Smith · no base weight` or `Cable · no microplate`, with a `›`. The unit switch cleared the
    Increment and the Base Weight too, and this list shows one field on purpose.
    → Tap that note. The **Exercise sheet** opens on that Exercise, where the Increment and the
    Base Weight are. Fill them, close the sheet, and the note is gone.
    → **Say whether stating it is enough, or whether the list should have asked for the Increment
    as a second field.**

69. **Zero is a real answer.** On the weighted chin-up row type `0` and leave the field.
    → It is accepted and the row is done. That is §2.8: zero is a chin-up with no belt, and unset
    is *you have not said*. **A refused `0` here would be the defect.**

70. Weigh every row, then `DONE`. → You land back on the rack screen. Walk back to the picker.
    → **No banner.** Then open an Exercise sheet, add a new Exercise and give it no weight.

71. **The second door.** Go home to the picker.
    → Under your Program's name, a card: `1 EXERCISE HAS NO WEIGHT` · *It logs no set until you
    weigh it*. Tap it → the same Re-weigh list, with that one row.
    → **Judgment call.** A sheet at launch was the alternative and it was **rejected**: the list
    holds every Exercise with no weight, including one you added on purpose a minute ago, so a
    modal would ambush you with your own decision. **Say whether the banner is loud enough**, and
    whether it sits right at the top — the **foot** of the picker is History's door.

72. Force-quit, reopen. → The banner is still there, and the list still holds the same row.
    **Nothing wrote it down**; it is derived from the weight being missing.

73. Weigh that last Exercise. → The banner goes by itself, with no tap of its own.

74. **Switch back to `KG`** and re-weigh everything in kg, or you are training in lbs from here.
    The switch warns and clears in exactly the same way — it is symmetric, and nothing converts.

75. **The stale One-off.** Start a Workout, set a **One-off Weight** on a barbell Exercise, log one
    Set, leave the logging screen with `‹`, go to the Plate Inventory and switch the unit.
    → Back in the Workout the One-off is **gone** and the Exercise shows no weight, so it cannot
    log. The Set you already logged **keeps its old number** — it really was lifted at that weight
    (§2.4). Fixed at ticket 0046; before it, the next Set would have been written at the old number
    under the new label.

---

## Flow 4 — the history screen (ticket 0047, §6.7)

**Two files are new**, `HistoryScreen.swift` and `Streak.swift` (in the `HoppaStore` package), and
`HarnessSeed.swift`, `WorkoutDayPicker.swift`, `Route.swift` and `HoppaApp.swift` changed. The app
target is a file-system synchronised group, so the new app file arrives with no project edit;
`Streak.swift` is inside the package and is not a project file at all. **If Xcode asks about either,
that is the finding.**

**This screen needs weeks of Workouts to say anything.** Your phone has as many Workouts as you have
walked, which is a handful — enough to prove the screen reads, not enough to prove it *looks* right.
Item 84 is the optional way to see sixteen weeks of it, and it costs you the app's data.

76. Go home to the picker and look at the **foot** of it, at the `HISTORY` row.
    → It now reads both halves: `12 workouts · 2 weeks in a row`, where before it read the count
    alone. **The run is dropped where it is zero** — `0 weeks in a row` is a shortfall, and §6.7
    took the best-ever number out for that same reason. If you have not trained this week or last,
    the row states the count only, and that is not a defect.

77. Tap it. → The history screen. `‹ UPPER / LOWER` at the top, then `HISTORY`, then the streak
    card, then the Workout list.

78. **The streak card.** A big figure, `WEEKS IN A ROW` under it, then the strip of blocks, then a
    date under each end.
    → **One block per week, and one Workout lights it.** A week you trained four times looks
    exactly like a week you trained once — deliberate: the question is whether you went.
    → **No flame, no warning, no *streak lost*, and no best-ever number.** If anything on this card
    compares you to a past you, that is the finding.

79. **Judgment call — the strip starts at your first Workout.** With three weeks of training you
    see three blocks, not three lit and thirteen dark.
    → Fourteen dark blocks would be fourteen weeks you did not own the app. **Say whether a short
    strip reads as unfinished**; the alternative is a full sixteen every time, and it was rejected
    for what it implies.

80. **Judgment call — a week that has not ended does not break the run.** If today is Monday or
    Tuesday and you have not trained yet, the last block is **dark** and the figure is still the
    run you had.
    → Otherwise the number would fall to zero every Monday morning and climb back on your first
    session, which reports the day of the week and not the run. **Say whether the dark last block
    beside an unchanged figure reads as wrong.**

81. **The Workout list.** Under `n WORKOUTS`, one row per finished Workout, newest first: the date
    as `18` over `AUG` in the left column, the Workout Day's name, then `4 exercises · 13 sets`, and
    in green, `2 WENT UP` where anything did.
    → A Workout that moved nothing has **no green line at all**, not `0 went up`.
    → A Workout where you skipped something reads `· 1 skipped`, plain, with no warning colour.
    → **The Open Workout is not in the list.** Start one and come back: the list is unchanged. It
    has been started, not done.

82. **Judgment call — the year.** A row from last year reads `DEC 25` under the day instead of
    `DEC`. Everything from this year shows the month alone.
    → You cannot check this today unless you have a Workout from 2025. It is here so it is not
    reported as a defect later.

83. Tap any row. → The Workout opens. This is ticket 0048's screen; items 87–97 walk it.

84. **Optional, and it wipes the app's data — sixteen weeks in one build.** Delete Hoppa from the
    phone. In `HarnessSeed.swift` set **both** `isEnabled` and `seedsHistory` to `true`, build and
    run.
    → The picker holds `Upper A` and `Lower A`, and History shows **30 Workouts**, a strip of
    **sixteen blocks with exactly one dark**, and `9 WEEKS IN A ROW`. The seed trains the Program
    forward through the shipping rules, so the weights really climbed and some rows really did not
    move. **Since ticket 0049 one Workout is at a One-off Weight** — week 9's Upper A, the Smith
    bench press 7.5 kg light — so §6.7's hollow marker has something to draw.
    → **This is the only way to judge whether the strip and the list look right at length.** Say so.
    → Set both back to `false` and delete the app again before you train on it.

85. **The empty state.** Only visible on a phone that has never finished a Workout, so it is a
    fresh-install check and not a walk step: `NOTHING HERE YET`, and one line — *Finish your first
    workout and it lands here. Every exercise gets a line as soon as it has two.*
    → The streak card is **not** drawn at all there. A card reading `0` over sixteen dark blocks
    was the alternative and it was rejected.

86. **The first weekday is your phone's, not Hoppa's.** The strip starts weeks on Monday because
    your phone's region does. Nothing to do here unless a block boundary looks a day out, which
    would be the finding.

---

## Flow 4 — a past Workout, opened and deleted (ticket 0048, §6.7)

Items 87–97. Open History from the foot of the picker, then tap the newest row. **Do items 87–95
before item 96**, because 96 destroys the Workout you were reading.

87. Read the top of the screen.
    → `‹ History` on the left and `•••` on the right, then the Day's Name big, then one meta line:
    `3 AUG 2026 · 5 exercises · 15 sets`, and `· 1 skipped` only where there was one.
    → **The counts are the list row's own counts.** Go back and compare them with the row you
    tapped. If they disagree, that is a finding — they come from the same value on purpose.

88. Read one Exercise block.
    → The name in Anton, and on the same line at the right either nothing, a steel `STAYED`, or a
    green `72.5 KG → 75 KG`. Under it one row per Set: the number, the reps big, `REPS`, and the
    weight at the right — `72.5 kg`, in **sentence case**, because it is a number in a table.

89. **Look at which rep numbers are green.** A Set's reps go green where that Set met the
    threshold — the top of the Rep Range under Progressive Overload, the bottom under Microloading.
    → An Exercise that went up has every rep green. One that stayed has some or none.
    → This is the same fact the chart's Set grid will fill a cell with (ticket 0049), so if it
    looks wrong here it is wrong in two places.

90. **The number this whole ticket was written for.** Find an Exercise that went up in an *older*
    Workout — one you have trained past since. The row must read the weights **as they were then**,
    not the weight the Exercise stands at today.
    → e.g. a Workout from three weeks ago reads `72.5 KG → 75 KG` while the Exercise now sits at
    `80 KG`. **A row that reads `77.5 KG → 80 KG` on an old Workout is the defect this ticket
    exists to prevent** — report it.
    → It is stored at Finish now (§2.4). **Workouts you finished before this build did not store
    it**, so they read a green `WENT UP` with no weights. That is not a defect; it is the old data.
    Every Workout finished from here on carries its number.

91. **A One-off Workout**, if you have one. The verdict beside the name is replaced by a chip under
    it: `ONE-OFF · 80 KG STAYED`.
    → The Set rows show the weight you actually lifted, and **none of the reps is green**, whatever
    you hit. A One-off never progresses (§4.3), so a green column would be a lie.

92. **A skipped Exercise.** → The name, a steel `SKIPPED` on the right, and no Set rows at all.
    → **A judgment call**: the artboard has no skipped Exercise in it. This is §6.5's rule — listed
    plain, no warning colour, no icon, no invitation to fix. Say whether it reads right in place.

93. Tap `•••`.
    → A menu with one item: `Delete workout`, in red.
    → **A judgment call**: §6.7 gives the menu nothing else, and it stayed a menu rather than
    becoming a `DELETE` button, because a destructive action one tap away from a scrolling list is
    not what the rest of the app does. Say if a menu of one reads as fussy.

94. Tap `Delete workout`.
    → A sheet from the bottom, in Hoppa's own dark: `DELETE THIS WORKOUT?`, then
    *This removes 5 exercises and 15 sets from your history.*, then in steel *Your working weights
    stay where they are.*, then `CANCEL` and a **red** `DELETE`.
    → **The red is the 25 kg plate red `#C8322B`, and that is deliberate** (§6.7). A plate colour is
    a plate only inside a Plate Breakdown; nothing near this button is a drawing of a bar. Look at
    it and say whether it reads as a plate. If it does, that is the finding.
    → **A judgment call**: every other confirm in Hoppa is a system dialog. This one is drawn,
    because §6.7 paints its button and a system dialog cannot carry that colour. Say whether the
    two kinds of confirm sitting in one app is worse than the colour is worth.

95. Tap `CANCEL`. → The sheet goes and the Workout is still there.

96. Tap `•••` → `Delete workout` → `DELETE`.
    → The screen closes back to History, and **the row is gone** and the count above the list is
    one lower.
    → Now go to your Program and **check the working weights of the Exercises in that Workout**.
    They must be **exactly where they were**. Hoppa applied the progression at Finish and never
    lowers a weight by itself (§4.1); recomputing the chain would also reach past any weight you
    have set by hand (§4.3). **A weight that moved is a serious finding.**
    → Restore one by hand if you want it back. That is the trade the confirm states.

97. Force-quit and reopen. → The deleted Workout is still gone, and the streak strip above the list
    has redrawn without it.

---

## Flow 4 — the per-Exercise chart (ticket 0049, §6.7)

**The door to this screen landed at ticket 0050** — items 111–118. Walk those first: they are how
you get here.

**And this is the screen the whole map has the least confidence in**, for a reason worth stating
before the first tap: §6.7 needs weeks of Workouts before it says anything, and your Logbook has
days. What shipped is a screen proved against a fixture, not a screen anyone has watched fill up.
`app/checks/Chart/run.sh` draws sixteen weeks of it as text on the VPS — **run it, or read the
output pasted into ticket 0049, before you judge the phone**, because three sessions on a real
phone cannot show you what fifteen look like.

98. Open a chart for an Exercise you have trained **twice or more**.
    → The Day's name and a `‹` at the top, the Exercise name under it, then
    `Smith · 3 × 8–12 · Progressive overload`, then the Working Weight as the biggest number on the
    screen, then the rule chip — `ALL 3 SETS AT 12 → 82.5 KG` — then the plot.

99. **Judgment call — there is no `•••`.** The artboard draws one at the top right. §6.7 hangs
    delete off a *Workout* row and gives this menu nothing at all, so the control is not drawn
    rather than drawn empty.
    → Say whether the header looks unbalanced without it.

100. **Look at the line.** 2 px steel, a filled **green** dot where that session went up and a
     filled **steel** dot where it stayed. **No plate colour anywhere on it** (§7.1).
     → The dot sits at the weight that was **lifted** that day, not the weight it earned. The step
     up appears on the *next* session. This is not a defect.

101. **The x axis is real time.** A week you missed is a wider gap and nothing else — no marker, no
     dashed segment, no label.
     → A Skipped Exercise draws **nothing at all** on that date. Also not a defect.

102. **The dashed step at the right.** After a session that went up, a **dashed green** step runs
     from the last dot to a hollow ring at the weight you carry now, labelled `NEXT`.
     → Solid is lifted; dashed is applied but not yet performed. Without it the big number at the
     top contradicts the end of the line, because Hoppa applies the weight at Finish.

103. **Judgment call — a weight you set by hand.** Re-weigh an Exercise from the Re-weigh list or at
     the rack, then open its chart.
     → The same dashed step, in **steel**, labelled `NOW` instead of `NEXT`. §6.7 only wrote the
     green case. Green means progression everywhere in Hoppa and a weight you typed is not one, so
     the gap is still shown and the colour says who moved it. **A weight you lowered draws the step
     downwards**, which is true and is not the *line never dips* rule (that one is about One-offs).

104. **The Set grid under the plot.** One column per session, one cell per Set, filled green where
     that Set met the threshold. `SETS` labels it on the left.
     → Three filled cells **is** the progression rule. A column with two filled and one hollow is
     the whole answer to *why did it not go up*, with no words and no advice.

105. **A One-off session.** Find one — the seeded book has one at item 84.
     → A **hollow** steel ring **below** the line, tied to its session by a dotted drop, labelled
     `ONE-OFF`. **The line itself does not dip**: a One-off never became the Working Weight.
     → Its Set grid column is **empty, whatever the reps**. A full green column beside a step that
     never came would be a lie. Not a defect.

106. **`LAST SESSIONS`.** The four newest, newest first: the date, the reps, and the weight lifted.
     → **Judgment call — the reps are green Set by Set**, not row by row. The artboard colours the
     whole row when every Set met the threshold; this marks each Set, which is the same fact the
     grid column above it draws and the same fact the Workout detail (item 89) turns green. Where
     all three met, the two read identically; where some met and some did not, only this one says
     so. Say which you prefer.

107. **The three figures at the foot.** The first weight with its date, the gain since then in
     green, and how many times it went up.
     → The gain counts to the weight you carry **now**, so it agrees with the big number at the top
     and with the end of the dashed step. **A gain that is not positive is not green** — a weight
     you lowered by hand must not read as a progression.

108. **Judgment call — one session is not a chart.** Open an Exercise you have trained exactly once.
     → The heroes and the chip stand, and where the plot would be: `NOTHING HERE YET` and *One
     session is a dot, not a climb. Train it once more.* §6.7's own empty state says an Exercise
     gets a line once it has two.

109. **Never reachable on your phone, and here so its absence is not reported as a defect: the
     mixed-unit chart.** A Machine (stack) or Cable marked in lbs with a kg Microplate has two
     numbers that never convert and no single number to plot, so the chart plots the **Microload**
     and the axis reads `+ KG`. **Your rack is kg and your stacks are kg**, so you cannot reach it —
     the same class as the lbs rack and as the `MICRO` stepper. It is built and it is walked on the
     VPS by `app/checks/Chart/run.sh`.

110. **An open item on that same half, written down rather than solved.** §6.7 chose the Microload
     as the line for a reference case whose pin had not moved in fifteen weeks. When the pin *does*
     move, the roll-up empties the Microload into it and **the line falls while the weight on the
     machine rises** — exactly the shape §6.7 refused volume for. The screen states it in a sentence
     under the plot instead of smoothing it. It waits for a lifter who can reach it.

---

## Flow 4 — the Exercise card's two doors (ticket 0050, §6.7)

**This is the last ticket on the build map.** With it, every screen in `SPEC.md` exists and every
door between them is open. **One new file**, `app/Hoppa/Hoppa/Sparkline.swift`; the app target is a
file-system synchronised group, so it arrives with no project edit — and if Xcode asks about it,
that is itself the finding (item 1).

§6.7 gives an Exercise card a door to that Exercise's chart, and the card already had one to §6.2's
Exercise sheet. **Which one is the whole card was a judgment call, taken here rather than asked**,
under the map's build-everything-first rule. Item 113 is where you overrule it.

111. On the **Workout Day** screen, look at an Exercise you have **never trained** — one you have
     just added.
     → The card is exactly what it was: the name, `barbell · 3 × 8–12 · +2.5`, the Working Weight
     or a `—`. **No sparkline.** Tap anywhere on it and the Exercise sheet opens, as before.

112. Now look at an Exercise you have trained **at least once**.
     → A small steel line sits between the Working Weight and the card's trailing edge, ending in a
     filled dot. That is the sparkline, and it is **the door**.

113. **Tap the sparkline.** Then tap the card anywhere else.
     → The mark opens that Exercise's **chart**; everywhere else still opens the **Exercise sheet**.
     → **This is the judgment call.** Three reasons it went this way: an Exercise card is edited far
     more often than it is charted, so the frequent path keeps the whole card; §6.7's own sentence
     is *the card carries a sparkline, so the door announces itself*, which makes the announcement
     and the door one object; and a card with nothing to plot draws no mark, so a door to an empty
     room is never offered. **Two shapes were refused** — a `•••` holding one item, and the swap
     that makes the chart the whole card. Say if either is what you wanted.

114. **Try to hit the mark with a thumb, standing up.** The mark itself is 44 × 16 pt; the target
     around it is the whole trailing column, 66 × 62.
     → It should not take two goes. If it does, say so — the column can widen without moving
     anything else.

115. **Drag the same card by its grip.** Then tap the mark again.
     → The reorder handle, the sheet and the chart are three regions side by side, none over
     another. A drag must never open either screen, and a tap must never start a drag.

116. **Look at what the mark plots.** It is the chart's own line, on the chart's own scale and its
     own real-time x axis — so a missed week is a wider gap on the card too.
     → Open the chart and compare the two shapes. They must be the same climb.
     → It draws **no** One-off marker and **no** dashed `NEXT` step, on purpose: a hollow marker is
     a smudge at that size, and the step's destination is the big number already printed beside the
     mark on the same card.

117. **One session is a dot.** An Exercise trained exactly once draws a single dot and still opens.
     → The chart then says `NOTHING HERE YET` and keeps its heroes and its chip. **The two gates
     are deliberately not one gate**: two sessions make a *line*, one makes a *screen worth
     reaching*. Say if you would rather the door waited for the second session.

118. **The caption under the Day name still reads `5 exercises · tap a row to open it`.**
     → Deliberate: §7.6 keeps Hoppa from instructing, and §6.7's mark is meant to announce itself.
     Say if you want a word about the chart there.

### What only the phone can answer

- **Whether a 44 × 16 mark reads at arm's length** in gym light, and whether it reads as a *door*
  rather than as decoration. Nothing on the VPS can answer that; `app/checks/Chart/run.sh` prints
  the same cards as text and proves only which of them carry a mark and what it plots.
- **Whether the door appearing after the first session is a pleasant surprise or a jumpy card.**
  The card changes shape the first time an Exercise is trained, and that has never been watched.
- **The mixed-unit pin.** There the card prints the pin and the mark plots the Microload — two
  different numbers side by side, and only the chart has room to label them. Suppressing the mark
  would leave that chart with no way in at all, which is worse. **Unreachable on your phone**: your
  rack is kg and your stacks are kg, same class as item 109.

---

## The walk's own findings — re-look at these

Appended as Rob walks. Each one is a change already made and pushed, so these items replace the
originals rather than adding to them.

119. **Go back to the logging screen and look at the sizes.**
   → The Working Weight is **64 px**, not 88 — it is still the biggest number on the screen, and
   the next biggest is the 31 px Set number. The `11.3 base + 20 + 5 + 2.5` line under the drawing
   is now **17 px in full white**, with `27.5 kg per side` under it at 11 px dim. Ticket
   [0053](issues/0053-the-hero-and-the-load-line.md). **Say whether the load line is now big
   enough, and whether 64 is still too big.** Both numbers are one edit away.

120. **Look at the loaded bar. Count the shapes outboard of the plates.**
   → There should be **none**. The collar is deleted. Going inward from the outermost plate you
   should see: plates, then a taller thin **sleeve stop**, then the knurled shaft, then the mirror
   image. If anything still reads as a fifth plate, name which one.

121. **Find a Dumbbell or a Bodyweight Exercise, if your Program has one.**
   → Its caption **swapped sides on purpose**: the big line is `2 × 22.5 kg` (or `15 kg on the belt`)
   and the small line under it is `each hand` (or `added weight only`). §5.5 had those the other way
   round, which put a label in the loud slot and the number in the quiet one. If your Program has
   neither type, skip this and say so.

## What is not built yet

None of this is a defect.

- **Flow 4 is complete, and so is the build map.** The streak and the Workout list landed at ticket
  0047, opening a row of that list at 0048, the **per-Exercise chart** at 0049 and **its door** at
  0050 — items 76–118. Every screen in `SPEC.md` now exists and every door between them is open.
- **The weights on a Workout you finished before this build.** Ticket 0048 started storing the
  weight a progression ended on; Workouts already on the phone have none, so an old Went-up row
  reads a green `WENT UP` and no numbers. Old data, not a defect — see item 90.
- **Flow 5 is complete.** The two warning dialogs and the Re-weigh list landed at ticket 0046,
  reorder handles at 0044, deleting an **Exercise** on its own sheet since 0035, and deleting a
  **Workout Day** at 0045.
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
| `app/HoppaRules` — `swift test` | 218 |
| `app/HoppaStore` — `swift test` | 49 |
| `app/checks/UnitStash/run.sh` | 34 |
| `app/checks/Reorder/run.sh` | 25 |
| `app/checks/Reweigh/run.sh` | 34 |
| `app/checks/History/run.sh` | 33 |
| `app/checks/Past/run.sh` | 66 |
| `app/checks/Chart/run.sh` | 41 |
| `app/checks/AppTarget/run.sh` | 30 files, 101 names |
