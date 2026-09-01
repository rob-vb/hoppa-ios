import Testing
@testable import HoppaRules

@Suite("No progression")
struct NoneProgressionTests {

    @Test("Top-range sets do not progress")
    func topRangeSetsStayPut() {
        var book = upperALogbook()
        book.updateExercise(Ids.smith) { $0.modeOverride = ProgressionMode.none }
        let exercise = book.exercise(Ids.smith)!
        let resolved = book.resolvedExercise(Ids.smith)!
        let performed = PerformedExercise(
            exerciseId: Ids.smith,
            name: exercise.name,
            state: .completed,
            sets: (0..<exercise.plannedSets).map {
                _ in LoggedSet(reps: exercise.repRange.top, weight: exercise.workingWeight!)
            })

        let result = Rules.evaluateProgression(
            performed: performed,
            exercise: resolved,
            inventory: book.plateInventory)

        #expect(result.outcome.thresholdReps == exercise.repRange.top)
        #expect(!result.outcome.progressed)
        #expect(result.move == nil)
    }

    @Test("None has a stable raw value")
    func rawValue() {
        #expect(ProgressionMode.none.rawValue == "none")
    }

    @Test("Program modes cycle in order")
    func modeCycle() {
        #expect(ProgressionMode.progressiveOverload.next == .microloading)
        #expect(ProgressionMode.microloading.next == .none)
        #expect(ProgressionMode.none.next == .progressiveOverload)
    }

    @Test("None uses normal plates")
    func normalPlates() {
        let inventory = PlateInventory.standard(.kg)
        #expect(inventory.plates(for: .none) == inventory.plates(for: .progressiveOverload))
    }
}
