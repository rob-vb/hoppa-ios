import Foundation
import Testing
import HoppaRules
@testable import HoppaStore

/// Layers 2, 3 and 4 — loading, writing and forwarding. Every one of these runs the real
/// atomic write against a real temporary directory, because a store tested through an
/// in-memory stand-in never runs the code that can lose Rob's training.
@Suite("The store on disk")
@MainActor
struct StoreTests {

    // MARK: - Layer 2: loading

    @Test("No file is a fresh install, and nothing is written")
    func missingFileIsEmpty() {
        let temp = TempDirectory("missing")
        let store = LogbookStore(url: temp.logbook, now: fixedClock())

        if case .empty = store.state {} else { Issue.record("Expected .empty") }
        #expect(store.logbook == Logbook.empty)
        #expect(temp.contents.isEmpty)
    }

    @Test("A good file loads")
    func goodFileLoads() throws {
        let temp = TempDirectory("good")
        try Fixtures.logbookJSON.write(to: temp.logbook)

        let store = LogbookStore(url: temp.logbook, now: fixedClock())

        guard case .loaded(let logbook) = store.state else {
            Issue.record("Expected .loaded, got \(store.state)")
            return
        }
        #expect(logbook.openWorkout != nil)
        #expect(store.logbook == logbook)
    }

    @Test("A corrupt file is unreadable, and the file on disk is byte-identical afterwards")
    func corruptFileIsUnreadableAndUntouched() throws {
        let temp = TempDirectory("corrupt")
        let bytes = Data("{ this is not, quite, JSON".utf8)
        try bytes.write(to: temp.logbook)

        let store = LogbookStore(url: temp.logbook, now: fixedClock())

        #expect(store.isUnreadable)
        // No Logbook at all: a view can render nothing and can call nothing.
        #expect(store.logbook == nil)
        #expect(try Data(contentsOf: temp.logbook) == bytes)
    }

    @Test("A file from a newer build is unreadable, and is not written over")
    func newerSchemaIsUnreadable() throws {
        let temp = TempDirectory("newer")
        var object = try JSONSerialization.jsonObject(with: try Fixtures.logbookJSON) as! [String: Any]
        object["schemaVersion"] = Logbook.currentSchemaVersion + 1
        let bytes = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        try bytes.write(to: temp.logbook)

        let store = LogbookStore(url: temp.logbook, now: fixedClock())

        #expect(store.isUnreadable)
        #expect(store.logbook == nil)
        #expect(try Data(contentsOf: temp.logbook) == bytes)
    }

    /// This once passed for a second reason as well: `Logbook.empty` was a fixed point
    /// under every action, so even a store that wrongly fell back to it would have
    /// written nothing. **`createProgram` ended that**, and the next test is the one the
    /// guard was written for.
    @Test("An unreadable store refuses to send, so nothing can write over the file")
    func unreadableRefusesToSend() throws {
        let temp = TempDirectory("refuse")
        let bytes = Data("not a logbook".utf8)
        try bytes.write(to: temp.logbook)

        let store = LogbookStore(url: temp.logbook, now: fixedClock())
        store.send(.startWorkout(programId: programId, workoutDayId: dayId))

        #expect(store.isUnreadable)
        #expect(store.logbook == nil)
        #expect(try Data(contentsOf: temp.logbook) == bytes)
        #expect(temp.contents == ["logbook.json"])
    }

    /// **The guard ticket 25 could not fail, now failing.**
    ///
    /// `send`'s first line is `guard let current = logbook else { return }`, and until
    /// §6.6's Program edits existed nothing could get past a store that ignored it: every
    /// action needed an Open Workout or a Program, and `Logbook.empty` has neither. A
    /// store that fell back to `.empty` on `.unreadable` would now write a brand-new
    /// Program over a logbook Hoppa merely failed to **read** — weeks of training, gone
    /// because one byte on disk was wrong.
    @Test("A create over an unreadable file writes nothing — the guard, at last provable")
    func unreadableRefusesToCreateAProgram() throws {
        let temp = TempDirectory("refuse-create")
        let bytes = Data("not a logbook".utf8)
        try bytes.write(to: temp.logbook)

        let store = LogbookStore(url: temp.logbook, now: fixedClock())
        store.send(.createProgram(name: "Upper / Lower", defaultWeightUnit: .kg, mode: .progressiveOverload))

        #expect(store.logbook == nil)
        #expect(try Data(contentsOf: temp.logbook) == bytes, "the unreadable file was written over")
        #expect(temp.contents == ["logbook.json"])
    }

    @Test("The same create on a fresh install does land, so the test above proves the guard")
    func aCreateOnAFreshInstallLands() throws {
        let temp = TempDirectory("create")
        let store = LogbookStore(url: temp.logbook, now: fixedClock())
        store.send(.createProgram(name: "Upper / Lower", defaultWeightUnit: .kg, mode: .progressiveOverload))

        #expect(store.logbook?.programs.count == 1)
        #expect(temp.contents == ["logbook.json"])
        let written = try LogbookFile.decode(try Data(contentsOf: temp.logbook))
        #expect(written.programs.first?.name == "Upper / Lower")
    }

