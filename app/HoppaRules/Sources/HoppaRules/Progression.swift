/// What a progression moves, and where it moves to.
public struct ProgressionMove: Sendable, Hashable {
    /// The new Working Weight, in the Exercise's unit.
    public var workingWeight: Weight
    /// The new Microload, in the Plate Inventory's unit. `nil` on any Exercise that has
    /// none — which is every Exercise except a mixed-unit pin.
    public var microload: Weight?
    /// How many pin steps the roll-up took. Nothing shows this; it exists so a test can
    /// see that the pin moved.
    public var pinSteps: Int

    public init(workingWeight: Weight, microload: Weight?, pinSteps: Int = 0) {
        self.workingWeight = workingWeight
        self.microload = microload
        self.pinSteps = pinSteps
    }
}

/// The outcome of evaluating one Performed Exercise at Finish, plus the move to apply.
public struct ProgressionResult: Sendable, Hashable {
    public var outcome: ProgressionOutcome
    /// `nil` when the Exercise did not progress.
    public var move: ProgressionMove?
}

extension Rules {

    /// Does this Exercise progress, and to what? Evaluated **per Exercise, never per
    /// Workout**, and applied at Finish (`SPEC.md` §4.1).
    ///
    /// Hoppa reads the Exercise **as it stands at Finish** — the Mode, the planned Sets
    /// and the Rep Range — so an edit made at the rack counts for the Workout it was made
    /// in. Hoppa never lowers a Working Weight by itself, ever.
    public static func evaluateProgression(
        performed: PerformedExercise,
        exercise: ResolvedExercise,
        inventory: PlateInventory
    ) -> ProgressionResult {
        let threshold = exercise.thresholdReps
        let planned = exercise.plannedSets

        // Both conditions, and neither is negotiable:
        //   1. at least the planned Sets — "Done early" never progresses
        //   2. every Set met the threshold of the Exercise's Progression Mode
        // A One-off Weight is the exception by definition: it never progresses.
        var progressed =
            performed.state == .completed
            && performed.oneOffWeight == nil
            && !performed.sets.isEmpty
            && performed.sets.count >= planned
            && performed.sets.allSatisfy { $0.reps >= threshold }

        var move: ProgressionMove?
        if progressed {
            move = progressionMove(for: exercise, inventory: inventory)
            // Nowhere to put the plate is not a progression. The one refused combination
            // (Microloading on a Dumbbell in the other unit, §2.6) lands here, as does an
            // Exercise on Microloading with no Microplate switched on yet (§5.2).
            if move == nil { progressed = false }
        }

        return ProgressionResult(
            outcome: ProgressionOutcome(
                plannedSets: planned,
                thresholdReps: threshold,
                progressed: progressed),
            move: move)
    }

    /// Where this Exercise's weight goes on a progression. `nil` when it has nowhere to go.
    ///
    /// Reps above the top of the Rep Range count the same as reaching the top: the weight
    /// goes up by the Increment **once**, never more (`SPEC.md` §4.2). That is why this
    /// takes no rep counts at all.
    public static func progressionMove(
        for exercise: ResolvedExercise,
        inventory: PlateInventory
    ) -> ProgressionMove? {
        switch exercise.mode {
        case .progressiveOverload:
            return ProgressionMove(
                workingWeight: exercise.workingWeight + exercise.increment,
                microload: exercise.microload)

        case .microloading:
            guard let increment = exercise.microloadingIncrement else { return nil }

            // The mixed-unit case is the only two-number case: the Microload moves, and
            // rolls into the pin at one Stack Step (§4.2).
            if exercise.isMixedUnitPin {
                guard let stackStep = exercise.stackStep, stackStep.hundredths > 0 else { return nil }
                return rollUp(
                    workingWeight: exercise.workingWeight,
                    microload: exercise.microload ?? .zero(inventory.unit),
                    increment: increment,
                    stackStep: stackStep,
                    inventory: inventory)
            }

            // Same unit: Microloading moves the Working Weight like any other
            // progression. A bar takes a pair, so the same plate moves it by twice as
            // much; everything else takes one plate.
            guard exercise.unit == exercise.inventoryUnit else { return nil }
            let plates = exercise.equipment.platesPerProgression
            return ProgressionMove(
                workingWeight: exercise.workingWeight + increment.scaled(by: plates),
                microload: exercise.microload)
        }
    }

    /// The roll-up: a Microload is never bigger than one Stack Step (`SPEC.md` §4.2).
    ///
    /// 1. The Microload goes up by one Microplate, as always.
    /// 2. **While** it is at or past one Stack Step, one Stack Step goes onto the Working
    ///    Weight and the remainder stays as the new Microload, **rounded up** to a weight
    ///    the rack can build.
    ///
    /// Two invariants follow, and they are the whole rule: after any progression the
    /// Microload is less than one Stack Step, and the weight never goes down. Rounding
    /// the remainder *up* is what guarantees the second, at the cost of at most one
    /// Microplate more than the user asked for.
    ///
    /// Comparing a Stack Step to a Microload is a conversion, and Hoppa does it —
    /// internally. Nothing converted reaches the screen.
    public static func rollUp(
        workingWeight: Weight,
        microload: Weight,
        increment: Weight,
        stackStep: Weight,
        inventory: PlateInventory
    ) -> ProgressionMove {
        var weight = workingWeight
        var hanging = microload + increment
        let stepInRackUnit = stackStep.converted(to: inventory.unit)
        guard stepInRackUnit.hundredths > 0 else {
            return ProgressionMove(workingWeight: weight, microload: hanging)
        }

        var pinSteps = 0
        while hanging.hundredths >= stepInRackUnit.hundredths {
            weight = weight + stackStep
            hanging = inventory.roundedUpToBuildable(hanging - stepInRackUnit, for: .microloading)
            pinSteps += 1
        }
        return ProgressionMove(workingWeight: weight, microload: hanging, pinSteps: pinSteps)
    }
}
