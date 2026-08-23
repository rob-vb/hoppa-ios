import Testing
import HoppaRules

/// Flow 5 — editing a Program (`SPEC.md` §6.6), and what an edit does to a Workout that is
/// running while it happens.
///
/// Every one of these is an `Action`, because a §6.6 edit is a **rule**: a raise to the
/// planned Sets reopens a Completed Exercise, a change of unit clears three fields and
/// destroys a Microload, and a delete has to leave the Sets the user lifted alone. Put any
/// of that in a view and no test can reach it.
///
/// > Decision record:
/// > [Program edits, and which of them are rules](../../../../issues/0026-program-edits-and-the-rules-boundary.md).
@Suite("SPEC.md §6.6 — the Program edits")
struct EditTests {

    /// Upper A plus a second Day, because half of §6.6 needs a Program the last-Day block
    /// does not refuse.
    static func twoDayBook() -> Logbook {
        var book = upperALogbook()
        book.programs[0].days.append(
            WorkoutDay(id: WorkoutDayID(3), name: "Lower A", exercises: [
                Exercise(
                    id: ExerciseID(20), name: "Barbell back squat", equipment: .barbell,
                    plannedSets: 3, repRange: RepRange(5, 8),
                    workingWeight: kg("80"), increment: kg("5"))
            ]))
        return book
    }

    static func draft(_ exercise: Exercise) -> ExerciseDraft { ExerciseDraft(exercise) }

    // MARK: - Program level (§2.1, §2.7, §4.4)

    @Test("A Program can be created from nothing, and its ids come off the counter")
    func createProgram() {
        var session = Session(.empty)
        session.send(.createProgram(name: "Upper / Lower", defaultWeightUnit: .kg, mode: .progressiveOverload))
        guard let program = session.book.programs.first else {
            Issue.record("no Program"); return
        }

        #expect(session.book.programs.count == 1)
        #expect(program.name == "Upper / Lower")
        #expect(program.days.isEmpty)

        session.send(.addWorkoutDay(programId: program.id, name: "Upper A"))
        #expect(session.book.programs[0].days.count == 1)
        // Ids are a counter and never reused (§2.8), so the Day cannot collide with it.
        #expect(session.book.programs[0].days[0].id.value != program.id.value)
    }

    @Test("A Workout Day is found with the Program that holds it")
    func aDayComesBackWithItsProgram() {
        let book = Self.twoDayBook()
        guard let found = book.workoutDay(WorkoutDayID(3)) else {
            Issue.record("no Workout Day"); return
        }

        #expect(found.day.name == "Lower A")
        #expect(found.program.id == Ids.program)
        // The pair is the point: the Day screen draws the Program's Name above the Day's
        // and resolves the Day's Exercises against the Program's Mode.
        #expect(found.program.mode == book.programs[0].mode)
        #expect(book.workoutDay(WorkoutDayID(999)) == nil)
    }

    @Test("The Program's Weight Unit is a default for new Exercises, so it moves nothing")
    func theProgramUnitTouchesNothing() {
        var session = Session()
        session.send(.setProgramDefaultWeightUnit(Ids.program, .lbs))

        #expect(session.book.programs[0].defaultWeightUnit == .lbs)
        #expect(session.stored(Ids.smith)?.workingWeight == kg("72.5"))
        #expect(session.resolved(Ids.smith)?.unit == .kg)               // still the rack's
    }

    @Test("The Program's Mode changes the default only, and fills the Microloading Increment")
    func theProgramModeFillsTheDefaultIncrement() {
        var session = Session()
        // Nobody holds a Microplate yet, and the smallest one switched on is 0.25 kg.
        session.book.updateExercise(Ids.smith) { $0.microloadingIncrement = nil }
        session.book.updateExercise(Ids.row) { $0.microloadingIncrement = nil }
        session.send(.setProgramMode(Ids.program, .microloading))

        #expect(session.stored(Ids.smith)?.microloadingIncrement == kg("0.25"))
        #expect(session.resolved(Ids.smith)?.mode == .microloading)
        // The Exercise with an override keeps its own Mode: an override is deliberate.
        #expect(session.resolved(Ids.pulldown)?.mode == .microloading)
        #expect(session.stored(Ids.pulldown)?.microloadingIncrement == kg("1"))
        // And it never touches a Working Weight (§4.4).
        #expect(session.stored(Ids.smith)?.workingWeight == kg("72.5"))
    }

