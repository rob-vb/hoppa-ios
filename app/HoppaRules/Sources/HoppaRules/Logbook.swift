/// Everything Hoppa knows about one lifter, as one value.
///
/// `openWorkout` is a single `Optional` at the top, so *one Open Workout at a time*
/// (`SPEC.md` §2.4) cannot be expressed wrongly. Finished Workouts sit at the top level
/// and not inside a Program, because history is global (§6.7).
public struct Logbook: Codable, Sendable, Hashable {
    /// The first field. An older version is backed up before it is migrated.
    public var schemaVersion: Int
    /// Ids are a counter, and an id is **never reused** after a delete (`SPEC.md` §2.8).
    public var nextId: Int
    public var plateInventory: PlateInventory
    public var programs: [Program]
    public var openWorkout: Workout?
    /// Finished, oldest first by `startedAt`.
    public var workouts: [Workout]

    public static let currentSchemaVersion = 1

    public init(
        schemaVersion: Int = Logbook.currentSchemaVersion,
        nextId: Int = 1,
        plateInventory: PlateInventory,
        programs: [Program] = [],
        openWorkout: Workout? = nil,
        workouts: [Workout] = []
    ) {
        self.schemaVersion = schemaVersion
        self.nextId = nextId
        self.plateInventory = plateInventory
        self.programs = programs
        self.openWorkout = openWorkout
        self.workouts = workouts
    }

    /// A fresh install. §6.1 pre-answers it: kg, Progressive Overload, the standard kg
    /// rack. An empty Logbook is that Plate Inventory and nothing else.
    public static var empty: Logbook {
        Logbook(plateInventory: .standard(.kg))
    }

    public mutating func mintId() -> Int {
        defer { nextId += 1 }
        return nextId
    }

    // MARK: - Lookup

    public func program(_ id: ProgramID) -> Program? {
        programs.first { $0.id == id }
    }

    /// Every Exercise there is, in Program order: Programs, then Days, then position.
    /// The order the §6.6 lists are drawn in.
    public var allExercises: [Exercise] {
        programs.flatMap { $0.days.flatMap(\.exercises) }
    }

    public func exercise(_ id: ExerciseID) -> Exercise? {
        for program in programs {
            if let match = program.exercise(id) { return match }
        }
        return nil
    }

    /// The Exercise behind a Performed Exercise, with every derived value worked out.
    /// `nil` once the Exercise has been deleted — history survives that (§2.8).
    public func resolvedExercise(_ id: ExerciseID) -> ResolvedExercise? {
        for program in programs {
            if let match = program.exercise(id) {
                return match.resolved(in: program, inventory: plateInventory)
            }
        }
        return nil
    }

    // MARK: - Mutation

    public mutating func updateExercise(_ id: ExerciseID, _ body: (inout Exercise) -> Void) {
        for programIndex in programs.indices {
            for dayIndex in programs[programIndex].days.indices {
                for exerciseIndex in programs[programIndex].days[dayIndex].exercises.indices
                where programs[programIndex].days[dayIndex].exercises[exerciseIndex].id == id {
                    body(&programs[programIndex].days[dayIndex].exercises[exerciseIndex])
                    return
                }
            }
        }
    }
}
