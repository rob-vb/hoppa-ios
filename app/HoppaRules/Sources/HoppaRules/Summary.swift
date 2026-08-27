/// §6.5's Workout Summary, as data.
///
/// **This is a rule, by ticket 27's test**: it decides its three sections, every
/// condition line and the added plate from the `Logbook` alone, and two lifters holding
/// the same `Logbook` must read the same summary. Only the English and the drawing are
/// the view's (§7.6).
///
/// It reads a **recorded** `ProgressionOutcome` and never re-derives one. §2.4 stores
/// the planned Sets and the threshold on the Workout precisely because both are
/// editable, and §2.5's defect — a screen recomputing off a Rep Range that has moved
/// since — is the thing this file must not repeat.

/// One weight as the Summary prints it: the number, and the Microload beside it on a
/// mixed-unit pin. **Never a total** (§4.2, §5.5) — the two numbers keep their own
/// units and Hoppa converts nothing the user can see.
public struct SummaryWeight: Sendable, Hashable {
    public var weight: Weight
    /// `nil` on everything except a mixed-unit pin.
    public var microload: Weight?

    public init(weight: Weight, microload: Weight? = nil) {
        self.weight = weight
        self.microload = microload
    }
}

/// Why a completed Exercise that met its condition still did not move.
///
/// §4.1 counts four of these and §6.6 asks the Summary to state the condition "in place
/// of the green line". They are **not one sentence**: an Exercise waiting for a weight
/// and an Exercise stranded by a switched-off Microplate send the user to two different
/// screens, and §5.2's principle is that Hoppa states its condition where the user
/// stands. The fifth is Progressive Overload with no Increment typed yet.
public enum ProgressionBlocker: Sendable, Hashable {
    /// No Working Weight — §6.6's Re-weigh list is the other end of it.
    case noWorkingWeight
    /// Progressive Overload with no Increment.
    case noIncrement
    /// Microloading with no Microplate picked yet (§5.2's empty state).
    case noMicroplate
    /// The Microplate this Exercise names is switched off (§6.6).
    case stranded
    /// The one refused combination: Microloading on an Exercise carrying its own unit,
    /// where that unit is not the rack's and there is no pin to hang a Microload on
    /// (§2.6).
    case unitMismatch
    /// A mixed-unit pin with no Stack Step typed: the roll-up has nothing to roll into
    /// (§4.2), so the Microload cannot move.
    case noStackStep
}

/// What a `STAYED` row says under the name. **Every stayed Exercise carries one, in
/// every state** (§6.5).
public enum SummaryCondition: Sendable, Hashable {
    /// A One-off Weight: nothing was ever going to progress, so the row states the
    /// Working Weight that survives instead of a condition. `nil` where the Exercise has
    /// no Working Weight at all.
    case oneOff(stays: Weight?)
    /// The logging screen's rule chip, restated: `ALL 3 SETS AT 12 → 75 KG`.
    case target(sets: Int, reps: Int, to: SummaryWeight)
    /// The condition was met, or could be, but there is nowhere to put the plate.
    case blocked(ProgressionBlocker, sets: Int, reps: Int)
    /// The Exercise was deleted mid-Workout, so there is no Rep Range left to state a
    /// condition from. History survives the delete; the condition does not (§2.7).
    case gone
}

/// A `WENT UP` row: the plate chip, the name, `72.5 KG → 75 KG` and `NEXT TIME`.
public struct SummaryWentUp: Sendable, Hashable, Identifiable {
    public var id: ExerciseID { exerciseId }
    public var exerciseId: ExerciseID
    public var name: String
    /// **The added plate** — what §6.5 paints the chip with, and what ticket 39 fires
    /// the burst from. `nil` where the progression does not put a nameable plate on:
    /// then §7.3's own fallback applies and the chip is steel.
    public var addedPlate: Weight?
    /// The weight that was lifted.
    public var from: SummaryWeight
    /// The Working Weight Hoppa has **already** written (§4.1). There is no Accept and
    /// no Undo, because this is a statement of fact and not an offer (§7.6).
    public var to: SummaryWeight
}

