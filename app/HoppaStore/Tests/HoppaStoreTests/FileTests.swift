import Foundation
import Testing
import HoppaRules
@testable import HoppaStore

/// Layer 1 — pure. Encode, decode and migrate, against committed fixtures, with no file
/// on disk anywhere.
@Suite("The logbook file, with no file")
struct FileTests {

    @Test("The committed logbook decodes, and re-encodes to the same bytes")
    func theCommittedFixtureRoundTrips() throws {
        let committed = try Fixtures.logbookJSON
        let logbook = try LogbookFile.decode(committed)
        let produced = try LogbookFile.encode(logbook)

        #expect(produced == committed)
        #expect(logbook.schemaVersion == Logbook.currentSchemaVersion)
        #expect(logbook.openWorkout != nil)
        #expect(logbook.workouts.count == 1)
    }

    @Test("An empty Logbook is the kg rack and nothing else")
    func theEmptyLogbookRoundTrips() throws {
        let decoded = try LogbookFile.decode(try LogbookFile.encode(.empty))
        #expect(decoded == Logbook.empty)
        #expect(decoded.programs.isEmpty)
        #expect(decoded.openWorkout == nil)
        #expect(decoded.plateInventory == PlateInventory.standard(.kg))
    }

    @Test("Bytes that are not JSON are refused")
    func notJSON() {
        #expect(throws: LogbookFileError.notJSON) {
            try LogbookFile.decode(Data("this is not a logbook".utf8))
        }
    }

    @Test("JSON with no schemaVersion is refused, because it is not a logbook")
    func noSchemaVersion() {
        #expect(throws: LogbookFileError.noSchemaVersion) {
            try LogbookFile.decode(Data(#"{"programs":[]}"#.utf8))
        }
    }

    @Test("A file from a newer build is refused, not parsed")
    func fromNewerBuild() throws {
        let newer = try bumped(try Fixtures.logbookJSON, to: Logbook.currentSchemaVersion + 1)

        #expect(throws: LogbookFileError.fromNewerBuild(
            found: Logbook.currentSchemaVersion + 1, known: Logbook.currentSchemaVersion)) {
            try LogbookFile.decode(newer)
        }
    }

    @Test("A Logbook-shaped file this build cannot decode is malformed, not a crash")
    func malformed() throws {
        var object = try object(in: try Fixtures.logbookJSON)
        object["programs"] = "not an array of programs"
        let broken = try JSONSerialization.data(withJSONObject: object)

        #expect(throws: (any Error).self) { try LogbookFile.decode(broken) }
        if case .malformed = errorFrom({ try LogbookFile.decode(broken) }) {} else {
            Issue.record("Expected .malformed")
        }
    }

    // MARK: - The migration engine

    /// There is no version bump yet, so `LogbookFile.steps` is empty. The engine is the
    /// part that must work the *first* time it is needed, on Rob's phone, so it is
    /// exercised here with a step table this test supplies.

    @Test("Steps chain, and each one stamps its own schemaVersion")
    func stepsChainAndStamp() throws {
        let steps: [Int: LogbookFile.Step] = [
            1: { $0["nickname"] = "one to two" },
            2: { $0["nickname"] = ($0["nickname"] as! String) + ", two to three" }
        ]
        let start = Data(#"{"schemaVersion":1}"#.utf8)

        let raised = try LogbookFile.migrate(start, from: 1, to: 3, steps: steps)
        let result = try object(in: raised)

        #expect(result["schemaVersion"] as? Int == 3)
        #expect(result["nickname"] as? String == "one to two, two to three")
    }

    @Test("A file already at the target version is returned untouched, byte for byte")
    func noMigrationIsNoWork() throws {
        let committed = try Fixtures.logbookJSON
        let result = try LogbookFile.migrate(
            committed, from: Logbook.currentSchemaVersion, to: Logbook.currentSchemaVersion,
            steps: [:])
        #expect(result == committed)
    }

    @Test("A missing step is an error, never a silent skip")
    func aMissingStepStops() {
        #expect(throws: LogbookFileError.noMigrationPath(from: 2)) {
            try LogbookFile.migrate(
                Data(#"{"schemaVersion":1}"#.utf8), from: 1, to: 3,
                steps: [1: { $0["a"] = 1 }])
        }
    }

    @Test("A step that throws stops the migration")
    func aThrowingStepStops() {
        struct Boom: Error {}
        #expect(throws: Boom.self) {
            try LogbookFile.migrate(
                Data(#"{"schemaVersion":1}"#.utf8), from: 1, to: 2,
                steps: [1: { _ in throw Boom() }])
        }
    }

    // MARK: - What "additive by default" actually costs

    /// Ticket 24 said a new field gets a default and needs no step. That is true **only
    /// if the new field is Optional**: Swift's synthesised `Codable` uses
    /// `decodeIfPresent` for an Optional property and plain `decode` for every other one,
    /// so a non-Optional property with a default in `init` still fails on a file written
    /// before it existed. These two tests pin the rule down so a later bump cannot get it
    /// wrong by accident.

    @Test("A missing Optional field decodes — this is what makes additive changes free")
    func aMissingOptionalFieldIsFine() throws {
        var object = try object(in: try Fixtures.logbookJSON)
        object.removeValue(forKey: "openWorkout")     // `openWorkout: Workout?`
        let without = try JSONSerialization.data(withJSONObject: object)

        let logbook = try LogbookFile.decode(without)
        #expect(logbook.openWorkout == nil)
    }

    @Test("A missing non-Optional field does not decode — that one needs a numbered step")
    func aMissingRequiredFieldIsNot() throws {
        var object = try object(in: try Fixtures.logbookJSON)
        object.removeValue(forKey: "nextId")          // `nextId: Int`, defaulted in init
        let without = try JSONSerialization.data(withJSONObject: object)

        #expect(throws: (any Error).self) { try LogbookFile.decode(without) }
    }

    // MARK: - Helpers

    private func object(in data: Data) throws -> [String: Any] {
        try JSONSerialization.jsonObject(with: data) as! [String: Any]
    }

    private func bumped(_ data: Data, to version: Int) throws -> Data {
        var object = try object(in: data)
        object["schemaVersion"] = version
        return try JSONSerialization.data(withJSONObject: object)
    }

    private func errorFrom(_ body: () throws -> Void) -> LogbookFileError? {
        do { try body(); return nil } catch let error as LogbookFileError { return error }
        catch { return nil }
    }
}