    @Test("With no Microplate switched on there is no default to fill, and §5.2's empty state stands")
    func noMicroplateNoDefault() {
        var session = Session(Logbook(nextId: 100, plateInventory: .standard(.kg),
                                      programs: upperALogbook().programs))
        session.book.updateExercise(Ids.smith) { $0.microloadingIncrement = nil }
        session.send(.setProgramMode(Ids.program, .microloading))

        #expect(session.stored(Ids.smith)?.microloadingIncrement == nil)
    }

    // MARK: - Workout Days (§3.1, §6.6)

    @Test("Reordering Workout Days is cosmetic")
    func reorderingDaysIsCosmetic() {
        var session = Session(Self.twoDayBook())
        session.send(.moveWorkoutDay(WorkoutDayID(3), to: 0))

        #expect(session.book.programs[0].days.map(\.name) == ["Lower A", "Upper A"])
    }

    @Test("A Workout Day cannot be deleted while the Open Workout runs on it")
    func theOpenWorkoutBlocksTheDelete() {
        var session = Session(Self.twoDayBook())
        session.start()

        #expect(Rules.deleteBlock(forWorkoutDay: Ids.upperA, in: session.book) == .openWorkoutRunsOnIt)
        session.send(.deleteWorkoutDay(Ids.upperA))
        #expect(session.book.programs[0].days.count == 2)               // refused

        // The other Day is free.
        #expect(Rules.deleteBlock(forWorkoutDay: WorkoutDayID(3), in: session.book) == nil)
    }

    @Test("The last Workout Day in a Program cannot be deleted")
    func theLastDayIsBlocked() {
        var session = Session()

        #expect(Rules.deleteBlock(forWorkoutDay: Ids.upperA, in: session.book) == .lastDayInProgram)
        session.send(.deleteWorkoutDay(Ids.upperA))
        #expect(session.book.programs[0].days.count == 1)
    }

    @Test("A deleted Workout Day leaves history alone, Name and Sets both")
    func historySurvivesADeletedDay() {
        var session = Session(Self.twoDayBook())
        session.start()
        session.logSets(3, reps: 12)
        session.send(.skipRemainingAndFinish)
        session.send(.deleteWorkoutDay(Ids.upperA))

        #expect(session.book.programs[0].days.count == 1)
        #expect(session.lastFinished?.workoutDayName == "Upper A")
        #expect(session.lastFinished?.exercises.first?.sets.count == 3)
        #expect(session.lastFinished?.exercises.first?.name == "Smith machine bench press")
    }

    // MARK: - The Exercise sheet, saved once (§6.2, §6.6)

    @Test("An Exercise arrives at its place in the Day, and Open in the Workout")
    func addingMirrorsIntoTheOpenWorkout() {
        var session = Session()
        session.start()
        session.goTo(Ids.pulldown)                                      // index 2
        let standing = session.workout?.current?.exerciseId

        session.send(.addExercise(
            workoutDayId: Ids.upperA, at: 1,
            draft: ExerciseDraft(
                name: "Face pull", equipment: .cable, ownWeightUnit: .lbs,
                plannedSets: 3, repRange: RepRange(12, 15),
                workingWeight: lbs("40"), increment: lbs("10"), stackStep: lbs("10"))))

        #expect(session.book.programs[0].days[0].exercises.map(\.name)[1] == "Face pull")
        #expect(session.workout?.exercises.map(\.name)[1] == "Face pull")
        #expect(session.workout?.exercises[1].state == .open)
        #expect(session.workout?.canFinish == false)
        // The user does not move: the card under his thumb is the same one (§6.4).
        #expect(session.workout?.current?.exerciseId == standing)
        // A pin in a unit the rack does not use gets a Microload at zero (§2.3).
        let added = session.book.programs[0].days[0].exercises[1]
        #expect(added.microload == .kg(hundredths: 0))
    }

    @Test("Raising the planned Sets reopens what Hoppa completed by itself")
    func raisingReopensAnAutoCompletedExercise() {
        var session = Session()
        session.start()
        session.logSets(3, reps: 12)                                    // auto-completed
        #expect(session.performed(Ids.smith)?.state == .completed)

        var draft = Self.draft(session.stored(Ids.smith)!)
        draft.plannedSets = 4
        session.send(.saveExercise(Ids.smith, draft: draft))

        #expect(session.performed(Ids.smith)?.state == .open)
        #expect(session.workout?.canFinish == false)                    // gated again
        #expect(session.performed(Ids.smith)?.sets.count == 3)          // nothing lost
    }

