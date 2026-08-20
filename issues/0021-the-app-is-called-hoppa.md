---
id: 21
title: The app is called Hoppa
parent: 17
labels: [wayfinder:task]
status: closed
assignee: agent
blocked-by: [18]
---

## Question

Nothing to decide about the name itself — **Rob named the app `Hoppa`** while answering
[An empty app on the phone](0018-an-empty-app-on-the-phone.md), which retires the build map's
charter line *"the app is called Fitty here, as a working name"*. The work is the sweep, and the
question is only **how far it goes**.

The Xcode project, the target, the app's display name and the bundle id (`com.robvb.hoppa`) are
already `Hoppa` — ticket 0018 created them that way, because a bundle id is expensive to change
after the app holds real training data. Everything else in the repo still says `Fitty`, and a repo
that disagrees with itself about the product's name costs a little confusion in every later
session.

### The three layers, which do not move together

1. **The documents.** `SPEC.md`, `CONTEXT.md`, `README`-level text and the 20 design-map issues.
   Mechanical, but the design-map issues are a **closed record** — they say what was decided and
   when, and rewriting history in them is a different act from renaming a live document. Decide
   whether the sweep touches closed issues at all, or stops at `SPEC.md` and `CONTEXT.md`.
2. **The Swift module.** The rules module lifted from the prototype is called `Fitty`
   (`SPEC.md` §8.1). Its name in Swift belongs to
   [The rules module and its oracle](0020-the-rules-module-and-its-oracle.md), which decides what
   that target *is*. Do not rename it here — take whatever 0020 lands on.
3. **The prototype HTML.** `design/0007-logging/fitty-workout-logging.html` and its `Fitty`
   module. These are **published artefacts that were validated as they stand**, and the build map
   already treats them as a record rather than as living code. Renaming them buys nothing and
   breaks every link in `SPEC.md` §8.3. The default answer is: leave them.

### The name is already taken, by Rob

`rob-vb/hoppa` on GitHub is the **earlier Expo test app** (see the map's charter). It holds the
plain `hoppa` repo name and a public `hoppa-landing`. This map's repo therefore pushes to
**`rob-vb/hoppa-ios`**, and no existing repo of Rob's was touched to make room for it. Whether the
real app eventually takes the plain name back — by renaming the test repo, which GitHub redirects
— is part of this ticket's sweep and costs one command.

### Do it when nothing else is in flight

A repo-wide rename conflicts with every open branch. Take this ticket on its own, between other
tickets, not beside one.

### Not here

**Whether `Hoppa` survives an App Store name check.** There is at least one established `Hoppa`
already — a UK/EU airport-transfer service — and the App Store requires a unique app name. That is
a launch question and this map never launches, so it rides with the App Store effort (§ the map's
Out of scope). It does not threaten the bundle id, which only has to be globally unique and is
never shown to a user.

---

## Resolution

**The repo now says `Hoppa` everywhere it speaks about the product, and `Fitty` only where the word
is a name of something that still exists.** That distinction is the whole answer, and it is worth
stating before the file list, because a future session will otherwise read a leftover `Fitty` as a
missed spot.

### The rule the sweep followed

`Fitty` was two different things in this repo, and only one of them was the app.

1. **The product name.** Prose, titles, the destination line. This is what Rob renamed, and every
   occurrence moved to `Hoppa`.
2. **An identifier of a real artefact.** The prototype's JavaScript module `` `Fitty` ``, the file
   paths `design/0007-logging/fitty-workout-logging.html` and its siblings, the design map's title
   *Fitty prototype map*, and the published artboard *Fitty History and Charts*. These name things
   that exist, under that name, right now. Renaming them in prose would make `SPEC.md` describe a
   file that is not there. **Every one of them stayed.**

`SPEC.md` therefore still contains the word `Fitty` five times, and all five are correct:

| Line | What it names | Why it stays |
|---|---|---|
| §head | `[Fitty prototype map](issues/0001-fitty-prototype-map.md)` | The design map's title, and a live link |
| §6.8 | `[Fitty History and Charts]` | A published artboard, at a fixed URL |
| §8.1 | pure module `` `Fitty` `` | The module in the prototype HTML |
| §8.2 | `` `Fitty.progression()` `` | A defect report against that module |
| §11 | the `Fitty` module | The same module, in the decision index |

### Scope, as Rob set it

Three choices, put to him as options:

- **The sweep covers the live documents and the build map, not the design map.** `SPEC.md`,
  `CONTEXT.md` and the build-map issues (`0017`, `0019`, `0020`, and this one). The 16 design-map
  issues `0001`–`0016` are **untouched**: they are a closed record of what was decided and when,
  and the app was called Fitty for all of it. Rewriting them would make them claim a name that did
  not exist at the time.
- **Both GitHub repos keep their names.** This repo stays `rob-vb/hoppa-ios`; the Expo test app
  keeps the plain `rob-vb/hoppa`. Nothing was renamed, archived or redirected. The plain name can
  still be taken later, and that question rides with the App Store effort, where the harder name
  question already lives.
- **The working folder on the VPS stays `/home/henk/fitty`.** A folder name is not a product name,
  and renaming it would break the path of every running session and saved setting that points at
  it. It is the last cosmetic `fitty` left, and it is deliberate.

### What changed

| File | Change |
|---|---|
| `SPEC.md` | 57 prose occurrences → `Hoppa`, including the title `# Hoppa — Specification`. The five identifier references above kept. |
| `SPEC.md` §10 | The out-of-scope bullet **"The definitive app name"** is gone — it is decided. It is replaced by **"Whether the name `Hoppa` survives an App Store name check"**, which is the part that is genuinely still out of scope, and which names the established UK/EU `Hoppa` and states that the bundle id is not threatened. |
| `CONTEXT.md` | 23 prose occurrences → `Hoppa`, including the title. No `Fitty` is left: the glossary named no artefact. |
| `issues/0017-fitty-build-map.md` | Renamed to **`issues/0017-hoppa-build-map.md`** (no inbound links to fix), `title: Hoppa build map`, and the destination line now reads *"Hoppa on Rob's own phone"*. The struck-through charter line keeps its `Fitty`, because it is the quotation being retired. |
| `issues/0019`, `issues/0020` | Prose occurrences → `Hoppa`. `0020`'s references to the prototype's `` `Fitty` `` module and its paths kept. |
| `app/bootstrap/setup-hoppa.sh` | *"Run this wizard on the Mac, inside the fitty repo"* → *"inside the Hoppa repo"*. It was already wrong: the Mac clone is `hoppa-ios`. |

### Not renamed, and why it is not a loose end

- **The Swift module.** [The rules module and its oracle](0020-the-rules-module-and-its-oracle.md)
  landed on `app/HoppaRules` before this ticket ran, so there was nothing to sweep. This ticket took
  its name, as planned.
- **The prototype HTML** — `design/`, 9 files with `fitty-` in their names. Left whole, as the
  ticket's default said. They are validated published artefacts and `SPEC.md` §8.3 links to them by
  path.
- **The design-map issues** `0001`–`0016`. Closed record.

### The finding

**A rename ticket is a classification ticket.** The count `grep -ril fitty` gives — 41 files — is
not the size of the job; it is the size of the question. Two thirds of those hits name artefacts,
not the product, and a mechanical `sed` across all of them would have broken five live links and
made `SPEC.md` §8 describe a module that does not exist under that name. The work was reading each
hit and deciding which of the two `Fitty`s it was.
