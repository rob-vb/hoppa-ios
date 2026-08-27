import Testing
@testable import HoppaRules

// Ticket 0047 — §6.7's Workout list.
//
// The list is read twice here: once against a Workout built tap by tap, where every figure
// on the row can be counted by hand, and once against the 56-Workout snapshot, which is the
// only fixture in the effort with holes, a skip and a One-off in it.

@Suite("The Workout list (SPEC.md §6.7)")
struct HistoryTests {

    // MARK: - One Workout, counted by hand

    @Test("Before the first Workout the list is empty")
    func empty() {
        #expect(Rules.history(in: upperALogbook()).isEmpty)
    }

    @Test("An Open Workout is not history — it has been started, not done")
    func openWorkoutIsNotHistory() {
        var session = Session()
        session.start()
        session.logSets(3)
        #expect(Rules.history(in: session.book).isEmpty)
    }

    @Test("A row counts the Exercises performed, the Sets, the skips and the green line")
    func theCounts() {
        var session = Session()
        session.start()
        // Upper A holds five Exercises. Three Sets at Target Reps on the first, which is
        // what §4.1 asks for, then skip the rest.
        session.logSets(3)
        session.send(.skipRemainingAndFinish)

        let rows = Rules.history(in: session.book)
        #expect(rows.count == 1)
        let row = rows[0]
        #expect(row.workoutDayName == "Upper A")
        #expect(row.exerciseCount == 1)
        #expect(row.skippedCount == 4)
        #expect(row.setCount == 3)
        #expect(row.wentUpCount == 1)
    }

    @Test("A Workout that moved nothing has no green line")
    func nothingWentUp() {
        var session = Session()
        session.start()
        // Every planned Set logged, every one of them short of the threshold, so §4.1
        // does not fire. A Set logged under it is still a Set the row counts.
        session.logSets(3, reps: 5)
        session.send(.skipRemainingAndFinish)

        let row = Rules.history(in: session.book)[0]
        #expect(row.wentUpCount == 0)
        #expect(row.exerciseCount == 1)
        #expect(row.setCount == 3)
    }

    @Test("The row keeps the day the Workout started, not the day it was finished")
    func theDayItStarted() {
        var session = Session()
        session.start()
        let started = session.book.openWorkout!.startedAt
        session.clock += 20 * 3600      // finished the next morning
        session.send(.skipRemainingAndFinish)

        #expect(Rules.history(in: session.book)[0].startedAt == started)
    }

    // MARK: - The Name on a row (§2.7)

    @Test("A renamed Workout Day reads its new Name all the way down the list")
    func aRenamedDay() {
        var session = Session()
        session.start()
        session.send(.skipRemainingAndFinish)
        session.send(.renameWorkoutDay(Ids.upperA, name: "Push"))

        #expect(Rules.history(in: session.book)[0].workoutDayName == "Push")
    }

    @Test("A deleted Workout Day keeps the Name it had — nothing else can say what was trained")
    func aDeletedDay() {
        var session = Session()
        session.start()
        session.send(.skipRemainingAndFinish)
        session.send(.deleteWorkoutDay(Ids.upperA))

        #expect(Rules.history(in: session.book)[0].workoutDayName == "Upper A")
    }

    // MARK: - Sixteen weeks of it

    @Test("Fifty-six Workouts, newest first")
    func reverseDateOrder() {
        let book = SnapshotTests.run(assertInvariants: false).book
        let rows = Rules.history(in: book)

        #expect(rows.count == 56)
        #expect(rows.count == book.workouts.count)
        #expect(rows[0].startedAt == book.workouts.last!.startedAt)
        for (newer, older) in zip(rows, rows.dropFirst()) {
            #expect(newer.startedAt > older.startedAt)
        }
    }

    @Test("The one skipped Exercise is counted once, and never inside the Exercise count")
    func theSkippedWeek() {
        let book = SnapshotTests.run(assertInvariants: false).book
        let rows = Rules.history(in: book)
        let withASkip = rows.filter { $0.skippedCount > 0 }

        // Week 14, Upper A, the weighted chin-up. One Workout in fifty-six.
        #expect(withASkip.count == 1)
        let row = withASkip[0]
        #expect(row.workoutDayName == "Upper A")
        #expect(row.skippedCount == 1)
        // Upper A holds five, so four were performed and none of the four is the skip.
        #expect(row.exerciseCount == 4)
    }

    @Test("Every row's figures are the Workout's own")
    func everyRowAgreesWithItsWorkout() {
        let book = SnapshotTests.run(assertInvariants: false).book
        for row in Rules.history(in: book) {
            let workout = book.workouts.first { $0.id == row.id }!
            #expect(row.setCount == workout.loggedSetCount)
            #expect(row.exerciseCount + row.skippedCount == workout.exercises.count)
            #expect(row.wentUpCount <= row.exerciseCount)
        }
    }

    @Test("A One-off Workout progresses nothing, so its row shows no green line")
    func theOneOffWeek() {
        let book = SnapshotTests.run(assertInvariants: false).book
        // Week 13's Smith bench was performed 7.5 kg lighter for one Workout.
        let workout = book.workouts.first { workout in
            workout.exercises.contains { $0.oneOffWeight != nil }
        }!
        let row = Rules.historyRow(workout.id, in: book)!
        let oneOff = workout.exercises.first { $0.oneOffWeight != nil }!
        #expect(oneOff.outcome?.progressed == false)
        #expect(row.wentUpCount == workout.exercises.filter { $0.outcome?.progressed == true }.count)
    }

    @Test("A row is found by id, and an unknown id finds nothing")
    func byId() {
        let book = SnapshotTests.run(assertInvariants: false).book
        let newest = book.workouts.last!
        #expect(Rules.historyRow(newest.id, in: book)?.startedAt == newest.startedAt)
        #expect(Rules.historyRow(WorkoutID(999_999), in: book) == nil)
    }
}
