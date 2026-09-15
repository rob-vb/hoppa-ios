import Foundation
import Testing
import HoppaRules
@testable import HoppaStore

@Suite("App language")
struct AppLanguageTests {
    @Test("nl prefixes detect Dutch")
    func dutchPrefixes() {
        #expect(AppLanguage.detected(from: ["nl"]) == .dutch)
        #expect(AppLanguage.detected(from: ["nl-NL"]) == .dutch)
        #expect(AppLanguage.detected(from: ["nl-BE"]) == .dutch)
        #expect(AppLanguage.detected(from: ["en-US", "nl"]) == .english)
        #expect(AppLanguage.detected(from: ["nl-NL", "en"]) == .dutch)
    }

    @Test("anything else is English")
    func englishDefault() {
        #expect(AppLanguage.detected(from: []) == .english)
        #expect(AppLanguage.detected(from: ["en"]) == .english)
        #expect(AppLanguage.detected(from: ["de-DE"]) == .english)
        #expect(AppLanguage.detected(from: ["fr_FR"]) == .english)
    }
}

@Suite("Language store")
@MainActor
struct LanguageStoreTests {
    @Test("missing file detects and does not write")
    func detectWithoutWrite() {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("hoppa-lang-\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("language.json")
        let store = LanguageStore(url: url, preferredIdentifiers: ["nl-NL"])
        #expect(store.language == .dutch)
        #expect(store.isChosen == false)
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }

    @Test("choose writes and a later store reads it")
    func choosePersists() {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("hoppa-lang-\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("language.json")
        let first = LanguageStore(url: url, preferredIdentifiers: ["en"])
        first.choose(.dutch)
        #expect(FileManager.default.fileExists(atPath: url.path))
        let second = LanguageStore(url: url, preferredIdentifiers: ["en"])
        #expect(second.language == .dutch)
        #expect(second.isChosen == true)
    }
}

@Suite("Phrasebook")
struct PhrasebookTests {
    @Test("English load line matches the shipping pin copy")
    func englishLoadLine() {
        let copy = Phrasebook(.english)
        let fly = stack("87.5", step: "5")
        #expect(copy.loadLine(fly) == "pin at 85 kg · 2.5 kg")
        #expect(copy.qualifierLine(fly) == "85 kg + 2.5")
        #expect(!copy.loadLine(fly).contains("microplate"))
    }

    @Test("Dutch speaks the same plates")
    func dutchLoadLine() {
        let copy = Phrasebook(.dutch)
        let fly = stack("87.5", step: "5")
        #expect(copy.loadLine(fly) == "pin op 85 kg · 2.5 kg")
        #expect(copy.qualifierLine(fly) == "85 kg + 2.5")
    }

    @Test("exception note interpolates storage keys")
    func exceptionNote() {
        let fact = UnitException(exerciseUnit: .lbs, rackUnit: .kg)!
        #expect(
            Phrasebook(.english).exceptionNote(fact)
                == "This machine is marked in LBS. Your gym is KG.")
        #expect(
            Phrasebook(.dutch).exceptionNote(fact)
                == "Dit apparaat is ingesteld in LBS. Jouw gym is KG.")
    }

    @Test("relative day words follow the book")
    func relativeDayWords() {
        #expect(Phrasebook(.english).relativeDay(.never) == "Never")
        #expect(Phrasebook(.english).relativeDay(.yesterday) == "Yesterday")
        #expect(Phrasebook(.dutch).relativeDay(.never) == "Nooit")
        #expect(Phrasebook(.dutch).relativeDay(.yesterday) == "Gisteren")
    }
}

private func stack(_ weight: String, step: String) -> StackLoad {
    let working = Weight(decimalString: weight, unit: .kg)!
    let stepWeight = Weight(decimalString: step, unit: .kg)!
    let exercise = Exercise(
        id: ExerciseID(1), name: "Chest fly machine", equipment: .machineStack,
        ownWeightUnit: .kg,
        plannedSets: 2, repRange: RepRange(6, 8),
        workingWeight: working, increment: stepWeight,
        modeOverride: .progressiveOverload,
        storedStackStep: stepWeight)
    let resolved = exercise.resolved(mode: .progressiveOverload, inventory: .standard(.kg))
    guard case .stack(let load) = Rules.breakdown(for: resolved, inventory: .standard(.kg)) else {
        fatalError("expected a stack")
    }
    return load
}
