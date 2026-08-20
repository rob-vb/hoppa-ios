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
