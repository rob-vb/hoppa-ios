/// One movement inside a Workout Day.
///
/// Two fields are stored flat and read through an accessor — `baseWeight` and
/// `stackStep` — because `SPEC.md` §2.3 refuses to re-ask a fact about a machine when
/// the Equipment Type changes, while no rule may read one where it does not apply.
///
/// The Weight Unit is **not** a field. For Barbell, Smith, Plate-loaded and Bodyweight it
/// is the Plate Inventory's (§5.1), so storing it would make a stale copy possible
/// (§2.8). Read everything through `resolved(in:inventory:)`.
public struct Exercise: Codable, Sendable, Hashable {
    public var id: ExerciseID
    public var name: String
    public var equipment: EquipmentType
    /// The unit the machine itself is marked with. Meaningful for Dumbbell, Machine
    /// (stack) and Cable only; ignored for the four types that read the rack.
    public var ownWeightUnit: WeightUnit
    public var plannedSets: Int
    public var repRange: RepRange
    public var workingWeight: Weight
    /// Progressive Overload. Any number the user types.
    public var increment: Weight
    /// Microloading. A Microplate the user owns, in the **Plate Inventory's** unit, even
    /// when the Exercise uses the other one. `nil` until a Microplate is switched on.
    public var microloadingIncrement: Weight?
    /// An Exercise may override the Program's Progression Mode. An override is deliberate.
    public var modeOverride: ProgressionMode?
    /// Kept across a change of Equipment Type; read through `resolved`.
    public var storedBaseWeight: Weight?
    /// Kept across a change of Equipment Type; read through `resolved`.
    public var storedStackStep: Weight?
    /// A weight on the pin, in the Plate Inventory's unit. Destroyed and recreated at
    /// zero when a unit changes (§2.8), never a count of plates (§4.2).
    public var microload: Weight?

    public init(
        id: ExerciseID,
        name: String,
        equipment: EquipmentType,
        ownWeightUnit: WeightUnit = .kg,
        plannedSets: Int,
        repRange: RepRange,
        workingWeight: Weight,
        increment: Weight,
        microloadingIncrement: Weight? = nil,
        modeOverride: ProgressionMode? = nil,
        storedBaseWeight: Weight? = nil,
        storedStackStep: Weight? = nil,
        microload: Weight? = nil
    ) {
        self.id = id
        self.name = name
        self.equipment = equipment
        self.ownWeightUnit = ownWeightUnit
        self.plannedSets = plannedSets
        self.repRange = repRange
        self.workingWeight = workingWeight
        self.increment = increment
        self.microloadingIncrement = microloadingIncrement
        self.modeOverride = modeOverride
        self.storedBaseWeight = storedBaseWeight
        self.storedStackStep = storedStackStep
        self.microload = microload
    }
}

/// A named template inside a Program.
public struct WorkoutDay: Codable, Sendable, Hashable {
    public var id: WorkoutDayID
    public var name: String
    public var exercises: [Exercise]

    public init(id: WorkoutDayID, name: String, exercises: [Exercise]) {
        self.id = id
        self.name = name
        self.exercises = exercises
    }
}

/// A training plan the user follows. A user may hold more than one.
public struct Program: Codable, Sendable, Hashable {
    public var id: ProgramID
    public var name: String
    /// For **new** Exercises only. A Program may hold Exercises in both units.
    public var defaultWeightUnit: WeightUnit
    /// The default for its Exercises. An Exercise may override it.
    public var mode: ProgressionMode
    public var days: [WorkoutDay]

    public init(
        id: ProgramID,
        name: String,
        defaultWeightUnit: WeightUnit,
        mode: ProgressionMode,
        days: [WorkoutDay]
    ) {
        self.id = id
        self.name = name
        self.defaultWeightUnit = defaultWeightUnit
        self.mode = mode
        self.days = days
    }

    public func exercise(_ id: ExerciseID) -> Exercise? {
        for day in days {
            if let match = day.exercises.first(where: { $0.id == id }) { return match }
        }
        return nil
    }
}
