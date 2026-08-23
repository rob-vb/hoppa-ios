import Foundation
import HoppaRules
import HoppaStore

// Ticket 0025 — scaffolding. **Off by default since ticket 0032.**
//
// It was written because the acceptance test needed a Program to start a Workout from and
// no `Action` created one. §6.6 ended that, so Flow 1 was going to delete this file — and
// ticket 0029 kept it instead, for a different job: **Flow 4 needs sixteen weeks of
// history to chart, and typing that on a phone is not a test.**
//
// So it survives behind `isEnabled`, and `isEnabled` is `false`. With it off the app opens
// on §6.1's real first run — `NOTHING HERE YET` — which is the screen ticket 0032 built and
// the one a new phone must actually show.
//
// It writes a starter logbook **only when there is no file at all**, which is exactly the
// state a returning user is never in. It never touches an existing file — least of all
// one the store could not read.

enum HarnessSeed {

    /// The debug switch. Flip it to `true`, rebuild, and delete the app first — it seeds
    /// nothing where a `logbook.json` already sits.
    ///
    /// A source constant and not a setting, on purpose: there is no settings screen in the
    /// five flows, and a build is what the Mac session is for anyway.
    static let isEnabled = false

    /// Returns the logbook URL, having put a starter Program there if the phone had none.
    static func prepare() -> URL {
        let url = Logbook.fileURL
        guard isEnabled else { return url }
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