/// A `STAYED` row: the name, the weight actually lifted with its reps, and the condition.
public struct SummaryStayed: Sendable, Hashable, Identifiable {
    public var id: ExerciseID { exerciseId }
    public var exerciseId: ExerciseID
    public var name: String
    /// **The weight actually lifted, not the Working Weight** (§6.5) — which is the
    /// whole point on a One-off row. `nil` when nothing was logged.
    public var performed: SummaryWeight?
    public var reps: [Int]
    public var condition: SummaryCondition
}

/// A `SKIPPED` row. **Listed plain** (§6.5): no warning colour, no icon, no invitation
/// to fix.
public struct SummarySkipped: Sendable, Hashable, Identifiable {
    public var id: ExerciseID { exerciseId }
    public var exerciseId: ExerciseID
    public var name: String
}

/// §6.5's screen, top to bottom.
public struct WorkoutSummary: Sendable, Hashable {
    public var workoutDayName: String
    public var wentUp: [SummaryWentUp]
    public var stayed: [SummaryStayed]
    public var skipped: [SummarySkipped]
    /// `finishedAt - startedAt`, floored at zero. Seconds, because the clock is the
    /// app's and a rule holds none (`Timestamp`).
    public var durationSeconds: Int
    public var setCount: Int
    /// **The one number that converts** (§5.1), to the Program's default unit.
    public var volume: Weight

    /// The hero, and exactly what ticket 39's confetti scales to.
    public var count: Int { wentUp.count }

    /// `n Exercises performed` on the zero screen — everything that was not skipped.
    public var performedCount: Int { wentUp.count + stayed.count }
}

extension Rules {

    /// Read §6.5's screen off a finished Workout.
    ///
    /// The two weights on a `WENT UP` row come from two different places on purpose.
    /// **`from` is the last logged Set's own weight**, which is a record of the past and
    /// cannot move again (§2.5); §6.4 lets the user raise the weight part-way through,
    /// and a raise writes the Working Weight, so the last Set is what the Exercise stood
    /// at when Finish read it. **`to` is the Exercise's live Working Weight**, because
    /// Finish has already written it there and this screen is what says so.
    public static func summary(of workout: Workout, in logbook: Logbook) -> WorkoutSummary {
        var wentUp: [SummaryWentUp] = []
        var stayed: [SummaryStayed] = []
        var skipped: [SummarySkipped] = []

        for performed in workout.exercises {
            let exercise = logbook.resolvedExercise(performed.exerciseId)
            // The live Name while the Exercise exists, the stored copy after a delete
            // (§2.7).
            let name = exercise?.name ?? performed.name

            if performed.state == .skipped {
                skipped.append(SummarySkipped(exerciseId: performed.exerciseId, name: name))
                continue
            }

            if performed.outcome?.progressed == true,
               let exercise,
               let working = exercise.workingWeight,
               let last = performed.sets.last {
                wentUp.append(SummaryWentUp(
                    exerciseId: performed.exerciseId,
                    name: name,
                    addedPlate: addedPlate(for: exercise),
                    from: SummaryWeight(
                        weight: last.weight.relabelled(exercise.unit),
                        microload: exercise.isMixedUnitPin ? last.microload : nil),
                    // **The recorded weight, not the live one** (§2.4, ticket 0048).
                    // On this screen they are the same number — the Summary stands
                    // between Finish and `DONE` and nothing can edit an Exercise in
                    // between — so the fallback is only for a Workout finished by a
                    // build that recorded none.
                    to: SummaryWeight(
                        weight: performed.outcome?.workingWeightAfter ?? working,
                        microload: exercise.isMixedUnitPin
                            ? (performed.outcome?.microloadAfter ?? exercise.microload)
                            : nil)))
                continue
            }

            stayed.append(SummaryStayed(
                exerciseId: performed.exerciseId,
                name: name,
                performed: performedWeight(performed, exercise),
                reps: performed.sets.map(\.reps),
                condition: condition(performed, exercise, logbook.plateInventory)))
        }

        let duration = max(0, Int((workout.finishedAt ?? workout.startedAt) - workout.startedAt))
        return WorkoutSummary(
            workoutDayName: workout.workoutDayName,
            wentUp: wentUp,
            stayed: stayed,
            skipped: skipped,
            durationSeconds: duration,
            setCount: workout.loggedSetCount,
            volume: totalVolume(of: workout, in: logbook))
    }

