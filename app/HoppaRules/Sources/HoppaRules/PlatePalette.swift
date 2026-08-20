/// The user's real rack (`SPEC.md` §7.3), as data.
///
/// It lives here and not in the view layer because it is a fact about plates, and
/// because the prototype's invented colours are one of the eight defects §8.2 lists.
/// Where a colour repeats, **the lighter shade is the lighter weight**.
///
/// The spec paints one gym's iron rack and lists kg only. An lbs rack has no palette
/// yet, so `hex(for:)` returns `nil` there and the view falls back to steel.
public enum PlatePalette {
    /// Steel: what a stack block, a dumbbell and an unpainted plate are drawn in.
    public static let steel = "#3A3E42"

    /// Green doubles as the done / progression colour.
    public static let progression = "#2E9E52"

    public static func hex(for weight: Weight) -> String? {
        guard weight.unit == .kg else { return nil }
        return switch weight.hundredths {
        case 2500: "#C8322B"   // 25 kg  red
        case 2000: "#1F5FCB"   // 20 kg  blue
        case 1000: "#2E9E52"   // 10 kg  green
        case 500: "#33373A"    // 5 kg   black -> dark grey
        case 250: "#4E5358"    // 2.5 kg black -> mid grey
        case 125: "#70767C"    // 1.25kg black -> light grey
        case 100: "#C8322B"    // 1 kg microplate    red
        case 75: "#1F5FCB"     // 0.75 kg microplate blue
        case 50: "#2E9E52"     // 0.5 kg microplate  green
        case 25: "#E8E6E1"     // 0.25 kg microplate white
        default: nil
        }
    }
}
