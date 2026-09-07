import Testing
@testable import HoppaRules

// Ticket 0058 — §6.7's Progress list.
//
// Read twice, the way `HistoryTests` reads the Workout list: once against sessions built
// tap by tap, where every row can be counted by hand, and once against the 56-Workout
// snapshot, where all eighteen Exercises have been trained and the order has to hold
// across four Days.

@Suite("The Progress list (SPEC.md §6.7)")
struct ProgressTests {

    // MARK: - Who is on it

    @Test("Before the first Workout the list is empty")
    func empty() {
        #expect(Rules.progress(in: upperALogbook()).isEmpty)
    }

    @Test("An Open Workout is not progress — it has been started, not done")
    func openWorkoutIsNotProgress() {
        var session = Session()
        session.start()
        session.logSets(3)
        #expect(Rules.progress(in: session.book).isEmpty)
    }

    @Test("One logged Exercise makes one row, and the row carries the chart's own figures")
    func oneRow() {
        var session = Session()
        session.start()
        session.logSets(3)                      // 12, 12, 12 — it goes up
        session.send(.skipRemainingAndFinish)

        let rows = Rules.progress(in: session.book)
        #expect(rows.count == 1)
        let row = rows[0]
        #expect(row.id == Ids.smith)
        #expect(row.name == "Smith machine bench press")
        #expect(row.workoutDayName == "Upper A")
        #expect(row.sessionCount == 1)
        #expect(row.timesUp == 1)
        let chart = Rules.exerciseChart(Ids.smith, in: session.book)!
        #expect(row.sparkline == chart.sparkline)
        #expect(row.sparkline.count == 1)
    }

    @Test("A Skipped-only Exercise makes no row, because a skip makes no point")
    func skipOnlyIsNoRow() {
        var session = Session()
        session.start()
        session.logSets(3)
        session.goTo(Ids.row)
        session.send(.skip)
        session.send(.skipRemainingAndFinish)

        #expect(Rules.progress(in: session.book).map(\.id) == [Ids.smith])
    }

    @Test("A session that moved nothing is still a session, with no green line")
    func stayedIsStillASession() {
        var session = Session()
        session.start()
        session.logSets(3, reps: 5)
        session.send(.skipRemainingAndFinish)

        let row = Rules.progress(in: session.book)[0]
        #expect(row.sessionCount == 1)
        #expect(row.timesUp == 0)
    }

    // MARK: - The order

    @Test("Rows are in program order, not the order they were trained in")
    func programOrder() {
        var session = Session()
        session.start()
        session.goTo(Ids.row)
        session.logSets(3)
        session.goTo(Ids.smith)
        session.logSets(3)
        session.send(.skipRemainingAndFinish)

        #expect(Rules.progress(in: session.book).map(\.id) == [Ids.smith, Ids.row])
    }

    @Test("Two Exercises with one Name are two rows, each labelled with its Day")
    func sameNameTwoRows() {
        var session = Session()
        session.send(.addWorkoutDay(programId: Ids.program, name: "Upper B"))
        let upperB = session.book.programs[0].days.last!.id
        session.send(.addExercise(
            workoutDayId: upperB, at: 0,
            draft: ExerciseDraft(
                name: "Smith machine bench press", equipment: .machinePlates, ownWeightUnit: .kg,
                plannedSets: 3, repRange: RepRange(8, 12),
                workingWeight: kg("60"), increment: kg("2.5"), baseWeight: kg("15"),
                shownUnit: .kg)))
        let twin = session.book.programs[0].days.last!.exercises[0].id

        session.start(upperB)
        session.logSets(3)
        session.send(.skipRemainingAndFinish)
        session.start()
        session.logSets(3)
        session.send(.skipRemainingAndFinish)

        let rows = Rules.progress(in: session.book)
        #expect(rows.map(\.id) == [Ids.smith, twin])
        #expect(rows.map(\.name) == ["Smith machine bench press", "Smith machine bench press"])
        #expect(rows.map(\.workoutDayName) == ["Upper A", "Upper B"])
    }

