import Foundation
import Testing
@testable import HoppaRules

// Ticket 0048 — §6.7's Workout detail, and the delete behind its ••• menu.
//
// The suite is built around the one thing the ticket was written for: **a Workout read
// back weeks later must not state a number that has moved since**. So most of these run
// the Workout, then change the world underneath it — a progression, a re-weigh by hand, a
// rename, a delete — and read the detail again.

@Suite("SPEC.md §6.7 — a past Workout, opened and deleted")
struct PastWorkoutTests {

    // MARK: - The record, read back

    @Test("Every Set is read back exactly as it was logged")
    func everySetAsPerformed() {
        var session = Session()
        session.start()
        session.logSets(1, reps: 12)
        session.logSets(1, reps: 11)
        session.logSets(1, reps: 10)
        session.send(.skipRemainingAndFinish)

        let past = Rules.pastWorkout(session.lastFinished!.id, in: session.book)!
        let smith = past.exercises[0]
        #expect(smith.name == "Smith machine bench press")
        #expect(smith.sets.map(\.reps) == [12, 11, 10])
        #expect(smith.sets.allSatisfy { $0.weight.weight == kg("72.5") })
        // Threshold 12 under Progressive Overload: the top of the Rep Range.
        #expect(smith.sets.map(\.metThreshold) == [true, false, false])
    }

