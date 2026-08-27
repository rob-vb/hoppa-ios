// Ticket 0048 — the past-Workout screen's own logic, walked on this machine.
//
// `PastWorkoutScreen.swift` imports SwiftUI, so what is below is the ring around it: the
// header's meta line, the verdict beside a name, the One-off chip, the weight text, the
// date, and the confirm's two sentences — with the SwiftUI wrapper dropped. Keep it in
// step with the screen by hand.
//
// `Rules.pastWorkout` is **not** copied. It is the shipping call, and it has nineteen tests
// of its own in `HoppaRulesTests`. What this file proves is that the screen says the right
// English about what it answers, and that it says it about **every one of the seeded
// thirty Workouts** and not only about a hand-built one.
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

// MARK: - The calendar every date runs against

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

// MARK: - The ring: `PastWorkoutScreen`

func weightText(_ value: PastWeight) -> String {
    var text = "\(value.weight.decimalString) \(value.weight.unit.rawValue)"
    if let micro = value.microload, !micro.isZero {
        text += " + \(micro.decimalString) \(micro.unit.rawValue)"
    }
    return text
}

/// What the label role uppercases, before it uppercases it.
func verdict(_ progression: PastProgression) -> String? {
    switch progression {
    case .wentUp(let from, let to):
        return to.map { "\(weightText(from)) → \(weightText($0))" } ?? "Went up"
    case .stayed: return "Stayed"
    case .skipped: return "Skipped"
    case .oneOff: return nil            // the chip under the name carries it
    case .gone: return "Removed from the program"
    }
}

func oneOffText(_ stayed: PastWeight?) -> String {
    guard let stayed else { return "One-off" }
    return "One-off · \(weightText(stayed)) stayed"
}

func meta(_ row: HistoryRow) -> String {
    var parts = [
        row.exerciseCount == 1 ? "1 exercise" : "\(row.exerciseCount) exercises",
        row.setCount == 1 ? "1 set" : "\(row.setCount) sets"
    ]
    if row.skippedCount > 0 { parts.append("\(row.skippedCount) skipped") }
    return "\(fullDate(row.startedAt)) · " + parts.joined(separator: " · ")
}

func removes(_ row: HistoryRow) -> String {
    let exercises = row.exerciseCount == 1 ? "1 exercise" : "\(row.exerciseCount) exercises"
    let sets = row.setCount == 1 ? "1 set" : "\(row.setCount) sets"
    return "This removes \(exercises) and \(sets) from your history."
}

/// `PastWorkoutDate.full`, with the app's calendar swapped for the fixed one.
func fullDate(_ timestamp: Timestamp) -> String {
    let date = Date(timeIntervalSince1970: timestamp)
    return [
        date.formatted(.dateTime.day()),
        date.formatted(.dateTime.month(.abbreviated)),
        date.formatted(.dateTime.year())
    ].joined(separator: " ").uppercased()
}

// MARK: - Sixteen weeks, seeded by the harness and trained through the shipping rules

let now = at("2026-08-26 09:00")
let book = HarnessSeed.trained(HarnessSeed.starterBook, weeks: 16, endingOn: now)
let rows = Rules.history(in: book)

check("the seed holds thirty Workouts", rows.count == 30)

// **Every Workout opens.** The list is thirty doors and none of them may lead nowhere.
check("every row opens a Workout", rows.allSatisfy { Rules.pastWorkout($0.id, in: book) != nil })

// **The header is the row.** The screen and the list it was opened from cannot disagree.
check("the header's counts are the row's own",
      rows.allSatisfy { Rules.pastWorkout($0.id, in: book)!.row == $0 })

// **Nothing that went up is missing its number**, across thirty Workouts.
var wentUpRows = 0
var stayedRows = 0
var skippedRows = 0
for row in rows {
    for exercise in Rules.pastWorkout(row.id, in: book)!.exercises {
        switch exercise.progression {
        case .wentUp(_, let to):
            wentUpRows += 1
            check("a went-up row states its weight", to != nil)
        case .stayed: stayedRows += 1
        case .skipped: skippedRows += 1
        default: break
        }
    }
}
check("the seed produced went-up rows", wentUpRows > 30)
check("and rows that stayed", stayedRows > 10)
check("and exactly one skip", skippedRows == 1)

