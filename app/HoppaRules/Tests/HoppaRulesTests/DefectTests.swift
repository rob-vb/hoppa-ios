import Testing
@testable import HoppaRules

/// One test per defect in `SPEC.md` §8.2.
///
/// The list is exact — it names the wrong behaviour and the right one — so each defect
/// becomes a named test. **The spec is right and the prototype is wrong.** Every one of
/// these fails against `Fitty` as it stands in
/// `design/0007-logging/fitty-workout-logging.html`.
///
/// The two Workout Summary defects are not here: they ride with the summary screen.
@Suite("SPEC.md §8.2 — the eight defects of the prototype")
struct DefectTests {

    // Defect 1: `Fitty.progression()` returns `to: ex.weight` with fromPlates/toPlates
    // under Microloading — so the weight never moved at all.
    @Test("Microloading returns a new Working Weight, or a new Microload")
    func microloadingReturnsANewWeight() {
        let book = upperALogbook()

        // Mixed units: the Microload moves, and the Working Weight holds.
        let pulldown = book.resolvedExercise(Ids.pulldown)!
        let mixed = Rules.progressionMove(for: pulldown, inventory: book.plateInventory)
        #expect(mixed?.workingWeight == lbs("100"))
        #expect(mixed?.microload == kg("2"))
        #expect(mixed?.microload != pulldown.microload)

        // Same unit: the Working Weight moves, by twice the plate on a bar.
        var overhead = upperAExercises()[1]              // Barbell row
        overhead.modeOverride = .microloading
        overhead.microloadingIncrement = kg("0.5")
        let resolved = overhead.resolved(mode: .microloading, inventory: book.plateInventory)
        let move = Rules.progressionMove(for: resolved, inventory: book.plateInventory)
        #expect(move?.workingWeight == kg("61"))
        #expect(move?.workingWeight != resolved.workingWeight)
    }

    // Defect 2: `ex.microplates` — a count of plates.
    @Test("A Microload is a weight, never a count of plates")
    func theMicroloadIsAWeight() {
        var book = upperALogbook()
        book.updateExercise(Ids.pulldown) {
            $0.microload = kg("0")
            $0.microloadingIncrement = kg("0.25")
        }

        // Four progressions at 0.25 land on 1 kg — one plate, not "4 plates".
        for _ in 0..<4 {
            let exercise = book.resolvedExercise(Ids.pulldown)!
            let move = Rules.progressionMove(for: exercise, inventory: book.plateInventory)!
            book.updateExercise(Ids.pulldown) { $0.microload = move.microload }
        }
        #expect(book.exercise(Ids.pulldown)?.microload == kg("1"))

        // And it draws as one plate, because identical plates are never stacked (§5.3).
        let exercise = book.resolvedExercise(Ids.pulldown)!
        guard case .stack(let load) = Rules.breakdown(for: exercise, inventory: book.plateInventory)
        else { Issue.record("expected a stack"); return }
        #expect(load.microloadPlates == [kg("1")])
    }

    // Defect 3: `greedy()` takes `inv.plates` unconditionally.
    @Test("The solver takes the plate list the Progression Mode allows")
    func theSolverIsModeScoped() {
        let inventory = rackKg()
        var row = upperAExercises()[1]                  // Barbell row, 20 kg bar
        row.workingWeight = kg("61")                    // 20.5 per side: needs a microplate

        // Progressive Overload — normal plates only. 20.5 per side is unbuildable.
        let overload = row.resolved(mode: .progressiveOverload, inventory: inventory)
        guard case .bar(let coarse) = Rules.breakdown(for: overload, inventory: inventory)
        else { Issue.record("expected a bar"); return }
        #expect(coarse.isExact == false)

        // Microloading — the whole Inventory, Microplates included. Now it is exact.
        let micro = row.resolved(mode: .microloading, inventory: inventory)
        guard case .bar(let fine) = Rules.breakdown(for: micro, inventory: inventory)
        else { Issue.record("expected a bar"); return }
        #expect(fine.isExact)
        #expect(fine.perSide == kg("20.5"))
        #expect(fine.plates == [kg("20"), kg("0.5")])
    }

    // Defect 4: the fixture holds a 15 kg plate.
    @Test("There is no 15 kg plate")
    func thereIsNoFifteenKilogramPlate() {
        let inventory = rackKg()
        let everySize = (inventory.plates + inventory.microplates).map(\.weight)
        #expect(!everySize.contains(kg("15")))
        #expect(inventory.enabledPlates == [kg("20"), kg("10"), kg("5"), kg("2.5"), kg("1.25")])
    }

