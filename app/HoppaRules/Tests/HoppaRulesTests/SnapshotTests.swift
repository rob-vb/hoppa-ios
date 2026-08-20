import Foundation
import Testing
@testable import HoppaRules

// MARK: - What gets written down

struct SnapshotSet: Codable, Hashable {
    var reps: Int
    var weight: String
    var microload: String?
    var oneOff: Bool?
}

struct SnapshotExercise: Codable, Hashable {
    var name: String
    var state: String
    var sets: [SnapshotSet]
    var plannedSets: Int
    var thresholdReps: Int
    var progressed: Bool
    var weightBefore: String
    var weightAfter: String
    var microloadBefore: String?
    var microloadAfter: String?
}

struct SnapshotWorkout: Codable, Hashable {
    var date: String
    var day: String
    var exercises: [SnapshotExercise]
}

struct SnapshotFinalWeight: Codable, Hashable {
    var name: String
    var weight: String
    var microload: String?
}

struct HistorySnapshot: Codable, Hashable {
    var workoutCount: Int
    var weeks: Int
    var exerciseCount: Int
    var finalWeights: [SnapshotFinalWeight]
    var workouts: [SnapshotWorkout]
}

private func text(_ weight: Weight?) -> String? {
    weight.map { "\($0.decimalString) \($0.unit.rawValue)" }
}

private func dateText(_ timestamp: Timestamp) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    formatter.timeZone = TimeZone(identifier: "UTC")
    return formatter.string(from: Date(timeIntervalSince1970: timestamp))
}

// MARK: - The run

/// Sixteen weeks of the user's own Program, run forward through `HoppaRules` itself.
///
/// This is the only thing in the whole effort that has ever run the rules further than
/// one Workout, and it is what found the roll-up defect in the first place. **A snapshot
/// proves nothing changed; it does not prove anything is right** — which is why the
/// defect, invariant and walkthrough suites come first, and why the invariants are
/// asserted again here at every single progression.
@Suite("The 56-Workout history")
struct SnapshotTests {

    static func run(assertInvariants: Bool) -> (snapshot: HistorySnapshot, book: Logbook) {
        var book = History.logbook()
        var generators = Dictionary(uniqueKeysWithValues: History.specs.enumerated().map {
            ($1.id, LinearCongruential(seed: 9001 + $0 * 137))
        })
        var sessionsAtThisWeight = Dictionary(uniqueKeysWithValues: History.specs.map { ($0.id, 0) })
        var workouts: [SnapshotWorkout] = []

        for session in History.sessions {
            var clock = session.startedAt
            func send(_ action: Action) {
                clock += 9
                book = Rules.reduce(book, action, at: clock)
            }

            send(.startWorkout(programId: ProgramID(1), workoutDayId: WorkoutDayID(session.day + 1)))
            guard let open = book.openWorkout else { Issue.record("no Workout started"); break }

            // What each Exercise stood at before this Workout, so the snapshot can show
            // the move and a test can check it never went backwards.
            var before: [ExerciseID: (weight: Weight, microload: Weight?)] = [:]
            for performed in open.exercises {
                let resolved = book.resolvedExercise(performed.exerciseId)!
                before[performed.exerciseId] = (resolved.workingWeight, resolved.microload)
            }

            for index in open.exercises.indices {
                let id = book.openWorkout!.exercises[index].exerciseId
                send(.selectExercise(index: index))

                // A Skipped Exercise logs no Sets, and its state does not move on.
                if session.week == History.skipWeek && id == ExerciseID(105) {
                    send(.skip)
                    continue
                }

                let resolved = book.resolvedExercise(id)!
                // A One-off Weight: performed lighter for one Workout, never the Working Weight.
                let oneOff = session.week == History.oneOffWeek && id == ExerciseID(101)
                    ? resolved.workingWeight - kg("7.5")
                    : nil
                if let oneOff { send(.setOneOffWeight(oneOff)) }

                let reps = Lifter.reps(
                    plannedSets: resolved.plannedSets,
                    repRange: resolved.repRange,
                    sessionsAtThisWeight: sessionsAtThisWeight[id]!,
                    random: &generators[id]!)
                for count in reps { send(.logSet(reps: count)) }
            }

            send(.finish)
            guard let finished = book.workouts.last else { Issue.record("Finish was refused"); break }

            var entries: [SnapshotExercise] = []
            for performed in finished.exercises {
                let id = performed.exerciseId
                let after = book.resolvedExercise(id)!
                let start = before[id]!
                let outcome = performed.outcome ?? ProgressionOutcome(
                    plannedSets: after.plannedSets, thresholdReps: after.thresholdReps, progressed: false)

                if assertInvariants {
                    check(
                        name: after.name, before: start, after: (after.workingWeight, after.microload),
                        stackStep: after.stackStep, inventory: book.plateInventory,
                        progressed: outcome.progressed)
                }

                if performed.state != .skipped {
                    sessionsAtThisWeight[id] = outcome.progressed
                        ? 0
                        : (performed.oneOffWeight == nil ? sessionsAtThisWeight[id]! + 1 : sessionsAtThisWeight[id]!)
                }

                entries.append(SnapshotExercise(
                    name: performed.name,
                    state: performed.state.rawValue,
                    sets: performed.sets.map {
                        SnapshotSet(reps: $0.reps, weight: text($0.weight)!,
                                    microload: text($0.microload), oneOff: $0.oneOff ? true : nil)
                    },
                    plannedSets: outcome.plannedSets,
                    thresholdReps: outcome.thresholdReps,
                    progressed: outcome.progressed,
                    weightBefore: text(start.weight)!,
                    weightAfter: text(after.workingWeight)!,
                    microloadBefore: text(start.microload),
                    microloadAfter: text(after.microload)))
            }

            workouts.append(SnapshotWorkout(
                date: dateText(finished.startedAt),
                day: finished.workoutDayName,
                exercises: entries))
        }

        let finalWeights = History.specs.map { spec -> SnapshotFinalWeight in
            let resolved = book.resolvedExercise(spec.id)!
            return SnapshotFinalWeight(
                name: spec.name,
                weight: text(resolved.workingWeight)!,
                microload: text(resolved.microload))
        }

        return (
            HistorySnapshot(
                workoutCount: workouts.count,
                weeks: History.weeks,
                exerciseCount: History.specs.count,
                finalWeights: finalWeights,
                workouts: workouts),
            book)
    }

