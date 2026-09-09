/// The plates of a selectorized stack. Plate `n` (n ≥ 1) reads
/// `first + (n - 1) × step`.
///
/// `first` is what the top plate reads. Most stacks read one step there; a nil
/// stored first means that. The kg column printed on an lbs stack is rounded lbs
/// and is not a second ladder (`SPEC.md` §5.1).
public struct StackLadder: Sendable, Hashable {
    public let step: Weight
    public let first: Weight

    public var startsFromZero: Bool { first == step }
    public var unit: WeightUnit { step.unit }

    /// nil / non-positive first → first == step. nil if step.hundredths <= 0.
    /// Differing units trap, same as `Weight.+`.
    public init?(step: Weight, first: Weight?) {
        guard step.hundredths > 0 else { return nil }
        if let first {
            precondition(first.unit == step.unit, "units never convert: \(first.unit) + \(step.unit)")
        }
        self.step = step
        if let first, first.hundredths > 0 {
            self.first = first
        } else {
            self.first = step
        }
    }

    /// A plate the pin can sit on, and what it reads.
    public struct Pin: Sendable, Hashable {
        /// 1-based. Plate 1 is the top plate.
        public let plate: Int
        public let label: Weight

        public init(plate: Int, label: Weight) {
            self.plate = plate
            self.label = label
        }
    }

    /// Highest label at or under `target`. nil if target < first.
    /// Wrong unit traps, same as `Weight.+`.
    public func pin(atOrUnder target: Weight) -> Pin? {
        guard target >= first else { return nil }
        let above = (target.hundredths - first.hundredths) / step.hundredths
        let label = Weight(hundredths: first.hundredths + above * step.hundredths, unit: unit)
        return Pin(plate: above + 1, label: label)
    }
}
