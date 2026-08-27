// Ticket 0046 — the Re-weigh list's screen logic, walked on this machine.
//
// `ReweighScreen.swift` imports SwiftUI, so it cannot be compiled here. `List` below is
// the thin ring around it: `freeze`, `typed`, `commit`, `missing` and `intro`, with
// `@State` and the SwiftUI wrapper dropped — plus the picker banner's count and copy.
// **That ring is a copy and it can rot**; keep it in step by hand when the screen changes,
// and keep it as small as it is. It is the same bargain `app/checks/UnitStash` struck.
//
// Every write goes through `Rules.reduce`, the door `LogbookStore.send` uses, so the
// screen's one action is judged by the shipping rule.
//
// Run it with `./run.sh`.
import Foundation
import HoppaRules

nonisolated(unsafe) var failures = 0
func check(_ what: String, _ ok: Bool) {
    print((ok ? "ok   " : "FAIL ") + what)
    if !ok { failures += 1 }
}

func kg(_ text: String) -> Weight { Weight(decimalString: text, unit: .kg)! }
func lbs(_ text: String) -> Weight { Weight(decimalString: text, unit: .lbs)! }

// MARK: - The book the screen is looking at

enum Ids {
    static let program = ProgramID(1)
    static let upperA = WorkoutDayID(2)
    static let lowerA = WorkoutDayID(3)
    static let smith = ExerciseID(10)
    static let row = ExerciseID(11)
    static let pulldown = ExerciseID(12)
    static let chin = ExerciseID(13)
    static let squat = ExerciseID(14)
}

func book() -> Logbook {
    var rack = PlateInventory.standard(.kg)
    for size in ["1", "0.5", "0.25"] { rack.setPlate(kg(size), on: true) }
    let upperA = WorkoutDay(id: Ids.upperA, name: "Upper A", exercises: [
        Exercise(
            id: Ids.smith, name: "Smith machine bench press", equipment: .smith,
            plannedSets: 3, repRange: RepRange(8, 12),
            workingWeight: kg("72.5"), increment: kg("2.5"),
            microloadingIncrement: kg("0.25"), storedBaseWeight: kg("15")),
        Exercise(
            id: Ids.row, name: "Barbell row", equipment: .barbell,
            plannedSets: 3, repRange: RepRange(8, 10),
            workingWeight: kg("60"), increment: kg("2.5")),
        Exercise(
            id: Ids.pulldown, name: "Lat pulldown", equipment: .stack, ownWeightUnit: .lbs,
            plannedSets: 3, repRange: RepRange(10, 12),
            workingWeight: lbs("100"), increment: lbs("10"),
            microloadingIncrement: kg("1"), modeOverride: .microloading,
            storedStackStep: lbs("10"), microload: kg("1")),
        Exercise(
            id: Ids.chin, name: "Weighted chin-up", equipment: .bodyweight,
            plannedSets: 3, repRange: RepRange(6, 8),
            workingWeight: kg("15"), increment: kg("2.5")),
    ])
    let lowerA = WorkoutDay(id: Ids.lowerA, name: "Lower A", exercises: [
        Exercise(
            id: Ids.squat, name: "Back squat", equipment: .barbell,
            plannedSets: 3, repRange: RepRange(5, 8),
            workingWeight: kg("100"), increment: kg("5")),
    ])
    return Logbook(
        nextId: 20, plateInventory: rack,
        programs: [Program(
            id: Ids.program, name: "Upper / Lower", defaultWeightUnit: .kg,
            mode: .progressiveOverload, days: [upperA, lowerA])])
}

// MARK: - The ring — verbatim from `ReweighScreen`, minus SwiftUI

final class List {
    var logbook: Logbook
    var frozen: [ExerciseID] = []
    var text: [ExerciseID: String] = [:]
    var focus: ExerciseID?
    /// Every action the screen has sent, in order. The screen writes through
    /// `LogbookStore.send`; this stands in for it and keeps the receipts.
    var sent: [Action] = []

    init(_ logbook: Logbook) { self.logbook = logbook }

    var rack: PlateInventory { logbook.plateInventory }

    func resolved(_ id: ExerciseID) -> ResolvedExercise? { logbook.resolvedExercise(id) }

    // --- verbatim from ReweighScreen ---
    func freeze() {
        guard frozen.isEmpty else { return }
        frozen = Rules.reweighList(in: logbook)
    }

    func typed(_ id: ExerciseID) -> Weight? {
        guard let unit = resolved(id)?.unit else { return nil }
        return Weight(decimalString: text[id] ?? "", unit: unit)
    }

    func commit(_ id: ExerciseID) {
        guard let weight = typed(id), weight != resolved(id)?.workingWeight else { return }
        send(.reweigh(id, weight))
    }

