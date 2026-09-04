/// §6.7's per-Exercise chart, as data — the one screen in this app that draws a series.
///
/// > Ticket 0049. Artboards: `design/0015-history/Main.dc.html`, `Plateau.dc.html` and
/// > `Mixed.dc.html`; the rejected figures-over-points board is `ChartLabels.dc.html`.
///
/// **The whole series is a rule**, by the map's test: every point, every filled cell and
/// every figure at the foot falls out of the `Logbook` alone, and two lifters holding the
/// same `Logbook` must read the same chart. Only the pixels, the English and the dates
/// are the view's (§7.6) — a date needs a calendar and a time zone, which is the same
/// clause that keeps the streak in `HoppaStore`.
///
/// That is not a tidiness argument. §6.7 needs weeks of Workouts before it says anything,
/// and the phone has none; putting the series here makes a fifteen-session screen
/// **checkable on this machine**, the way `Summary.swift` made §6.5 checkable.
///
/// Like `Summary.swift`, `History.swift` and `PastWorkout.swift`, it reads **recorded**
/// outcomes and re-derives none. §2.4 stores the planned Sets and the threshold on the
/// Workout precisely because both are editable, and a chart that re-solved them would
/// repaint fifteen weeks of Set cells at the next Rep Range edit.
///
/// **Charts never join by Name** (§2.7). This reads one `ExerciseID`, so `Barbell Bench
/// Press` in Upper A and in Upper B can never splice into one line — not by policy, but
/// because there is no way to ask for it.

/// One weight as the chart prints it: the number, and the Microload beside it on a
/// mixed-unit pin. **Never a total** (§4.2, §5.5) — the same value `SummaryWeight` is,
/// under its own name, for the reason `PastWeight` is.
public typealias ChartWeight = SummaryWeight

/// One session on the line.
///
/// A **Skipped** Exercise makes none of these: §6.7 draws *nothing at all* for it, no
/// point and no gap marker, and the wider spacing the real-time x axis already gives it
/// is the whole of what the screen says.
public struct ChartPoint: Sendable, Hashable, Identifiable {
    public var id: WorkoutID
    /// **The day the Workout started** (§2.4) — the x axis is real time, so a missed week
    /// is already a wider gap and needs no marker of its own.
    public var startedAt: Timestamp
    /// Where the **line** stands for this session: the Working Weight this Exercise was
    /// performed at, or, on a mixed-unit pin, the Microload (see `ExerciseChart.axisUnit`).
    ///
    /// **A One-off is never here**, which is why the line never dips: a One-off Weight
    /// never became the Working Weight (§4.3), so the line holds the weight that survived
    /// and the hollow marker below carries what was actually lifted.
    public var line: Weight
    /// A **One-off Weight**: the weight actually lifted, off the line, tied to this
    /// session by a dotted drop and labelled `ONE-OFF`. `nil` on every other session.
    public var oneOff: Weight?
    /// Filled green where this session progressed, filled steel where it stayed. Read off
    /// the **recorded** outcome, so it is the same fact §6.5 and §6.7's Workout detail
    /// state in words.
    public var progressed: Bool
    /// The Set grid's column: one entry per logged Set, true where that Set met the
    /// threshold of its Progression Mode. **Three filled cells *is* §4.1**, so the grid
    /// answers *why did it not go up* with no words and no advice.
    ///
    /// **Never true on a One-off's column**, whatever the reps — the same fact, and the
    /// same line of code, as `PastSet.metThreshold`. A full green column beside a step
    /// that never came would be a lie.
    public var setMarks: [Bool]
    /// The exact rep counts, for the `Last sessions` list under the grid — so nothing on
    /// this screen lives only in a picture.
    public var reps: [Int]
    /// The weight as that list prints it: **the Set's own stored numbers** (§2.5), in the
    /// unit they were logged in, One-off included. Not relabelled to the Exercise's unit
    /// the way §6.5 relabels — this is looking at three weeks ago, and a unit may have
    /// moved since (§6.6).
    public var performed: ChartWeight

    /// Did the whole session meet its threshold? The grid says it cell by cell; this is
    /// the same fact for a reader who wants the column in one word.
    public var metEverySet: Bool { !setMarks.isEmpty && !setMarks.contains(false) }
}

