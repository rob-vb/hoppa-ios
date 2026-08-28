import SwiftUI
import UIKit

// Ticket 0056 — what an iOS app does under the thumb, added without touching what it looks
// like. Rob's call at the walk (2026-08-28): **keep the Plate Rack language, add the
// behaviour** — *"native gedrag, eigen look"*. Three things every native app does that
// Hoppa did not, and all three are felt rather than seen:
//
// 1. **A button reacts while it is held.** Every button in the app wore
//    `.buttonStyle(.pressable)`, which draws nothing on press — a tap landed and the screen
//    gave no sign until the next state arrived. `PressableButtonStyle` is the one place
//    that sign now comes from, and every `.plain` became `.pressable`.
// 2. **The phone ticks.** One `sensoryFeedback` in the whole app, on the reorder handle.
//    `Haptic` puts a tick on the moments that matter: a Set logged, a Workout finished,
//    a weight stepped, a thing deleted. Haptics are not motion, so Reduce Motion does not
//    reach them (§6.5's own line about the confetti).
// 3. **A sheet shows its grabber.** Lives at each sheet's site, not here.

/// Dims and very slightly shrinks the label while the finger is down. 0.12 s, so a quick
/// tap still flashes it. Nothing about the label's own drawing changes — this is what
/// `.plain` was, with a pressed state.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.55 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}

/// The four ticks Hoppa uses, named by what happened and not by how hard the phone taps.
/// UIKit generators rather than `sensoryFeedback`, because the moments below are actions
/// in a function and not a value a view could watch change.
enum Haptic {
    /// A Set logged — the tap the whole screen is for.
    static func logged() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    /// A Workout finished. The Summary lands on this.
    static func finished() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    /// A weight stepped by `−` / `+`. Light, because the stepper is held and tapped fast.
    static func stepped() { UISelectionFeedbackGenerator().selectionChanged() }
    /// Something deleted, or a Workout discarded — the moments that keep nothing.
    static func destroyed() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}
