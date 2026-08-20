import Testing
@testable import HoppaRules

/// The nine walkthroughs of `SPEC.md` §6.4, which the logging prototype drove end to end
/// and which the user approved **outright on the first pass**.
///
/// They are the only validated record of how logging behaves, and each was written to
/// demonstrate one rule — so they are this package's acceptance tests. The keypad taps
/// and the overlays are gone: a draft buffer is not a rule. What the keypad produced
/// arrives here as a finished `Weight`.
@Suite("SPEC.md §6.4 — the nine walkthroughs")
struct WalkthroughTests {

    // 1
    @Test("Everything at the top of the range — 5 Exercises progress")
    func everythingGoesUp() {
        var session = Session()
        session.start()
        session.logSets(3, reps: 12)                     // Smith bench, 8-12
        session.send(.nextOpen)
        session.logSets(3, reps: 10)                     // Barbell row, 8-10
        session.send(.nextOpen)
        session.logSets(3, reps: 12)                     // Lat pulldown, 10-12
        session.send(.nextOpen)
        session.logSets(3, reps: 12)                     // Dumbbell press, 8-12
        session.send(.nextOpen)
        session.logSets(3, reps: 8)                      // Chin-up, 6-8
        session.send(.finish)

        #expect(session.workout == nil)
        let finished = session.lastFinished!
        #expect(finished.exercises.filter { $0.outcome?.progressed == true }.count == 5)

        #expect(session.stored(Ids.smith)?.workingWeight == kg("75"))
        #expect(session.stored(Ids.row)?.workingWeight == kg("62.5"))
        #expect(session.stored(Ids.press)?.workingWeight == kg("25"))
        #expect(session.stored(Ids.chin)?.workingWeight == kg("17.5"))
        // Mixed units: the Microload moves and the pin holds. Two numbers, no total.
        #expect(session.stored(Ids.pulldown)?.workingWeight == lbs("100"))
        #expect(session.stored(Ids.pulldown)?.microload == kg("2"))
    }

    // 2
    @Test("Done early, 2 of 3 Sets at 12 — 0 progress, the rule bites as designed")
    func doneEarly() {
        var session = Session()
        session.start()
        session.logSets(2, reps: 12)
        session.send(.doneEarly)
        session.send(.finish)                            // 4 still Open: the gate holds
        #expect(session.workout != nil)
        session.send(.skipRemainingAndFinish)

        let finished = session.lastFinished!
        #expect(finished.exercises.filter { $0.outcome?.progressed == true }.count == 0)
        #expect(session.performed(Ids.smith)?.state == .completed)   // real work, not a Skip
        #expect(session.stored(Ids.smith)?.workingWeight == kg("72.5"))
    }

    // 3
    @Test("14 reps against 8–12 — one Increment, never more")
    func repsAboveTheRange() {
        var session = Session()
        session.start()
        session.send(.logSet(reps: 14))
        session.logSets(2, reps: 12)
        session.send(.skipRemainingAndFinish)

        #expect(session.performed(Ids.smith)?.sets.map(\.reps) == [14, 12, 12])
        #expect(session.stored(Ids.smith)?.workingWeight == kg("75"))
    }

    // 4
    @Test("Lower to 65 → Just today — the Working Weight stays 72.5 kg")
    func aBadDay() {
        var session = Session()
        session.start()
        session.send(.setOneOffWeight(kg("65")))
        session.logSets(3, reps: 12)
        session.send(.skipRemainingAndFinish)

        let performed = session.performed(Ids.smith)!
        #expect(performed.sets.allSatisfy { $0.weight == kg("65") && $0.oneOff })
        #expect(performed.outcome?.progressed == false)
        #expect(session.stored(Ids.smith)?.workingWeight == kg("72.5"))
    }

