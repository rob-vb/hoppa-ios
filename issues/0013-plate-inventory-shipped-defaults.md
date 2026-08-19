---
id: 13
title: Plate Inventory shipped defaults
parent: 1
labels: [wayfinder:grilling]
status: closed
assignee: henk
blocked-by: [5, 11]
---

## Question

Three gaps that [Assemble the spec](0008-assemble-the-spec.md) found and no ticket ever closed.
Each is small on its own; together they decide what a fresh install of Fitty believes about the
user's gym.

1. **The 25 kg plate has no colour.** It ships in the default kg list, switched off.
   [Design language & visual direction](0002-design-language-and-visual-direction.md) drew it
   red. [Microplate accumulation](0011-microplate-accumulation.md) then moved red to the 1 kg
   microplate and never said what happens to the 25.
2. **The lbs Microplate sizes were never specified**, and nobody said whether Microplates ship
   on or off. [Program onboarding flow prototype](0006-program-onboarding-flow-prototype.md)
   says "both Microplates on", written when the rack held two; it now holds four.
3. Whatever 2 decides, it lands on the Microloading Increment, which must name a Microplate the
   user owns.

## Resolution

### The 25 kg plate is red `#C8322B`

The same red as the 1 kg microplate. *Colour plus size means weight* carries it: the two differ
by roughly a factor of four in drawn diameter, and
[Microplate accumulation](0011-microplate-accumulation.md) already accepted exactly this for
blue (20 kg and the 0.75) and green (10 kg and the 0.5). Red was the 25's colour before the
palette amendment, so nothing moves.

### The shipped palette stays this one gym's rack

Raised and deferred knowingly. Fitty is a public app and the shipped palette is an iron rack —
5, 2.5 and 1.25 in black. A bumper or IWF set paints those white, red and chrome, and 25 red.
Most users will therefore see wrong colours.

A second shipped palette ("iron rack" / "bumper", one tap at onboarding step 2) was drawn up in
discussion and rejected **for now**: the second palette needs the same care as the first, and it
re-opens which colour means what. The user is the first test user, so their rack ships correct
and the general case waits. **User-set plate colours** stays on the map as fog; this ticket does
not close it.

### Every Microplate ships switched OFF, in both units

| Group | kg | lbs |
| --- | --- | --- |
| Normal plates, on | 1.25, 2.5, 5, 10, 20 | 2.5, 5, 10, 25, 45 |
| Normal plates, off | 25 | 35, 55 |
| **Microplates, all off** | **0.25, 0.5, 0.75, 1** | **0.5, 1, 1.25, 2.5** |

Normal plates are near-universal, so their defaults earn their "on". Microplates are owned by a
minority, so "off" is the honest default, and it costs an owner four taps on a screen that
already asks them to check the rack. This also makes the footer true on a fresh install.

**The footer states only what is true.** With no Microplate on it reads
`Smallest jump on the bar: 2.5 kg`, and it gains `· 0.5 kg with Microloading` the moment one is
switched on.

This supersedes [Program onboarding flow prototype](0006-program-onboarding-flow-prototype.md)'s
"both Microplates on". The tap counts in that ticket are unaffected — the standard rack still
confirms in one tap, because a user with no microplates changes nothing.

### Microloading with an empty Microplate group

Shipping every Microplate off creates a hole: the Progression Mode sits one tap away on the
Program card at onboarding step 1, so a fresh user can choose Microloading before any Microplate
exists, and the Microloading Increment picker has nothing to show. Stack and Cable Exercises hit
the same wall, because their Increment also comes from the Inventory.

**Choosing Microloading with no Microplate on opens the Microplate group of the Plate Inventory
as a sheet, in place.** The user switches on what they own and lands back where they were. The
Microloading Increment field, while empty, reads `NO MICROPLATES · SET UP YOUR RACK` and taps
through to the same sheet.

Fitty never blocks the Mode and never disables the option. A disabled control makes the user
hunt for the reason, which is the one thing Fitty does nowhere else — every other screen states
its condition in place (`ALL 3 SETS AT 12 → 75 KG`, `+2.5 KG IF ALL 12`).

Reversing the default — shipping the Microplates on — was rejected: it makes a fresh install
claim plates the user probably does not own, and the Plate Breakdown would then propose a load
they cannot build.
