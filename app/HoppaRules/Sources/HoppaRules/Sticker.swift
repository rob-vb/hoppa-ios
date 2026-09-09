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

    /// `11` tenths reads `1.1`; `10` reads `1`.
    public var decimalString: String {
        let negative = tenths < 0
        let magnitude = negative ? -tenths : tenths
        let whole = magnitude / 10
        let fraction = magnitude % 10
        let sign = negative ? "-" : ""
        if fraction == 0 { return "\(sign)\(whole)" }
        return "\(sign)\(whole).\(fraction)"
    }

    /// Half away from zero, both signs. Uses truncating division.
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
