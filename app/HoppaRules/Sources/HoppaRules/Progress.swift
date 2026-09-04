/// §6.7's Progress list, as data — the sibling of `History.swift`.
///
/// > Ticket 0058. History is a list of Workouts; this is a list of Exercises, each across
/// > every Workout it has ever been in. Two questions, two lists, reached the same way.
///
/// **This is a rule, by the map's test**: which Exercises are on it, in what order, with
/// what figures, all falls out of the `Logbook` alone, and two lifters holding the same
/// `Logbook` must read the same list. Only the English and the drawing are the view's
/// (§7.6). The view prints `Upper A · 12 sessions` and `3 went up`; it counts nothing.
///
/// **One source.** Every figure on a row is read off `Rules.exerciseChart`, the same call
/// the screen behind the row draws from — so the mark on the row and the line on the
/// chart can never show two different climbs, and the session count here can never
/// disagree with the points there. There is no second, thinner rule that says *has this
/// been performed*; the chart already answers it, and two rules that must agree about the
/// same door is the thing this map keeps refusing.
///
/// **Charts never join by Name** (§2.7), so neither does this list. A row is an
/// `ExerciseID`, and two Exercises called `Barbell Bench Press` sit apart, each labelled
/// with its Workout Day.

/// One row of §6.7's Progress list: the Exercise, its Day, the counts, and the mark.
///
/// **If it is in the list, it has been performed at least once.** There is no
/// `hasChart` flag to keep in step: an Exercise with nothing to plot is not a row, which
/// is `ExerciseChart.hasSpark` applied at the list rather than at the card.
public struct ProgressRow: Sendable, Hashable, Identifiable {
    public var id: ExerciseID
    /// The **live** Name (§2.7). A rename is a correction of one lift's name, not the
    /// invention of a second lift, so a renamed Exercise reads its new Name here.
    public var name: String
    /// The live Day Name, for the same reason — and it is what tells two Exercises with
    /// one Name apart.
    public var workoutDayName: String
    /// Sessions this Exercise was **performed** in: one per point on its chart. A skip
    /// makes no point (§6.7), so it is not a session here either.
    public var sessionCount: Int
    /// How many of those sessions went up, in green. Read off the recorded outcomes.
    public var timesUp: Int
    /// `ExerciseChart.sparkline` — the chart's own line, in fractions of a box the view
    /// owns. Decoration on a row that is itself the door, not a control of its own.
    public var sparkline: [SparkPoint]

    public init(
        id: ExerciseID,
        name: String,
        workoutDayName: String,
        sessionCount: Int,
        timesUp: Int,
        sparkline: [SparkPoint]
    ) {
        self.id = id
        self.name = name
        self.workoutDayName = workoutDayName
        self.sessionCount = sessionCount
        self.timesUp = timesUp
        self.sparkline = sparkline
    }
}

extension Rules {

    /// §6.7's Progress list: every Exercise that has been performed at least once, in
    /// **program order** — Programs, then Days, then position in the Day.
    ///
    /// Program order and not recency, because this is a list *about the Program*: a
    /// lifter looking for his bench finds it where he put it. History is the list that
    /// answers *when*.
    ///
    /// What is not in it, and why, without a branch for any of them:
    ///
    /// - **The Open Workout.** `exerciseChart` reads finished `workouts` only, so a
    ///   session in progress adds no point and changes no row (the same clause that
    ///   keeps it out of `history`).
    /// - **A deleted Exercise.** `exerciseChart` is `nil` for it, and there is no Day to
    ///   walk it under anyway. Its Sets survive in §6.7's Workout detail (§2.8).
    /// - **A Skipped-only Exercise.** A skip makes no point, so `hasSpark` is false.
    public static func progress(in logbook: Logbook) -> [ProgressRow] {
        logbook.programs.flatMap { program in
            program.days.flatMap { day in
                day.exercises.compactMap { exercise in
                    guard let chart = exerciseChart(exercise.id, in: logbook), chart.hasSpark
                    else { return nil }
                    return ProgressRow(
                        id: exercise.id,
                        name: chart.name,
                        workoutDayName: day.name,
                        sessionCount: chart.points.count,
                        // `totals` is present exactly where `hasSpark` is: both need one
                        // point. The fallback is unreachable and states the same fact.
                        timesUp: chart.totals?.timesUp ?? 0,
                        sparkline: chart.sparkline)
                }
            }
        }
    }
}