/// The **NEXT** step: a dashed step from the last point to a hollow marker at the weight
/// the Exercise carries now.
///
/// **Solid is lifted; dashed is applied but not yet performed.** Hoppa applies the
/// progression at Finish (§4.1), so after a session that went up the hero is already one
/// step above the end of the line; without this step the two contradict each other.
public struct ChartNextStep: Sendable, Hashable {
    /// The weight the Exercise carries now — the Working Weight, or the Microload on a
    /// mixed-unit pin.
    public var to: Weight
    /// **Green where Hoppa moved it, steel where the user did.**
    ///
    /// §6.7 writes the step as *where the last session progressed*, and that is the only
    /// case the artboards draw. It is not the only case that opens the gap: §4.3 lets the
    /// user set a weight by hand, and then the hero contradicts the end of the line for a
    /// reason no green step should claim credit for. **Judgment call, ticket 0049**: draw
    /// the step whenever the two differ, and let the colour say which of the two moved it
    /// — steel is already this chart's word for *not a progression*, so the only new word
    /// is the step's own label, `NEXT` against `NOW`. A hand-lowered weight therefore
    /// draws a steel step downwards, which is true; *the line never dips* is a rule about
    /// One-offs, not about §4.3.
    public var isProgression: Bool
}

/// The chip under the heroes: `ALL 3 SETS AT 12 → 82.5 KG`.
///
/// **Read live, not recorded**, exactly as `SummaryCondition.target` is: it is a
/// statement about the next session, and the next session runs on the Exercise as it
/// stands now.
public struct ChartTarget: Sendable, Hashable {
    public var sets: Int
    public var reps: Int
    /// Where the weight goes if the condition is met. On a mixed-unit pin the Microload
    /// is the half that moves, and the pin only joins it on a roll-up (§4.2).
    public var to: ChartWeight
}

/// The three figures the screen ends on.
public struct ChartTotals: Sendable, Hashable {
    /// The first plotted value, and the day it was lifted.
    public var first: Weight
    public var firstDate: Timestamp
    /// **What the Exercise carries now, minus that** — the current weight and not the
    /// last one performed, so it agrees with the hero and with the end of the dashed
    /// step. Negative where the user has lowered it by hand (§4.3).
    public var gain: Weight
    /// How many sessions went up. Read off the recorded outcomes.
    public var timesUp: Int
    /// Mixed-unit pin only: has the pin itself moved since the first session? The
    /// reference case is `90 LBS · PIN, UNCHANGED`, and it is a fact and not a caption,
    /// so a pin that *has* moved must not read that way.
    public var pinMoved: Bool
}

/// The y axis: where it starts, where it ends, and the hairlines in between.
///
/// The scale is a rule for the same reason the series is — it is arithmetic on `Weight`,
/// it is exact, and two lifters must read the same ladder. The view turns it into pixels.
public struct ChartScale: Sendable, Hashable {
    /// The bottom and the top of the plot, **padded** so no marker sits on an edge.
    public var low: Weight
    public var high: Weight
    /// The gridlines, low to high. Clean steps of the unit, four or fewer.
    public var ticks: [Weight]

    /// Where a value sits between `low` and `high`, `0` at the bottom. The one place a
    /// `Double` is allowed near a weight: it is a screen coordinate and never a weight.
    public func fraction(of value: Weight) -> Double {
        let span = high.hundredths - low.hundredths
        guard span > 0 else { return 0.5 }
        return Double(value.hundredths - low.hundredths) / Double(span)
    }
}

