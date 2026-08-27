// Ticket 0047 — the history screen's own logic, walked on this machine.
//
// `HistoryScreen.swift` imports SwiftUI, so what is below is the ring around it: `meta`,
// `historyLine` from `WorkoutDayPicker`, and `HistoryDate`, with the SwiftUI wrapper
// dropped. Keep it in step with the screen by hand.
//
// `Rules.history` and `Streak.read` are **not** copied — they are the shipping calls, and
// they have their own suites in the two packages. What this file proves is that the screen
// says the right English about what they answer.
//
// Run it with `./run.sh`.
import Foundation
import HoppaRules
import HoppaStore

nonisolated(unsafe) var failures = 0
func check(_ what: String, _ ok: Bool) {
    print((ok ? "ok   " : "FAIL ") + what)
    if !ok { failures += 1 }
}

// MARK: - The calendar every case runs against

/// Rob's own: Amsterdam, Monday first. Fixed, so the checks do not read the machine.
let zone = TimeZone(identifier: "Europe/Amsterdam")!
let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = zone
    calendar.firstWeekday = 2
    return calendar
}()

func at(_ text: String) -> Timestamp {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = zone
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    return formatter.date(from: text)!.timeIntervalSince1970
}

// MARK: - The ring: `HistoryScreen.meta`

func meta(_ row: HistoryRow) -> String {
    var parts = [
        row.exerciseCount == 1 ? "1 exercise" : "\(row.exerciseCount) exercises",
        row.setCount == 1 ? "1 set" : "\(row.setCount) sets"
    ]
    if row.skippedCount > 0 {
        parts.append("\(row.skippedCount) skipped")
    }
    return parts.joined(separator: " · ")
}

func wentUp(_ row: HistoryRow) -> String? {
    guard row.wentUpCount > 0 else { return nil }
    return row.wentUpCount == 1 ? "1 went up" : "\(row.wentUpCount) went up"
}

// MARK: - The ring: `WorkoutDayPicker.historyLine`

func historyLine(_ logbook: Logbook, now: Timestamp) -> String {
    let count = logbook.workouts.count
    let workouts = count == 1 ? "1 workout" : "\(count) workouts"
    let run = Streak.read(logbook, now: now, calendar: calendar).run
    guard run > 0 else { return workouts }
    return "\(workouts) · \(run) week\(run == 1 ? "" : "s") in a row"
}

// MARK: - The ring: `HistoryDate`

func dayText(_ timestamp: Timestamp) -> String {
    Date(timeIntervalSince1970: timestamp).formatted(.dateTime.day().locale(Locale(identifier: "en_GB")))
}

func monthText(_ timestamp: Timestamp, now: Timestamp) -> String {
    let date = Date(timeIntervalSince1970: timestamp)
    let month = date.formatted(
        .dateTime.month(.abbreviated).locale(Locale(identifier: "en_GB"))).uppercased()
    guard calendar.component(.year, from: date)
        != calendar.component(.year, from: Date(timeIntervalSince1970: now))
    else { return month }
    return "\(month) \(date.formatted(.dateTime.year(.twoDigits).locale(Locale(identifier: "en_GB"))))"
}

// MARK: - The book the screen is looking at

let programId = ProgramID(1)
let upperA = WorkoutDayID(2)
let lowerA = WorkoutDayID(3)

func performed(_ id: Int, sets: Int, state: ExerciseState = .completed, progressed: Bool = false)
    -> PerformedExercise {
    PerformedExercise(
        exerciseId: ExerciseID(id),
        name: "Exercise \(id)",
        state: state,
        sets: state == .skipped
            ? []
            : (0..<sets).map { _ in LoggedSet(reps: 10, weight: Weight.kg(hundredths: 6000)) },
        outcome: state == .skipped
            ? nil
            : ProgressionOutcome(plannedSets: sets, thresholdReps: 10, progressed: progressed))
}

func workout(
    _ id: Int, day: WorkoutDayID, name: String, at started: String,
    exercises: [PerformedExercise]
) -> Workout {
    Workout(
        id: WorkoutID(id), programId: programId, workoutDayId: day, workoutDayName: name,
        startedAt: at(started), finishedAt: at(started) + 3600, state: .finished,
        exercises: exercises)
}

func book(_ workouts: [Workout]) -> Logbook {
    Logbook(
        nextId: 500,
        plateInventory: .standard(.kg),
        programs: [
            Program(
                id: programId, name: "Upper / Lower",
                defaultWeightUnit: .kg, mode: .progressiveOverload,
                days: [
                    WorkoutDay(id: upperA, name: "Upper A", exercises: []),
                    WorkoutDay(id: lowerA, name: "Lower A", exercises: [])
                ])
        ],
        workouts: workouts)
}

/// Three weeks of it: a run of three, one Workout with a skip, one that moved nothing.
let threeWeeks = book([
    workout(101, day: upperA, name: "Upper A", at: "2026-08-03 18:00", exercises: [
        performed(11, sets: 3, progressed: true),
        performed(12, sets: 3),
        performed(13, sets: 3)
    ]),
    workout(102, day: lowerA, name: "Lower A", at: "2026-08-11 18:00", exercises: [
        performed(21, sets: 3),
        performed(22, sets: 0, state: .skipped),
        performed(23, sets: 4, progressed: true),
        performed(24, sets: 3, progressed: true)
    ]),
    workout(103, day: upperA, name: "Upper A", at: "2026-08-19 18:00", exercises: [
        performed(11, sets: 1)
    ])
])

