/// The rules of Hoppa, as pure functions over the `Logbook`.
///
/// **The clock is never inside a rule.** It arrives as the `at:` argument, so no action
/// can forget it and no rule can reach for one.
///
/// > Ticket 20 fixed the signature as `reduce(_ workout: Workout, _ action: Action,
/// > at: Timestamp) -> Workout`. It cannot be that, and the reason is a rule and not a
/// > preference: **progression writes to the Program**, because the Working Weight lives
/// > on the Exercise (§4.1), and an edit at the rack is a Program edit (§6.6). A Finish
/// > that returns only a `Workout` can move no weight and cannot even read the planned
/// > Sets or the Rep Range it needs to write a Progression Outcome. `Logbook` is the
/// > root value ticket 19 landed on afterwards, and it holds exactly what the rules need
/// > and nothing that faces outward.
public enum Rules {

    /// Applies one action. An action that cannot apply returns the state unchanged.
    public static func reduce(_ logbook: Logbook, _ action: Action, at now: Timestamp) -> Logbook {
        var book = logbook

        switch action {

        case .startWorkout(let programId, let workoutDayId):
            // One Open Workout at a time.
            guard book.openWorkout == nil,
                  let program = book.program(programId),
                  let day = program.days.first(where: { $0.id == workoutDayId })
            else { return logbook }

            let id = WorkoutID(book.mintId())
            book.openWorkout = Workout(
                id: id,
                programId: programId,
                workoutDayId: workoutDayId,
                workoutDayName: day.name,
                startedAt: now,
                restStartedAt: nil,
                state: .open,
                currentIndex: 0,
                // Every Exercise starts Open, and keeps the Name as it reads now.
                exercises: day.exercises.map {
                    PerformedExercise(exerciseId: $0.id, name: $0.name)
                })
            return book

        case .selectExercise(let index):
            guard var workout = book.openWorkout, workout.exercises.indices.contains(index)
            else { return logbook }
            workout.currentIndex = index
            book.openWorkout = workout
            return book

        case .nextOpen:
            guard var workout = book.openWorkout,
                  let next = workout.nextOpenIndex(after: workout.currentIndex)
            else { return logbook }
            workout.currentIndex = next
            book.openWorkout = workout
            return book

        case .logSet(let reps):
            guard var workout = book.openWorkout,
                  let index = currentIndex(of: workout),
                  let exercise = book.resolvedExercise(workout.exercises[index].exerciseId)
            else { return logbook }

            var performed = workout.exercises[index]
            // A Skipped Exercise logs no Sets, and no Exercise logs past its planned Sets.
            guard performed.state != .skipped, performed.sets.count < exercise.plannedSets
            else { return logbook }

            // The weight sits on the Set, not on the Exercise: §6.4 lets the user raise
            // it part-way through, and the Sets before the raise were lifted lighter.
            // **No weight, no Set** (§2.8): an Exercise the user has not weighed yet, or
            // one §6.6 has just cleared, has no number to write down.
            guard let weight = performed.oneOffWeight ?? exercise.workingWeight
            else { return logbook }
            performed.sets.append(LoggedSet(
                reps: max(0, reps),
                weight: weight,
                microload: exercise.microload,
                oneOff: performed.oneOffWeight != nil))

            // Completing an Exercise costs no tap: the last Set does it.
            if performed.sets.count >= exercise.plannedSets { performed.state = .completed }

            workout.exercises[index] = performed
            // The Rest Timer starts automatically after each logged Set.
            workout.restStartedAt = now
            book.openWorkout = workout
            return book

        case .doneEarly:
            guard var workout = book.openWorkout, let index = currentIndex(of: workout)
            else { return logbook }
            guard workout.exercises[index].state == .open else { return logbook }
            workout.exercises[index].state = .completed
            book.openWorkout = workout
            return book

        case .skip:
            guard var workout = book.openWorkout, let index = currentIndex(of: workout)
            else { return logbook }
            workout.exercises[index].state = .skipped
            workout.exercises[index].sets = []
            book.openWorkout = workout
            return book

        case .reopen:
            guard var workout = book.openWorkout, let index = currentIndex(of: workout)
            else { return logbook }
            workout.exercises[index].state = .open
            book.openWorkout = workout
            return book

        case .setWorkingWeight(let weight):
            guard weight.hundredths > 0,
                  var workout = book.openWorkout,
                  let index = currentIndex(of: workout)
            else { return logbook }
            let exerciseId = workout.exercises[index].exerciseId
            guard book.exercise(exerciseId) != nil else { return logbook }
            // An edit at the rack is a Program edit (§6.6), and it clears any One-off.
            book.updateExercise(exerciseId) { $0.workingWeight = weight }
            workout.exercises[index].oneOffWeight = nil
            book.openWorkout = workout
            return book

        case .setOneOffWeight(let weight):
            guard weight.hundredths > 0,
                  var workout = book.openWorkout,
                  let index = currentIndex(of: workout)
            else { return logbook }
            workout.exercises[index].oneOffWeight = weight
            book.openWorkout = workout
            return book

        case .finish:
            guard let workout = book.openWorkout, workout.canFinish else { return logbook }
            return finish(book, at: now)

        case .skipRemainingAndFinish:
            guard var workout = book.openWorkout else { return logbook }
            for index in workout.exercises.indices where workout.exercises[index].state == .open {
                workout.exercises[index].state = .skipped
                workout.exercises[index].sets = []
            }
            book.openWorkout = workout
            return finish(book, at: now)

        case .discard:
            guard book.openWorkout != nil else { return logbook }
            book.openWorkout = nil
            return book

        case .deleteWorkout(let id):
            // §6.7, ticket 0048. **The Sets go and the weights stay**: nothing else in
            // this case, and that is the whole rule. `updateExercise` is not called, so
            // no Working Weight can move by accident.
            guard book.workouts.contains(where: { $0.id == id }) else { return logbook }
            book.workouts.removeAll { $0.id == id }
            return book

        // Flow 5 (§6.6), in `Rules+Edit.swift`. One door, two files: a `default:` here
        // would let a new edit case land unhandled, so they are listed one by one and the
        // compiler checks the list.
        case .createProgram, .renameProgram, .setProgramDefaultWeightUnit, .setProgramMode,
             .addWorkoutDay, .renameWorkoutDay, .moveWorkoutDay, .deleteWorkoutDay,
             .addExercise, .saveExercise, .moveExercise, .deleteExercise,
             .setPlateInventoryUnit, .setPlate, .reweigh:
            return applyEdit(logbook, action, at: now)
        }
    }