// MARK: - One Workout, read line by line

let newest = rows[0]
let past = Rules.pastWorkout(newest.id, in: book)!
check("the meta line reads date, exercises and sets",
      meta(newest) == "\(fullDate(newest.startedAt)) · \(newest.exerciseCount) exercises · \(newest.setCount) sets")
check("the confirm counts what the header counts",
      removes(newest) == "This removes \(newest.exerciseCount) exercises and \(newest.setCount) sets from your history.")
check("and it names no skip, because this Workout has none", newest.skippedCount == 0)

let skipped = rows.first { $0.skippedCount > 0 }!
check("a Workout with a skip says so in the meta line", meta(skipped).hasSuffix("· 1 skipped"))
let skippedPast = Rules.pastWorkout(skipped.id, in: book)!
let skippedExercise = skippedPast.exercises.first { $0.progression == .skipped }!
check("the skipped Exercise reads SKIPPED", verdict(skippedExercise.progression) == "Skipped")
check("and it carries no Sets", skippedExercise.sets.isEmpty)
// The confirm counts the Sets, and a skip holds none of them, so the sentence stays true.
check("the confirm's Set count is the Sets that exist",
      skippedPast.exercises.reduce(0) { $0 + $1.sets.count } == skipped.setCount)

// MARK: - The English of a verdict

check("a went-up verdict is an arrow between two weights",
      verdict(.wentUp(from: PastWeight(weight: Weight(decimalString: "25", unit: .kg)!),
                      to: PastWeight(weight: Weight(decimalString: "27.5", unit: .kg)!)))
      == "25 kg → 27.5 kg")
check("a mixed-unit pin keeps both units and converts nothing",
      verdict(.wentUp(
        from: PastWeight(weight: Weight(decimalString: "100", unit: .lbs)!,
                         microload: Weight(decimalString: "1", unit: .kg)!),
        to: PastWeight(weight: Weight(decimalString: "100", unit: .lbs)!,
                       microload: Weight(decimalString: "2", unit: .kg)!)))
      == "100 lbs + 1 kg → 100 lbs + 2 kg")
check("a Workout from an older build still says it went up",
      verdict(.wentUp(from: PastWeight(weight: Weight(decimalString: "25", unit: .kg)!), to: nil))
      == "Went up")
check("a One-off has no verdict beside the name", verdict(.oneOff(stayed: nil)) == nil)
check("and its chip states the weight that survived",
      oneOffText(PastWeight(weight: Weight(decimalString: "80", unit: .kg)!)) == "One-off · 80 kg stayed")
check("a One-off with no Working Weight states the chip alone",
      oneOffText(nil) == "One-off")
check("an Exercise deleted mid-Workout says why it has no verdict",
      verdict(.gone) == "Removed from the program")

// MARK: - The date

check("the date carries the year, always", fullDate(at("2026-08-03 18:00")) == "3 AUG 2026")
check("and it does so for a date in another year", fullDate(at("2025-12-29 18:00")) == "29 DEC 2025")

// MARK: - The delete, through the one door

var afterDelete = Rules.reduce(book, .deleteWorkout(newest.id), at: now)
check("the deleted Workout is gone from the list", Rules.history(in: afterDelete).count == 29)
check("and its screen has nothing left to show", Rules.pastWorkout(newest.id, in: afterDelete) == nil)
// **The working weights stay where they are** — the second half of the confirm.
check("every Working Weight is untouched", afterDelete.programs == book.programs)

// A Workout that is not there deletes nothing at all.
afterDelete = Rules.reduce(afterDelete, .deleteWorkout(newest.id), at: now)
check("deleting it twice changes nothing", Rules.history(in: afterDelete).count == 29)

// MARK: -

print(failures == 0 ? "\nAll checks passed." : "\n\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
