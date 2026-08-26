---
id: 42
title: The MICRO stepper on a mixed-unit pin, and what a `−` means there
parent: 17
labels: [wayfinder:grilling]
status: open
assignee:
blocked-by: []
---

## Question

**§6.4 gives the weight sheet a `MICRO` stepper on every stack. On a mixed-unit pin it steps a
number the sheet cannot write, in a direction §4.2 does not describe.**

`SPEC.md` §6.4: *"On a Machine (stack) or Cable the sheet grows a second stepper … `PIN` steps by
the Stack Step (`− 100 LBS +`), `MICRO` steps by the Microloading Increment (`− +1 KG +`), and the
keypad stays under them. The big number is still the Working Weight."* The `+1 KG` beside a
`100 LBS` pin is the **mixed-unit** case by construction — an lbs stack in a kg gym.

[The weight sheet](0037-the-weight-sheet.md) built both steppers for a **same-unit** stack, where
they are unambiguous: the Microplates are simply part of the Working Weight, so `MICRO` steps the
keypad buffer by the Microplate and `PIN` steps it by the Stack Step. Both write one number
through `.setWorkingWeight`.

**A mixed-unit pin is a different write.** There the Microplates are a `Microload` — a second
stored field, in the rack's unit — and the Working Weight can never absorb it, because units never
convert (§5.1). So `MICRO` there is not a keypad nudge at all. Three things are open:

- **There is no action for it.** `Action` has `setWorkingWeight` and `setOneOffWeight` and nothing
  that writes a Microload by hand; today the only thing that moves it is progression.
- **`+` has an answer and `−` does not.** §4.2's roll-up says a Microload rolls into the pin at one
  Stack Step and is *bounded by one Stack Step at all times* (§5.3), so `+` is
  `Rules.rollUp` with the Microplate as its increment. **`−` past zero is unspecified**: it either
  refuses at zero, or takes one Stack Step off the pin and hangs the remainder — a **roll-down**,
  which §4.2 does not have and which is the first thing in Hoppa that would lower a Working
  Weight without asking (§4.3).
- **Whether a One-off Weight has a Microload.** A One-off is a `Weight` on the Performed Exercise;
  a mixed-unit pin's second number has nowhere to ride on it. Lowering an lbs stack *just today*
  today keeps the Microload that belongs to the Working Weight.

**What is built meanwhile**: the sheet draws `PIN` and no `MICRO` on a mixed-unit pin, so nothing
writes a Microload by hand and nothing is silently wrong. Rob's rack is kg and his stacks are kg,
so the case does not arise for him — this sits beside **the lbs rack** in the map's fog for the
same reason.

Consult `SPEC.md` §2.3, §4.2, §4.3, §5.1, §5.3 and §6.4, `Progression.swift` (`rollUp`),
`WeightSheet.swift` (`steppers`, `microStep`), and
[Microplate accumulation](0011-microplate-accumulation.md), which is where the roll-up was decided.
