// Ticket 0058 — the Progress page's own logic, walked on this machine.
//
// `ProgressScreen.swift` imports SwiftUI, so what is below is the ring around it: `meta`,
// the green line, the empty copy, and `progressLine` from `WorkoutDayPicker`, with the
// SwiftUI wrapper dropped. Keep it in step with the screen by hand.
//
// `Rules.progress` is **not** copied — it is the shipping call, and it has its own suite in
// `HoppaRulesTests`. What this file proves is that the screen says the right English about
// what it answers, and that on the seed the phone gets, the list is the Program's own order
// and holds exactly the Exercises that have been trained. Ticket 0050's version of that last
// check lived in `app/checks/Chart` as *which cards carry a door*; the door moved, and so
// did the check.
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

// MARK: - The calendar the seed runs against

/// Rob's own: Amsterdam. Fixed, so the checks do not read the machine.
let zone = TimeZone(identifier: "Europe/Amsterdam")!
let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = zone
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

// MARK: - The ring: `ProgressScreen`

func meta(_ row: ProgressRow) -> String {
    let sessions = row.sessionCount == 1 ? "1 session" : "\(row.sessionCount) sessions"
    return "\(row.workoutDayName) · \(sessions)"
}

func wentUp(_ row: ProgressRow) -> String? {
    guard row.timesUp > 0 else { return nil }
    return row.timesUp == 1 ? "1 went up" : "\(row.timesUp) went up"
}

func countLine(_ rows: [ProgressRow]) -> String {
    rows.count == 1 ? "1 exercise" : "\(rows.count) exercises"
}

let emptyHeading = "Nothing here yet"
let emptyBody = "Finish a workout and every exercise you trained lands here."

// MARK: - The ring: `WorkoutDayPicker.progressLine`

func progressLine(_ logbook: Logbook) -> String {
    let count = Rules.progress(in: logbook).count
    return count == 1 ? "1 exercise" : "\(count) exercises"
}

// MARK: - The mark, as `Sparkline.swift` draws it, on a grid of characters

/// **A copy, and it can rot** — it copies only the flip and the inset. Every point is
/// `ProgressRow.sparkline`, which is the shipping rule's own.
func spark(_ marks: [SparkPoint], width: Int = 22, height: Int = 5) -> [String] {
    var grid = Array(repeating: Array(repeating: Character(" "), count: width), count: height)
    guard !marks.isEmpty else { return grid.map { String($0) } }
    func at(_ mark: SparkPoint) -> (x: Int, y: Int) {
        (Int((mark.x * Double(width - 1)).rounded()),
         Int(((1 - mark.y) * Double(height - 1)).rounded()))
    }
    for (a, b) in zip(marks, marks.dropFirst()) {
        let (x0, y0) = at(a), (x1, y1) = at(b)
        guard x1 > x0 else { continue }
        for x in x0...x1 {
            let t = Double(x - x0) / Double(x1 - x0)
            grid[Int((Double(y0) + t * Double(y1 - y0)).rounded())][x] = "─"
        }
    }
    let last = at(marks[marks.count - 1])
    grid[last.y][last.x] = "●"
    return grid.map { String($0) }
}

extension String {
    func rightPadded(to width: Int) -> String {
        count >= width ? self : self + String(repeating: " ", count: width - count)
    }
}

/// One row as `ProgressScreen` draws it: the Name, the meta line, the green line where
/// there is one, the mark, and the chevron. The whole row is the door.
func draw(_ row: ProgressRow) {
    let textWidth = 40
    let text = [row.name, meta(row), wentUp(row) ?? "", "", ""]
    for (line, marked) in zip(text, spark(row.sparkline)) {
        print("   " + line.rightPadded(to: textWidth) + marked + (line == row.name ? "  ›" : ""))
    }
    print("   " + String(repeating: "─", count: textWidth + 22 + 3))
}

// MARK: - Before the first session

let bare = HarnessSeed.starterBook
let none = Rules.progress(in: bare)

print("=== Before the first Workout ===")
check("no Exercise has been trained, so the list is empty", none.isEmpty)
check("the picker's door reads the count alone", progressLine(bare) == "0 exercises")
check("the empty heading is History's", emptyHeading == "Nothing here yet")
check("and the body says what lands here",
      emptyBody == "Finish a workout and every exercise you trained lands here.")

// MARK: - One session

let onceNow = at("2026-08-26 18:00")
let once = HarnessSeed.trained(bare, weeks: 1, endingOn: onceNow)
let onceRows = Rules.progress(in: once)

print("")
print("=== One week: Upper A on Monday, Lower A on Thursday ===")
for row in onceRows { draw(row) }
check("every seeded Exercise was trained once, so all four are rows", onceRows.count == 4)
check("and the door counts them", progressLine(once) == "4 exercises")
check("one session is singular", onceRows.allSatisfy { meta($0).hasSuffix("· 1 session") })
check("the Day comes first on the meta line",
      onceRows.map { meta($0) } == ["Upper A · 1 session", "Upper A · 1 session",
                                    "Lower A · 1 session", "Lower A · 1 session"])