    @Test("A Skipped Exercise is listed plain, with no Sets")
    func aSkip() {
        var session = Session()
        session.start()
        session.logSets(3)
        session.send(.skipRemainingAndFinish)

        let past = Rules.pastWorkout(session.lastFinished!.id, in: session.book)!
        #expect(past.exercises.count == 5)
        #expect(past.exercises[0].progression == .wentUp(
            from: PastWeight(weight: kg("72.5")), to: PastWeight(weight: kg("75"))))
        for skipped in past.exercises.dropFirst() {
            #expect(skipped.progression == .skipped)
            #expect(skipped.sets.isEmpty)
        }
    }

    @Test("An Exercise that stayed says so, and states no future")
    func stayed() {
        var session = Session()
        session.start()
        session.logSets(3, reps: 9)     // short of 12
        session.send(.skipRemainingAndFinish)

        let past = Rules.pastWorkout(session.lastFinished!.id, in: session.book)!
        #expect(past.exercises[0].progression == .stayed)
        #expect(past.exercises[0].sets.allSatisfy { !$0.metThreshold })
    }

    @Test("The header's counts are the list row's, so the two can never disagree")
    func theHeaderIsTheRow() {
        var session = Session()
        session.start()
        session.logSets(3)
        session.send(.skipRemainingAndFinish)

        let id = session.lastFinished!.id
        #expect(Rules.pastWorkout(id, in: session.book)!.row == Rules.historyRow(id, in: session.book))
    }

    // MARK: - The thing this ticket was written for

    @Test("A Went-up row states the weight the Workout ended on, not the weight today")
    func theWeightDoesNotDriftWithTheExercise() {
        var session = Session()
        session.start()
        session.logSets(3)                       // 72.5 → 75
        session.send(.skipRemainingAndFinish)
        let first = session.lastFinished!.id

        // Two more Workouts on the same Exercise, and the weight climbs with them.
        for _ in 0..<2 {
            session.start()
            session.logSets(3)
            session.send(.skipRemainingAndFinish)
        }
        #expect(session.resolved(Ids.smith)?.workingWeight == kg("80"))

        // The first Workout still says what it did at the time.
        let past = Rules.pastWorkout(first, in: session.book)!
        #expect(past.exercises[0].progression == .wentUp(
            from: PastWeight(weight: kg("72.5")), to: PastWeight(weight: kg("75"))))
    }

    @Test("A weight set by hand afterwards does not rewrite what a past Workout says")
    func aWeightSetByHandAfterwards() {
        var session = Session()
        session.start()
        session.logSets(3)
        session.send(.skipRemainingAndFinish)
        let id = session.lastFinished!.id

        // §4.3: the user sets it himself, weeks later, and lower.
        session.send(.reweigh(Ids.smith, kg("60")))

        #expect(Rules.pastWorkout(id, in: session.book)!.exercises[0].progression
                == .wentUp(from: PastWeight(weight: kg("72.5")), to: PastWeight(weight: kg("75"))))
    }

    @Test("An edited Rep Range does not re-mark the Sets of a Workout already finished")
    func anEditedRepRangeLeavesTheMarksAlone() {
        var session = Session()
        session.start()
        session.logSets(3, reps: 9)
        session.send(.skipRemainingAndFinish)
        let id = session.lastFinished!.id

        var draft = ExerciseDraft(session.stored(Ids.smith)!, in: session.book.plateInventory)
        draft.repRange = RepRange(6, 8)          // 9 would now clear the threshold
        session.send(.saveExercise(Ids.smith, draft: draft))

        let past = Rules.pastWorkout(id, in: session.book)!
        #expect(past.exercises[0].sets.allSatisfy { !$0.metThreshold })
        #expect(past.exercises[0].progression == .stayed)
    }

    @Test("The Increment moving afterwards cannot move a recorded progression")
    func aMovedIncrement() {
        var session = Session()
        session.start()
        session.logSets(3)
        session.send(.skipRemainingAndFinish)
        let id = session.lastFinished!.id

        var draft = ExerciseDraft(session.stored(Ids.smith)!, in: session.book.plateInventory)
        draft.increment = kg("10")
        session.send(.saveExercise(Ids.smith, draft: draft))

        #expect(Rules.pastWorkout(id, in: session.book)!.exercises[0].progression
                == .wentUp(from: PastWeight(weight: kg("72.5")), to: PastWeight(weight: kg("75"))))
    }

    // MARK: - The two-number cases

    @Test("A mixed-unit pin keeps both numbers in their own units, converting nothing")
    func aMixedUnitPin() {
        var session = Session()
        session.start()
        session.goTo(Ids.pulldown)
        session.logSets(3)              // 100 lbs + 1 kg, Microloading by a 1 kg plate
        session.send(.skipRemainingAndFinish)

        let past = Rules.pastWorkout(session.lastFinished!.id, in: session.book)!
        let pulldown = past.exercises.first { $0.exerciseId == Ids.pulldown }!
        guard case .wentUp(let from, let to) = pulldown.progression else {
            Issue.record("The pulldown met its threshold and should have gone up.")
            return
        }
        #expect(from.weight == lbs("100"))
        #expect(from.microload == kg("1"))
        // The roll-up: 1 + 1 = 2 kg is still under a 10 lbs Stack Step, so the pin holds.
        #expect(to?.weight == lbs("100"))
        #expect(to?.microload == kg("2"))
    }

    @Test("A One-off replaces the verdict and states the Working Weight that survived")
    func aOneOff() {
        var session = Session()
        session.start()
        session.send(.setOneOffWeight(kg("65")))
        session.logSets(3)              // every Set at Target Reps, and it still cannot move
        session.send(.skipRemainingAndFinish)
        let id = session.lastFinished!.id

        let past = Rules.pastWorkout(id, in: session.book)!
        #expect(past.exercises[0].progression == .oneOff(stayed: PastWeight(weight: kg("72.5"))))
        // **Never marked, whatever the reps** (§6.7): the column could not have filled.
        #expect(past.exercises[0].sets.allSatisfy { !$0.metThreshold })
        #expect(past.exercises[0].sets.allSatisfy { $0.weight.weight == kg("65") })

        // And the weight it names is the one that stood then, not the one that stands now.
        session.start()
        session.logSets(3)
        session.send(.skipRemainingAndFinish)
        #expect(session.resolved(Ids.smith)?.workingWeight == kg("75"))
        #expect(Rules.pastWorkout(id, in: session.book)!.exercises[0].progression
                == .oneOff(stayed: PastWeight(weight: kg("72.5"))))
    }

    @Test("A weight raised at the rack leaves the Sets before it lighter")
    func aRaiseMidExercise() {
        var session = Session()
        session.start()
        session.logSets(1, reps: 12)
        session.send(.setWorkingWeight(kg("77.5")))
        session.logSets(2, reps: 12)
        session.send(.skipRemainingAndFinish)

        let past = Rules.pastWorkout(session.lastFinished!.id, in: session.book)!
        #expect(past.exercises[0].sets.map(\.weight.weight) == [kg("72.5"), kg("77.5"), kg("77.5")])
        // `from` is the last Set's own weight, which is what the Exercise stood at when
        // Finish read it (§2.5, §6.4).
        #expect(past.exercises[0].progression == .wentUp(
            from: PastWeight(weight: kg("77.5")), to: PastWeight(weight: kg("80"))))
    }

    // MARK: - Names, and what a delete leaves behind (§2.7, §2.8)

    @Test("A renamed Exercise reads its new Name; a deleted one keeps the Name it had")
    func names() {
        var session = Session()
        session.start()
        session.logSets(3)
        session.send(.skipRemainingAndFinish)
        let id = session.lastFinished!.id

        var draft = ExerciseDraft(session.stored(Ids.smith)!, in: session.book.plateInventory)
        draft.name = "Smith bench"
        session.send(.saveExercise(Ids.smith, draft: draft))
        #expect(Rules.pastWorkout(id, in: session.book)!.exercises[0].name == "Smith bench")

        session.send(.deleteExercise(Ids.smith))
        let after = Rules.pastWorkout(id, in: session.book)!.exercises[0]
        // **The Name as it read at the time** (§2.4), which is the Name the Workout
        // started under and not the rename that came later. A rename corrects a live
        // Exercise; once the live Exercise is gone there is nothing left to correct, and
        // the stored copy is the only thing that can say what was trained.
        #expect(after.name == "Smith machine bench press")
        // The outcome was written at Finish and survives the delete, so the row still
        // states what it earned. **`gone` is the mid-Workout delete only.**
        #expect(after.progression == .wentUp(
            from: PastWeight(weight: kg("72.5")), to: PastWeight(weight: kg("75"))))
        #expect(after.sets.count == 3)
    }

    @Test("An Exercise deleted mid-Workout has no outcome to state")
    func deletedMidWorkout() {
        var session = Session()
        session.start()
        session.logSets(3)
        session.send(.deleteExercise(Ids.smith))
        session.send(.skipRemainingAndFinish)

        let past = Rules.pastWorkout(session.lastFinished!.id, in: session.book)!
        let smith = past.exercises.first { $0.exerciseId == Ids.smith }!
        #expect(smith.progression == .gone)
        #expect(smith.sets.count == 3)
        // No recorded threshold, so no Set is marked. A mark would be a guess.
        #expect(smith.sets.allSatisfy { !$0.metThreshold })
    }

    // MARK: - The delete (§6.7)

    @Test("Deleting a Workout removes every Set of it, and nothing else")
    func theDelete() {
        var session = Session()
        session.start()
        session.logSets(3)
        session.send(.skipRemainingAndFinish)
        let id = session.lastFinished!.id
        let weightsAfterFinish = session.book.programs

        session.send(.deleteWorkout(id))

        #expect(session.book.workouts.isEmpty)
        #expect(Rules.history(in: session.book).isEmpty)
        #expect(Rules.pastWorkout(id, in: session.book) == nil)
        #expect(Rules.historyRow(id, in: session.book) == nil)
        // **The working weights stay where they are** — the whole second half of the
        // confirm, and the reason there is no recomputation here (§4.1, §4.3).
        #expect(session.book.programs == weightsAfterFinish)
        #expect(session.resolved(Ids.smith)?.workingWeight == kg("75"))
    }

    @Test("Deleting one Workout leaves the others alone")
    func deleteOneOfMany() {
        var session = Session()
        for _ in 0..<3 {
            session.start()
            session.logSets(3)
            session.send(.skipRemainingAndFinish)
        }
        let middle = session.book.workouts[1].id
        session.send(.deleteWorkout(middle))

        #expect(session.book.workouts.count == 2)
        #expect(!session.book.workouts.contains { $0.id == middle })
        #expect(session.resolved(Ids.smith)?.workingWeight == kg("80"))
    }

    @Test("An unknown id deletes nothing, and the Open Workout is out of reach")
    func deleteRefusals() {
        var session = Session()
        session.start()
        session.logSets(3)
        session.send(.skipRemainingAndFinish)
        session.start()                                  // a second Workout, still Open
        let before = session.book

        session.send(.deleteWorkout(WorkoutID(999_999)))
        #expect(session.book == before)

        // The Open Workout's own id names nothing in `workouts`, so this is a no-op too.
        session.send(.deleteWorkout(before.openWorkout!.id))
        #expect(session.book == before)
        #expect(session.book.openWorkout != nil)
    }

    // MARK: - Sixteen weeks of it

    @Test("Every Workout in the 56-Workout history reads back")
    func theWholeHistory() {
        let book = SnapshotTests.run(assertInvariants: false).book
        for row in Rules.history(in: book) {
            let past = Rules.pastWorkout(row.id, in: book)!
            let workout = book.workouts.first { $0.id == row.id }!
            #expect(past.exercises.count == workout.exercises.count)
            #expect(past.exercises.reduce(0) { $0 + $1.sets.count } == row.setCount)
            let up = past.exercises.filter { if case .wentUp = $0.progression { true } else { false } }
            #expect(up.count == row.wentUpCount)
            // **Nothing that went up is missing its number**, across fifty-six Workouts.
            for exercise in up {
                guard case .wentUp(_, let to) = exercise.progression else { continue }
                #expect(to != nil)
            }
        }
    }

    @Test("The One-off week reads as a One-off, three weeks after the fact")
    func theOneOffWeekReadsBack() {
        let book = SnapshotTests.run(assertInvariants: false).book
        let workout = book.workouts.first { $0.exercises.contains { $0.oneOffWeight != nil } }!
        let past = Rules.pastWorkout(workout.id, in: book)!
        let oneOff = past.exercises.first {
            if case .oneOff = $0.progression { return true } else { return false }
        }
        #expect(oneOff != nil)
        #expect(oneOff!.sets.allSatisfy { !$0.metThreshold })
    }

    // MARK: - History written before this ticket existed

    /// The fixture as it stood **before** `workingWeightAfter` was recorded — the shape of
    /// every Workout already on Rob's phone. It must still decode, and the detail must
    /// read back with its verdict and without a number rather than inventing one.
    @Test("A Workout finished by an older build reads back, minus the number")
    func historyFromBeforeThisTicket() throws {
        let url = Recording.directory.appendingPathComponent("Fixtures/logbook-before-0048.json")
        let book = try JSONDecoder().decode(Logbook.self, from: try Data(contentsOf: url))

        let workout = try #require(book.workouts.last)
        #expect(workout.exercises.allSatisfy { $0.outcome?.workingWeightAfter == nil })

        let past = try #require(Rules.pastWorkout(workout.id, in: book))
        let smith = past.exercises[0]
        guard case .wentUp(let from, let to) = smith.progression else {
            Issue.record("The Smith bench went up in that fixture.")
            return
        }
        #expect(from.weight == kg("72.5"))
        #expect(to == nil)
        // And the Sets still mark, because the threshold was always recorded.
        #expect(smith.sets.map { $0.metThreshold } == [true, true, true])
    }
}
