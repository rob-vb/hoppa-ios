/// A converted mass as tenths of a unit. Copy prints it. Arithmetic never sees it:
/// no `+`, no `<`. Round half away from zero so 2.5 lbs reads 1.1 kg, matching the
/// column printed on the machine.
public struct Sticker: Sendable, Hashable {
    public let tenths: Int
    public let unit: WeightUnit

    /// `nil` only if the integer multiply would overflow. Same-unit still produces tenths.
    public init?(of weight: Weight, readIn target: WeightUnit) {
        let tenths: Int
        if target == weight.unit {
            tenths = Self.roundHalfAwayFromZero(weight.hundredths, 10)
        } else {
            let factor: Int
            let divisor: Int
            switch (weight.unit, target) {
            case (.kg, .lbs):
                factor = Weight.lbsPerKgNumerator
                divisor = Weight.lbsPerKgDenominator * 10
            case (.lbs, .kg):
                factor = Weight.lbsPerKgDenominator
                divisor = Weight.lbsPerKgNumerator * 10
            default:
                return nil
            }
            let (product, overflow) = weight.hundredths.multipliedReportingOverflow(by: factor)
            guard !overflow else { return nil }
            tenths = Self.roundHalfAwayFromZero(product, divisor)
        }
        self.tenths = tenths
        self.unit = target
    }

    /// The pin column on an lbs stack: 190 lbs reads 86 kg, not 86.2.
    /// Rounds converted hundredths to whole units. Going through tenths first would
    /// turn 195 lbs (88.45 kg) into 89.
    public static func ones(of weight: Weight, readIn target: WeightUnit) -> Sticker? {
        let ones: Int
        if target == weight.unit {
            ones = roundHalfAwayFromZero(weight.hundredths, 100)
        } else {
            let factor: Int
            let divisor: Int
            switch (weight.unit, target) {
            case (.kg, .lbs):
                factor = Weight.lbsPerKgNumerator
                divisor = Weight.lbsPerKgDenominator * 100
            case (.lbs, .kg):
                factor = Weight.lbsPerKgDenominator
                divisor = Weight.lbsPerKgNumerator * 100
            default:
                return nil
            }
            let (product, overflow) = weight.hundredths.multipliedReportingOverflow(by: factor)
            guard !overflow else { return nil }
            ones = roundHalfAwayFromZero(product, divisor)
        }
        return Sticker(tenths: ones * 10, unit: target)
    }

    /// Printed columns a lifter can set the pin to. Tenths always. Ones only
    /// when they do not round past tenths: 125 lbs prints 56.7 kg, not 57.
    public static func settableColumns(of weight: Weight, readIn target: WeightUnit) -> [Sticker] {
        guard let tenths = Sticker(of: weight, readIn: target) else { return [] }
        var columns = [tenths]
        if let ones = Sticker.ones(of: weight, readIn: target),
           ones.tenths <= tenths.tenths, ones != tenths {
            columns.append(ones)
        }
        return columns
    }

    init(tenths: Int, unit: WeightUnit) {
        self.tenths = tenths
        self.unit = unit
    }

    public var decimalString: String {
        let negative = tenths < 0
        let magnitude = negative ? -tenths : tenths
        let whole = magnitude / 10
        let fraction = magnitude % 10
        let sign = negative ? "-" : ""
        if fraction == 0 { return "\(sign)\(whole)" }
        return "\(sign)\(whole).\(fraction)"
    }

    /// Hundredths tagged in this sticker's unit. The solver totals spoken masses here,
    /// once, because `Sticker` itself has no `+`.
    public var asWeight: Weight {
        Weight(hundredths: tenths * 10, unit: unit)
    }

    static func roundHalfAwayFromZero(_ numerator: Int, _ denominator: Int) -> Int {
        let negative = (numerator < 0) != (denominator < 0)
        let absN = numerator < 0 ? -numerator : numerator
        let absD = denominator < 0 ? -denominator : denominator
        let quotient = absN / absD
        let remainder = absN % absD
        let rounded = remainder * 2 >= absD ? quotient + 1 : quotient
        return negative ? -rounded : rounded
    }
}
