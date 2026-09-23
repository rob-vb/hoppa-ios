# App Store listing — Hoppa 1.0

Paste into App Store Connect. Limits are Apple's; counts were checked with
`store/check-listing.py`. Copy follows gethoppa.com: states, never offers.

## Shared (not per language)

| Field | Value |
|---|---|
| Bundle id | `com.robvb.hoppa` |
| SKU | `hoppa-ios` |
| Primary category | Health & Fitness |
| Secondary category | Sports |
| Price | Free (tier 0) |
| Privacy Policy URL | https://gethoppa.com/privacy |
| Support URL | https://gethoppa.com/support/ |
| Marketing URL | https://gethoppa.com/ |
| Copyright | 2026 Rob van Baaren |
| Age rating | 4+ (answer "None" to every question) |
| App Privacy | Data Not Collected |
| Content rights | No third-party content |
| Sign-in required | No — review needs no demo account |

### Review notes

```
Hoppa has no account, no server and no network access. Everything is stored in one
file on the phone.

To try it: create a program, add a workout day with an exercise and a working
weight, start the workout, log the sets and tap Finish. The summary shows which
weights went up.

The app is English and Dutch; it follows the phone's language.
```

## English (U.S.) — primary

**Name** (30): `Hoppa: Progressive Overload`

**Subtitle** (30): `The weight goes up when earned`

**Promotional text** (170):
```
Log the set, see the loaded bar, and the weight goes up at Finish. No account, no coach, no suggestions.
```

**Keywords** (100 bytes, no spaces):
```
workout,gym,log,strength,weightlifting,microloading,plates,barbell,tracker,reps,sets,lifting
```

**Description** (4000):
```
The weight goes up when you earn it.

Hoppa is a progressive overload app for lifters who already know their program. You write the program once. Hoppa keeps the numbers honest.

LOG THE SET. HOPPA DRAWS THE BAR.
The number is the weight. The drawing is what hangs on it: plates per side, in real rack colours, true proportions. Target reps are pre-filled and the rest timer starts itself.

COLOUR IS WEIGHT
Switch on the plates your gym owns. Hoppa only draws loads you can actually build.

PROGRESSIVE OVERLOAD, APPLIED AT FINISH
Top of the rep range on every set, and the working weight goes up by your increment. Hoppa never lowers it, and never asks.

MICROLOADING, 0.25 KG AT A TIME
Hit the bottom of the range on every set and the weight goes up by one microplate next time. Set per program, overridden per exercise.

KG RACK. LBS STACK. ONE PROGRAM.
Units are set per exercise. Hoppa never converts on screen; it shows what the machine is marked with.

HISTORY AND PROGRESS
Every finished workout, and a chart per exercise.

YOUR LOGBOOK STAYS ON YOUR PHONE
One file. No account, no cloud, no tracking. Your phone's backup covers it.

NOT FOR BEGINNERS
If you need someone to write your program, this is the wrong app.
```

**What's New** — not shown for 1.0.

## Dutch — localization

**Name** (30): `Hoppa: Progressive Overload`

**Subtitle** (30): `Meer gewicht als je het haalt`

**Promotional text** (170):
```
Log de set, zie de geladen stang, en het gewicht gaat omhoog bij Afronden. Geen account, geen coach, geen suggesties.
```

**Keywords** (100 bytes, no spaces):
```
training,sportschool,krachttraining,logboek,gewichten,halter,schema,fitness,herhalingen,sets,gym
```

**Description** (4000):
```
Het gewicht gaat omhoog als je het verdient.

Hoppa is een progressive-overload-app voor lifters die hun schema al kennen. Je schrijft het programma één keer. Hoppa houdt de getallen eerlijk.

LOG DE SET. HOPPA TEKENT DE STANG.
Het getal is het gewicht. De tekening is wat eraan hangt: schijven per kant, in echte rackkleuren, op ware verhouding. Het doelaantal herhalingen staat al klaar en de rusttimer start vanzelf.

KLEUR IS GEWICHT
Zet in je platenrek de schijven aan die jouw sportschool heeft. Hoppa tekent alleen ladingen die je echt kunt bouwen.

PROGRESSIVE OVERLOAD, TOEGEPAST BIJ AFRONDEN
Bovenkant van de herhalingsrange in elke set, en het werkgewicht gaat omhoog met jouw increment. Hoppa verlaagt het nooit en vraagt niets.

MICROLOADING, 0,25 KG PER KEER
Haal de onderkant van de range in elke set en het gewicht gaat de volgende keer één microplate omhoog. In te stellen per programma, per oefening te overschrijven.

KG-REK. LBS-STACK. ÉÉN PROGRAMMA.
De eenheid stel je per oefening in. Hoppa rekent nooit om op het scherm; het toont wat er op de machine staat.

GESCHIEDENIS EN VOORTGANG
Elke afgeronde workout, en een grafiek per oefening.

JE LOGBOEK BLIJFT OP JE TELEFOON
Eén bestand. Geen account, geen cloud, geen tracking. De back-up van je telefoon neemt het mee.

NIET VOOR BEGINNERS
Heb je iemand nodig die je schema schrijft, dan is dit de verkeerde app.
```

## Screenshots

Required: iPhone 6.9" (1320 × 2868 portrait). Apple scales these down for smaller
iPhones. Up to 10 per language; 5 is enough:

1. The logging screen with a loaded barbell (hero: "The weight goes up when you earn it")
2. The workout summary leading with what went up
3. The plate rack with microplates switched on
4. A mixed-unit stack exercise (`100 lbs + 1 kg`)
5. The per-exercise chart

Capture in the iPhone 16 Pro Max / 17 Pro Max simulator with `HarnessSeed.isEnabled`
and `seedsHistory` set to `true` for the history shots — and back to `false` before
archiving.