    /// §3.2's exception, and the trap under a literal reading: *Done early* never earned a
    /// progression, so a raise takes none away — and ending early is a deliberate act an
    /// edit made afterwards must not argue with.
    @Test("Raising the planned Sets leaves a Done-early Exercise Completed")
    func raisingLeavesDoneEarlyAlone() {
        var session = Session()
        session.start()
        session.logSets(2, reps: 12)
        session.send(.doneEarly)

        var draft = Self.draft(session.stored(Ids.smith)!)
        draft.plannedSets = 4
        session.send(.saveExercise(Ids.smith, draft: draft))

        #expect(session.performed(Ids.smith)?.state == .completed)
    }

    /// The mirror, and without it the Exercise is stuck: the plan is full so no Set can be
    /// logged, nothing fires to complete it, and it holds the Finish gate.
    @Test("Lowering the planned Sets to what is logged Completes an Open Exercise")
    func loweringCompletesAnOpenExercise() {
        var session = Session()
        session.start()
        session.logSets(2, reps: 12)
        #expect(session.performed(Ids.smith)?.state == .open)

        var draft = Self.draft(session.stored(Ids.smith)!)
        draft.plannedSets = 2
        session.send(.saveExercise(Ids.smith, draft: draft))

        #expect(session.performed(Ids.smith)?.state == .completed)
    }

    @Test("Changing a Weight Unit clears the weights rather than converting them")
    func aUnitChangeClears() {
        var session = Session()
        var draft = Self.draft(session.stored(Ids.press)!)              // Dumbbell, kg
        draft.ownWeightUnit = .lbs
        session.send(.saveExercise(Ids.press, draft: draft))

        let press = session.stored(Ids.press)!
        #expect(press.workingWeight == nil)
        #expect(press.increment == nil)
        #expect(press.ownWeightUnit == .lbs)
        // The Microloading Increment keeps the Plate Inventory's unit whatever the
        // Exercise does (§5.1), so it survives untouched.
        #expect(press.microloadingIncrement == kg("0.25"))
        // A Dumbbell has nowhere to hang a Microload, so none is created (§2.6).
        #expect(press.microload == nil)
        // And the Exercise is now on the Re-weigh list, without anything writing it down.
        #expect(Rules.reweighList(in: session.book) == [Ids.press])
    }

    @Test("A Microload is really destroyed when the pin joins the rack's unit")
    func theMicroloadIsDestroyed() {
        var session = Session()
        #expect(session.stored(Ids.pulldown)?.microload == kg("1"))

        var draft = Self.draft(session.stored(Ids.pulldown)!)
        draft.ownWeightUnit = .kg                                       // the rack's unit
        session.send(.saveExercise(Ids.pulldown, draft: draft))
        #expect(session.stored(Ids.pulldown)?.microload == nil)
        #expect(session.stored(Ids.pulldown)?.storedStackStep == nil)

        // Back again: created at zero, not the old 1 kg. Hiding it instead would bring
        // the old Microload back here (§6.6).
        var back = Self.draft(session.stored(Ids.pulldown)!)
        back.ownWeightUnit = .lbs
        back.stackStep = lbs("10")
        session.send(.saveExercise(Ids.pulldown, draft: back))
        #expect(session.stored(Ids.pulldown)?.microload == .kg(hundredths: 0))
    }

    @Test("A Base Weight and a Stack Step survive a change of Equipment Type")
    func machineFactsSurviveATypeChange() {
        var session = Session()
        var draft = Self.draft(session.stored(Ids.smith)!)              // Smith, base 15 kg
        draft.equipment = .barbell
        draft.baseWeight = nil                                          // the sheet shows no row
        session.send(.saveExercise(Ids.smith, draft: draft))

        // Stored, and hidden by `resolved` — §2.3 refuses to re-ask a fact about a machine.
        #expect(session.stored(Ids.smith)?.storedBaseWeight == kg("15"))
        #expect(session.resolved(Ids.smith)?.baseWeight == nil)
        // The unit did not change, so the weights stayed.
        #expect(session.stored(Ids.smith)?.workingWeight == kg("72.5"))
    }

    @Test("A change of Equipment Type across the rack boundary is a unit change too")
    func aTypeChangeCanChangeTheUnit() {
        var session = Session()
        var draft = Self.draft(session.stored(Ids.pulldown)!)           // stack, lbs
        draft.equipment = .barbell                                      // now reads the kg rack
        session.send(.saveExercise(Ids.pulldown, draft: draft))

        #expect(session.stored(Ids.pulldown)?.workingWeight == nil)
        #expect(session.stored(Ids.pulldown)?.microload == nil)
    }