    // Defect 5: `PLATE` holds the invented colours.
    @Test("The plate palette is the user's real rack")
    func thePaletteIsTheRealRack() {
        #expect(PlatePalette.hex(for: kg("25")) == "#C8322B")
        #expect(PlatePalette.hex(for: kg("20")) == "#1F5FCB")
        #expect(PlatePalette.hex(for: kg("10")) == "#2E9E52")
        #expect(PlatePalette.hex(for: kg("5")) == "#33373A")
        #expect(PlatePalette.hex(for: kg("2.5")) == "#4E5358")
        #expect(PlatePalette.hex(for: kg("1.25")) == "#70767C")
        #expect(PlatePalette.hex(for: kg("1")) == "#C8322B")
        #expect(PlatePalette.hex(for: kg("0.75")) == "#1F5FCB")
        #expect(PlatePalette.hex(for: kg("0.5")) == "#2E9E52")
        #expect(PlatePalette.hex(for: kg("0.25")) == "#E8E6E1")
        // The plate that never existed has no colour either.
        #expect(PlatePalette.hex(for: kg("15")) == nil)
    }

    // Defect 6: `ex.blockSize`.
    @Test("It is a Stack Step, and only a pin has one")
    func stackStepIsTheName() {
        let book = upperALogbook()
        #expect(book.resolvedExercise(Ids.pulldown)?.stackStep == lbs("10"))

        // Stored values survive a change of Equipment Type, but no rule can read one
        // where it does not apply (§2.3, §2.8).
        var row = upperAExercises()[1]
        row.storedStackStep = kg("10")
        row.storedBaseWeight = kg("15")
        let resolved = row.resolved(mode: .progressiveOverload, inventory: rackKg())
        #expect(resolved.stackStep == nil)
        #expect(resolved.baseWeight == nil)
        #expect(row.storedStackStep == kg("10"))         // still there, still not readable
    }

    // A ninth defect, found while lifting and now listed in §8.2 as one: the prototype's
    // `breakdown()` puts the pin at `Math.round(w / blockSize)`, which can place it
    // **over** the Working Weight. §5.3 says the pin takes the largest Stack Step at or
    // under it, and the rest hangs on the pin.
    @Test("The pin never sits above the Working Weight")
    func thePinNeverOvershoots() {
        var book = upperALogbook()
        book.plateInventory = .standard(.lbs)            // an lbs rack, so the stack matches
        book.updateExercise(Ids.pulldown) { $0.workingWeight = lbs("105") }

        let exercise = book.resolvedExercise(Ids.pulldown)!
        guard case .stack(let load) = Rules.breakdown(for: exercise, inventory: book.plateInventory)
        else { Issue.record("expected a stack"); return }

        #expect(load.blocks == 10)                       // not 11, which rounding would give
        #expect(load.pinWeight == lbs("100"))
        #expect(load.pinWeight <= exercise.workingWeight)
        #expect(load.pinRemainder == [lbs("5")])         // the rest hangs on the pin
        #expect(load.isExact)
    }

    // Defect 7: a logged Set holds the rep count only, and the weight is read live off
    // the Exercise.
    @Test("A Set stores its own weight, and a later raise does not move it")
    func aSetStoresItsOwnWeight() {
        var session = Session()
        session.start()
        session.logSets(1, reps: 12)
        session.send(.setWorkingWeight(kg("75")))
        session.logSets(1, reps: 12)

        let sets = session.performed(Ids.smith)!.sets
        #expect(sets.count == 2)
        #expect(sets[0].weight == kg("72.5"))            // lifted before the raise
        #expect(sets[1].weight == kg("75"))
        #expect(session.stored(Ids.smith)?.workingWeight == kg("75"))
    }

    // Defect 8: progression tests the logged Sets for equality with the planned Sets.
    @Test("At least the planned Sets, not exactly")
    func atLeastThePlannedSets() {
        let inventory = rackKg()
        var exercise = upperAExercises()[0]              // 3 planned, 8–12
        exercise.plannedSets = 3
        let resolved = exercise.resolved(mode: .progressiveOverload, inventory: inventory)

        // Four Sets at the top against three planned: the plan asks for three, so it
        // progresses. Under `==` this is refused.
        let four = PerformedExercise(
            exerciseId: exercise.id, name: exercise.name, state: .completed,
            sets: (0..<4).map { _ in LoggedSet(reps: 12, weight: kg("72.5")) })
        let more = Rules.evaluateProgression(performed: four, exercise: resolved, inventory: inventory)
        #expect(more.outcome.progressed)
        #expect(more.move?.workingWeight == kg("75"))

        // Two of three is still "Done early", and still does not progress.
        let two = PerformedExercise(
            exerciseId: exercise.id, name: exercise.name, state: .completed,
            sets: (0..<2).map { _ in LoggedSet(reps: 12, weight: kg("72.5")) })
        let fewer = Rules.evaluateProgression(performed: two, exercise: resolved, inventory: inventory)
        #expect(!fewer.outcome.progressed)
        #expect(fewer.move == nil)
    }
}
