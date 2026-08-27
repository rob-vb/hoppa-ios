/// One performed group of reps. **A record of the past, and nothing later changes it.**
///
/// It carries no id: the app only ever appends, so its position is its identity
/// (`SPEC.md` §2.5, and the decision record on ticket 19).
public struct LoggedSet: Codable, Sendable, Hashable {
    public var reps: Int
    /// The weight lifted, **stored here** and not read live off the Exercise. §6.4 lets
    /// the user raise the weight part-way through, so one weight per Exercise would lie
    /// about the Sets before the raise.
    public var weight: Weight
    /// The Microload as performed, where the Exercise had one.
    public var microload: Weight?
    /// Logged under a One-off Weight, yes or no.
    public var oneOff: Bool

    public init(reps: Int, weight: Weight, microload: Weight? = nil, oneOff: Bool = false) {
        self.reps = reps
        self.weight = weight
        self.microload = microload
        self.oneOff = oneOff
    }
}

/// What progression did to one Performed Exercise. Written at Finish, **never recomputed**.
///
/// The threshold and the planned Sets are stored because both are editable, and §6.7
/// draws its dots and its Set grid off them. Solve those live and one edit to a Rep Range
/// rewrites the whole history (`SPEC.md` §2.4).
///
/// **The weight the Exercise stood at when this Workout ended is stored for the same
/// reason** — ticket 0048. The Summary reads a Working Weight live and is right to: it
/// appears between Finish and `DONE`, and nothing can edit an Exercise in between. §6.7
/// opens a Workout from three weeks ago, where the live weight has moved on, so a row
/// reading it would claim a progression that never happened. It is not derivable either:
/// re-adding the Increment reaches an Increment that is editable (§2.8), and any weight
/// the user has since set by hand (§4.3) is past recomputing altogether.
public struct ProgressionOutcome: Codable, Sendable, Hashable {
    public var plannedSets: Int
    public var thresholdReps: Int
    public var progressed: Bool
    /// The Working Weight **as it stood when this Workout ended** — after the progression,
    /// where there was one. Recorded for every performed Exercise and not only for the
    /// ones that went up, because §6.7's One-off row states the Working Weight that
    /// survived and that number goes stale exactly as fast.
    ///
    /// `nil` on an Exercise that had no Working Weight, and on **every Workout finished
    /// by a build older than ticket 0048** — an absent key decodes to `nil`, so old
    /// history reads back with its verdict and without its number.
    public var workingWeightAfter: Weight?
    /// The Microload after Finish, on a mixed-unit pin. `nil` everywhere else.
    public var microloadAfter: Weight?

    public init(
        plannedSets: Int,
        thresholdReps: Int,
        progressed: Bool,
        workingWeightAfter: Weight? = nil,
        microloadAfter: Weight? = nil
    ) {
        self.plannedSets = plannedSets
        self.thresholdReps = thresholdReps
        self.progressed = progressed
        self.workingWeightAfter = workingWeightAfter
        self.microloadAfter = microloadAfter
    }
}

/// One performance of an Exercise inside a Workout.
public struct PerformedExercise: Codable, Sendable, Hashable {
    public var exerciseId: ExerciseID
    /// The Name as it read at the time. A fallback only: Hoppa shows the live Name while
    /// the Exercise still exists, and reaches for this copy after a delete.
    public var name: String
    public var state: ExerciseState
    public var sets: [LoggedSet]
    /// The live One-off choice, which applies to this Workout only. Not the same thing as
    /// the One-off mark on a Set: that is the record, this is the choice.
    public var oneOffWeight: Weight?
    /// `nil` until Finish. An Open Workout cannot carry a result.
    public var outcome: ProgressionOutcome?

    public init(
        exerciseId: ExerciseID,
        name: String,
        state: ExerciseState = .open,
        sets: [LoggedSet] = [],
        oneOffWeight: Weight? = nil,
        outcome: ProgressionOutcome? = nil
    ) {
        self.exerciseId = exerciseId
        self.name = name
        self.state = state
        self.sets = sets
        self.oneOffWeight = oneOffWeight
        self.outcome = outcome
    }
}

/// One performance of a Workout Day.
public struct Workout: Codable, Sendable, Hashable {
    public var id: WorkoutID
    public var programId: ProgramID
    public var workoutDayId: WorkoutDayID
    /// The Workout Day's Name as it read at the time.
    public var workoutDayName: String
    /// The Workout keeps **the day it started**, even when finished the next day.
    public var startedAt: Timestamp
    public var finishedAt: Timestamp?
    /// The Rest Timer: a count-up stopwatch that restarts after each logged Set. A pure
    /// `Timestamp`, so it survives a relaunch and holds no clock of its own.
    public var restStartedAt: Timestamp?
    public var state: WorkoutState
    /// Where the user is standing. Navigating past an Open Exercise means "later".
    public var currentIndex: Int
    public var exercises: [PerformedExercise]

    public init(
        id: WorkoutID,
        programId: ProgramID,
        workoutDayId: WorkoutDayID,
        workoutDayName: String,
        startedAt: Timestamp,
        finishedAt: Timestamp? = nil,
        restStartedAt: Timestamp? = nil,
        state: WorkoutState = .open,
        currentIndex: Int = 0,
        exercises: [PerformedExercise]
    ) {
        self.id = id
        self.programId = programId
        self.workoutDayId = workoutDayId
        self.workoutDayName = workoutDayName
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.restStartedAt = restStartedAt
        self.state = state
        self.currentIndex = currentIndex
        self.exercises = exercises
    }

    public var openExerciseCount: Int {
        exercises.filter { $0.state == .open }.count
    }

    /// Finish is gated: allowed only when no Exercise is Open (`SPEC.md` §3.3).
    public var canFinish: Bool { openExerciseCount == 0 }

    public var loggedSetCount: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }

    /// A Workout with no logged Sets discards without a question.
    public var hasLoggedAnything: Bool { loggedSetCount > 0 }

    public var current: PerformedExercise? {
        exercises.indices.contains(currentIndex) ? exercises[currentIndex] : nil
    }

    /// The next Open Exercise after the current one, wrapping. `nil` when none is Open.
    public func nextOpenIndex(after index: Int) -> Int? {
        guard !exercises.isEmpty else { return nil }
        for step in 1...exercises.count {
            let candidate = (index + step) % exercises.count
            if exercises[candidate].state == .open { return candidate }
        }
        return nil
    }
}