    /// The two invariants of §4.2, checked at every progression of every Exercise.
    static func check(
        name: String,
        before: (weight: Weight, microload: Weight?),
        after: (weight: Weight, microload: Weight?),
        stackStep: Weight?,
        inventory: PlateInventory,
        progressed: Bool
    ) {
        // Hoppa never lowers a Working Weight by itself, ever.
        let old = totalInKg(before.weight, before.microload ?? .zero(inventory.unit))
        let new = totalInKg(after.weight, after.microload ?? .zero(inventory.unit))
        #expect(new.hundredths >= old.hundredths,
                "\(name): \(old.decimalString) -> \(new.decimalString) kg")

        // After any progression the Microload is less than one Stack Step.
        if let microload = after.microload, let step = stackStep {
            let stepInRackUnit = step.converted(to: inventory.unit)
            #expect(microload.hundredths < stepInRackUnit.hundredths,
                    "\(name): a Microload of \(microload.decimalString) is not under one Stack Step")
        }
        if !progressed {
            #expect(after.weight == before.weight, "\(name) did not progress but its weight moved")
        }
    }

    @Test("Sixteen weeks run forward, with the invariants held at every progression")
    func theHistoryHolds() {
        let result = Self.run(assertInvariants: true)
        #expect(result.snapshot.workoutCount == 56)
        #expect(result.snapshot.workouts.count == result.book.workouts.count)
        #expect(result.book.openWorkout == nil)

        // The pin must have moved. Sixteen weeks of 1 kg Microplates on a 10 lbs stack
        // is exactly the case `gen-fixture.mjs` engineered its way around, so a run that
        // never rolls up has quietly stopped testing the rule.
        let pulldown = result.book.resolvedExercise(ExerciseID(103))!
        #expect(pulldown.workingWeight > lbs("90"), "the pin never moved")
        let step = pulldown.stackStep!.converted(to: result.book.plateInventory.unit)
        #expect(pulldown.microload!.hundredths < step.hundredths)
    }

    @Test("The committed 56-Workout snapshot has not drifted")
    func theSnapshotHasNotDrifted() throws {
        let produced = String(
            decoding: try Recording.encoder.encode(Self.run(assertInvariants: false).snapshot),
            as: UTF8.self)
        let result = try Recording.check(produced, against: "Snapshots/history.json")

        guard let committed = result.committed else {
            Issue.record("Snapshots/history.json is missing. Re-record with HOPPA_RECORD=1.")
            return
        }
        if !result.matched {
            Issue.record("""
                The history drifted. A rule changed. If that was on purpose, re-record \
                with HOPPA_RECORD=1 and review the diff — a wrong weight in the gym six \
                weeks from now is what this file exists to prevent.
                \(Recording.firstDifference(committed, produced))
                """)
        }
    }

    @Test("The run is deterministic: two runs produce the same history")
    func theRunIsDeterministic() throws {
        let first = try Recording.encoder.encode(Self.run(assertInvariants: false).snapshot)
        let second = try Recording.encoder.encode(Self.run(assertInvariants: false).snapshot)
        #expect(first == second)
    }
}