/// §6.7's per-Exercise chart, top to bottom.
public struct ExerciseChart: Sendable, Hashable {
    public var exerciseId: ExerciseID
    public var name: String
    public var equipment: EquipmentType
    public var mode: ProgressionMode
    public var plannedSets: Int
    public var repRange: RepRange
    /// What one Set must reach — the top of the range, or its bottom under Microloading
    /// (§4.1). The Set grid's legend states it: `SET AT 12`.
    public var thresholdReps: Int
    /// The hero. On a mixed-unit pin the two stack — `90 LBS` over `+ 3 KG` — each with
    /// its own label, **converting nothing** (§5.1).
    public var hero: ChartWeight
    /// True where the two numbers are in different units and never convert.
    public var isMixedUnitPin: Bool
    /// **What the line plots, when that is not the Working Weight.**
    ///
    /// A mixed-unit pin has no single number to plot, so the chart plots whichever number
    /// actually moves — for §6.7's reference case, a 90 lbs stack whose pin has not moved
    /// in fifteen weeks, that is the Microload, and the axis says so: `+ KG`. `nil`
    /// everywhere else, where the line is the Working Weight and needs no label.
    public var axisUnit: WeightUnit?
    /// Oldest first. Empty until the Exercise has been performed once.
    public var points: [ChartPoint]
    /// `nil` when the plot is empty.
    public var scale: ChartScale?
    public var next: ChartNextStep?
    /// `nil` where the weight has nowhere to go — then `blocker` says which of §4.1's
    /// five stopped it, exactly as §6.5's `STAYED` row does.
    public var target: ChartTarget?
    public var blocker: ProgressionBlocker?
    /// `nil` until the Exercise has been performed once.
    public var totals: ChartTotals?

    /// **An Exercise gets a line once it has two** (§6.7's empty state). One point is a
    /// dot and not a climb, and the screen says so in words instead of drawing it.
    public var hasLine: Bool { points.count >= 2 }

    /// The `Last sessions` list: the four most recent, newest first. Four because the
    /// grid abstracts the reps to met / not met, and this carries the exact numbers for
    /// the sessions a lifter can still remember.
    public var lastSessions: [ChartPoint] { points.suffix(4).reversed() }
}

extension Rules {

    /// §6.7's chart for one Exercise. `nil` once the Exercise has been deleted — the
    /// chart is a screen about an Exercise that exists, and history outliving it (§2.8)
    /// is `PastWorkout`'s job, not this one.
    public static func exerciseChart(_ id: ExerciseID, in logbook: Logbook) -> ExerciseChart? {
        guard let exercise = logbook.resolvedExercise(id) else { return nil }

        // The mixed-unit pin is the only case where the line is not the Working Weight.
        let plotsMicroload = exercise.isMixedUnitPin
        let points = logbook.workouts.compactMap {
            chartPoint($0, id, exercise, plotsMicroload: plotsMicroload)
        }

        // The weight the Exercise carries **now** — what the hero states, what the dashed
        // step reaches, and what the gain is measured against.
        let current = plotsMicroload ? exercise.microload : exercise.workingWeight

        var next: ChartNextStep?
        if let last = points.last, let current {
            let now = current.relabelled(last.line.unit)
            if now != last.line {
                next = ChartNextStep(to: now, isProgression: last.progressed)
            }
        }

        var target: ChartTarget?
        var blocker: ProgressionBlocker?
        if exercise.mode == .none {
            target = nil
            blocker = nil
        } else if let move = progressionMove(for: exercise, inventory: logbook.plateInventory) {
            target = ChartTarget(
                sets: exercise.plannedSets,
                reps: exercise.thresholdReps,
                to: ChartWeight(
                    weight: move.workingWeight,
                    microload: plotsMicroload ? move.microload : nil))
        } else {
            blocker = progressionBlocker(for: exercise)
        }

        var totals: ChartTotals?
        if let first = points.first, let last = points.last {
            let ends = (next?.to ?? last.line).relabelled(first.line.unit)
            totals = ChartTotals(
                first: first.line,
                firstDate: first.startedAt,
                gain: ends - first.line,
                timesUp: points.filter(\.progressed).count,
                // The pin is the Set's own weight, so this asks the record and not the
                // live Exercise for where the pin started.
                pinMoved: plotsMicroload
                    && exercise.workingWeight.map {
                        $0.relabelled(first.performed.weight.unit) != first.performed.weight
                    } ?? false)
        }

        return ExerciseChart(
            exerciseId: id,
            name: exercise.name,
            equipment: exercise.equipment,
            mode: exercise.mode,
            plannedSets: exercise.plannedSets,
            repRange: exercise.repRange,
            thresholdReps: exercise.thresholdReps,
            hero: ChartWeight(
                weight: exercise.workingWeight ?? .zero(exercise.unit),
                microload: plotsMicroload ? exercise.microload : nil),
            isMixedUnitPin: plotsMicroload,
            axisUnit: plotsMicroload ? exercise.inventoryUnit : nil,
            points: points,
            scale: scale(points: points, next: next?.to),
            next: next,
            target: target,
            blocker: blocker,
            totals: totals)
    }

