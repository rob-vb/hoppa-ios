import HoppaRules

// Exact weights, written the way a person writes them. The parser is the only way in,
// so `Double` never touches a test either.
func kg(_ text: String) -> Weight { Weight(decimalString: text, unit: .kg)! }
func lbs(_ text: String) -> Weight { Weight(decimalString: text, unit: .lbs)! }

/// The user's own rack: the standard kg Inventory with the Microplates he owns switched
/// on. The prototype fixture also held a **15 kg plate**, which does not exist
/// (`SPEC.md` §7.3, defect 4 of §8.2), and it is not here.
func rackKg(microplates: [String] = ["1", "0.75", "0.5", "0.25"]) -> PlateInventory {
    var inventory = PlateInventory.standard(.kg)
    for size in microplates { inventory.setPlate(kg(size), on: true) }
    return inventory
}

enum Ids {
    static let program = ProgramID(1)
    static let upperA = WorkoutDayID(2)
    static let smith = ExerciseID(10)
    static let row = ExerciseID(11)
    static let pulldown = ExerciseID(12)
    static let press = ExerciseID(13)
    static let chin = ExerciseID(14)
}

/// Upper A, exactly as the logging prototype's `template()` holds it — minus the two
/// things §8.2 calls wrong: `blockSize` is a **Stack Step**, and the lat pulldown's
/// `microplates: 1` count is a **Microload of 1 kg**.
func upperAExercises() -> [Exercise] {
    [
        Exercise(
            id: Ids.smith, name: "Smith machine bench press", equipment: .smith,
            plannedSets: 3, repRange: RepRange(8, 12),
            workingWeight: kg("72.5"), increment: kg("2.5"),
            microloadingIncrement: kg("0.25"),
            storedBaseWeight: kg("15")),
        Exercise(
            id: Ids.row, name: "Barbell row", equipment: .barbell,
            plannedSets: 3, repRange: RepRange(8, 10),
            workingWeight: kg("60"), increment: kg("2.5"),
            microloadingIncrement: kg("0.25")),
        Exercise(
            id: Ids.pulldown, name: "Lat pulldown", equipment: .stack,
            ownWeightUnit: .lbs,
            plannedSets: 3, repRange: RepRange(10, 12),
            workingWeight: lbs("100"), increment: lbs("10"),
            microloadingIncrement: kg("1"),
            modeOverride: .microloading,
            storedStackStep: lbs("10"),
            microload: kg("1")),
        Exercise(
            id: Ids.press, name: "Dumbbell shoulder press", equipment: .dumbbell,
            plannedSets: 3, repRange: RepRange(8, 12),
            workingWeight: kg("22.5"), increment: kg("2.5"),
            microloadingIncrement: kg("0.25")),
        Exercise(
            id: Ids.chin, name: "Weighted chin-up", equipment: .bodyweight,
            plannedSets: 3, repRange: RepRange(6, 8),
            workingWeight: kg("15"), increment: kg("2.5"),
            microloadingIncrement: kg("0.25"))
    ]
}

func upperALogbook() -> Logbook {
    Logbook(
        nextId: 100,
        plateInventory: rackKg(),
        programs: [
            Program(
                id: Ids.program, name: "Upper / Lower",
                defaultWeightUnit: .kg, mode: .progressiveOverload,
                days: [WorkoutDay(id: Ids.upperA, name: "Upper A", exercises: upperAExercises())])
        ])
}

/// A Logbook plus a fake wall clock, so a walkthrough reads as a list of taps.
struct Session {
    var book: Logbook
    /// Any fixed instant. The rules hold no clock, so the value only has to be stable.
    var clock: Timestamp = 1_770_000_000

    init(_ book: Logbook = upperALogbook()) { self.book = book }

    mutating func send(_ action: Action) {
        clock += 9
        book = Rules.reduce(book, action, at: clock)
    }

    mutating func send(_ actions: [Action]) {
        for action in actions { send(action) }
    }

    mutating func start(_ day: WorkoutDayID = Ids.upperA) {
        send(.startWorkout(programId: Ids.program, workoutDayId: day))
    }

    /// Logs `count` Sets. Without `reps`, each lands on Target Reps — the top of the
    /// Rep Range, which is what the `LOG n REPS` button is pre-filled with.
    mutating func logSets(_ count: Int, reps: Int? = nil) {
        for _ in 0..<count {
            let value = reps ?? current?.targetReps ?? 0
            send(.logSet(reps: value))
        }
    }

    var workout: Workout? { book.openWorkout }

    var current: ResolvedExercise? {
        guard let performed = book.openWorkout?.current else { return nil }
        return book.resolvedExercise(performed.exerciseId)
    }

    func resolved(_ id: ExerciseID) -> ResolvedExercise? { book.resolvedExercise(id) }

    func stored(_ id: ExerciseID) -> Exercise? { book.exercise(id) }

    /// The Performed Exercise for `id`, from the Open Workout or the last finished one.
    func performed(_ id: ExerciseID) -> PerformedExercise? {
        let source = book.openWorkout ?? book.workouts.last
        return source?.exercises.first { $0.exerciseId == id }
    }

    var lastFinished: Workout? { book.workouts.last }

    /// The index of an Exercise inside the Open Workout.
    func index(of id: ExerciseID) -> Int {
        book.openWorkout?.exercises.firstIndex { $0.exerciseId == id } ?? 0
    }

    mutating func goTo(_ id: ExerciseID) { send(.selectExercise(index: index(of: id))) }
}