    // MARK: - Layer 3: writing

    @Test("After a save the file decodes back to the same Logbook, and no temporary is left")
    func aSaveRoundTrips() throws {
        let temp = TempDirectory("save")
        try temp.seed()
        let store = LogbookStore(url: temp.logbook, now: fixedClock())
        store.send(.startWorkout(programId: programId, workoutDayId: dayId))

        let written = try LogbookFile.decode(try Data(contentsOf: temp.logbook))
        #expect(written == store.logbook)
        #expect(written.openWorkout != nil)
        #expect(temp.contents == ["logbook.json"], "a temporary file was left behind")
    }

    @Test("A refused action writes nothing at all")
    func aRefusedActionWritesNothing() {
        let temp = TempDirectory("refused")
        let store = LogbookStore(url: temp.logbook, now: fixedClock())

        // No such Program, so the rules refuse it and the Logbook is unchanged.
        store.send(.startWorkout(programId: ProgramID(999), workoutDayId: WorkoutDayID(999)))

        if case .empty = store.state {} else { Issue.record("Expected .empty") }
        #expect(temp.contents.isEmpty, "a fresh install wrote a file before it had anything in it")
    }

    @Test("A relaunch sees exactly what the last send left — the force-quit, on disk")
    func aRelaunchSeesTheOpenWorkout() throws {
        let temp = TempDirectory("relaunch")
        try temp.seed()

        let first = LogbookStore(url: temp.logbook, now: fixedClock())
        first.send(.startWorkout(programId: programId, workoutDayId: dayId))
        first.send(.logSet(reps: 12))
        first.send(.logSet(reps: 11))
        let before = first.logbook

        // Nothing is closed, flushed or told to finish: the process simply stops.
        let second = LogbookStore(url: temp.logbook, now: fixedClock())

        #expect(second.logbook == before)
        #expect(second.logbook?.openWorkout?.exercises.first?.sets.count == 2)
        #expect(second.logbook?.openWorkout?.currentIndex == 0)
    }

    @Test("A save failure is reported, not swallowed")
    func aSaveFailureIsReported() throws {
        let temp = TempDirectory("unwritable")
        try temp.seed()
        let store = LogbookStore(url: temp.logbook, now: fixedClock())

        // The file goes away under the store — the closest a test gets to a full disk.
        try FileManager.default.removeItem(at: temp.url)
        store.send(.startWorkout(programId: programId, workoutDayId: dayId))

        #expect(store.lastSaveError != nil)
        // The in-memory Logbook still moved, so the screen is not lying about the Set.
        #expect(store.logbook?.openWorkout != nil)
    }

    // MARK: - Layer 4: forwarding

    /// One test, not thirteen. The actions are tested four ways over in `HoppaRules`;
    /// what this proves is that the store adds nothing and subtracts nothing.
    @Test("send is Rules.reduce, and then a save")
    func sendIsReduceThenSave() throws {
        let temp = TempDirectory("forward")
        try temp.seed()
        let clock: Timestamp = 1_770_000_000
        let store = LogbookStore(url: temp.logbook, now: { clock })

        let actions: [Action] = [
            .startWorkout(programId: programId, workoutDayId: dayId),
            .logSet(reps: 12),
            .logSet(reps: 12),
            .logSet(reps: 12),
            .finish
        ]

        var expected = seedLogbook()
        for action in actions {
            expected = Rules.reduce(expected, action, at: clock)
            store.send(action)
            #expect(store.logbook == expected)
        }

        // And the last one is on disk.
        #expect(try LogbookFile.decode(try Data(contentsOf: temp.logbook)) == expected)
    }

    // MARK: - Migration, with a real file

    @Test("An older file is backed up before it is migrated")
    func anOlderFileIsBackedUp() throws {
        // There is no v0 in the wild, so this drives the load path with the engine's own
        // rule: a file below the current version is copied aside before anything reads it.
        let temp = TempDirectory("backup")
        var object = try JSONSerialization.jsonObject(with: try Fixtures.logbookJSON) as! [String: Any]
        object["schemaVersion"] = 0
        let old = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        try old.write(to: temp.logbook)

        let store = LogbookStore(url: temp.logbook, now: fixedClock())

        // No step from 0 exists, so the load fails — but the backup was already taken,
        // which is the point: the copy happens before anything can go wrong.
        #expect(store.isUnreadable)
        #expect(temp.contents == ["logbook-v0-backup.json", "logbook.json"])
        #expect(try Data(contentsOf: temp.url.appendingPathComponent("logbook-v0-backup.json")) == old)
        #expect(try Data(contentsOf: temp.logbook) == old)
    }
}
