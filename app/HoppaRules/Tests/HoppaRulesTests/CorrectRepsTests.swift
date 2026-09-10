import Testing
@testable import HoppaRules

@Suite("Correct reps on an Open Workout")
struct CorrectRepsTests {

    @Test("11 becomes 12; weight, microload and one-off stay; rest and place do not move")
    func repsChangeAndNothingElse() {
        var session = Session()
        session.start()
        session.send(.logSet(reps: 11))
        let rest = session.workout!.restStartedAt
        session.send(.correctReps(index: 0, reps: 12))

        let set = session.workout!.exercises[0].sets[0]
        #expect(set.reps == 12)
        #expect(set.weight == kg("72.5"))
        #expect(set.microload == nil)
        #expect(set.oneOff == false)
        #expect(session.workout!.restStartedAt == rest)
        #expect(session.workout!.currentIndex == 0)
        #expect(session.performed(Ids.smith)?.state == .open)
    }

    @Test("A One-off mixed-unit Set keeps its weight, Microload and mark")
    func oneOffAndMicroloadStay() {
        var session = Session()
        session.start()
        session.goTo(Ids.pulldown)
        session.send(.setOneOffWeight(lbs("90")))
        session.send(.logSet(reps: 10))
        session.send(.correctReps(index: 0, reps: 11))

        let set = session.performed(Ids.pulldown)!.sets[0]
        #expect(set.reps == 11)
        #expect(set.weight == lbs("90"))
        #expect(set.microload == kg("1"))
        #expect(set.oneOff == true)
        #expect(session.performed(Ids.pulldown)?.state == .open)
        #expect(session.workout?.currentIndex == 2)
    }

    @Test("After the last Set the Exercise stays completed and every index is legal")
    func completedExerciseStillCorrects() {
        var session = Session()
        session.start()
        session.logSets(3, reps: 11)
        #expect(session.performed(Ids.smith)?.state == .completed)

        session.send(.correctReps(index: 0, reps: 12))
        session.send(.correctReps(index: 1, reps: 12))
        session.send(.correctReps(index: 2, reps: 12))

        #expect(session.performed(Ids.smith)?.sets.map(\.reps) == [12, 12, 12])
        #expect(session.performed(Ids.smith)?.state == .completed)
        #expect(session.workout?.currentIndex == 0)
    }

    @Test("An out-of-range index leaves the Logbook, including rest, unchanged")
    func outOfRangeRefuses() {
        var session = Session()
        session.start()
        session.send(.logSet(reps: 11))
        let before = session.book
        let rest = session.workout!.restStartedAt
        session.send(.correctReps(index: 4, reps: 12))
        session.send(.correctReps(index: -1, reps: 12))

        #expect(session.book == before)
        #expect(session.workout!.restStartedAt == rest)
        #expect(session.performed(Ids.smith)?.sets[0].reps == 11)
    }

    @Test("A stale index after leaving the Exercise refuses")
    func staleIndexAfterNavigationRefuses() {
        var session = Session()
        session.start()
        session.send(.logSet(reps: 11))
        session.goTo(Ids.row)
        let before = session.book
        session.send(.correctReps(index: 0, reps: 12))

        #expect(session.book == before)
        #expect(session.performed(Ids.smith)?.sets[0].reps == 11)
    }

    @Test("No Open Workout leaves the Logbook unchanged")
    func noOpenWorkoutRefuses() {
        var session = Session()
        let before = session.book
        session.send(.correctReps(index: 0, reps: 12))
        #expect(session.book == before)
    }

    @Test("Negative reps land on 0")
    func negativeRepsClampToZero() {
        var session = Session()
        session.start()
        session.send(.logSet(reps: 11))
        session.send(.correctReps(index: 0, reps: -3))
        #expect(session.performed(Ids.smith)?.sets[0].reps == 0)
        #expect(session.performed(Ids.smith)?.sets[0].weight == kg("72.5"))
    }

    @Test("Finish after 11→12 on the last failing Set progresses")
    func finishReadsTheCorrectedSets() {
        var session = Session()
        session.start()
        session.send(.logSet(reps: 12))
        session.send(.logSet(reps: 12))
        session.send(.logSet(reps: 11))
        session.send(.correctReps(index: 2, reps: 12))
        session.send(.skipRemainingAndFinish)

        #expect(session.stored(Ids.smith)?.workingWeight == kg("75"))
        #expect(session.performed(Ids.smith)?.sets.map(\.reps) == [12, 12, 12])
        #expect(session.performed(Ids.smith)?.outcome?.progressed == true)
    }
}
