import Foundation
import Testing
import HoppaRules

/// **An unset weight is not zero** (`SPEC.md` §2.3, §2.8), and **a switched-off Microplate
/// strands** (§6.6).
///
/// Two rules with one thing in common: both are reasons an Exercise does not progress, and
/// before this ticket neither existed. `workingWeight` was a non-optional `Weight`, so
/// "cleared" could only mean zero — which is a real weight, a Bodyweight Exercise done with
/// no belt. And `microloadingIncrement` stores a raw `Weight` and not a reference to a
/// plate, so switching that plate off left the weight climbing by steel the user does not
/// own. That one was **live in 46 green tests**, because nothing had switched a plate off.
@Suite("SPEC.md §2.8 and §6.6 — an unset weight, and a stranded Exercise")
struct UnsetWeightTests {

    // MARK: - No weight, no Set, no progression

    @Test("An Exercise with no Working Weight logs no Set")
    func noWeightNoSet() {
        var session = Session()
        session.book.updateExercise(Ids.smith) { $0.workingWeight = nil }
        session.start()
        session.logSets(1)

        #expect(session.performed(Ids.smith)?.sets.isEmpty == true)
        #expect(session.performed(Ids.smith)?.state == .open)
    }

    @Test("A One-off Weight stands in for a Working Weight that is not there")
    func aOneOffIsEnoughToLog() {
        var session = Session()
        session.book.updateExercise(Ids.smith) { $0.workingWeight = nil }
        session.start()
        session.send(.setOneOffWeight(kg("60")))
        session.logSets(1)

        #expect(session.performed(Ids.smith)?.sets.first?.weight == kg("60"))
        #expect(session.performed(Ids.smith)?.sets.first?.oneOff == true)
        // ...and it still never becomes the Working Weight (§4.3).
        #expect(session.stored(Ids.smith)?.workingWeight == nil)
    }

    @Test("An Exercise with no Working Weight does not progress")
    func noWeightNoProgression() {
        let book = upperALogbook()
        var exercise = book.exercise(Ids.smith)!
        exercise.workingWeight = nil
        let resolved = exercise.resolved(mode: .progressiveOverload, inventory: book.plateInventory)

        #expect(Rules.progressionMove(for: resolved, inventory: book.plateInventory) == nil)
    }

    @Test("Progressive Overload with no Increment does not progress either")
    func noIncrementNoProgression() {
        let book = upperALogbook()
        var exercise = book.exercise(Ids.smith)!
        exercise.increment = nil
        let resolved = exercise.resolved(mode: .progressiveOverload, inventory: book.plateInventory)

        #expect(Rules.progressionMove(for: resolved, inventory: book.plateInventory) == nil)
    }

    @Test("Zero is a real weight: a Bodyweight Exercise with no belt logs and progresses")
    func zeroIsNotUnset() {
        var session = Session()
        session.book.updateExercise(Ids.chin) { $0.workingWeight = kg("0") }
        session.start()
        session.goTo(Ids.chin)
        session.logSets(3)
        session.send(.skipRemainingAndFinish)

        #expect(session.performed(Ids.chin)?.sets.count == 3)
        #expect(session.performed(Ids.chin)?.sets.first?.weight == kg("0"))
        #expect(session.stored(Ids.chin)?.workingWeight == kg("2.5"))
        // And it is not on the Re-weigh list, which zero-as-cleared would have put it on.
        #expect(!Rules.reweighList(in: session.book).contains(Ids.chin))
    }