check("a session that went up is one green line",
      onceRows.compactMap(wentUp).allSatisfy { $0 == "1 went up" })
check("and the mark on each row is the one dot",
      onceRows.allSatisfy { $0.sparkline.count == 1 && $0.sparkline[0].x == 1 })

// MARK: - Sixteen weeks, seeded by the harness and trained through the shipping rules

let seededNow = at("2026-08-26 09:00")
let seeded = HarnessSeed.trained(bare, weeks: 16, endingOn: seededNow)
let rows = Rules.progress(in: seeded)

print("")
print("=== Sixteen weeks: the Progress page, top to bottom ===")
print("   " + countLine(rows).uppercased())
for row in rows { draw(row) }

check("the count above the list matches the door", countLine(rows) == progressLine(seeded))
check("the list is the Program's own order",
      rows.map(\.id) == seeded.allExercises.map(\.id))
check("which is Upper A's two, then Lower A's two",
      rows.map(\.workoutDayName) == ["Upper A", "Upper A", "Lower A", "Lower A"])
check("the Names are live off the Program",
      rows.map(\.name) == seeded.allExercises.map(\.name))
check("fifteen weeks trained, so fifteen sessions on the row that was never skipped",
      rows[1].sessionCount == 15)
check("the skipped week is one session fewer on the bench",
      rows[0].sessionCount == 14 && meta(rows[0]) == "Upper A · 14 sessions")
check("the green line counts what went up, in words",
      rows.allSatisfy { row in
          let chart = Rules.exerciseChart(row.id, in: seeded)!
          return wentUp(row) == "\(chart.totals!.timesUp) went up"
      })
check("some sessions went up on every row", rows.allSatisfy { $0.timesUp > 0 })
check("and none went up more often than it was trained",
      rows.allSatisfy { $0.timesUp <= $0.sessionCount })
check("every mark is the chart's own line, point for point",
      rows.allSatisfy { Rules.exerciseChart($0.id, in: seeded)!.sparkline == $0.sparkline })

// MARK: - Which Exercises appear, and which do not

print("")
print("=== Who is on the list ===")

var withOneMore = Rules.reduce(
    seeded,
    .addExercise(
        workoutDayId: WorkoutDayID(2), at: 2,
        draft: ExerciseDraft(
            name: "Face pull", equipment: .machineStack, ownWeightUnit: .kg,
            plannedSets: 3, repRange: RepRange(12, 15),
            workingWeight: Weight(decimalString: "20", unit: .kg)!,
            increment: Weight(decimalString: "5", unit: .kg)!,
            stackStep: Weight(decimalString: "5", unit: .kg)!,
            shownUnit: .kg)),
    at: seededNow)
check("an Exercise added after the last Workout is not a row",
      Rules.progress(in: withOneMore).count == 4 && withOneMore.allExercises.count == 5)
check("so the door still says four", progressLine(withOneMore) == "4 exercises")

withOneMore = Rules.reduce(
    withOneMore,
    .startWorkout(programId: ProgramID(1), workoutDayId: WorkoutDayID(2)), at: seededNow + 3600)
for _ in 0..<3 {
    withOneMore = Rules.reduce(withOneMore, .logSet(reps: 12), at: seededNow + 3600)
}
check("an Open Workout adds nothing yet", Rules.progress(in: withOneMore).count == 4)

let deleted = Rules.reduce(seeded, .deleteExercise(ExerciseID(10)), at: seededNow)
check("a deleted Exercise drops out, and the rest keep their order",
      Rules.progress(in: deleted).map(\.id) == [ExerciseID(11), ExerciseID(12), ExerciseID(13)])
check("and the door counts three", progressLine(deleted) == "3 exercises")

let renamed = Rules.reduce(seeded, .renameWorkoutDay(WorkoutDayID(2), name: "Push"), at: seededNow)
check("a renamed Day reads live on its rows",
      Rules.progress(in: renamed).prefix(2).allSatisfy { $0.workoutDayName == "Push" })

let oneLeft = Rules.reduce(
    Rules.reduce(
        Rules.reduce(seeded, .deleteExercise(ExerciseID(10)), at: seededNow),
        .deleteExercise(ExerciseID(11)), at: seededNow),
    .deleteExercise(ExerciseID(12)), at: seededNow)
check("one row is singular on the door", progressLine(oneLeft) == "1 exercise")
check("and above the list", countLine(Rules.progress(in: oneLeft)) == "1 exercise")

// MARK: -

print("")
print(failures == 0 ? "All checks passed." : "\(failures) check(s) FAILED.")
exit(failures == 0 ? 0 : 1)