    /// **The added plate** (§6.5) — the iron the progression puts on, which is what the
    /// chip is painted with.
    ///
    /// Under Microloading the Increment **is** a plate, on every Equipment Type (§4.2).
    /// Under Progressive Overload the Increment is a total, so a bar's is two plates and
    /// this halves it; everything else takes one plate and the Increment is it.
    ///
    /// It answers a `Weight`, not a colour: `PlatePalette.hex(for:)` paints it, and the
    /// view falls back to steel where the rack has no colour — an lbs plate (§7.3), or a
    /// pin Increment that is no plate size at all.
    public static func addedPlate(for exercise: ResolvedExercise) -> Weight? {
        switch exercise.mode {
        case .microloading:
            return exercise.microloadingIncrement
        case .progressiveOverload:
            guard let increment = exercise.increment else { return nil }
            let sides = exercise.equipment.platesPerProgression
            guard sides > 1 else { return increment }
            // An odd number of hundredths does not halve into a plate, and inventing one
            // would be a colour that means a weight nobody owns.
            guard increment.hundredths % sides == 0 else { return nil }
            return Weight(hundredths: increment.hundredths / sides, unit: increment.unit)
        }
    }

    /// The weight lifted, which is the Set's own and never the Exercise's (§2.5, §6.5).
    private static func performedWeight(
        _ performed: PerformedExercise, _ exercise: ResolvedExercise?
    ) -> SummaryWeight? {
        guard let last = performed.sets.last else { return nil }
        let unit = exercise?.unit ?? last.weight.unit
        return SummaryWeight(
            weight: last.weight.relabelled(unit),
            microload: (exercise?.isMixedUnitPin ?? false) ? last.microload : nil)
    }

    /// What a `STAYED` row states. The planned Sets and the threshold come from the
    /// **recorded** outcome; the weight it would move to is a statement about the future
    /// and is read live, exactly as the logging screen's chip reads it.
    private static func condition(
        _ performed: PerformedExercise,
        _ exercise: ResolvedExercise?,
        _ inventory: PlateInventory
    ) -> SummaryCondition {
        // A One-off never writes back, so nothing was ever going to progress and there
        // is no condition to state — only the Working Weight that survives (§6.5).
        if performed.oneOffWeight != nil {
            return .oneOff(stays: exercise?.workingWeight)
        }
        guard let exercise, let outcome = performed.outcome else { return .gone }
        let sets = outcome.plannedSets
        let reps = outcome.thresholdReps

        if let move = progressionMove(for: exercise, inventory: inventory) {
            return .target(
                sets: sets,
                reps: reps,
                to: SummaryWeight(
                    weight: move.workingWeight,
                    microload: exercise.isMixedUnitPin ? move.microload : nil))
        }
        return .blocked(blocker(for: exercise), sets: sets, reps: reps)
    }

    /// Which of §4.1's four — five, with a missing Increment — stopped the plate.
    ///
    /// Ordered by what the user does about it: a missing number first, then the rack.
    private static func blocker(for exercise: ResolvedExercise) -> ProgressionBlocker {
        if exercise.workingWeight == nil { return .noWorkingWeight }
        switch exercise.mode {
        case .progressiveOverload:
            return .noIncrement
        case .microloading:
            if exercise.microloadingIncrement == nil { return .noMicroplate }
            if exercise.isStranded { return .stranded }
            // A mixed-unit pin moves the Microload, and the roll-up needs a Stack Step
            // to roll it into; everything else moves the Working Weight, and cannot
            // where the plate is in the other unit (§2.6).
            if exercise.isMixedUnitPin { return .noStackStep }
            if exercise.unit != exercise.inventoryUnit { return .unitMismatch }
            return .noMicroplate
        }
    }
}
