import Foundation
import Testing
@testable import HoppaRules

/// One full `Logbook`, encoded, decoded and re-encoded.
///
/// The committed file is the point. Hand-written `CodingKeys` on every property are not
/// worth their volume, but an accidental key rename has to fail **in review** and not on
/// Rob's phone six weeks into a training block.
@Suite("The Logbook round-trip")
struct RoundTripTests {

    /// A Logbook with everything in it: both units, a mixed-unit pin carrying a Microload,
    /// a finished Workout with outcomes, and an Open Workout mid-Set.
    static func fixture() -> Logbook {
        var session = Session()
        session.start()
        session.logSets(3, reps: 12)                     // Smith bench progresses
        session.send(.nextOpen)
        session.logSets(2, reps: 9)                      // Barbell row, done early
        session.send(.doneEarly)
        session.send(.nextOpen)
        session.send(.setOneOffWeight(lbs("90")))        // a lighter pulldown today
        session.logSets(3, reps: 11)
        session.send(.nextOpen)
        session.send(.skip)                              // the dumbbells are busy
        session.send(.skipRemainingAndFinish)

        // A second Workout, left Open in the middle of the first Exercise.
        session.start()
        session.logSets(1, reps: 12)
        return session.book
    }

    @Test("A Logbook survives encode, decode and encode again")
    func encodeDecodeEncode() throws {
        let original = Self.fixture()
        let first = try Recording.encoder.encode(original)
        let decoded = try JSONDecoder().decode(Logbook.self, from: first)
        let second = try Recording.encoder.encode(decoded)

        #expect(decoded == original)
        #expect(first == second)
    }

    @Test("The committed Logbook fixture still decodes, key for key")
    func theCommittedFixtureIsUnchanged() throws {
        let produced = String(decoding: try Recording.encoder.encode(Self.fixture()), as: UTF8.self)
        let result = try Recording.check(produced, against: "Fixtures/logbook.json")

        guard let committed = result.committed else {
            Issue.record("Fixtures/logbook.json is missing. Re-record with HOPPA_RECORD=1.")
            return
        }
        if !result.matched {
            Issue.record("""
                The Logbook JSON changed. If that was on purpose, re-record with \
                HOPPA_RECORD=1 and review the diff.
                \(Recording.firstDifference(committed, produced))
                """)
        }
        // And the committed bytes are still readable by this build.
        _ = try JSONDecoder().decode(Logbook.self, from: Data(committed.utf8))
    }

    @Test("Every enum writes a string, never a Swift case name by accident")
    func enumsCarryExplicitRawValues() {
        #expect(EquipmentType.machinePlates.rawValue == "machine-plates")
        #expect(EquipmentType.machineStack.rawValue == "machine-stack")
        #expect(ProgressionMode.progressiveOverload.rawValue == "progressive-overload")
        #expect(WeightUnit.kg.rawValue == "kg")
        #expect(ExerciseState.skipped.rawValue == "skipped")
        #expect(WorkoutState.finished.rawValue == "finished")
    }

    @Test("Old equipment strings decode; encodes are canonical; chip order is allCases")
    func equipmentAliasesAndChipOrder() throws {
        func decode(_ raw: String) throws -> EquipmentType {
            try JSONDecoder().decode(EquipmentType.self, from: Data("\"\(raw)\"".utf8))
        }
        func encode(_ type: EquipmentType) throws -> String {
            String(decoding: try JSONEncoder().encode(type), as: UTF8.self)
        }

        #expect(try decode("smith") == .machinePlates)
        #expect(try decode("plate-loaded") == .machinePlates)
        #expect(try decode("machine-plates") == .machinePlates)
        #expect(try decode("cable") == .machineStack)
        #expect(try decode("machine-stack") == .machineStack)
        #expect(try encode(.machinePlates) == "\"machine-plates\"")
        #expect(try encode(.machineStack) == "\"machine-stack\"")
        #expect(throws: DecodingError.self) {
            try decode("unknown")
        }
        #expect(Array(EquipmentType.allCases) == [
            .barbell, .dumbbell, .machinePlates, .machineStack, .bodyweight
        ])
        #expect(EquipmentType.allCases.count == 5)
    }

    @Test("An id encodes as a plain number")
    func idsEncodeAsNumbers() throws {
        let data = try JSONEncoder().encode(ExerciseID(42))
        #expect(String(decoding: data, as: UTF8.self) == "42")
    }
}
