---
id: 21
title: The app is called Hoppa
parent: 17
labels: [wayfinder:task]
status: open
assignee:
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
