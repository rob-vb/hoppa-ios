/// §6.7's Workout list, as data.
///
/// **This is a rule, by the map's test**: every figure on a row falls out of the `Logbook`
/// alone, and two lifters holding the same `Logbook` must read the same row. Only the
/// English, the date and the drawing are the view's (§7.6).
///
/// **The streak is not here**, and that is the same test answering the other way. A week
/// needs a calendar and a time zone, and two lifters in two zones may then correctly
/// disagree about which week one instant fell in — the very clause that kept
/// `RelativeDay` out of this module (ticket 0032). It lives beside it, in `HoppaStore`.
///
/// Like `Summary.swift`, this reads **recorded** outcomes and never re-derives one. §2.4
/// stores the planned Sets and the threshold on the Workout precisely because both are
/// editable, and a history that re-solved them would rewrite itself at every Rep Range
/// edit.

/// One row of §6.7's Workout list: the date, the Day, the counts, and the green line.
public struct HistoryRow: Sendable, Hashable, Identifiable {
    public var id: WorkoutID
    /// **The day the Workout started** (§2.4), which is the date the row prints — a
    /// Workout finished after midnight belongs to the day it began.
    public var startedAt: Timestamp
    public var workoutDayName: String
    /// **Exercises performed** — everything that was not Skipped. The artboard reads
    /// `4 exercises · 12 sets · 1 skipped`, so a skip is counted once, on its own, and
    /// never inside this number.
    public var exerciseCount: Int
    public var setCount: Int
    public var skippedCount: Int
    /// How many Exercises went up, in green. Read off the recorded outcome.
    public var wentUpCount: Int

    public init(
        id: WorkoutID,
        startedAt: Timestamp,
        workoutDayName: String,
        exerciseCount: Int,
        setCount: Int,
        skippedCount: Int,
        wentUpCount: Int
    ) {
        self.id = id
        self.startedAt = startedAt
        self.workoutDayName = workoutDayName
        self.exerciseCount = exerciseCount
        self.setCount = setCount
        self.skippedCount = skippedCount
        self.wentUpCount = wentUpCount
    }
}

extension Rules {

    /// §6.7's Workout list: **reverse date order**, newest first.
    ///
    /// `Logbook.workouts` is finished Workouts, oldest first, so this is that list turned
    /// around. **The Open Workout is not in it**: it has been started, not done — the same
    /// clause that keeps it out of `Logbook.lastTrained`.
    public static func history(in logbook: Logbook) -> [HistoryRow] {
        logbook.workouts.reversed().map { row($0, in: logbook) }
    }

    /// The Workout behind one row, by id. `nil` once it has been deleted (ticket 0048).
    public static func historyRow(_ id: WorkoutID, in logbook: Logbook) -> HistoryRow? {
        logbook.workouts.first { $0.id == id }.map { row($0, in: logbook) }
    }

    /// **The live Day Name while the Workout Day still exists, the stored copy after a
    /// delete** — word for word the rule `summary(of:in:)` applies to an Exercise Name
    /// (§2.7). A rename is a correction of one lift's name, not the invention of a second
    /// lift, so a renamed Day reads its new Name all the way down the list; a deleted one
    /// keeps the Name it had, because nothing else can say what was trained.
    private static func row(_ workout: Workout, in logbook: Logbook) -> HistoryRow {
        let name = logbook.workoutDay(workout.workoutDayId)?.day.name ?? workout.workoutDayName
        let skipped = workout.exercises.filter { $0.state == .skipped }
        return HistoryRow(
            id: workout.id,
            startedAt: workout.startedAt,
            workoutDayName: name,
            exerciseCount: workout.exercises.count - skipped.count,
            setCount: workout.loggedSetCount,
            skippedCount: skipped.count,
            wentUpCount: workout.exercises.filter { $0.outcome?.progressed == true }.count)
    }
}
