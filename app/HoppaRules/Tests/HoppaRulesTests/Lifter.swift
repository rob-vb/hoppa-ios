import HoppaRules

/// The lifter from `design/0015-history/gen-fixture.mjs`, ported.
///
/// **Only the lifter.** That file's *rules* are not ported and must not be: it predates
/// [Bounding the Microload](../../../../issues/0016-bounding-the-microload.md) and has no
/// roll-up at all — its own comment admits it picked a 0.25 kg Microplate so that sixteen
/// weeks would land under one Stack Step and never expose the case. `HoppaRules` supplies
/// the rules here; this file supplies the person.
///
/// A lifter is not a metronome. Two forces shape a session: how new the weight still is,
/// and the day itself. The second is what puts plateaus in the data, and a history with
/// no plateau proves nothing. Deterministic, so the snapshot is stable across runs.
struct LinearCongruential {
    var state: UInt32

    init(seed: Int) { state = UInt32(truncatingIfNeeded: seed) }

    /// The same generator `gen-fixture.mjs` used, to the bit.
    mutating func next() -> Double {
        state = state &* 1_664_525 &+ 1_013_904_223
        return Double(state) / 4_294_967_296
    }
}

enum Lifter {
    /// How this Exercise goes today, given how many sessions the weight has been owned.
    static func reps(
        plannedSets: Int,
        repRange: RepRange,
        sessionsAtThisWeight: Int,
        random: inout LinearCongruential
    ) -> [Int] {
        let top = repRange.top
        let bottom = repRange.bottom
        let span = max(1, top - bottom)
        // A new weight costs reps; owning it takes about two sessions.
        let halfSpan = Int((Double(span) * 0.5).rounded(.toNearestOrAwayFromZero))
        let newness = max(0, halfSpan - sessionsAtThisWeight * ((span + 1) / 2))
        // The day itself. Most days are fine; roughly one in three is short by a rep or two.
        let roll = random.next()
        let badDay = roll < 0.34 ? (roll < 0.12 ? 2 : 1) : 0

        return (0..<plannedSets).map { index in
            let fatigue = index > 0 && (newness > 0 || badDay > 0) ? 1 : 0
            return max(bottom - 2, min(top, top - newness - badDay - fatigue))
        }
    }
}

// MARK: - The Program, four Workout Days and eighteen Exercises

/// The logging prototype only ever needed Upper A. Sixteen weeks of history needs the
/// whole Program, or the Workout list reads "Upper A" fifteen times.
enum History {
    static let dayNames = ["Upper A", "Lower A", "Upper B", "Lower B"]
    /// Mon, Tue, Thu, Fri inside the same week.
    static let dayOffsets = [0, 1, 3, 4]

    /// Midnight UTC on Monday 17 August 2026, as seconds since the epoch. The rules hold
    /// no calendar, so the whole calendar is arithmetic on this one number.
    static let lastMonday: Timestamp = 1_786_924_800
    static let weeks = 16
    static let missedWeek = 6          // the gap in the streak grid
    static let shortWeek = 11          // only Upper A and Lower A that week
    static let oneOffWeek = 13         // a lighter bench away from the home gym
    static let skipWeek = 14           // one Exercise skipped that day

    struct Spec {
        let id: ExerciseID
        let name: String
        let day: Int
        let equipment: EquipmentType
        let unit: WeightUnit
        let start: String
        let sets: Int
        let range: RepRange
        let mode: ProgressionMode
        let increment: String
        let microplate: String?
        let base: String?
        let stackStep: String?
    }

    static func spec(
        _ id: Int, _ name: String, day: Int, _ equipment: EquipmentType, _ unit: WeightUnit,
        start: String, sets: Int, _ bottom: Int, _ top: Int, mode: ProgressionMode,
        increment: String, microplate: String? = nil, base: String? = nil, stackStep: String? = nil
    ) -> Spec {
        Spec(
            id: ExerciseID(id), name: name, day: day, equipment: equipment, unit: unit,
            start: start, sets: sets, range: RepRange(bottom, top), mode: mode,
            increment: increment, microplate: microplate, base: base, stackStep: stackStep)
    }