    func missing(_ exercise: Exercise) -> String? {
        guard let resolved = resolved(exercise.id) else { return nil }
        if resolved.equipment.takesBaseWeight, resolved.baseWeight == nil { return "no base weight" }
        switch resolved.mode {
        case .progressiveOverload:
            return resolved.increment == nil ? "no increment" : nil
        case .microloading:
            return resolved.microloadingIncrement == nil ? "no microplate" : nil
        }
    }

    var intro: String {
        let left = Rules.reweighList(in: logbook).count
        let done = frozen.count - left
        guard done > 0 else {
            return "An exercise with no weight logs no set and does not progress. "
                + "Type what you lift it with now."
        }
        return left == 0
            ? "Every exercise has a weight."
            : "\(done) of \(frozen.count) done. \(left) still \(left == 1 ? "has" : "have") no weight."
    }
    // --- end verbatim ---

    /// `.onChange(of: focus)`: the field being left is the field that writes.
    func focusOn(_ id: ExerciseID?) {
        if let old = focus { commit(old) }
        focus = id
    }

    /// The `Done` button, and the back chevron.
    func leave() { if let focus { commit(focus) } }

    func type(_ id: ExerciseID, _ value: String) { text[id] = value }

    func send(_ action: Action) {
        sent.append(action)
        logbook = Rules.reduce(logbook, action, at: 1_770_000_000)
    }

    /// The rows the screen actually draws, in Program then Day then position order.
    var rows: [ExerciseID] {
        logbook.programs.flatMap { $0.days.flatMap { $0.exercises } }
            .filter { frozen.contains($0.id) }.map(\.id)
    }
}

/// `WorkoutDayPicker.reweighBanner` — verbatim.
func bannerCopy(_ logbook: Logbook) -> (heading: String, sub: String)? {
    let count = Rules.reweighList(in: logbook).count
    guard count > 0 else { return nil }
    return (count == 1 ? "1 exercise has no weight" : "\(count) exercises have no weight",
            count == 1 ? "It logs no set until you weigh it"
                       : "They log no sets until you weigh them")
}

// MARK: - The switch, and the list it lands on

print("\n— the door after the confirm —")
do {
    let list = List(book())
    // §6.6’s warning states the count before the switch. Every barbell, Smith and
    // bodyweight Exercise; the lbs pin keeps its own unit.
    let warned = Rules.exercisesClearedByInventoryUnit(.lbs, in: list.logbook)
    check("the warning counts four, and names them in Program order",
          warned == [Ids.smith, Ids.row, Ids.chin, Ids.squat])

    list.send(.setPlateInventoryUnit(.lbs))
    list.freeze()
    check("the list the confirm lands on is exactly what was warned about",
          list.frozen == warned)
    check("and it is drawn in Program, Day, position order",
          list.rows == [Ids.smith, Ids.row, Ids.chin, Ids.squat])
    check("the pin is not on it — it carries its own unit",
          !list.frozen.contains(Ids.pulldown))
    check("nothing is done yet, so the intro states the cost",
          list.intro.hasPrefix("An exercise with no weight logs no set"))
}

print("\n— the list is frozen while the screen is open —")
do {
    let list = List(book())
    list.send(.setPlateInventoryUnit(.lbs))
    list.freeze()
    let before = list.rows

    list.focusOn(Ids.row)
    list.type(Ids.row, "135")
    list.focusOn(Ids.smith)

    check("the weight is written when the field is left", list.logbook.exercise(Ids.row)?.workingWeight == lbs("135"))
    check("the row keeps its place", list.rows == before)
    check("the rule no longer holds it", !Rules.reweighList(in: list.logbook).contains(Ids.row))
    check("and the intro counts it", list.intro == "1 of 4 done. 3 still have no weight.")

    list.type(Ids.smith, "185")
    list.type(Ids.chin, "0")
    list.type(Ids.squat, "225")
    list.focusOn(nil)
    check("only the focused field wrote", list.sent.count == 3)
    list.focusOn(Ids.chin); list.focusOn(Ids.squat); list.leave()
    check("every row is weighed", Rules.reweighList(in: list.logbook).isEmpty)
    check("and the intro says so", list.intro == "Every exercise has a weight.")
    check("the rows are still all there", list.rows == before)
}

print("\n— one write per row, and one field —")
do {
    let list = List(book())
    list.send(.setPlateInventoryUnit(.lbs))
    list.freeze()
    // Half-typed states are not weights and must not reach the disk.
    list.focusOn(Ids.squat)
    for keystroke in ["2", "22", "225"] { list.type(Ids.squat, keystroke) }
    list.leave()
    check("a three-digit number is one write, not three", list.sent.count == 2)
    check("and it is the finished number", list.logbook.exercise(Ids.squat)?.workingWeight == lbs("225"))

    let squat = list.logbook.exercise(Ids.squat)!
    check("the Increment the switch cleared stays cleared", squat.increment == nil)
    check("so the row says what is still missing", list.missing(squat) == "no increment")
}