    @Test("Reordering moves the Workout too, and the user stays on his Exercise")
    func reorderingKeepsTheCardUnderTheThumb() {
        var session = Session()
        session.start()
        session.goTo(Ids.pulldown)
        session.send(.moveExercise(Ids.chin, to: 0))

        #expect(session.book.programs[0].days[0].exercises.first?.id == Ids.chin)
        #expect(session.workout?.exercises.first?.exerciseId == Ids.chin)
        #expect(session.workout?.current?.exerciseId == Ids.pulldown)   // not the position
    }

    @Test("A deleted Exercise keeps its Sets and stops holding the Finish gate")
    func deletingReleasesTheGate() {
        var session = Session()
        session.start()
        session.logSets(2, reps: 12)                                    // Smith, 2 of 3
        session.send(.deleteExercise(Ids.smith))

        #expect(session.book.exercise(Ids.smith) == nil)
        #expect(session.workout?.exercises.count == 5)                  // the list never shrinks
        #expect(session.performed(Ids.smith)?.sets.count == 2)          // the user lifted them
        #expect(session.performed(Ids.smith)?.state == .completed)
        #expect(session.performed(Ids.smith)?.name == "Smith machine bench press")
    }

    @Test("A deleted Exercise with no Sets ends Skipped")
    func deletingAnUntouchedExerciseSkipsIt() {
        var session = Session()
        session.start()
        session.send(.deleteExercise(Ids.row))

        #expect(session.performed(Ids.row)?.state == .skipped)
        #expect(session.performed(Ids.row)?.sets.isEmpty == true)
    }

    // MARK: - The rack (§5.2, §6.6)

    @Test("Changing the Plate Inventory's unit clears every Exercise that reads it")
    func theInventoryUnitClearsAtFullBlastRadius() {
        var session = Session()
        let warned = Rules.exercisesClearedByInventoryUnit(.lbs, in: session.book)
        // Smith, Barbell row and the Bodyweight chin-up read the rack; the Dumbbell and
        // the stack carry their own unit (§5.1).
        #expect(warned == [Ids.smith, Ids.row, Ids.chin])

        session.send(.setPlateInventoryUnit(.lbs))

        #expect(session.book.plateInventory.unit == .lbs)
        #expect(session.stored(Ids.smith)?.workingWeight == nil)
        #expect(session.stored(Ids.smith)?.storedBaseWeight == nil)
        #expect(session.stored(Ids.chin)?.workingWeight == nil)
        // The Dumbbell and the pin keep their own unit, so their weights stand.
        #expect(session.stored(Ids.press)?.workingWeight == kg("22.5"))
        #expect(session.stored(Ids.pulldown)?.workingWeight == lbs("100"))
        // Every Microloading Increment resets: the other unit's Microplates all ship off.
        #expect(session.book.allExercises.allSatisfy { $0.microloadingIncrement == nil })
        // The pin's Microload is recreated at zero in the new unit (§2.3).
        #expect(session.stored(Ids.pulldown)?.microload == nil)         // lbs pin, lbs rack
        #expect(session.stored(Ids.press)?.microload == nil)

        #expect(Rules.reweighList(in: session.book) == [Ids.smith, Ids.row, Ids.chin])
    }

    @Test("The warning counts the Exercises that have a weight to lose, and no more")
    func theWarningIsTheSameRuleAskedEarly() {
        var session = Session()
        session.book.updateExercise(Ids.chin) { $0.workingWeight = nil }

        #expect(Rules.exercisesClearedByInventoryUnit(.lbs, in: session.book) == [Ids.smith, Ids.row])
        // The switch it is already on clears nothing.
        #expect(Rules.exercisesClearedByInventoryUnit(.kg, in: session.book).isEmpty)
    }

    @Test("Switching a Microplate off writes nothing else, and the count says who it strands")
    func switchingAPlateWritesNothingElse() {
        var session = Session()
        let users = Rules.exercisesUsingMicroplate(kg("0.25"), in: session.book)
        #expect(users == [Ids.smith, Ids.row, Ids.press, Ids.chin])

        let before = session.book
        session.send(.setPlate(kg("0.25"), on: false))

        #expect(session.book.allExercises == before.allExercises)       // not one field moved
        #expect(session.book.plateInventory.enabledMicroplates.contains(kg("0.25")) == false)
    }
}
