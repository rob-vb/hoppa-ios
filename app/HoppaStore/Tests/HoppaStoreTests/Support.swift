import Foundation
import HoppaRules
@testable import HoppaStore

/// Where the committed fixtures live, found from this file rather than from a resource
/// bundle — the same arrangement `HoppaRulesTests` uses.
enum Fixtures {
    static var directory: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures")
    }

    /// A real Logbook, recorded by `HoppaRulesTests` from a run of the rules: two
    /// Workouts, both units, a Microload on a pin, and an Open Workout mid-Set. A
    /// hand-written fixture would only prove that the store can read what the store wrote.
    static var logbookJSON: Data {
        get throws { try Data(contentsOf: directory.appendingPathComponent("logbook.json")) }
    }
}

/// A temporary directory that removes itself, so a failed test cannot leak state into the
/// next one. `LogbookStore` takes a URL and not a protocol, so every test here runs the
/// real atomic write.
final class TempDirectory {
    let url: URL

    init(_ name: String) {
        url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("hoppa-store-tests")
            .appendingPathComponent(name)
        try? FileManager.default.removeItem(at: url)
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit { try? FileManager.default.removeItem(at: url) }

    var logbook: URL { url.appendingPathComponent("logbook.json") }

    /// Everything in the directory, sorted — used to prove no temporary file is left over.
    var contents: [String] {
        ((try? FileManager.default.contentsOfDirectory(atPath: url.path)) ?? []).sorted()
    }

    /// Puts a Program on disk the way a returning user has one: as a file the store
    /// loads. There is no action that creates a Program yet — §6.6's Program edits are
    /// [ticket 26](../../../../issues/0026-program-edits-and-the-rules-boundary.md) — so
    /// this is also the only honest way to get one.
    @discardableResult
    func seed(_ logbook: Logbook = seedLogbook()) throws -> Logbook {
        try LogbookFile.encode(logbook).write(to: self.logbook)
        return logbook
    }
}

// MARK: - A small Program to send actions at

let programId = ProgramID(1)
let dayId = WorkoutDayID(2)
let benchId = ExerciseID(3)

func kg(_ text: String) -> Weight { Weight(decimalString: text, unit: .kg)! }

/// One Program, one Workout Day, one Exercise. The rules are tested four ways over in
/// `HoppaRules`; here the Logbook only has to be real enough to change.
func seedLogbook() -> Logbook {
    Logbook(
        nextId: 10,
        plateInventory: .standard(.kg),
        programs: [
            Program(
                id: programId, name: "Upper / Lower",
                defaultWeightUnit: .kg, mode: .progressiveOverload,
                days: [
                    WorkoutDay(id: dayId, name: "Upper A", exercises: [
                        Exercise(
                            id: benchId, name: "Barbell Bench Press", equipment: .barbell,
                            plannedSets: 3, repRange: RepRange(8, 12),
                            workingWeight: kg("60"), increment: kg("2.5"))
                    ])
                ])
        ])
}

/// A fixed clock. The store owns the clock; the rules take it as an argument.
func fixedClock(_ value: Timestamp = 1_770_000_000) -> () -> Timestamp { { value } }
