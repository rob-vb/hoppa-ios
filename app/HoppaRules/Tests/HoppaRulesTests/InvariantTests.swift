import Testing
@testable import HoppaRules

/// A rack with exactly these sizes switched on.
func rack(_ unit: WeightUnit, plates: [String], microplates: [String]) -> PlateInventory {
    func size(_ text: String) -> PlateSize {
        PlateSize(weight: Weight(decimalString: text, unit: unit)!, isOn: true)
    }
    return PlateInventory(
        unit: unit,
        plates: plates.map(size).sorted { $0.weight.hundredths > $1.weight.hundredths },
        microplates: microplates.map(size).sorted { $0.weight.hundredths > $1.weight.hundredths })
}

/// One roll-up case: a mixed-unit pin, its rack, and the plate that hangs on it.
///
/// These four are `design/0015-history/check-rollup.mjs` ported straight across as data —
/// including the one it calls *the case that broke*. That file is the only correct
/// roll-up code that existed before this package.
struct RollUpCase: Sendable, CustomStringConvertible {
    let name: String
    let startWeight: String
    let exerciseUnit: WeightUnit
    let stackStep: String
    let microplate: String
    let inventory: PlateInventory

    var description: String { name }

    static let all: [RollUpCase] = [
        RollUpCase(
            name: "lbs stack, kg rack, 0.25 microplate",
            startWeight: "90", exerciseUnit: .lbs, stackStep: "10", microplate: "0.25",
            inventory: rack(.kg, plates: ["1.25", "2.5", "5", "10", "20"],
                            microplates: ["0.25", "0.5", "0.75", "1"])),
        RollUpCase(
            name: "lbs stack, kg rack, 1 microplate (the case that broke)",
            startWeight: "90", exerciseUnit: .lbs, stackStep: "10", microplate: "1",
            inventory: rack(.kg, plates: ["1.25", "2.5", "5", "10", "20"], microplates: ["1"])),
        RollUpCase(
            name: "kg stack, lbs rack, 2.5 lbs microplate",
            startWeight: "50", exerciseUnit: .kg, stackStep: "5", microplate: "2.5",
            inventory: rack(.lbs, plates: ["2.5", "5", "10", "25", "45"],
                            microplates: ["0.5", "1", "1.25", "2.5"])),
        RollUpCase(
            name: "tiny stack step, big microplate (every progression rolls)",
            startWeight: "40", exerciseUnit: .lbs, stackStep: "2.5", microplate: "1",
            inventory: rack(.kg, plates: ["1.25", "2.5", "5", "10", "20"], microplates: ["1"]))
    ]
}

@Suite("The invariants that deserve more than a snapshot")
struct InvariantTests {

    // MARK: - §4.2, the roll-up

    @Test("The roll-up holds both invariants over 40 progressions", arguments: RollUpCase.all)
    func rollUpHolds(testCase: RollUpCase) {
        let inventory = testCase.inventory
        let step = Weight(decimalString: testCase.stackStep, unit: testCase.exerciseUnit)!
        let increment = Weight(decimalString: testCase.microplate, unit: inventory.unit)!
        let stepInRackUnit = step.converted(to: inventory.unit)

        var weight = Weight(decimalString: testCase.startWeight, unit: testCase.exerciseUnit)!
        var microload = Weight.zero(inventory.unit)
        var previousTotal = totalInKg(weight, microload)
        var pinSteps = 0

        for progression in 1...40 {
            let move = Rules.rollUp(
                workingWeight: weight, microload: microload,
                increment: increment, stackStep: step, inventory: inventory)
            weight = move.workingWeight
            microload = move.microload ?? .zero(inventory.unit)
            pinSteps += move.pinSteps

            // 1. After any progression the Microload is less than one Stack Step.
            #expect(
                microload.hundredths < stepInRackUnit.hundredths,
                "progression \(progression): \(microload.decimalString) is not under one step")

            // 3. And the Microload is a weight the rack can actually build — there is no
            // point hanging 0.46 kg on a hook when the smallest plate is 1 kg.
            #expect(
                inventory.roundedUpToBuildable(microload, for: .microloading) == microload,
                "progression \(progression): \(microload.decimalString) is not buildable")