    @Test("There is no Plate Breakdown to draw without a weight")
    func noWeightNoBreakdown() {
        let book = upperALogbook()
        var exercise = book.exercise(Ids.row)!
        exercise.workingWeight = nil
        let resolved = exercise.resolved(mode: .progressiveOverload, inventory: book.plateInventory)

        #expect(Rules.breakdown(for: resolved, inventory: book.plateInventory) == nil)
        // A One-off is a weight, so it draws.
        #expect(Rules.breakdown(
            for: resolved, performedAt: kg("60"), inventory: book.plateInventory) != nil)
    }

    // MARK: - Stranding (§6.6)

    /// The live defect. Before this ticket the pin climbed by 1 kg of steel that was not
    /// in the rack.
    @Test("A Microplate switched off strands the Exercise, and it does not progress")
    func aSwitchedOffMicroplateStrands() {
        var book = upperALogbook()
        book = Rules.reduce(book, .setPlate(kg("0.25"), on: false), at: 0)
        var exercise = book.exercise(Ids.smith)!
        exercise.modeOverride = .microloading

        let resolved = exercise.resolved(mode: .microloading, inventory: book.plateInventory)
        #expect(resolved.isStranded)
        #expect(Rules.progressionMove(for: resolved, inventory: book.plateInventory) == nil)
    }

    @Test("Nothing is written and nothing is cleared: switch the plate back on and it moves again")
    func strandingIsDerivedAndReversible() {
        var session = Session()
        session.book.updateExercise(Ids.smith) { $0.modeOverride = .microloading }
        session.send(.setPlate(kg("0.25"), on: false))

        // The Increment is still the plate the user picked.
        #expect(session.stored(Ids.smith)?.microloadingIncrement == kg("0.25"))

        session.start()
        session.logSets(3, reps: 12)
        session.send(.skipRemainingAndFinish)
        #expect(session.stored(Ids.smith)?.workingWeight == kg("72.5"))      // it did not move
        #expect(session.lastFinished?.exercises.first?.outcome?.progressed == false)

        session.send(.setPlate(kg("0.25"), on: true))
        session.start()
        session.logSets(3, reps: 12)
        session.send(.skipRemainingAndFinish)
        // A bar takes a pair, so the same plate moves it by twice the plate (§4.2).
        #expect(session.stored(Ids.smith)?.workingWeight == kg("73"))
    }

    @Test("An Exercise that names no Microplate at all is not stranded — that is §5.2's empty state")
    func namingNoPlateIsNotStranding() {
        let book = upperALogbook()
        var exercise = book.exercise(Ids.smith)!
        exercise.microloadingIncrement = nil
        let resolved = exercise.resolved(mode: .microloading, inventory: book.plateInventory)

        #expect(!resolved.isStranded)
        #expect(Rules.progressionMove(for: resolved, inventory: book.plateInventory) == nil)
    }

    @Test("A stranded Increment on a Progressive Overload Exercise still progresses")
    func strandingOnlyBitesUnderMicroloading() {
        var book = upperALogbook()
        book = Rules.reduce(book, .setPlate(kg("0.25"), on: false), at: 0)
        let resolved = book.resolvedExercise(Ids.smith)!      // still Progressive Overload

        #expect(resolved.isStranded)                          // the plate is off...
        #expect(Rules.progressionMove(for: resolved, inventory: book.plateInventory)?
            .workingWeight == kg("75"))                       // ...and it is not using it
    }

    // MARK: - The file (§2.8, and ticket 25's finding read forwards)

    /// **Widening a field to `Optional` is the safe direction.** Ticket 25 found that
    /// Swift's synthesised `Codable` decodes an `Optional` with `decodeIfPresent` and
    /// everything else with plain `decode`; read forwards that says an old file still
    /// loads. It is exactly the kind of claim this map has been wrong about before, so
    /// here is the file.
    @Test("A v1 Exercise that carries both weights still decodes")
    func theOldFileStillLoads() throws {
        let old = """
            {"equipment":"barbell","id":11,"increment":{"hundredths":250,"unit":"kg"},\
            "modeOverride":null,"name":"Barbell row","ownWeightUnit":"kg","plannedSets":3,\
            "repRange":{"bottom":8,"top":10},"workingWeight":{"hundredths":6000,"unit":"kg"}}
            """
        let exercise = try decodeExercise(old)
        #expect(exercise.workingWeight == kg("60"))
        #expect(exercise.increment == kg("2.5"))
    }

    @Test("An Exercise with neither weight decodes, which an old build could not have written")
    func theNewFileLoadsToo() throws {
        let new = """
            {"equipment":"barbell","id":11,"name":"Barbell row","ownWeightUnit":"kg",\
            "plannedSets":3,"repRange":{"bottom":8,"top":10}}
            """
        let exercise = try decodeExercise(new)
        #expect(exercise.workingWeight == nil)
        #expect(exercise.increment == nil)
    }

    private func decodeExercise(_ json: String) throws -> Exercise {
        try JSONDecoder().decode(Exercise.self, from: Data(json.utf8))
    }
}
