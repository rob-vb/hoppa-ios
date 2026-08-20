import Foundation
import HoppaRules
import HoppaStore

// Ticket 0025 — scaffolding, and the only piece of this build that is not meant to last.
//
// The acceptance test needs a Program to start a Workout from, and **no `Action` creates
// one**: `Rules.reduce` landed exactly one Program edit, and §6.6's others are
// [ticket 26](../../../../issues/0026-program-edits-and-the-rules-boundary.md). Flow 1
// deletes this file.
//
// It writes a starter logbook **only when there is no file at all**, which is exactly the
// state a returning user is never in. It never touches an existing file — least of all
// one the store could not read.

enum HarnessSeed {

    /// Returns the logbook URL, having put a starter Program there if the phone had none.
    static func prepare() -> URL {
        let url = Logbook.fileURL
        guard !FileManager.default.fileExists(atPath: url.path) else { return url }
        do {
            try LogbookFile.encode(starter).write(to: url, options: [.atomic])
        } catch {
            // Nothing to recover: the harness will simply show a fresh install.
            print("[harness] could not seed a Program — \(error)")
        }
        return url
    }

    /// Upper A, cut down to what a two-Set proof needs. The weights are Rob's own from
    /// `SPEC.md`'s worked examples, so the numbers on screen are recognisable.
    private static var starter: Logbook {
        Logbook(
            nextId: 100,
            plateInventory: .standard(.kg),
            programs: [
                Program(
                    id: ProgramID(1), name: "Upper / Lower",
                    defaultWeightUnit: .kg, mode: .progressiveOverload,
                    days: [
                        WorkoutDay(id: WorkoutDayID(2), name: "Upper A", exercises: [
                            Exercise(
                                id: ExerciseID(10), name: "Smith machine bench press",
                                equipment: .smith,
                                plannedSets: 3, repRange: RepRange(8, 12),
                                workingWeight: Weight(decimalString: "72.5", unit: .kg)!,
                                increment: Weight(decimalString: "2.5", unit: .kg)!,
                                storedBaseWeight: Weight(decimalString: "15", unit: .kg)!),
                            Exercise(
                                id: ExerciseID(11), name: "Barbell row",
                                equipment: .barbell,
                                plannedSets: 3, repRange: RepRange(8, 10),
                                workingWeight: Weight(decimalString: "60", unit: .kg)!,
                                increment: Weight(decimalString: "2.5", unit: .kg)!)
                        ])
                    ])
            ])
    }
}
