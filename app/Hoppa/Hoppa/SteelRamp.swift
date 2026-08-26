// Ticket 0031 — the steel of a drawing.
//
// A loaded bar draws seven things that carry no plate colour: the shaft, its knurl,
// the collars, the sleeve stops, a stack's loaded and unloaded blocks, and the pin.
// `SPEC.md` §7.2 names exactly one of them — steel `#9BA1A7` — and ticket 30 ruled
// that a screen needing an unnamed value **adds a named role or derives it from one**,
// and that a genuinely new hue is a finding with its own ticket.
//
// It derives, and nothing is a finding. Every grey in `SPEC.md` §7.2 and every grey in
// the two prototypes sits on **hue 210° at ~6% saturation** — floor, card, line, chip
// border, steel, and all seven of the drawing's greys. They are one colour at different
// lightnesses, so the ramp below is the whole surface palette's spine.
//
// No `import SwiftUI` on purpose: this is arithmetic, so it compiles and runs on the
// VPS. `Palette.swift` turns a value from here into a `Color`.
enum Steel {

    /// Hue 210°, saturation 6.4% — measured off `#9BA1A7`, which §7.2 names.
    static let hue = 210.0 / 360
    static let saturation = 0.064

    /// One point on the ramp, as `0xRRGGBB`. `lightness` is HSL's L, 0...1.
    static func hex(lightness: Double) -> UInt32 {
        let l = min(max(lightness, 0), 1)
        let c = (1 - abs(2 * l - 1)) * saturation
        let h6 = hue * 6
        let x = c * (1 - abs(h6.truncatingRemainder(dividingBy: 2) - 1))
        let m = l - c / 2

        // Hue 210° falls in the 180°–240° sextant, where the channels are (0, x, c).
        let (r, g, b) = (0.0 + m, x + m, c + m)
        // `rounded()` is libm, and this file imports nothing on purpose, so it rounds
        // by hand. Every channel here is 0...1, so the add-a-half truncation is exact.
        func byte(_ v: Double) -> UInt32 { UInt32(v * 255 + 0.5) }
        return byte(r) << 16 | byte(g) << 8 | byte(b)
    }

    // The ramp, named by what it draws. Lightnesses are measured off the prototypes in
    // `design/0007-logging/` and `design/0009-summary/`; the names are what §5.5 calls
    // the parts.
    static let stackEmpty = hex(lightness: 0.149)   // an unloaded pin block
    static let collar     = hex(lightness: 0.453)   // collar, dumbbell handle
    static let knurlLow   = hex(lightness: 0.506)   // the dark stripe of the knurl
    static let sleeveStop = hex(lightness: 0.565)   // sleeve stop, dumbbell bell
    static let shaft      = hex(lightness: 0.631)   // the shaft itself — §7.2's steel
    static let knurlHigh  = hex(lightness: 0.671)   // the light stripe of the knurl
    static let pin        = hex(lightness: 0.784)   // the pin through the stack

    // Ticket 0038 adds two more, both **derivations and not new hues** — ticket 30's
    // rule, and the same one `labelText` was added under. §6.5's summary artboards use
    // a name grey quieter than `text` and a divider quieter than `line`, and both sit on
    // this ramp: `#C9CDD1` lands within 2/255 of `rowName`, and `hairline` reproduces
    // `#1E2123` exactly.

    /// A name the user reads down a list, quieter than the hero — §6.5's `STAYED` rows.
    static let rowName    = hex(lightness: 0.800)

    /// A divider inside a quiet section, one step under `line` `#26292C`.
    static let hairline   = hex(lightness: 0.1275)
}