    /// One session, or `nil` where the Workout has nothing to plot.
    ///
    /// Four ways to plot nothing, and each is a statement:
    ///
    /// - **The Exercise was not in that Workout.** It was added later, or the Workout ran
    ///   a different Day.
    /// - **It was Skipped.** §6.7: *nothing at all. No point, no gap marker.*
    /// - **Nothing was logged**, so there is no weight the session can be said to have
    ///   been performed at.
    /// - **There is no recorded outcome** — the Exercise was deleted mid-Workout, so
    ///   Finish wrote none (§2.8). Without it there is no threshold, and a Set grid
    ///   filled against a live Rep Range is the defect this whole file avoids.
    private static func chartPoint(
        _ workout: Workout,
        _ id: ExerciseID,
        _ exercise: ResolvedExercise,
        plotsMicroload: Bool
    ) -> ChartPoint? {
        guard let performed = workout.exercises.first(where: { $0.exerciseId == id }),
              performed.state != .skipped,
              let outcome = performed.outcome,
              let last = performed.sets.last
        else { return nil }

        // Read off the **Set** and not off the Exercise's live One-off choice, for the
        // reason `PastWorkout` reads it there: `oneOffWeight` is cleared by an edit at
        // the rack (§6.4), and the Sets logged before that edit still were not going
        // anywhere.
        let isOneOff = performed.sets.contains(where: \.oneOff)

        let line: Weight
        var oneOff: Weight?
        if plotsMicroload {
            // The line is the Microload, and **a One-off moves the pin, not the
            // Microload** — so a One-off makes no marker on a mixed-unit chart, because
            // the number this chart plots did not change. The session's grid column
            // stays empty, which is where the chart still says a One-off happened.
            guard let microload = last.microload else { return nil }
            line = microload
        } else if isOneOff {
            // **The Working Weight that survived**, which §2.4 records precisely because
            // it goes stale (ticket 0048). Where it was not recorded — a Workout finished
            // by a build older than that — Hoppa does not know where the line stood, so
            // it plots nothing rather than inventing a height for it.
            guard let survived = outcome.workingWeightAfter else { return nil }
            line = survived.relabelled(exercise.unit)
            oneOff = last.weight.relabelled(exercise.unit)
        } else {
            line = last.weight.relabelled(exercise.unit)
        }

        return ChartPoint(
            id: workout.id,
            startedAt: workout.startedAt,
            line: line,
            oneOff: oneOff,
            progressed: outcome.progressed,
            setMarks: performed.sets.map { met($0, threshold: outcome.thresholdReps) },
            reps: performed.sets.map(\.reps),
            performed: ChartWeight(weight: last.weight, microload: last.microload))
    }

    /// **Did this Set meet the threshold?** The one copy of the fact §6.7's Set grid
    /// fills a cell with and §6.7's Workout detail turns a rep count green — so the two
    /// screens can never disagree about the same Set.
    ///
    /// **False on every Set of a One-off**, whatever the reps: it could not have
    /// progressed (§4.3).
    static func met(_ set: LoggedSet, threshold: Int?) -> Bool {
        guard let threshold, !set.oneOff else { return false }
        return set.reps >= threshold
    }

    /// The y axis: a padded range, and clean steps of the unit inside it.
    ///
    /// Everything a marker can reach decides the range — the line, every One-off below
    /// it, and the hollow marker the dashed step ends at — so nothing is ever drawn off
    /// the top or the bottom of the plot.
    static func scale(points: [ChartPoint], next: Weight?) -> ChartScale? {
        guard let unit = points.first?.line.unit else { return nil }
        var values = points.map(\.line.hundredths)
        values += points.compactMap(\.oneOff?.hundredths)
        if let next { values.append(next.hundredths) }

        var low = values.min() ?? 0
        var high = values.max() ?? 0
        // 18% of the spread, so no marker sits on an edge. A flat series has no spread to
        // take a fraction of, so it gets one whole unit of air either way.
        let spread = high - low
        let pad = spread == 0 ? 100 : max(1, spread * 18 / 100)
        low -= pad
        high += pad

        // Steps a lifter reads without decoding: quarters and halves for a Microload,
        // then the plate sizes. Four gridlines at most — five would fence the line in.
        let ladder = [25, 50, 100, 250, 500, 1_000, 2_000, 2_500, 5_000, 10_000]
        let span = high - low
        let step = ladder.first { span * 2 <= $0 * 9 } ?? ladder[ladder.count - 1]

        var ticks: [Weight] = []
        var value = ceilMultiple(low, step)
        while value <= high {
            ticks.append(Weight(hundredths: value, unit: unit))
            value += step
        }
        return ChartScale(
            low: Weight(hundredths: low, unit: unit),
            high: Weight(hundredths: high, unit: unit),
            ticks: ticks)
    }

