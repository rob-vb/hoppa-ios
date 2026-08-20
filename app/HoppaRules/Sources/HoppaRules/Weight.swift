/// A weight: a whole number of hundredths of its unit, carrying that unit.
///
/// Never a `Double`. `≈ CLOSEST` with *a tie rounds down* (`SPEC.md` §5.4) and *is the
/// Microload now one Stack Step* (§4.2) are exact comparisons, and the committed
/// snapshot must stay byte-stable — floating point makes guesses of both.
///
/// The unit rides on the number, so *units never convert* (§5.1) is something a rule
/// cannot break by accident: adding kg to lbs is a programmer error and traps.
public struct Weight: Codable, Sendable, Hashable {
    public let hundredths: Int
    public let unit: WeightUnit

    public init(hundredths: Int, unit: WeightUnit) {
        self.hundredths = hundredths
        self.unit = unit
    }

    public static func kg(hundredths: Int) -> Weight { Weight(hundredths: hundredths, unit: .kg) }
    public static func lbs(hundredths: Int) -> Weight { Weight(hundredths: hundredths, unit: .lbs) }

    public static func zero(_ unit: WeightUnit) -> Weight { Weight(hundredths: 0, unit: unit) }

    public var isZero: Bool { hundredths == 0 }
}

// MARK: - Text, in and out

extension Weight {
    /// `7250` kg reads `72.5`; `125` reads `1.25`; `2000` reads `20`.
    public var decimalString: String {
        let negative = hundredths < 0
        let magnitude = negative ? -hundredths : hundredths
        let whole = magnitude / 100
        let fraction = magnitude % 100
        let sign = negative ? "-" : ""
        if fraction == 0 { return "\(sign)\(whole)" }
        if fraction % 10 == 0 { return "\(sign)\(whole).\(fraction / 10)" }
        return "\(sign)\(whole).\(fraction < 10 ? "0" : "")\(fraction)"
    }

    /// Parses what a keypad produces. Exact: no `Double` is involved at any point.
    /// Rejects anything with more than two decimal places, because it is not a weight
    /// this app can hold.
    public init?(decimalString text: String, unit: WeightUnit) {
        var negative = false
        var whole = 0
        var fraction = 0
        var fractionDigits = 0
        var seenSeparator = false
        var seenDigit = false

        for (index, character) in text.enumerated() {
            if index == 0, character == "-" { negative = true; continue }
            if character == "." || character == "," {
                if seenSeparator { return nil }
                seenSeparator = true
                continue
            }
            guard let digit = character.wholeNumberValue, digit >= 0, digit <= 9 else { return nil }
            seenDigit = true
            if seenSeparator {
                fractionDigits += 1
                if fractionDigits > 2 { return nil }
                fraction = fraction * 10 + digit
            } else {
                let (multiplied, overflowA) = whole.multipliedReportingOverflow(by: 10)
                guard !overflowA else { return nil }
                let (added, overflowB) = multiplied.addingReportingOverflow(digit)
                guard !overflowB else { return nil }
                whole = added
            }
        }
        guard seenDigit else { return nil }
        if fractionDigits == 1 { fraction *= 10 }

        let (scaled, overflow) = whole.multipliedReportingOverflow(by: 100)
        guard !overflow else { return nil }
        let magnitude = scaled + fraction
        self.init(hundredths: negative ? -magnitude : magnitude, unit: unit)
    }
}

// MARK: - Arithmetic, within one unit only

extension Weight {
    public static func + (lhs: Weight, rhs: Weight) -> Weight {
        precondition(lhs.unit == rhs.unit, "units never convert: \(lhs.unit) + \(rhs.unit)")
        return Weight(hundredths: lhs.hundredths + rhs.hundredths, unit: lhs.unit)
    }

    public static func - (lhs: Weight, rhs: Weight) -> Weight {
        precondition(lhs.unit == rhs.unit, "units never convert: \(lhs.unit) - \(rhs.unit)")
        return Weight(hundredths: lhs.hundredths - rhs.hundredths, unit: lhs.unit)
    }

    public func scaled(by factor: Int) -> Weight {
        Weight(hundredths: hundredths * factor, unit: unit)
    }

    /// The same number, relabelled. Used only where a unit is **derived** and the stored
    /// label may be stale (`SPEC.md` §2.8) — it moves no iron and converts nothing.
    public func relabelled(_ unit: WeightUnit) -> Weight {
        Weight(hundredths: hundredths, unit: unit)
    }
}

extension Weight: Comparable {
    public static func < (lhs: Weight, rhs: Weight) -> Bool {
        precondition(lhs.unit == rhs.unit, "units never convert: \(lhs.unit) < \(rhs.unit)")
        return lhs.hundredths < rhs.hundredths
    }
}

// MARK: - Conversion, which Hoppa does only inside itself

extension Weight {
    /// 1 kg in lbs, as an exact ratio. `Double` is deliberately absent: the roll-up
    /// compares a converted Stack Step against a Microload, and that comparison decides
    /// whether the pin moves.
    static let lbsPerKgNumerator = 22_046_226_218
    static let lbsPerKgDenominator = 10_000_000_000

    /// Converts, rounding **towards zero**.
    ///
    /// `SPEC.md` §4.2 lets Hoppa do the mixed-unit arithmetic itself and forbids only
    /// *showing* the result. Nothing this returns reaches a screen: it exists so the
    /// roll-up can ask whether a Microload has reached one Stack Step.
    ///
    /// Rounding down is not arbitrary. A Stack Step converted **down** makes the
    /// remainder after a roll-up no smaller than it should be, which is what keeps the
    /// *weight never goes down* invariant safe at the hundredth.
    public func converted(to target: WeightUnit) -> Weight {
        if target == unit { return self }
        let value: Int
        switch (unit, target) {
        case (.kg, .lbs):
            value = Self.floorDivide(hundredths * Self.lbsPerKgNumerator, Self.lbsPerKgDenominator)
        case (.lbs, .kg):
            value = Self.floorDivide(hundredths * Self.lbsPerKgDenominator, Self.lbsPerKgNumerator)
        default:
            value = hundredths
        }
        return Weight(hundredths: value, unit: target)
    }

    static func floorDivide(_ numerator: Int, _ denominator: Int) -> Int {
        let quotient = numerator / denominator
        let remainder = numerator % denominator
        return (remainder != 0 && ((remainder < 0) != (denominator < 0))) ? quotient - 1 : quotient
    }
}
