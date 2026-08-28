import SwiftUI
import UIKit

// Ticket 0055 — the edge swipe that every hidden navigation bar had switched off.
//
// Every screen in Hoppa hides its navigation bar, because §7.4 draws nothing in the safe
// top inset and each screen owns its own chevron. **What nobody knew until Rob's thumb
// found it**: hiding the bar also hides the back button, and UIKit's interactive pop
// gesture — the left-edge swipe iOS users reach for without thinking — is delegated to
// that back button. No button, no delegate, no swipe. On every screen at once.
//
// SwiftUI has no modifier for this. The gesture lives on the `UINavigationController`
// under the `NavigationStack`, so the only way to reach it is from a `UIViewController`
// that sits inside that stack. This one is invisible, zero-sized, and does exactly one
// thing: it becomes the gesture's delegate.
//
// **A hidden back button still means no way back.** `SummaryScreen` says
// `.navigationBarBackButtonHidden(true)` on purpose (§6.5: `DONE` is the only exit), and
// SwiftUI writes that through as `hidesBackButton` on the top item. The delegate reads it,
// so the swipe refuses there and nowhere else — the screen keeps saying it once.

/// Put once on the `NavigationStack`'s root view. It finds the navigation controller
/// above it and takes over the pop gesture's delegate.
struct SwipeBackEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Controller { Controller() }
    func updateUIViewController(_ controller: Controller, context: Context) {}

    final class Controller: UIViewController, UIGestureRecognizerDelegate {
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            guard let gesture = navigationController?.interactivePopGestureRecognizer else { return }
            gesture.delegate = self
            gesture.isEnabled = true
        }

        /// Never on the root — there is nothing under it — and never where the screen
        /// has hidden its back button, because that screen has ruled out going back.
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let navigation = navigationController, navigation.viewControllers.count > 1
            else { return false }
            return !(navigation.topViewController?.navigationItem.hidesBackButton ?? false)
        }
    }
}
