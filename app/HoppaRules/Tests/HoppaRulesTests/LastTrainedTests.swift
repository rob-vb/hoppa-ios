import Testing
@testable import HoppaRules

// Ticket 0032 — the Workout Day picker.
//
// §3.1 puts "when the user last did each Day" on every row. The instant is a rule; the
// phrasing ("4 days ago") is not, and lives in the app with the calendar it needs.

@Suite("Last trained (SPEC.md §3.1)")
struct LastTrainedTests {

    /// Two Days, one Program, so a Workout on one cannot answer for the other.
    private func twoDayLogbook() -> Logbook {
        Logbook(
            nextId: 100,
            plateInventory: rackKg(),
            programs: [
                Program(
                    id: Ids.program, name: "Upper / Lower",
                    defaultWeightUnit: .kg, mode: .progressiveOverload,
                    days: [
                        WorkoutDay(id: Ids.upperA, name: "Upper A", exercises: upperAExercises()),
                        WorkoutDay(id: WorkoutDayID(3), name: "Lower A", exercises: upperAExercises())
                    ])
            ])
    }

    @Test("A Day never done reads nothing at all")
    func neverDone() {
        #expect(upperALogbook().lastTrained(Ids.upperA) == nil)
    }

    @Test("It reads the newest finished Workout on that Day")
    func newestFinished() {
        var session = Session(twoDayLogbook())
        session.start()
        session.send([.skipRemainingAndFinish])
        let first = session.book.workouts.last!.startedAt

        session.start()
        session.send([.skipRemainingAndFinish])
        let second = session.book.workouts.last!.startedAt

        #expect(second > first)
        #expect(session.book.lastTrained(Ids.upperA) == second)
    }

    @Test("A Workout on another Day never answers for this one")
    func perDay() {
        var session = Session(twoDayLogbook())
        session.start(Ids.upperA)
        session.send([.skipRemainingAndFinish])

        #expect(session.book.lastTrained(Ids.upperA) != nil)
        #expect(session.book.lastTrained(WorkoutDayID(3)) == nil)
    }

    /// Started is not done. A picker that counted the Open Workout would say the user
    /// trained today the moment he tapped a row, before he lifted anything.
    @Test("The Open Workout does not count")
    func openWorkoutDoesNotCount() {
        var session = Session(twoDayLogbook())
        session.start()

        #expect(session.book.openWorkout != nil)
        #expect(session.book.lastTrained(Ids.upperA) == nil)
    }

    /// §2.4: a Workout keeps the day it **started**, even when finished the next day.
    /// The picker reads that, so a session that ran past midnight counts on its own day.
    @Test("It reads startedAt, not finishedAt")
    func readsStartedAt() {
        var session = Session(twoDayLogbook())
        session.start()
        let started = session.book.openWorkout!.startedAt
        session.send([.skipRemainingAndFinish])
        let finished = session.book.workouts.last!.finishedAt!

        #expect(finished > started)
        #expect(session.book.lastTrained(Ids.upperA) == started)
    }
}
