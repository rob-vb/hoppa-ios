/// §6.7's Workout detail — one finished Workout, read back weeks later.
///
/// > Ticket 0048. Artboards: `design/0015-history/Workout.dc.html` and `Delete.dc.html`.
///
/// **This is not the Summary, and the artboard is what settles it.** §6.5's screen is a
/// verdict on a session that has just ended: a count as the hero, three sections, a
/// condition line under every stayed Exercise and `NEXT TIME` beside every green one.
/// §6.7's is a *record*: "every Set as performed, from the Set's own stored numbers
/// (§2.5), with the progression each Exercise earned stated beside its name." One
/// Exercise after another in the order they were performed, every Set listed, and a
/// verdict on the right.
///
/// That difference is what dissolves the staleness this ticket was written for. **A past
/// Workout states no future.** The Summary's `NEXT TIME` and its `ALL 3 SETS AT 12 →
/// 75 KG` are both statements about the session after this one, and three weeks later
/// that session has already happened — so §6.7 prints neither, and there is nothing left
/// on the screen that can go out of date. What remains is one number about the past, the
/// weight the Exercise ended on, and §2.4 records it (`ProgressionOutcome`).
///
/// Everything here is read off the record and never re-derived, for the reason
/// `Summary.swift` and `History.swift` both state: the Rep Range, the Increment and the
/// Working Weight are all editable, so a screen that solved them live would rewrite its
/// own history at the next edit.

/// What one Exercise earned, as §6.7 states it beside the name.
public enum PastProgression: Sendable, Hashable {
    /// Green: `25 → 27.5 KG`. `to` is `nil` on a Workout finished before ticket 0048
    /// recorded the number — then the row says it went up and states no weight, rather
    /// than inventing one.
    case wentUp(from: PastWeight, to: PastWeight?)
    /// Steel: `STAYED`.
    case stayed
    /// A One-off Weight. **Nothing was ever going to progress** (§4.3), so the chip says
    /// so and states the Working Weight that survived instead of a verdict — the same
    /// shape §6.5 gives it, in the past tense, because this Workout is over.
    case oneOff(stayed: PastWeight?)
    /// **Listed plain**: no warning colour, no icon, no invitation to fix (§6.5).
    case skipped
    /// The Exercise was deleted **mid-Workout**, so Finish wrote no outcome and there is
    /// nothing to state. An Exercise deleted *after* the Workout keeps its outcome and
    /// reads normally — history survives a delete (§2.8).
    case gone
}

/// One weight as §6.7 prints it: the number, and the Microload beside it on a mixed-unit
/// pin. **Never a total** (§4.2, §5.5) — the same value `SummaryWeight` is, under its own
/// name, because a past Workout may not borrow a type whose doc comment is about a screen
/// it is not.
public typealias PastWeight = SummaryWeight

/// One Set, exactly as it was logged.
public struct PastSet: Sendable, Hashable, Identifiable {
    /// Its position, which **is** its identity: a Set carries no id because the app only
    /// ever appends (§2.5).
    public var id: Int
    public var reps: Int
    /// **The Set's own stored numbers** (§2.5), in the unit they were logged in. Not
    /// relabelled to the Exercise's unit the way §6.5 relabels: the Summary is looking at
    /// the same minute it was logged in, and this is looking at three weeks ago, where a
    /// unit may have moved since (§6.6).
    public var weight: PastWeight
    /// **Did this Set meet the threshold?** Read off the recorded `thresholdReps`, which
    /// is why §2.4 stores it. This is the same fact §6.7's Set grid fills a cell with, so
    /// the chart and this screen can never disagree.
    ///
    /// **False on every Set of a One-off**, whatever the reps: it could not have
    /// progressed, and a green column beside a step that never came would be a lie
    /// (§6.7).
    public var metThreshold: Bool
}

/// One Exercise inside a past Workout: the name, the verdict, the Sets.
public struct PastExercise: Sendable, Hashable, Identifiable {
    public var id: ExerciseID { exerciseId }
    public var exerciseId: ExerciseID
    /// The live Name while the Exercise exists, the stored copy after a delete (§2.7).
    public var name: String
    public var progression: PastProgression
    public var sets: [PastSet]
}

/// §6.7's Workout detail, top to bottom.
public struct PastWorkout: Sendable, Hashable {
    /// The list row this screen was opened from — the Day's Name, the date and the counts
    /// under it are that row's, so the list and the screen can never state two different
    /// numbers, and the delete confirm counts what the header counts.
    public var row: HistoryRow
    public var exercises: [PastExercise]

    public var workoutDayName: String { row.workoutDayName }
    public var startedAt: Timestamp { row.startedAt }
}

extension Rules {

    /// §6.7's Workout detail, by id. `nil` once the Workout has been deleted.
    ///
    /// **The Open Workout is not reachable here.** It is not in `workouts`, the same
    /// clause that keeps it out of `Rules.history` and `Logbook.lastTrained`: it has been
    /// started, not done, and it has no outcome to state.
    public static func pastWorkout(_ id: WorkoutID, in logbook: Logbook) -> PastWorkout? {
        guard let workout = logbook.workouts.first(where: { $0.id == id }),
              let row = historyRow(id, in: logbook)
        else { return nil }
        return PastWorkout(
            row: row,
            exercises: workout.exercises.map { pastExercise($0, in: logbook) })
    }

    private static func pastExercise(
        _ performed: PerformedExercise, in logbook: Logbook
    ) -> PastExercise {
        let exercise = logbook.resolvedExercise(performed.exerciseId)
        let threshold = performed.outcome?.thresholdReps
        // A One-off's Sets are never marked, whatever the reps (§6.7). The mark is read
        // off the **Set** and not off the Exercise's live One-off choice, because the
        // Set is the record: `oneOffWeight` is cleared by an edit at the rack (§6.4) and
        // the Sets logged before that edit still were not going anywhere.
        //
        // `Rules.met` since ticket 0049: §6.7's Set grid fills its cells with this same
        // fact, and two copies of it could disagree about one Set.
        let sets = performed.sets.enumerated().map { index, set in
            PastSet(
                id: index,
                reps: set.reps,
                weight: PastWeight(weight: set.weight, microload: set.microload),
                metThreshold: met(set, threshold: threshold))
        }
        return PastExercise(
            exerciseId: performed.exerciseId,
            name: exercise?.name ?? performed.name,
            progression: progression(performed),
            sets: sets)
    }

    /// What the row states, and **every number in it is recorded** — the weight lifted
    /// comes off the Set, the weight it ended on comes off the outcome (§2.4).
    private static func progression(_ performed: PerformedExercise) -> PastProgression {
        if performed.state == .skipped { return .skipped }
        guard let outcome = performed.outcome else { return .gone }

        let after = outcome.workingWeightAfter.map {
            PastWeight(weight: $0, microload: outcome.microloadAfter)
        }

        // A One-off replaces the verdict, because nothing was ever going to progress
        // (§4.3, §6.5). Read off the Sets and not off `oneOffWeight`, for the reason the
        // Set marks are: the choice is live, the Sets are the record.
        if performed.sets.contains(where: \.oneOff) { return .oneOff(stayed: after) }

        guard outcome.progressed, let last = performed.sets.last else { return .stayed }
        return .wentUp(
            from: PastWeight(weight: last.weight, microload: last.microload),
            to: after)
    }
}