print("\n— zero, which is a real weight (§2.8) —")
do {
    let list = List(book())
    list.send(.setPlateInventoryUnit(.lbs))
    list.freeze()
    list.focusOn(Ids.chin)
    list.type(Ids.chin, "0")
    list.leave()
    check("a chin-up with no belt leaves the list", !Rules.reweighList(in: list.logbook).contains(Ids.chin))
    check("and it is stored as zero, not as unset", list.logbook.exercise(Ids.chin)?.workingWeight == lbs("0"))
}

print("\n— an empty field writes nothing —")
do {
    let list = List(book())
    list.send(.setPlateInventoryUnit(.lbs))
    list.freeze()
    list.focusOn(Ids.row)
    list.focusOn(Ids.chin)       // opened, touched nothing, moved on
    list.leave()
    check("a field left blank writes nothing", list.sent.count == 1)
    check("and both rows are still on the list",
          Rules.reweighList(in: list.logbook).contains(Ids.row)
            && Rules.reweighList(in: list.logbook).contains(Ids.chin))

    // A trailing separator **is** a number here — `Weight(decimalString:)` reads `72.` as
    // 72 — and that is the parser the Exercise sheet already types through. It matters
    // only because the field writes on the way out: a user who taps away mid-decimal has
    // written the whole number, not nothing. Leaving and typing the rest is the fix, and
    // it is one more write on a screen that expects several.
    list.focusOn(Ids.smith)
    list.type(Ids.smith, "185.")
    list.leave()
    check("a trailing separator commits the whole number",
          list.logbook.exercise(Ids.smith)?.workingWeight == lbs("185"))
}

print("\n— the unit a row prints, and stores in —")
do {
    var start = book()
    start.updateExercise(Ids.pulldown) { $0.workingWeight = nil }
    let list = List(start)
    list.freeze()
    check("a pin with no weight is on the list whatever the rack says", list.frozen == [Ids.pulldown])
    check("and the row prints the pin's own unit", list.resolved(Ids.pulldown)?.unit == .lbs)
    list.focusOn(Ids.pulldown)
    list.type(Ids.pulldown, "120")
    list.leave()
    check("so the number is stored in lbs, not in the rack's kg",
          list.logbook.exercise(Ids.pulldown)?.workingWeight == lbs("120"))
}

print("\n— what else the row states (§7.6) —")
do {
    let list = List(book())
    let smith = list.logbook.exercise(Ids.smith)!
    check("a Smith with its Base Weight says nothing", list.missing(smith) == nil)

    list.send(.setPlateInventoryUnit(.lbs))
    let cleared = list.logbook.exercise(Ids.smith)!
    check("the switch takes the Base Weight, and that is the loudest one",
          list.missing(cleared) == "no base weight")

    let pulldown = list.logbook.exercise(Ids.pulldown)!
    check("a Microloading Exercise with no Microplate says so",
          list.missing(pulldown) == "no microplate")
}

print("\n— a brand-new Exercise, which is the second door's whole reason —")
do {
    var start = book()
    let added = ExerciseDraft(
        name: "Cable row", equipment: .cable, ownWeightUnit: .kg,
        plannedSets: 3, repRange: RepRange(10, 12), shownUnit: .kg)
    start = Rules.reduce(
        start, .addExercise(workoutDayId: Ids.upperA, at: 4, draft: added), at: 1_770_000_000)
    check("it has no weight, so it is on the list",
          Rules.reweighList(in: start).count == 1)
    // The banner, not a sheet: the user knows he added it, and a modal at launch would
    // ambush him with a thing he did on purpose.
    check("and the picker states it",
          bannerCopy(start)?.heading == "1 exercise has no weight")
    check("in the singular", bannerCopy(start)?.sub == "It logs no set until you weigh it")

    let switched = Rules.reduce(start, .setPlateInventoryUnit(.lbs), at: 1_770_000_000)
    check("after the switch it counts them all",
          bannerCopy(switched)?.heading == "5 exercises have no weight")
    check("in the plural", bannerCopy(switched)?.sub == "They log no sets until you weigh them")
}

print("\n— and the banner goes by itself —")
do {
    check("a book where every Exercise is weighed shows no banner", bannerCopy(book()) == nil)
}

print(failures == 0 ? "\nall green" : "\n\(failures) FAILED")
// A red check exits 1, so a runner never reads a failure as a pass.
exit(failures == 0 ? 0 : 1)
