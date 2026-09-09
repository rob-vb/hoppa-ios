/// A slider that hangs on a selectorized pin. Closed set: the two sizes gyms actually
/// ship. Each `iron` is lbs, even when the Working Weight is kg.
public enum StackAddOn: Sendable, Hashable, CaseIterable {
    case twoAndAHalfLbs
    case fiveLbs

    public var iron: Weight {
        switch self {
        case .twoAndAHalfLbs: .lbs(hundredths: 250)
        case .fiveLbs: .lbs(hundredths: 500)
        }
    }
}

/// Which of the two sliders this gym has on the stack machines. Nested on the Plate
/// Inventory so `Rules.breakdown(for:inventory:)` stays the only UI entry.
public struct MachineAddOns: Codable, Sendable, Hashable {
    public var twoAndAHalfLbs: Bool
    public var fiveLbs: Bool

    public static let standard = MachineAddOns(twoAndAHalfLbs: true, fiveLbs: true)

    public init(twoAndAHalfLbs: Bool, fiveLbs: Bool) {
        self.twoAndAHalfLbs = twoAndAHalfLbs
        self.fiveLbs = fiveLbs
    }

    /// Biggest first, one of each. Empty when both are off.
    public var enabledSizes: [Weight] {
        var sizes: [Weight] = []
        if fiveLbs { sizes.append(StackAddOn.fiveLbs.iron) }
        if twoAndAHalfLbs { sizes.append(StackAddOn.twoAndAHalfLbs.iron) }
        return sizes
    }

    public func isOn(_ addOn: StackAddOn) -> Bool {
        switch addOn {
        case .twoAndAHalfLbs: twoAndAHalfLbs
        case .fiveLbs: fiveLbs
        }
    }

    public mutating func set(_ addOn: StackAddOn, on isOn: Bool) {
        switch addOn {
        case .twoAndAHalfLbs: twoAndAHalfLbs = isOn
        case .fiveLbs: fiveLbs = isOn
        }
    }
}
