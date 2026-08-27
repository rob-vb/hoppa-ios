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

    /// Ticket 0047 — **the second switch, and the one Flow 4 was kept for.**
    ///
    /// §6.7 needs weeks of Workouts to say anything: a streak of one block and a list of
    /// one row prove that the screen draws, not that it reads. Ticket 0029 kept this file
    /// alive for exactly that, and this is the flag that pays it off. With it on, the
    /// starter Program is trained forward through **the shipping rules** — every Workout is
    /// `Rules.reduce` doing what it does on the phone — so the weights climb, the reps
    /// plateau and the streak has a hole in it, because a fixture with none proves nothing.
    ///
    /// It needs `isEnabled` too: it is the same seed, with more of it.
    static let seedsHistory = false

    /// Returns the logbook URL, having put a starter Program there if the phone had none.
    static func prepare() -> URL {
        let url = Logbook.fileURL
        guard isEnabled else { return url }
        guard !FileManager.default.fileExists(atPath: url.path) else { return url }
        do {
            try LogbookFile.encode(seed).write(to: url, options: [.atomic])
        } catch {
            // Nothing to recover: the harness will simply show a fresh install.
            print("[harness] could not seed a Program — \(error)")
        }
        return url
    }

    /// What lands on the phone: the bare Program, or that Program sixteen weeks in.
    private static var seed: Logbook {
        seedsHistory ? trained(starter, weeks: 16, endingOn: Date().timeIntervalSince1970) : starter
    }

    /// `starter`, reachable from `app/checks/History` — the seed is walked on the VPS
    /// before it ever reaches a phone.
    static var starterBook: Logbook { starter }

    /// Upper A and Lower A, cut down to what a two-Set proof needs. The weights are Rob's
    /// own from `SPEC.md`'s worked examples, so the numbers on screen are recognisable.
    ///
    /// **Two Days, since ticket 0047**: a history built on one Day is a list that reads
    /// `Upper A` fifty times, and the picker's own line has nothing to tell apart.
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
                        ]),
                        WorkoutDay(id: WorkoutDayID(3), name: "Lower A", exercises: [
                            Exercise(
                                id: ExerciseID(12), name: "Barbell back squat",
                                equipment: .barbell,
                                plannedSets: 3, repRange: RepRange(5, 8),
                                workingWeight: Weight(decimalString: "80", unit: .kg)!,
                                increment: Weight(decimalString: "5", unit: .kg)!),
                            Exercise(
                                id: ExerciseID(13), name: "Romanian deadlift",
                                equipment: .barbell,
                                plannedSets: 3, repRange: RepRange(8, 10),
                                workingWeight: Weight(decimalString: "70", unit: .kg)!,
                                increment: Weight(decimalString: "2.5", unit: .kg)!)
                        ])
                    ])
            ])
    }

    // MARK: - Sixteen weeks of it (ticket 0047)

    /// Which week has no Workout in it at all, counted from the start. §6.7's strip draws
    /// a dark block and **nothing else** for it, and a fixture where every block is lit
    /// cannot show that.
    static let missedWeek = 6
    /// Which week skips one Exercise, so one row of the list carries `· 1 skipped`.
    static let skipWeek = 11
    /// Ticket 0049 — which week is trained at a **One-off Weight**: a lighter bench away
    /// from the home gym. §6.7's chart draws a hollow marker off the line for it and
    /// leaves its Set grid column empty, and a seed with no One-off in it cannot show
    /// either. Reachable on Rob's phone, unlike the mixed-unit half of the same screen.
    static let oneOffWeek = 8

    /// Train the Program forward, Monday and Thursday, `weeks` weeks back from `endingOn`.
    ///
    /// **Every Workout goes through `Rules.reduce`**, the one door the phone uses, so the
    /// progressions on screen are the progressions §4.1 actually makes. Nothing here writes
    /// a `Workout` by hand.
    ///
    /// Deterministic: no clock and no randomness, so two runs seed the same book. The reps
    /// fall short on every third session, which is what puts a plateau in the chart and a
    /// row with no green line in the list.
    static func trained(_ base: Logbook, weeks: Int, endingOn now: Timestamp) -> Logbook {
        var book = base
        let day = 86_400.0
        // Whole days back from today, so the last session is this week and the strip ends lit.
        let lastMonday = now - 3 * day
        var session = 0

        for week in 0..<weeks {
            if week == missedWeek { continue }
            let monday = lastMonday - Double((weeks - 1 - week)) * 7 * day
            for (index, offset) in [0.0, 3.0].enumerated() {
                var clock = monday + offset * day + 18 * 3600
                func send(_ action: Action) {
                    clock += 9
                    book = Rules.reduce(book, action, at: clock)
                }
                let dayId = WorkoutDayID(index == 0 ? 2 : 3)
                send(.startWorkout(programId: ProgramID(1), workoutDayId: dayId))
                guard let open = book.openWorkout else { continue }

                for position in open.exercises.indices {
                    send(.selectExercise(index: position))
                    // One Exercise skipped, one week, so the list has a `· 1 skipped` row.
                    if week == skipWeek && index == 0 && position == 0 {
                        send(.skip)
                        continue
                    }
                    guard let resolved = book.openWorkout?.current
                        .flatMap({ book.resolvedExercise($0.exerciseId) }) else { continue }
                    // One Workout at a One-off Weight, so §6.7's chart has a hollow marker
                    // to draw. It logs its Sets and it never progresses (§4.3).
                    if week == oneOffWeek && index == 0 && position == 0,
                       let working = resolved.workingWeight {
                        send(.setOneOffWeight(working - Weight(decimalString: "7.5", unit: working.unit)!))
                    }
                    // Every third session is short of the threshold, so the weight stays.
                    let reps = session % 3 == 2 ? resolved.repRange.bottom : resolved.targetReps
                    for _ in 0..<resolved.plannedSets { send(.logSet(reps: reps)) }
                }
                send(.finish)
                session += 1
            }
        }
        return book
    }
}