// MARK: - The list

let rows = Rules.history(in: threeWeeks)

check("the list is newest first", rows.map(\.id) == [WorkoutID(103), WorkoutID(102), WorkoutID(101)])
check("a row reads the live Day Name", rows[0].workoutDayName == "Upper A")
check("three exercises, nine sets", meta(rows[2]) == "3 exercises · 9 sets")
check("a skip is counted once, on its own", meta(rows[1]) == "3 exercises · 10 sets · 1 skipped")
check("one of each is singular", meta(rows[0]) == "1 exercise · 1 set")
check("the green line counts what went up", wentUp(rows[1]) == "2 went up")
check("one is singular there too", wentUp(rows[2]) == "1 went up")
check("a Workout that moved nothing draws no green line", wentUp(rows[0]) == nil)

// MARK: - The empty list

check("before the first Workout there is nothing to draw", Rules.history(in: book([])).isEmpty)
check("and the picker states the count alone",
      historyLine(book([]), now: at("2026-08-19 20:00")) == "0 workouts")

// MARK: - The strip and the figure

let streak = Streak.read(threeWeeks, now: at("2026-08-19 20:00"), calendar: calendar)
check("three weeks, all lit", streak.weeks.map(\.trained) == [true, true, true])
check("and the run is three", streak.run == 3)
check("the picker states both halves",
      historyLine(threeWeeks, now: at("2026-08-19 20:00")) == "3 workouts · 3 weeks in a row")

let monday = Streak.read(threeWeeks, now: at("2026-08-24 07:00"), calendar: calendar)
check("Monday morning adds a dark block", monday.weeks.map(\.trained) == [true, true, true, false])
check("and the run still reads three", monday.run == 3)

let broken = Streak.read(threeWeeks, now: at("2026-08-31 07:00"), calendar: calendar)
check("a whole week missed ends the run", broken.run == 0)
check("and the picker drops the half that is no longer true",
      historyLine(threeWeeks, now: at("2026-08-31 07:00")) == "3 workouts")

let one = book([workout(101, day: upperA, name: "Upper A", at: "2026-08-19 18:00", exercises: [
    performed(11, sets: 3)
])])
check("one workout, one week, both singular",
      historyLine(one, now: at("2026-08-19 20:00")) == "1 workout · 1 week in a row")

// MARK: - The dates

check("the day is the number alone", dayText(at("2026-08-18 18:00")) == "18")
check("the month is three letters", monthText(at("2026-08-18 18:00"), now: at("2026-08-26 09:00")) == "AUG")
check("and it carries the year once the date leaves this one",
      monthText(at("2025-12-29 18:00"), now: at("2026-08-26 09:00")) == "DEC 25")

// MARK: - Sixteen weeks, seeded by the harness and trained through the shipping rules

let seededNow = at("2026-08-26 09:00")
let seeded = HarnessSeed.trained(HarnessSeed.starterBook, weeks: 16, endingOn: seededNow)
let seededRows = Rules.history(in: seeded)
let seededStreak = Streak.read(seeded, now: seededNow, calendar: calendar)

// Fifteen weeks trained, two Workouts each: one week is missed on purpose.
check("the seed holds thirty Workouts", seededRows.count == 30)
check("the strip is sixteen blocks", seededStreak.weeks.count == Streak.blocks)
check("with exactly one dark one", seededStreak.weeks.filter { !$0.trained }.count == 1)
check("so the run is nine, not sixteen", seededStreak.run == 9)
check("the list names both Days",
      Set(seededRows.map(\.workoutDayName)) == ["Upper A", "Lower A"])
check("one row carries a skip", seededRows.filter { $0.skippedCount > 0 }.count == 1)
check("and that row counts one Exercise performed",
      seededRows.first { $0.skippedCount > 0 }?.exerciseCount == 1)
check("some Workouts moved nothing", seededRows.contains { $0.wentUpCount == 0 })
check("and most of them moved something", seededRows.filter { $0.wentUpCount > 0 }.count > 15)
// The whole point of running it through `Rules.reduce`: the weights are §4.1's own.
let squat = seeded.resolvedExercise(ExerciseID(12))!
check("the squat climbed off 80 kg", squat.workingWeight!.hundredths > 8000)
let bench = seeded.resolvedExercise(ExerciseID(10))!
check("and the bench climbed off 72.5 kg", bench.workingWeight!.hundredths > 7250)
// A Set is a record of the past (§2.5): the last Workout was performed at the weight the
// Exercise stood at then, which is one Increment behind where it stands now.
let lastBenchSet = seeded.workouts.last { workout in
    workout.exercises.contains { $0.exerciseId == ExerciseID(10) && !$0.sets.isEmpty }
}!
check("and the newest Set is not the live weight",
      lastBenchSet.exercises.first { $0.exerciseId == ExerciseID(10) }!
        .sets.last!.weight.hundredths <= bench.workingWeight!.hundredths)

// MARK: -

print(failures == 0 ? "\nAll checks passed." : "\n\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
