import SwiftUI

// Ticket 0018 — the surface palette, lifted out of the smoke-test screen when
// ticket 0025 replaced it.

// MARK: - Surface palette (SPEC.md §7.2)

// Internal, not private: ticket 0025 split this out of the one file that used it.
extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    static let floor = Color(hex: 0x0E0F10)
    static let card = Color(hex: 0x17191B)
    static let line = Color(hex: 0x26292C)
    static let steel = Color(hex: 0x9BA1A7)
    static let dimText = Color(hex: 0x8D9296)
    static let text = Color(hex: 0xF4F1EC)
    static let go = Color(hex: 0x2E9E52)      // green — done / progression
    static let stop = Color(hex: 0xC8322B)    // 25 kg red

    /// Ticket 0032 — the **seventh** role, and the first time ticket 30's escalation rule
    /// has actually added one.
    ///
    /// §7.2 named one text grey, and the artboards use two: `#8D9296` for a meta line a
    /// user reads, and this for the tiny uppercase labels above a block, which are
    /// furniture. Both onboarding (`design/0006-onboarding/Main.dc.html`) and the picker
    /// (`design/0015-history/Home.dc.html`) use it, so it is a role and not noise.
    ///
    /// It is **not a new hue**: it measures hue 210° at 4.5% saturation, the same spine as
    /// every grey in §7.2 and every grey in `Steel` — `Steel.hex(lightness: 0.349)` lands
    /// within 2/255 of it. `SPEC.md` §7.2 carries the row.
    static let labelText = Color(hex: 0x55595D)

    /// §7.2's Steel row carries **two** values — `#9BA1A7` for the mark itself and
    /// `#3A3E42` for the border of a chip. `steel` is the first; this is the second,
    /// and it is a name for a value the table already holds, not a new role and not a
    /// new hue. First needed by ticket 0033: the unswitched half of the `KG | LBS`
    /// toggle and the off state of a plate switch are both chip borders.
    static let chipBorder = Color(hex: 0x3A3E42)
}

// MARK: - The bridge to a plate colour (ticket 0030)

extension Color {
    /// `PlatePalette.hex(for:)` answers in `#RRGGBB`, because `HoppaRules` imports nothing
    /// and cannot name a `Color`. `nil` — an lbs rack, which §7.3 does not paint — is the
    /// caller's to answer, and §7.3 says steel.
    init?(plateHex: String?) {
        guard let plateHex else { return nil }
        let digits = plateHex.hasPrefix("#") ? String(plateHex.dropFirst()) : plateHex
        guard digits.count == 6, let value = UInt32(digits, radix: 16) else { return nil }
        self.init(hex: value)
    }
}

// MARK: - The steel of a drawing (SPEC.md §5.5, ticket 0031)

// A loaded bar and a stack draw seven things that carry no plate colour. §7.2 names one
// of them; ticket 30 forbids a view inventing the other six. They are all one hue at
// different lightnesses, so `Steel` derives them and this is only the naming.
//
// `Steel` imports nothing, so the arithmetic is checked on the VPS: it reproduces
// §7.2's `#9BA1A7` exactly and every prototype grey within 3/255.
extension Color {
    static let stackEmpty = Color(hex: Steel.stackEmpty)
    static let collar     = Color(hex: Steel.collar)
    static let knurlLow   = Color(hex: Steel.knurlLow)
    static let sleeveStop = Color(hex: Steel.sleeveStop)
    static let shaft      = Color(hex: Steel.shaft)
    static let knurlHigh  = Color(hex: Steel.knurlHigh)
    static let pin        = Color(hex: Steel.pin)

    /// Ticket 0038 — the name on a `STAYED` row (§6.5). Quieter than `text`, louder than
    /// `steel`: the row is read, not shouted, and the loud section above it is `WENT UP`.
    static let rowText = Color(hex: Steel.rowName)

    /// Ticket 0038 — the divider between `STAYED` rows, one step under `line`. The
    /// artboards separate the two sections by the weight of their rules as well as their
    /// type, and a `line` here would make the quiet section as loud as the loud one.
    static let hairline = Color(hex: Steel.hairline)
}

// MARK: - The rim of a plate (SPEC.md §7.3, ticket 0036)

extension Color {
    /// §7.3 gives every plate **a 1 px rim one step lighter than its face**. It is written
    /// there for the black family — `#33373A`, `#4E5358`, `#70767C` cannot sit flat on the
    /// `#0E0F10` floor — and the drawing gives it to every plate, because a rim that
    /// appeared only on three sizes would itself be a signal.
    ///
    /// **A derivation, not a new hue** (§7.2): each channel moves 30/255 towards white,
    /// which is the step the black family's own three greys are spaced at. So the 5 kg's
    /// rim lands beside the 2.5 kg's face, which is what "one step lighter" means in that
    /// table.
    init?(plateRimHex hex: String?) {
        guard let hex, let face = Color.plateChannels(hex) else { return nil }
        func lift(_ channel: UInt32) -> UInt32 { min(channel + 30, 255) }
        self.init(hex: lift(face.r) << 16 | lift(face.g) << 8 | lift(face.b))
    }

    private static func plateChannels(_ hex: String) -> (r: UInt32, g: UInt32, b: UInt32)? {
        let digits = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard digits.count == 6, let value = UInt32(digits, radix: 16) else { return nil }
        return ((value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF)
    }
}
