import HoppaRules

// Ticket 0036 — how big a plate is drawn.
//
// [Drawing the loaded bar and the Ignition confetti](0031-drawing-the-bar-and-the-confetti.md)
// handed this down as a fact: **plate glyph geometry stays in the view**, because a
// drawing is not a rule. Two lifters with the same `Logbook` load the same iron; how
// wide the picture of it is decides nothing.
//
// The prototype's relative sizes are the reference — 20 kg at 34x114, 10 at 24x96, 5 at
// 20x90, 2.5 at 15x74, 1.25 at 11x60 — and **its colours are §8.2 defect 5**, so this
// file takes the size and `PlatePalette` answers the colour. There is no 15 kg (§7.3),
// and the 25 kg the prototype never drew is extrapolated one step above the 20.
//
// **A microplate draws at roughly a quarter of the smallest normal plate** (§7.1 rule 1),
// which the prototype never drew at all. 1.25 kg stands 60 tall, so the microplates run
// 26 down to 17 — a step the eye cannot mistake for a normal plate, which is the whole
// point of the rule: a blue disc that small can only be the 0.75.
//
// No `import SwiftUI` on purpose, the same trick `SteelRamp.swift` uses: this is
// arithmetic, so it compiles and runs on the VPS. `Double` and not `CGFloat` for the
// same reason — `CGFloat` is CoreGraphics.
enum PlateGlyph {

    struct Size: Sendable, Hashable {
        var width: Double
        var height: Double
    }

    /// The real rack (§7.3), at the prototype's measured sizes. **kg only**, exactly as
    /// `PlatePalette.hex(for:)` is kg only — the spec paints one gym's iron rack and an
    /// lbs rack has no drawing of its own yet. Anything not on this list falls to the
    /// ramp below.
    static func size(for weight: Weight) -> Size {
        if weight.unit == .kg, let measured = kgTable(weight.hundredths) { return measured }
        return ramp(ratio: ratioToReference(weight))
    }

    private static func kgTable(_ hundredths: Int) -> Size? {
        switch hundredths {
        case 2500: Size(width: 36, height: 120)   // 25 kg   — one step above the 20
        case 2000: Size(width: 34, height: 114)
        case 1000: Size(width: 24, height: 96)
        case 500:  Size(width: 20, height: 90)
        case 250:  Size(width: 15, height: 74)
        case 125:  Size(width: 11, height: 60)
        // The microplates, at roughly a quarter of the 1.25 (§7.1 rule 1).
        case 100:  Size(width: 9, height: 26)
        case 75:   Size(width: 8, height: 23)
        case 50:   Size(width: 8, height: 20)
        case 25:   Size(width: 7, height: 17)
        default: nil
        }
    }

    /// The biggest plate the unit's shipped list holds (§5.2), so the ramp reads a
    /// fraction of a full rack and not a fraction of whatever is on the bar.
    private static func ratioToReference(_ weight: Weight) -> Double {
        let reference: Double = weight.unit == .kg ? 2500 : 5500
        guard reference > 0 else { return 0 }
        return Double(weight.hundredths) / reference
    }

    /// The kg table's own normal-plate ramp, generalised — so an lbs rack draws in the
    /// same proportions the kg one was measured at.
    ///
    /// **It carries no microplate cliff.** 2.5 lbs is a normal plate *and* a Microplate
    /// in §5.2's shipped list, so no weight alone can say which one is on the bar, and a
    /// ramp that guessed would draw the wrong one half the time. The cliff is a fact
    /// about the kg rack, and the kg rack has a table.
    private static func ramp(ratio: Double) -> Size {
        let anchors: [(ratio: Double, size: Size)] = [
            (0.00, Size(width: 7, height: 18)),
            (0.05, Size(width: 11, height: 60)),
            (0.10, Size(width: 15, height: 74)),
            (0.20, Size(width: 20, height: 90)),
            (0.40, Size(width: 24, height: 96)),
            (0.80, Size(width: 34, height: 114)),
            (1.00, Size(width: 36, height: 120)),
        ]
        let clamped = min(max(ratio, 0), 1)
        for index in 1..<anchors.count {
            let high = anchors[index]
            guard clamped <= high.ratio else { continue }
            let low = anchors[index - 1]
            let span = high.ratio - low.ratio
            let t = span > 0 ? (clamped - low.ratio) / span : 0
            return Size(
                width: low.size.width + (high.size.width - low.size.width) * t,
                height: low.size.height + (high.size.height - low.size.height) * t)
        }
        return anchors[anchors.count - 1].size
    }
}
