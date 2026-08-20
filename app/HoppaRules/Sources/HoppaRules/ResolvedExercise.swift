/// An Exercise with every derived value already worked out, in the right unit.
///
/// This is the one place derivation happens. Every rule takes a `ResolvedExercise`, so
/// a stale Weight Unit, a Base Weight on a Barbell or a Stack Step on a Dumbbell is
/// unrepresentable inside the rules rather than something each rule must remember
/// (`SPEC.md` §2.8).
public struct ResolvedExercise: Sendable, Hashable {
    public let id: ExerciseID
    public let name: String
    public let equipment: EquipmentType
    /// The Exercise's Weight Unit: the Plate Inventory's for the four rack types, its
    /// own for Dumbbell, Machine (stack) and Cable (`SPEC.md` §5.1).
    public let unit: WeightUnit
    /// The Plate Inventory's unit. A Microload and a Microloading Increment live here.
    public let inventoryUnit: WeightUnit
    public let mode: ProgressionMode
    public let plannedSets: Int
    public let repRange: RepRange
    public let workingWeight: Weight
    public let increment: Weight
    public let microloadingIncrement: Weight?
    /// `nil` on any type that has none, whatever is stored.
    public let baseWeight: Weight?
    /// `nil` on any type that has none, whatever is stored.
    public let stackStep: Weight?
    /// A Microload exists only on a pin whose unit differs from the rack's
    /// (`SPEC.md` §2.3). `nil` everywhere else, whatever is stored.
    public let microload: Weight?

    /// What a Set must reach for this Exercise's Mode.
    public var thresholdReps: Int { repRange.threshold(for: mode) }

    /// The pre-filled rep count for the next Set: the top of the Rep Range.
    public var targetReps: Int { repRange.targetReps }

    /// True where the two numbers on the screen are in different units and never convert.
    public var isMixedUnitPin: Bool { equipment.hasPin && unit != inventoryUnit }
}

extension Exercise {
    /// The Weight Unit of this Exercise. Derived, never stored (`SPEC.md` §2.8).
    public func weightUnit(in inventory: PlateInventory) -> WeightUnit {
        equipment.takesUnitFromInventory ? inventory.unit : ownWeightUnit
    }

    public func mode(in program: Program) -> ProgressionMode {
        modeOverride ?? program.mode
    }

    public func resolved(in program: Program, inventory: PlateInventory) -> ResolvedExercise {
        resolved(mode: mode(in: program), inventory: inventory)
    }

    public func resolved(mode: ProgressionMode, inventory: PlateInventory) -> ResolvedExercise {
        let unit = weightUnit(in: inventory)
        let mixedUnitPin = equipment.hasPin && unit != inventory.unit
        return ResolvedExercise(
            id: id,
            name: name,
            equipment: equipment,
            unit: unit,
            inventoryUnit: inventory.unit,
            mode: mode,
            plannedSets: plannedSets,
            repRange: repRange,
            // A derived unit relabels the stored number; it never converts it. §6.6
            // clears the weights when the rack's unit changes, so nothing is reinterpreted
            // behind the user's back.
            workingWeight: workingWeight.relabelled(unit),
            increment: increment.relabelled(unit),
            microloadingIncrement: microloadingIncrement?.relabelled(inventory.unit),
            baseWeight: equipment.takesBaseWeight ? storedBaseWeight?.relabelled(unit) : nil,
            stackStep: equipment.hasPin ? storedStackStep?.relabelled(unit) : nil,
            microload: mixedUnitPin ? (microload ?? .zero(inventory.unit)).relabelled(inventory.unit) : nil
        )
    }
}