            // 2. The weight never goes down.
            let total = totalInKg(weight, microload)
            #expect(
                total.hundredths >= previousTotal.hundredths,
                "progression \(progression): \(previousTotal.decimalString) -> \(total.decimalString)")
            previousTotal = total
        }

        // The pin has to move at all — a Microload that only ever grows is the bug.
        #expect(pinSteps > 0)
    }

    @Test("A Microload the size of a Stack Step steps the pin and keeps the remainder")
    func theRemainderIsRoundedUp() {
        // One 1 kg microplate at a time on a 10 lbs pin. One step is 4.53 kg, so the
        // fifth plate rolls: 5 kg hanging, minus the step, leaves 0.46 — rounded UP to
        // 1 kg, which is the smallest thing this rack can build.
        let inventory = rack(.kg, plates: ["1.25", "2.5", "5", "10", "20"], microplates: ["1"])
        var weight = lbs("90")
        var microload = kg("0")
        for _ in 0..<5 {
            let move = Rules.rollUp(
                workingWeight: weight, microload: microload,
                increment: kg("1"), stackStep: lbs("10"), inventory: inventory)
            weight = move.workingWeight
            microload = move.microload!
        }
        #expect(weight == lbs("100"))
        #expect(microload == kg("1"))
    }

    @Test("Rounding up is what keeps the weight from dipping")
    func roundingUpNeverDips() {
        // 4.53 kg of step against a 1 kg plate leaves 0.46 kg, and 0.46 is not a weight
        // this rack builds. Rounding it *down* to zero would drop the total.
        let inventory = rack(.kg, plates: ["1.25", "2.5", "5", "10", "20"], microplates: ["1"])
        let rounded = inventory.roundedUpToBuildable(kg("0.46"), for: .microloading)
        #expect(rounded == kg("1"))
        #expect(rounded.hundredths >= 46)
    }

    // MARK: - §4.1, the rule

    @Test("Done early never progresses, however good the reps were")
    func doneEarlyNeverProgresses() {
        var session = Session()
        session.start()
        session.logSets(2, reps: 12)
        session.send(.doneEarly)
        session.send(.skipRemainingAndFinish)

        #expect(session.stored(Ids.smith)?.workingWeight == kg("72.5"))
        #expect(session.performed(Ids.smith)?.outcome?.progressed == false)
    }

    @Test("One Set under the threshold stops the whole Exercise")
    func everySetMustMeetTheThreshold() {
        var session = Session()
        session.start()
        session.send(.logSet(reps: 12))
        session.send(.logSet(reps: 11))
        session.send(.logSet(reps: 12))
        session.send(.skipRemainingAndFinish)

        #expect(session.stored(Ids.smith)?.workingWeight == kg("72.5"))
        #expect(session.performed(Ids.smith)?.outcome?.progressed == false)
    }

    @Test("Reps above the top raise the weight once, never more")
    func repsAboveTheTopRaiseOnce() {
        var session = Session()
        session.start()
        session.logSets(3, reps: 14)                     // the range tops out at 12
        session.send(.skipRemainingAndFinish)

        #expect(session.stored(Ids.smith)?.workingWeight == kg("75"))
        #expect(session.performed(Ids.smith)?.sets.map(\.reps) == [14, 14, 14])
    }

    @Test("A One-off Weight logs its Sets and never progresses")
    func aOneOffNeverProgresses() {
        var session = Session()
        session.start()
        session.send(.setOneOffWeight(kg("65")))
        session.logSets(3, reps: 12)
        session.send(.skipRemainingAndFinish)

        #expect(session.stored(Ids.smith)?.workingWeight == kg("72.5"))
        #expect(session.performed(Ids.smith)?.outcome?.progressed == false)
        #expect(session.performed(Ids.smith)?.sets.allSatisfy { $0.oneOff } == true)
        #expect(session.performed(Ids.smith)?.sets.first?.weight == kg("65"))
    }

    @Test("A Skipped Exercise logs no Sets and never progresses")
    func aSkippedExerciseNeverProgresses() {
        var session = Session()
        session.start()
        session.logSets(2, reps: 12)
        session.send(.skip)
        session.send(.skipRemainingAndFinish)

        #expect(session.performed(Ids.smith)?.sets.isEmpty == true)
        #expect(session.stored(Ids.smith)?.workingWeight == kg("72.5"))
    }

    @Test("Hoppa reads the Exercise as it stands at Finish")
    func theExerciseIsReadAtFinish() {
        // Three Sets at the top of 8-12, then the Rep Range is edited to 8-14 at the
        // rack. Finish reads 14, and the Exercise no longer qualifies.
        var session = Session()
        session.start()
        session.logSets(3, reps: 12)
        session.book.updateExercise(Ids.smith) { $0.repRange = RepRange(8, 14) }
        session.send(.skipRemainingAndFinish)

        #expect(session.performed(Ids.smith)?.outcome?.thresholdReps == 14)
        #expect(session.performed(Ids.smith)?.outcome?.progressed == false)
        #expect(session.stored(Ids.smith)?.workingWeight == kg("72.5"))
    }

    @Test("A weight changed by hand progresses under the normal rules")
    func aHandChangedWeightStillProgresses() {
        var session = Session()
        session.start()
        session.send(.setWorkingWeight(kg("75")))
        session.logSets(3, reps: 12)
        session.send(.skipRemainingAndFinish)

        #expect(session.stored(Ids.smith)?.workingWeight == kg("77.5"))
    }

    // MARK: - §5.3 and §5.4, the solver

    @Test("The Mode decides which plates the solver may use")
    func theSolverIsScopedToTheMode() {
        let inventory = rackKg()
        var exercise = upperAExercises()[1]
        exercise.workingWeight = kg("60.5")             // 20.25 per side

        let coarse = Rules.breakdown(
            for: exercise.resolved(mode: .progressiveOverload, inventory: inventory),
            inventory: inventory)
        let fine = Rules.breakdown(
            for: exercise.resolved(mode: .microloading, inventory: inventory),
            inventory: inventory)

        guard case .bar(let a) = coarse, case .bar(let b) = fine else {
            Issue.record("expected two bars"); return
        }
        #expect(a.isExact == false)                      // the same weight...
        #expect(b.isExact == true)                       // ...two different loads
        #expect(b.plates == [kg("20"), kg("0.25")])
    }

    @Test("The closest buildable load wins, and a tie rounds down")
    func aTieRoundsDown() {
        let inventory = rackKg()
        var exercise = upperAExercises()[1]              // Barbell row, 20 kg bar
        exercise.workingWeight = kg("61.25")             // exactly between 60 and 62.5

        guard case .bar(let load) = Rules.breakdown(
            for: exercise.resolved(mode: .progressiveOverload, inventory: inventory),
            inventory: inventory)
        else { Issue.record("expected a bar"); return }

        #expect(load.isExact == false)
        #expect(load.loadedTotal == kg("60"))            // down, not up
        #expect(load.difference == kg("-1.25"))
        #expect(load.perSide == kg("20"))
    }

    @Test("The big number never bends to fit the rack")
    func theWorkingWeightNeverBends() {
        var session = Session()
        session.start()
        session.goTo(Ids.row)
        session.send(.setWorkingWeight(kg("61.25")))
        session.logSets(3, reps: 10)
        session.send(.skipRemainingAndFinish)

        // Sets are logged against the Working Weight, not against what was on the bar.
        #expect(session.performed(Ids.row)?.sets.first?.weight == kg("61.25"))
        #expect(session.stored(Ids.row)?.workingWeight == kg("63.75"))
    }

    @Test("The pin takes the largest Stack Step at or under the Working Weight")
    func thePinFollowsTheWorkingWeight() {
        let book = upperALogbook()
        let pulldown = book.resolvedExercise(Ids.pulldown)!
        guard case .stack(let load) = Rules.breakdown(for: pulldown, inventory: book.plateInventory)
        else { Issue.record("expected a stack"); return }

        #expect(load.blocks == 10)
        #expect(load.pinWeight == lbs("100"))
        #expect(load.microload == kg("1"))               // never a total, never converted
    }

    // MARK: - §5.1, units

    @Test("A plate-loaded Exercise reads its unit off the rack, and never converts")
    func theUnitIsDerivedNotStored() {
        var exercise = upperAExercises()[1]              // Barbell row, kg
        exercise.ownWeightUnit = .lbs                    // a stale field, deliberately
        let inLbsGym = exercise.resolved(mode: .progressiveOverload, inventory: .standard(.lbs))

        #expect(inLbsGym.unit == .lbs)                   // the rack decides
        #expect(inLbsGym.workingWeight?.hundredths == 6000)  // relabelled, not converted
        #expect(exercise.resolved(mode: .progressiveOverload, inventory: rackKg()).unit == .kg)
    }

    @Test("A Dumbbell reads its unit off the rack, even when ownWeightUnit is stale")
    func aDumbbellTakesTheRackUnit() {
        var dumbbell = upperAExercises()[3]
        dumbbell.ownWeightUnit = .lbs
        let inLbsGym = dumbbell.resolved(mode: .progressiveOverload, inventory: .standard(.lbs))

        #expect(inLbsGym.unit == .lbs)
        #expect(dumbbell.resolved(mode: .progressiveOverload, inventory: rackKg()).unit == .kg)
    }

    @Test("Microloading with no Microplate switched on cannot progress")
    func microloadingWithoutAMicroplate() {
        let inventory = PlateInventory.standard(.kg)     // every Microplate ships OFF
        var exercise = upperAExercises()[1]
        exercise.microloadingIncrement = nil
        let resolved = exercise.resolved(mode: .microloading, inventory: inventory)

        #expect(Rules.progressionMove(for: resolved, inventory: inventory) == nil)
    }

    // MARK: - §3.3, the gate

    @Test("Finish is refused while an Exercise is Open, and the shortcut ends it")
    func finishIsGated() {
        var session = Session()
        session.start()
        session.logSets(3, reps: 12)
        #expect(session.workout?.openExerciseCount == 4)

        session.send(.finish)
        #expect(session.workout != nil)                  // the gate holds

        session.send(.skipRemainingAndFinish)
        #expect(session.workout == nil)
        #expect(session.lastFinished?.state == .finished)
        // Nothing stays ambiguous: every Exercise ended Completed or Skipped.
        #expect(session.lastFinished?.exercises.allSatisfy { $0.state != .open } == true)
    }

    @Test("One Open Workout at a time")
    func oneOpenWorkoutAtATime() {
        var session = Session()
        session.start()
        let first = session.workout?.id
        session.start()
        #expect(session.workout?.id == first)
        #expect(session.book.workouts.isEmpty)
    }

    // MARK: - the weight, exactly

    @Test("A weight is exact, and adding a quarter fifty times says so")
    func aWeightIsExact() {
        var weight = kg("0")
        for _ in 0..<50 { weight = weight + kg("0.25") }
        #expect(weight == kg("12.5"))
        #expect(weight.decimalString == "12.5")
    }

    @Test("Weights parse and print without a Double in sight")
    func weightsRoundTripAsText() {
        for text in ["0", "0.25", "1.25", "2.5", "20", "61.25", "72.5", "100"] {
            #expect(kg(text).decimalString == text)
        }
        #expect(Weight(decimalString: "1.005", unit: .kg) == nil)
        #expect(Weight(decimalString: "", unit: .kg) == nil)
        #expect(Weight(decimalString: "kg", unit: .kg) == nil)
        #expect(Weight(decimalString: "1,25", unit: .kg) == kg("1.25"))
    }
}

/// The total, in kg, for an invariant that has to see both numbers at once. Nothing on a
/// screen ever does this (`SPEC.md` §5.5: there is no combined total anywhere).
func totalInKg(_ weight: Weight, _ microload: Weight) -> Weight {
    weight.converted(to: .kg) + microload.converted(to: .kg)
}
