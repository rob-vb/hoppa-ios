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

    /// The Workout Day behind an id, **with the Program that holds it**.
    ///
    /// Both, because a screen showing a Day needs both: §6.1's Day screen draws the
    /// Program's Name above the Day's, and the Day's Exercises resolve against the
    /// Program's Mode. Two lookups would walk the same Programs twice and could
    /// disagree about which Program a Day belongs to.
    public func workoutDay(_ id: WorkoutDayID) -> (program: Program, day: WorkoutDay)? {
        for program in programs {
            if let day = program.days.first(where: { $0.id == id }) { return (program, day) }
        }
        return nil
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

    /// When this Workout Day was **last done** — the `startedAt` of the newest finished
    /// Workout that performed it, or `nil` if it never has been.
    ///
    /// §3.1 puts this on every row of the picker, as information and not advice. It is a
    /// rule and not a view helper: two lifters holding the same `Logbook` must read the
    /// same instant off it. **Turning that instant into "4 days ago" is not** — that
    /// needs a calendar and a time zone, and two lifters in two zones may then correctly
    /// disagree. The phrasing lives in the app.
    ///
    /// The Open Workout does not count: it has been started, not done.
    ///
    /// `workouts` is oldest first by `startedAt`, so the last match is the newest.
    public func lastTrained(_ workoutDayId: WorkoutDayID) -> Timestamp? {
        workouts.last { $0.workoutDayId == workoutDayId }?.startedAt
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
