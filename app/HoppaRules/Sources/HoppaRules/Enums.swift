/// kg or lbs. Units never convert, anywhere the user can see (`SPEC.md` §5.1).
public enum WeightUnit: String, Codable, Sendable, Hashable, CaseIterable {
    case kg
    case lbs
}

/// How an Exercise is loaded (`SPEC.md` §2.6).
///
/// The first four take their Weight Unit from the Plate Inventory: you cannot load a
/// plate you do not own. The last three carry the unit the machine itself is marked with.
public enum EquipmentType: String, Codable, Sendable, Hashable, CaseIterable {
    case barbell
    case smith
    case plateLoaded = "plate-loaded"
    case bodyweight
    case dumbbell
    case stack = "machine-stack"
    case cable

    /// True where the Weight Unit is the Plate Inventory's and not the Exercise's own.
    public var takesUnitFromInventory: Bool {
        switch self {
        case .barbell, .smith, .plateLoaded, .bodyweight: true
        case .dumbbell, .stack, .cable: false
        }
    }

    /// A bar has two sides, so one Microplate per side moves the weight by twice the
    /// plate (`SPEC.md` §4.2). Everything else takes one plate.
    public var platesPerProgression: Int {
        switch self {
        case .barbell, .smith, .plateLoaded: 2
        case .bodyweight, .dumbbell, .stack, .cable: 1
        }
    }

    /// Only a pin has somewhere to hang a Microload and a Stack Step to roll it into.
    public var hasPin: Bool {
        self == .stack || self == .cable
    }

    /// A Base Weight is a fact about a Smith or a plate-loaded machine, and nothing else.
    public var takesBaseWeight: Bool {
        self == .smith || self == .plateLoaded
    }

    /// Barbell, Smith and Plate-loaded draw the same loaded bar (`SPEC.md` §5.5).
    public var isBarLoaded: Bool {
        switch self {
        case .barbell, .smith, .plateLoaded: true
        case .bodyweight, .dumbbell, .stack, .cable: false
        }
    }
}

/// How an Exercise handles progression (`SPEC.md` §4.2).
public enum ProgressionMode: String, Codable, Sendable, Hashable, CaseIterable {
    case progressiveOverload = "progressive-overload"
    case microloading
    case none
}

extension ProgressionMode {
    /// Program-level one-tap cycle: PO → Microloading → None → PO.
    public var next: ProgressionMode {
        switch self {
        case .progressiveOverload: .microloading
        case .microloading: .none
        case .none: .progressiveOverload
        }
    }
}

/// Open until Finish or Discard. One Open Workout at a time (`SPEC.md` §2.4).
public enum WorkoutState: String, Codable, Sendable, Hashable {
    case open
    case finished
}

/// Open / Completed / Skipped (`SPEC.md` §3.2).
///
/// Navigating past an Exercise means "later". Skipping means "not at all".
public enum ExerciseState: String, Codable, Sendable, Hashable {
    case open
    case completed
    case skipped
}

/// The target span of reps per Set. Its two ends drive progression.
public struct RepRange: Codable, Sendable, Hashable {
    public var bottom: Int
    public var top: Int

    public init(_ bottom: Int, _ top: Int) {
        self.bottom = bottom
        self.top = top
    }

    /// What a Set must reach for this Mode: the bottom under Microloading, the top
    /// otherwise (`SPEC.md` §4.1).
    public func threshold(for mode: ProgressionMode) -> Int {
        mode == .microloading ? bottom : top
    }

    /// The pre-filled rep count for the next Set is always the top of the range.
    public var targetReps: Int { top }
}