    /// Eighteen Exercises, in `gen-fixture.mjs`'s order — which is what seeds the
    /// generators, so the order is part of the fixture.
    static let specs: [Spec] = [
        // Upper A
        spec(101, "Smith machine bench press", day: 0, .smith, .kg, start: "65", sets: 3, 8, 12,
             mode: .progressiveOverload, increment: "2.5", base: "15"),
        spec(102, "Barbell row", day: 0, .barbell, .kg, start: "52.5", sets: 3, 8, 10,
             mode: .progressiveOverload, increment: "2.5"),
        // gen-fixture.mjs gave this a 0.25 kg Microplate **on purpose**, so that sixteen
        // weeks of Microloading would land under one Stack Step and the roll-up would
        // never be reached. That is the plate this history runs on the **1 kg**: it is
        // the case ticket 16 settled and the case ticket 20 said the old fixture dodged,
        // and a snapshot that never reaches it is not worth committing.
        spec(103, "Lat pulldown", day: 0, .stack, .lbs, start: "90", sets: 3, 10, 12,
             mode: .microloading, increment: "10", microplate: "1", stackStep: "10"),
        spec(104, "Dumbbell shoulder press", day: 0, .dumbbell, .kg, start: "20", sets: 3, 8, 12,
             mode: .progressiveOverload, increment: "2.5"),
        spec(105, "Weighted chin-up", day: 0, .bodyweight, .kg, start: "10", sets: 3, 6, 8,
             mode: .progressiveOverload, increment: "2.5"),
        // Lower A
        spec(106, "Barbell back squat", day: 1, .barbell, .kg, start: "80", sets: 3, 5, 8,
             mode: .progressiveOverload, increment: "5"),
        spec(107, "Romanian deadlift", day: 1, .barbell, .kg, start: "70", sets: 3, 8, 10,
             mode: .progressiveOverload, increment: "2.5"),
        spec(108, "Leg curl", day: 1, .stack, .lbs, start: "70", sets: 3, 10, 12,
             mode: .progressiveOverload, increment: "10", stackStep: "10"),
        spec(109, "Standing calf raise", day: 1, .smith, .kg, start: "60", sets: 4, 10, 15,
             mode: .progressiveOverload, increment: "2.5", base: "15"),
        // Upper B
        spec(110, "Overhead press", day: 2, .barbell, .kg, start: "40", sets: 3, 5, 8,
             mode: .microloading, increment: "2.5", microplate: "0.5"),
        spec(111, "Dumbbell row", day: 2, .dumbbell, .kg, start: "30", sets: 3, 8, 12,
             mode: .progressiveOverload, increment: "2.5"),
        spec(112, "Weighted dip", day: 2, .bodyweight, .kg, start: "10", sets: 3, 6, 10,
             mode: .progressiveOverload, increment: "2.5"),
        spec(113, "Face pull", day: 2, .cable, .lbs, start: "40", sets: 3, 12, 15,
             mode: .progressiveOverload, increment: "10", stackStep: "10"),
        spec(114, "Barbell curl", day: 2, .barbell, .kg, start: "30", sets: 3, 8, 12,
             mode: .microloading, increment: "2.5", microplate: "0.5"),
        // Lower B
        spec(115, "Front squat", day: 3, .barbell, .kg, start: "60", sets: 3, 5, 8,
             mode: .progressiveOverload, increment: "2.5"),
        spec(116, "Leg press", day: 3, .plateLoaded, .kg, start: "120", sets: 3, 8, 12,
             mode: .progressiveOverload, increment: "5", base: "25"),
        spec(117, "Leg extension", day: 3, .stack, .lbs, start: "80", sets: 3, 10, 15,
             mode: .progressiveOverload, increment: "10", stackStep: "10"),
        spec(118, "Seated calf raise", day: 3, .plateLoaded, .kg, start: "40", sets: 4, 10, 15,
             mode: .progressiveOverload, increment: "2.5", base: "10")
    ]

    /// The rack this history is run against: the standard kg Inventory, with the two
    /// Microplates the Program's Microloading Exercises name switched on (§5.2 ships them
    /// all off, and an Exercise on Microloading cannot name a plate the user does not own).
    static var inventory: PlateInventory { rackKg(microplates: ["1", "0.5"]) }

    static func logbook() -> Logbook {
        let days = (0..<4).map { index in
            WorkoutDay(
                id: WorkoutDayID(index + 1),
                name: dayNames[index],
                exercises: specs.filter { $0.day == index }.map { spec in
                    Exercise(
                        id: spec.id,
                        name: spec.name,
                        equipment: spec.equipment,
                        ownWeightUnit: spec.unit,
                        plannedSets: spec.sets,
                        repRange: spec.range,
                        workingWeight: Weight(decimalString: spec.start, unit: spec.unit)!,
                        increment: Weight(decimalString: spec.increment, unit: spec.unit)!,
                        microloadingIncrement: spec.microplate.map { Weight(decimalString: $0, unit: .kg)! },
                        modeOverride: spec.mode,
                        storedBaseWeight: spec.base.map { Weight(decimalString: $0, unit: spec.unit)! },
                        storedStackStep: spec.stackStep.map { Weight(decimalString: $0, unit: spec.unit)! },
                        microload: spec.equipment.hasPin && spec.unit != .kg ? Weight.kg(hundredths: 0) : nil)
                })
        }
        return Logbook(
            nextId: 1000,
            plateInventory: inventory,
            programs: [
                Program(
                    id: ProgramID(1), name: "Upper / Lower",
                    defaultWeightUnit: .kg, mode: .progressiveOverload, days: days)
            ])
    }

    struct Session {
        let startedAt: Timestamp
        let week: Int
        let day: Int
    }

    /// The Program runs Mon / Tue / Thu / Fri, sixteen weeks back, with two holes the
    /// screens have to survive: week 7 missed entirely and week 12 cut to two days.
    static var sessions: [Session] {
        var out: [Session] = []
        for week in 0..<weeks {
            if week == missedWeek { continue }
            let monday = lastMonday - Double((weeks - 1 - week) * 7 * 86_400)
            let dayIndices = week == shortWeek ? [0, 1] : [0, 1, 2, 3]
            for day in dayIndices {
                // The last week stops after two days: today is Wednesday.
                if week == weeks - 1 && day > 1 { continue }
                out.append(Session(
                    startedAt: monday + Double(dayOffsets[day] * 86_400) + 18 * 3600,
                    week: week,
                    day: day))
            }
        }
        return out.sorted { $0.startedAt < $1.startedAt }
    }
}
