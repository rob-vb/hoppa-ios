/// What the Exercise sheet prints beside Working Weight (`SPEC.md` §2.3).
///
/// `.locked` is steel text, not a control: the four types loaded off the rack, and an
/// add sheet before a chip is picked — that sheet states the Program default and does
/// not offer a flip. `.own` is the one-tap chip Dumbbell, stack and cable get. The view
/// must not re-derive this. Unpicked equipment used to be coded as *own the Program
/// default*, which put a flip on every add; two callers drifting on that case is why
/// the tag lives here.
public enum UnitTag: Sendable, Hashable {
    case locked(WeightUnit)
    case own(WeightUnit)

    public var unit: WeightUnit {
        switch self {
        case .locked(let unit), .own(let unit): unit
        }
    }
}

extension Rules {

    public static func unitTag(
        equipment: EquipmentType?, own: WeightUnit, rack: WeightUnit
    ) -> UnitTag {
        guard let equipment else { return .locked(own) }
        return equipment.takesUnitFromInventory ? .locked(rack) : .own(own)
    }

    /// Always 5 and 10 in `unit`. Never a converted kg column (2.3, 4.5, 11.3) on an
    /// lbs stack: that machine is lbs, and the chips print what the pin actually jumps.
    public static func stackStepOffers(in unit: WeightUnit) -> [Weight] {
        [Weight(hundredths: 500, unit: unit), Weight(hundredths: 1000, unit: unit)]
    }

    public static func barIncrementOffers(in unit: WeightUnit) -> [Weight] {
        switch unit {
        case .kg:
            [.kg(hundredths: 125), .kg(hundredths: 250), .kg(hundredths: 500)]
        case .lbs:
            [.lbs(hundredths: 250), .lbs(hundredths: 500), .lbs(hundredths: 1000)]
        }
    }

    /// `nil` unless the Exercise owns a unit the rack does not.
    public static func exceptionNote(tag: UnitTag, rack: WeightUnit) -> String? {
        guard case .own(let unit) = tag, unit != rack else { return nil }
        return "This machine is marked in \(printed(unit)). Your gym is \(printed(rack))."
    }

    private static func printed(_ unit: WeightUnit) -> String {
        switch unit {
        case .kg: "KG"
        case .lbs: "LBS"
        }
    }
}