    private static func currentIndex(of workout: Workout) -> Int? {
        workout.exercises.indices.contains(workout.currentIndex) ? workout.currentIndex : nil
    }

    /// Ends the Workout and applies progression. **The user accepts nothing**: there is
    /// no pending suggestion and no acceptance step (`SPEC.md` §4.1).
    private static func finish(_ logbook: Logbook, at now: Timestamp) -> Logbook {
        var book = logbook
        guard var workout = book.openWorkout else { return logbook }

        for index in workout.exercises.indices {
            let performed = workout.exercises[index]
            guard let exercise = book.resolvedExercise(performed.exerciseId) else {
                // The Exercise was deleted mid-Workout. History survives it, but there is
                // nothing left to progress and no Rep Range to write an outcome from.
                continue
            }
            let result = evaluateProgression(
                performed: performed,
                exercise: exercise,
                inventory: book.plateInventory)
            var outcome = result.outcome
            if let move = result.move {
                book.updateExercise(performed.exerciseId) { stored in
                    stored.workingWeight = move.workingWeight
                    if exercise.isMixedUnitPin { stored.microload = move.microload }
                }
            }
            // **The weight this Workout ended on, written down** (§2.4, ticket 0048).
            // Read back out of the book rather than off the move, so the number recorded
            // is the number stored — the two differ on a mixed-unit pin, where the move
            // carries a Microload the Exercise does not keep.
            let after = book.resolvedExercise(performed.exerciseId)
            outcome.workingWeightAfter = after?.workingWeight
            outcome.microloadAfter = after?.microload
            workout.exercises[index].outcome = outcome
        }

        workout.state = .finished
        workout.finishedAt = now
        workout.restStartedAt = nil
        book.openWorkout = nil
        book.workouts.append(workout)
        return book
    }

    /// Total volume, in the Program's default unit.
    ///
    /// **The one place in Hoppa where a conversion happens** (`SPEC.md` §5.1). Volume is
    /// a rough progress number and not a loading instruction, so a conversion misleads
    /// nobody here — unlike the Plate Breakdown, which stays exact. Sets on a Dumbbell
    /// count both dumbbells.
    public static func totalVolume(of workout: Workout, in logbook: Logbook) -> Weight {
        let unit = logbook.program(workout.programId)?.defaultWeightUnit ?? logbook.plateInventory.unit
        var total = 0
        for performed in workout.exercises {
            let equipment = logbook.exercise(performed.exerciseId)?.equipment
            let hands = equipment == .dumbbell ? 2 : 1
            for set in performed.sets {
                total += set.weight.converted(to: unit).hundredths * set.reps * hands
            }
        }
        return Weight(hundredths: total, unit: unit)
    }
}
