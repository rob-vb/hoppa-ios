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
}
