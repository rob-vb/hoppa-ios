import SwiftUI

// Ticket 0032, inherited from [Dark only, or a light mode too](0030) — which found that
// **`Font.custom(_:size:)` scales with Dynamic Type by default** and only
// `Font.custom(_:fixedSize:)` does not. §7.4 fixes its sizes in points and its line
// heights below 1.0, and a layout with a 0.78 leading and a 50 px hit target does not
// survive a text scale. So the app pins Dynamic Type at the root (`HoppaApp`) **and**
// every face here is built with `fixedSize`.
//
// **A view never calls `.custom` itself.** That is the whole reason this file exists: one
// bypass and the screen scales again, on somebody's phone and not on Rob's.

/// `SPEC.md` §7.4 as named roles.
enum Typography {

    /// A font, its letter-spacing and its case, as one thing a view can wear.
    struct Role: ViewModifier {
        let font: Font
        /// Points, not em. The factories below do the multiplication, because §7.4 and
        /// the artboards both write letter-spacing in em.
        let tracking: CGFloat
        /// **Additive**, which is all SwiftUI's `lineSpacing` can be: it adds to the
        /// face's own leading and cannot cut into it. Tightening below 1.0 is
        /// `Font.leading(.tight)` on the display role instead.
        let lineSpacing: CGFloat
        let uppercase: Bool

        func body(content: Content) -> some View {
            content
                .font(font)
                .tracking(tracking)
                .lineSpacing(lineSpacing)
                .textCase(uppercase ? .uppercase : nil)
        }
    }

    /// **Anton.** Working Weight, headings, set numbers, button labels. Uppercase, tight.
    ///
    /// §7.4 asks for a line-height of 0.78–0.94, and SwiftUI cannot state that as a
    /// number — `lineSpacing` only ever adds. `Font.leading(.tight)` is the native way to
    /// pull it in, and it is an approximation of the artboard rather than a measurement
    /// of it. **Unproven until a multi-line display heading runs on the Mac**; the picker
    /// has none, and ticket 0033's `NAME YOUR PROGRAM` is the first that does.
    static func display(_ size: CGFloat, tracking em: CGFloat = 0.02) -> Role {
        Role(
            font: .custom(BundledFonts.display, fixedSize: size).leading(.tight),
            tracking: size * em, lineSpacing: 0, uppercase: true)
    }

    /// The small uppercase labels: 10–11 px, letter-spacing 0.12–0.14 em (§7.4).
    static func label(_ size: CGFloat = 10, tracking em: CGFloat = 0.14) -> Role {
        Role(
            font: .custom(BundledFonts.bodyMedium, fixedSize: size),
            tracking: size * em, lineSpacing: 0, uppercase: true)
    }

    /// The meta line under a name — "2 days ago", "3 sets · 8–12". Sentence case.
    static func meta(_ size: CGFloat = 11) -> Role {
        Role(font: plex(size), tracking: 0, lineSpacing: 0, uppercase: false)
    }

    /// Prose. `lineSpacing` is the *extra* over the face's own leading, so the artboard's
    /// 1.65 on 13 px — about 21.5 pt against Plex's own ~17 pt — is roughly 4.
    static func body(_ size: CGFloat = 13, lineSpacing: CGFloat = 0) -> Role {
        Role(font: plex(size), tracking: 0, lineSpacing: lineSpacing, uppercase: false)
    }

    /// **Tabular figures on** (§7.4). Every figure Hoppa prints sits in a column that a
    /// proportional `1` would make jump.
    private static func plex(_ size: CGFloat) -> Font {
        .custom(BundledFonts.body, fixedSize: size).monospacedDigit()
    }
}

extension View {
    func typography(_ role: Typography.Role) -> some View { modifier(role) }
}