    // MARK: - What changes under it (§2.7, §2.8)

    @Test("A deleted Exercise drops out of the list")
    func aDeletedExercise() {
        var session = Session()
        session.start()
        session.logSets(3)
        session.send(.skipRemainingAndFinish)
        #expect(Rules.progress(in: session.book).count == 1)

        session.send(.deleteExercise(Ids.smith))
        #expect(Rules.progress(in: session.book).isEmpty)
    }

    @Test("A renamed Day and a renamed Exercise read live")
    func renamesReadLive() {
        var session = Session()
        session.start()
        session.logSets(3)
        session.send(.skipRemainingAndFinish)
        session.send(.renameWorkoutDay(Ids.upperA, name: "Push"))
        var draft = ExerciseDraft(session.stored(Ids.smith)!, in: session.book.plateInventory)
        draft.name = "Smith bench"
        session.send(.saveExercise(Ids.smith, draft: draft))

        let row = Rules.progress(in: session.book)[0]
        #expect(row.workoutDayName == "Push")
        #expect(row.name == "Smith bench")
    }

    @Test("A deleted Workout takes its session with it")
    func aDeletedWorkout() {
        var session = Session()
        session.start()
        session.logSets(3, reps: 9)
        session.send(.skipRemainingAndFinish)
        let first = session.lastFinished!.id
        session.start()
        session.logSets(3, reps: 9)
        session.send(.skipRemainingAndFinish)
        #expect(Rules.progress(in: session.book)[0].sessionCount == 2)

        session.send(.deleteWorkout(first))
        #expect(Rules.progress(in: session.book)[0].sessionCount == 1)
    }

    // MARK: - Sixteen weeks of it

    @Test("Every trained Exercise is a row, in the Program's own order")
    func everyTrainedExercise() {
        let book = SnapshotTests.run(assertInvariants: false).book
        let rows = Rules.progress(in: book)

        #expect(rows.count == 18)
        #expect(rows.map(\.id) == History.specs.map(\.id))
        #expect(rows.map(\.workoutDayName) == History.specs.map { History.dayNames[$0.day] })
    }

    @Test("An Exercise added after the last Workout is not a row")
    func neverTrainedIsNoRow() {
        var book = SnapshotTests.run(assertInvariants: false).book
        book = Rules.reduce(
            book,
            .addExercise(
                workoutDayId: WorkoutDayID(1), at: 0,
                draft: ExerciseDraft(
                    name: "Cable crunch", equipment: .machineStack, ownWeightUnit: .lbs,
                    plannedSets: 3, repRange: RepRange(12, 15),
                    workingWeight: lbs("40"), increment: lbs("10"), stackStep: lbs("10"),
                    shownUnit: .lbs)),
            at: History.lastMonday)

        let rows = Rules.progress(in: book)
        #expect(rows.count == 18)
        #expect(!rows.contains { $0.name == "Cable crunch" })
        #expect(book.allExercises.count == 19)
    }

    @Test("Every row's figures are its chart's own")
    func everyRowAgreesWithItsChart() {
        let book = SnapshotTests.run(assertInvariants: false).book
        for row in Rules.progress(in: book) {
            let chart = Rules.exerciseChart(row.id, in: book)!
            #expect(row.name == chart.name)
            #expect(row.sessionCount == chart.points.count)
            #expect(row.timesUp == chart.totals!.timesUp)
            #expect(row.sparkline == chart.sparkline)
            #expect(row.timesUp <= row.sessionCount)
        }
    }

    @Test("The one skipped session is not counted on its row")
    func theSkippedWeek() {
        let book = SnapshotTests.run(assertInvariants: false).book
        let chin = Rules.progress(in: book).first { $0.id == ExerciseID(105) }!
        let workoutsWithIt = book.workouts.filter { workout in
            workout.exercises.contains { $0.exerciseId == ExerciseID(105) }
        }.count
        #expect(chin.sessionCount == workoutsWithIt - 1)
    }
}
