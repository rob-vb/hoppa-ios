/// One plate size in the rack, switched on or off. No count of pairs (`SPEC.md` §5.2).
public struct PlateSize: Codable, Sendable, Hashable {
    public var weight: Weight
    public var isOn: Bool

    public init(weight: Weight, isOn: Bool) {
        self.weight = weight
        self.isOn = isOn
    }
}

/// The plate sizes available in the user's gym, in **one** unit. Hoppa holds one.
///
/// That unit sets the Weight Unit of every Exercise with a Plate Breakdown
/// (`SPEC.md` §5.2), which is why `Exercise` does not store one for those types.
public struct PlateInventory: Codable, Sendable, Hashable {
    public var unit: WeightUnit
    public var plates: [PlateSize]
    public var microplates: [PlateSize]

    public init(unit: WeightUnit, plates: [PlateSize], microplates: [PlateSize]) {
        self.unit = unit
        self.plates = plates
        self.microplates = microplates
    }

    /// The switched-on normal plates, biggest first. What Progressive Overload may load.
    public var enabledPlates: [Weight] {
        plates.filter(\.isOn).map(\.weight).sorted(by: >)
    }

    /// The switched-on Microplates, biggest first.
    public var enabledMicroplates: [Weight] {
        microplates.filter(\.isOn).map(\.weight).sorted(by: >)
    }

    /// The plate list a solve may use. **The Progression Mode decides** (`SPEC.md` §5.3):
    /// Progressive Overload gets the normal plates only, Microloading the whole rack.
    /// A normal barbell exercise must never be told to hang a 0.5 kg microplate.
    public func plates(for mode: ProgressionMode) -> [Weight] {
        switch mode {
        case .progressiveOverload:
            return enabledPlates
        case .microloading:
            // A size can sit in both groups — 2.5 lbs is a normal plate and a Microplate
            // in the shipped lbs rack — and the same size twice helps no solve.
            var seen: [Int] = []
            return (enabledPlates + enabledMicroplates).sorted(by: >).filter { plate in
                if seen.contains(plate.hundredths) { return false }
                seen.append(plate.hundredths)
                return true
            }
        }
    }

    /// The smallest plate a Microloading solve can reach for. Every buildable hanging
    /// load is a multiple of it, because the rack holds no count of pairs.
    public func smallestBuildableStep(for mode: ProgressionMode) -> Weight? {
        plates(for: mode).last
    }

    /// Rounds **up** to a weight the rack can build. This is what keeps the roll-up from
    /// ever dropping the total weight (`SPEC.md` §4.2).
    public func roundedUpToBuildable(_ weight: Weight, for mode: ProgressionMode) -> Weight {
        precondition(weight.unit == unit, "a plate load is solved in the Inventory's unit")
        guard let step = smallestBuildableStep(for: mode), step.hundredths > 0 else { return weight }
        if weight.hundredths <= 0 { return Weight(hundredths: 0, unit: unit) }
        let steps = (weight.hundredths + step.hundredths - 1) / step.hundredths
        return Weight(hundredths: steps * step.hundredths, unit: unit)
    }

    /// Shipped defaults (`SPEC.md` §5.2). **Every Microplate ships OFF, in both units**:
    /// most gyms own none, and an honest default keeps the footer true on a fresh install.
    /// There is no 15 kg plate — that was an invention in the prototype fixture (§7.3).
    public static func standard(_ unit: WeightUnit) -> PlateInventory {
        switch unit {
        case .kg:
            PlateInventory(
                unit: .kg,
                plates: [
                    PlateSize(weight: .kg(hundredths: 2500), isOn: false),
                    PlateSize(weight: .kg(hundredths: 2000), isOn: true),
                    PlateSize(weight: .kg(hundredths: 1000), isOn: true),
                    PlateSize(weight: .kg(hundredths: 500), isOn: true),
                    PlateSize(weight: .kg(hundredths: 250), isOn: true),
                    PlateSize(weight: .kg(hundredths: 125), isOn: true)
                ],
                microplates: [
                    PlateSize(weight: .kg(hundredths: 100), isOn: false),
                    PlateSize(weight: .kg(hundredths: 75), isOn: false),
                    PlateSize(weight: .kg(hundredths: 50), isOn: false),
                    PlateSize(weight: .kg(hundredths: 25), isOn: false)
                ])
        case .lbs:
            PlateInventory(
                unit: .lbs,
                plates: [
                    PlateSize(weight: .lbs(hundredths: 5500), isOn: false),
                    PlateSize(weight: .lbs(hundredths: 4500), isOn: true),
                    PlateSize(weight: .lbs(hundredths: 3500), isOn: false),
                    PlateSize(weight: .lbs(hundredths: 2500), isOn: true),
                    PlateSize(weight: .lbs(hundredths: 1000), isOn: true),
                    PlateSize(weight: .lbs(hundredths: 500), isOn: true),
                    PlateSize(weight: .lbs(hundredths: 250), isOn: true)
                ],
                microplates: [
                    PlateSize(weight: .lbs(hundredths: 250), isOn: false),
                    PlateSize(weight: .lbs(hundredths: 125), isOn: false),
                    PlateSize(weight: .lbs(hundredths: 100), isOn: false),
                    PlateSize(weight: .lbs(hundredths: 50), isOn: false)
                ])
        }
    }

    /// Switches a size on or off in whichever group holds it.
    public mutating func setPlate(_ weight: Weight, on isOn: Bool) {
        for index in plates.indices where plates[index].weight == weight { plates[index].isOn = isOn }
        for index in microplates.indices where microplates[index].weight == weight { microplates[index].isOn = isOn }
    }
}
