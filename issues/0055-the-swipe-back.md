---
id: 55
title: The edge swipe that no screen allowed
parent: 17
labels: [wayfinder:task]
status: closed
assignee: agent
blocked-by: []
---

## Question

Rob, on the walk, 2026-08-28:

> wat mij opvalt is dat ik niet van links naar rechts kan swipen op een pagina om terug te gaan.
> Toch is dit wel iets wat ik gewend ban van apps op iOS.

**It is off on every screen, and every screen switched it off the same way.** All thirteen
routes say `.toolbar(.hidden, for: .navigationBar)`, because §7.4 draws nothing in the safe top
inset and each screen draws its own chevron. What none of the screen tickets knew: hiding the bar
hides the back button, and UIKit's interactive pop gesture — the left-edge swipe — is delegated to
that button. No button, no delegate, no swipe. It was never a decision; it was a side effect
nobody could see without a thumb.

## Resolution

**One new file, `SwipeBack.swift`, and one line at the root.** SwiftUI has no modifier for the
pop gesture; it lives on the `UINavigationController` under the `NavigationStack`. So a zero-sized
`UIViewControllerRepresentable` sits in the root view's background, finds that controller in
`viewDidAppear`, and takes over `interactivePopGestureRecognizer.delegate`. Every pushed screen
then swipes back — the chevrons stay, the bars stay hidden, nothing on any screen changes.

**A hidden back button still means no way back.** `SummaryScreen` sets
`.navigationBarBackButtonHidden(true)` on purpose — §6.5: *`DONE` is the only exit* — and SwiftUI
writes that through as `navigationItem.hidesBackButton` on the top controller. The delegate reads
that flag, so the swipe refuses on the Summary and nowhere else. One screen states the rule once,
and the gesture obeys it. Also refused on the root, where there is nothing under it.

**Unproven here, and more so than usual.** This is the first UIKit in the app target, and whether
`navigationController` resolves from a representable inside a `NavigationStack` is a runtime
fact about SwiftUI's hosting that Linux cannot check. The fallback if it does not: the same
delegate via an `extension UINavigationController` overriding `viewDidLoad`, which is the widely
used pattern and slightly uglier. `HANDOFF.md` items 124–125.

**The second half of the same message** — *"de app ziet er niet iOS native uit"* — is not in this
ticket. It is a question about a settled decision (§7, the Plate Rack language), so it goes to
Rob as options rather than into a build. See the map's fog.