    // 5
    @Test("Raise to 75 by hand — it sticks silently, then progresses to 77.5")
    func raiseTheWeight() {
        var session = Session()
        session.start()
        session.send(.setWorkingWeight(kg("75")))
        #expect(session.stored(Ids.smith)?.workingWeight == kg("75"))    // no question asked

        session.logSets(3, reps: 12)
        session.send(.skipRemainingAndFinish)
        // There is no "unless you edited it" clause.
        #expect(session.stored(Ids.smith)?.workingWeight == kg("77.5"))
    }

    // 6
    @Test("Skip the Barbell row, reopen it later — inside the same Workout")
    func skipAndPutItBack() {
        var session = Session()
        session.start()
        session.goTo(Ids.row)
        session.send(.skip)
        #expect(session.performed(Ids.row)?.state == .skipped)

        session.goTo(Ids.pulldown)
        session.logSets(3, reps: 12)

        session.goTo(Ids.row)
        session.send(.reopen)
        #expect(session.performed(Ids.row)?.state == .open)
        session.logSets(3, reps: 10)
        session.send(.skipRemainingAndFinish)

        #expect(session.stored(Ids.row)?.workingWeight == kg("62.5"))
        #expect(session.stored(Ids.pulldown)?.microload == kg("2"))
    }

    // 7
    @Test("Finish with 4 Open — the gate holds, with the one-tap way out")
    func finishWithExercisesOpen() {
        var session = Session()
        session.start()
        session.logSets(3, reps: 12)
        #expect(session.workout?.openExerciseCount == 4)

        session.send(.finish)
        #expect(session.workout != nil)

        session.send(.skipRemainingAndFinish)
        #expect(session.workout == nil)
        let finished = session.lastFinished!
        #expect(finished.exercises.filter { $0.state == .skipped }.count == 4)
        #expect(finished.exercises.allSatisfy { $0.state != ExerciseState.open })
    }

    // 8
    @Test("61.25 kg on a kg rack — ≈ CLOSEST, you load 60 kg, 1.25 under")
    func aWeightTheRackCannotBuild() {
        var session = Session()
        session.start()
        session.goTo(Ids.row)
        session.send(.setWorkingWeight(kg("61.25")))

        // This Exercise runs Progressive Overload, so Microplates were never in its solve
        // — the walkthrough stands unchanged under the Mode-scoped solver of §5.3.
        let exercise = session.resolved(Ids.row)!
        guard case .bar(let load) = Rules.breakdown(for: exercise, inventory: session.book.plateInventory)
        else { Issue.record("expected a bar"); return }
        #expect(load.isExact == false)
        #expect(load.loadedTotal == kg("60"))
        #expect(load.difference == kg("-1.25"))          // a tie rounds down
        #expect(load.plates == [kg("20")])

        session.logSets(3, reps: 10)
        session.send(.skipRemainingAndFinish)
        #expect(session.performed(Ids.row)?.sets.first?.weight == kg("61.25"))
    }

    // 9
    @Test("lbs stack + kg microplate — 100 LBS over +1 KG, never converted")
    func twoUnitsInOneWorkout() {
        var session = Session()
        session.start()
        session.goTo(Ids.pulldown)

        let before = session.resolved(Ids.pulldown)!
        #expect(before.unit == .lbs)                     // the machine's own unit
        #expect(before.inventoryUnit == .kg)             // the rack's
        #expect(before.workingWeight == lbs("100"))
        #expect(before.microload == kg("1"))
        // Microloading needs only the bottom of the range, so 10 reps is enough.
        #expect(before.thresholdReps == 10)

        session.logSets(3, reps: 10)
        session.send(.skipRemainingAndFinish)

        #expect(session.stored(Ids.pulldown)?.workingWeight == lbs("100"))
        #expect(session.stored(Ids.pulldown)?.microload == kg("2"))
        #expect(session.performed(Ids.pulldown)?.sets.first?.microload == kg("1"))
        #expect(session.performed(Ids.pulldown)?.outcome?.progressed == true)

        // Total volume is the one place a conversion happens (§5.1).
        let volume = Rules.totalVolume(of: session.lastFinished!, in: session.book)
        #expect(volume.unit == .kg)
        #expect(volume.hundredths > 0)
    }
}