    /// The smallest multiple of `step` at or above `value`. Written out because `value`
    /// goes negative — a Microload chart padded below zero — and Swift's `/` truncates
    /// towards zero, which would put the first gridline below the floor of the plot.
    private static func ceilMultiple(_ value: Int, _ step: Int) -> Int {
        let quotient = value / step
        let rounded = (value % step > 0) ? quotient + 1 : quotient
        return rounded * step
    }
}

// MARK: - The sparkline on a Progress row (§6.7 — ticket 0050, moved at ticket 0058)

/// One point of the mark a Progress row carries, in fractions of its box.
///
/// **Fractions and not points**, for the reason `ChartScale.fraction(of:)` answers in
/// fractions: a `Weight` is exact and a pixel is not, so the rule stops at the last
/// number that is still a fact about the Logbook, and the view multiplies it by a box it
/// owns. The one place a `Double` is allowed near a weight, twice over.
public struct SparkPoint: Sendable, Hashable {
    /// `0` at the first session, `1` at the last. **Real time** (§6.7), the same axis the
    /// chart's own line runs on — so a missed week is a wider gap on the row too.
    public var x: Double
    /// `0` at the bottom of the plot, `1` at the top, on **the chart's own `ChartScale`**.
    public var y: Double
}

extension ExerciseChart {

    /// §6.7's sparkline: the mark on a Progress row, beside the Exercise's figures.
    ///
    /// **It is the chart's own line, and nothing else.** Same points, same real-time x
    /// axis, same padded `ChartScale` — so the mark on the row is a small true copy of
    /// the line on the screen it opens, and the two can never draw two different climbs.
    /// The view scales it into 44 × 16 and strokes it 2 px steel.
    ///
    /// **What it leaves out, and why** (ticket 0050, and still true on the row). The
    /// One-off markers, the dashed NEXT step and the gridlines are all on the chart and
    /// none of them is here. A hollow marker at this size is a smudge, and the step is a
    /// statement about the next session that the chart has room to label and a row does
    /// not. What is left is the one thing a sparkline is for: the shape of the climb.
    ///
    /// Ticket 0050 drew it on the Exercise card as the chart's door. Ticket 0058 moved it
    /// onto the Progress row, where the whole row is the door and the mark is decoration.
    public var sparkline: [SparkPoint] {
        guard let scale, let first = points.first?.startedAt, let last = points.last?.startedAt
        else { return [] }
        let span = last - first
        return points.map {
            SparkPoint(
                // A single session, or several inside one day, have no span to divide by.
                // They land at the end of the box, where the newest session belongs.
                x: span > 0 ? ($0.startedAt - first) / span : 1,
                y: scale.fraction(of: $0.line))
        }
    }

    /// **Is this Exercise a row of the Progress list?**
    ///
    /// The gate ticket 0050 set, kept word for word at ticket 0058 and applied one room
    /// further up: *no sparkline, no door.* An Exercise with nothing to plot is not a row
    /// of `Rules.progress`, so a door to an empty room is never offered — which is §6.7's
    /// own empty-state rule, applied at the list. A Program the user is still building has
    /// an empty Progress page and nothing else changes.
    ///
    /// **One session is enough**, though it is only a dot. §6.7's *two sessions* is the
    /// rule for the **line**, not for the screen: at one session the chart still states
    /// the hero, the chip and the condition for the next step, which is the whole of what
    /// a lifter one session in can be told. Gating the row at two would build a screen
    /// with no way to reach it. The two gates were never the same gate, and moving the
    /// door did not join them.
    public var hasSpark: Bool { !points.isEmpty }
}
