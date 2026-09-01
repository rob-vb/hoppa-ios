// Ticket 0049 — §6.7's per-Exercise chart, drawn and walked on this machine.
//
// **This screen's real cost is that it needs weeks of Workouts to say anything, and the
// Logbook has none.** What ships is a screen proved against a fixture, not a screen anyone
// has watched fill up. So the whole series was written as a rule, and this is what that
// buys: sixteen weeks of Workouts, run through the shipping rules, printed as a chart a
// person can read — on a VPS, with no phone anywhere near it.
//
// Two things are printed and neither is decoration:
//
// - **The plot**, in text. The line, the green and steel markers, the hollow One-off off
//   the line, the dashed step to the right, the axis ticks and the Set grid under it. If
//   the shape is wrong here it is wrong on the phone, because both read the same
//   `Rules.exerciseChart`.
// - **The ring** — the parts of `ExerciseChartScreen.swift` that are not SwiftUI: the meta
//   line, the chip, the weight text, the `Last sessions` rows and the three figures at the
//   foot. **That ring is a copy and it can rot**; keep it in step by hand when the screen
//   changes, and keep it as small as it is. Same bargain as `app/checks/Past`.
//
// `Rules.exerciseChart` is **not** copied: it is the shipping call, linked from the built
// package, with its own suite in `HoppaRulesTests`. `HarnessSeed.swift` is not copied
// either — it imports no SwiftUI, so the seed the phone gets is the seed drawn here.
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

/// `4 MAY` — `HistoryDate.week`, which is what the `Last sessions` rows and the foot print.
func week(_ timestamp: Timestamp) -> String {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = zone
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "d MMM"
    return formatter.string(from: Date(timeIntervalSince1970: timestamp)).uppercased()
}

func month(_ timestamp: Timestamp) -> String {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = zone
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "MMM"
    return formatter.string(from: Date(timeIntervalSince1970: timestamp)).uppercased()
}

// MARK: - The ring: `ExerciseChartScreen`

/// `75 kg`, and `90 lbs + 2.5 kg` on a mixed-unit pin. **Never a total** (§4.2).
func weightText(_ value: ChartWeight) -> String {
    var text = "\(value.weight.decimalString) \(value.weight.unit.rawValue)"
    if let micro = value.microload, !micro.isZero {
        text += " + \(micro.decimalString) \(micro.unit.rawValue)"
    }
    return text
}

func equipmentName(_ equipment: EquipmentType) -> String {
    switch equipment {
    case .barbell: "Barbell"
    case .smith: "Smith"
    case .plateLoaded: "Plate-loaded"
    case .bodyweight: "Bodyweight"
    case .dumbbell: "Dumbbell"
    case .stack: "Stack"
    case .cable: "Cable"
    }
}

func modeName(_ mode: ProgressionMode) -> String {
    switch mode {
    case .progressiveOverload: "Progressive overload"
    case .microloading: "Microloading"
    case .none: "None"
    }
}

func blockerReason(_ blocker: ProgressionBlocker) -> String {
    switch blocker {
    case .noWorkingWeight: "no weight yet"
    case .noIncrement: "no increment yet"
    case .noMicroplate: "no microplates · set up your rack"
    case .stranded: "microplate switched off · set up your rack"
    case .unitMismatch: "microplate is in the other unit"
    case .noStackStep: "no stack step yet"
    }
}

/// The sentence under a mixed-unit chart. The second half is the open item ticket 0049
/// recorded: the roll-up empties the Microload into the pin (§4.2), so the line falls
/// while the weight on the machine rises.
func mixedUnitNote(_ chart: ExerciseChart) -> String {
    guard chart.totals?.pinMoved == true, let start = chart.points.first?.performed.weight else {
        return "The line is the microload. The pin has not moved, so the pin is not on it."
            + " Nothing here converts."
    }
    return "The line is the microload. The pin has gone from"
        + " \(start.decimalString) \(start.unit.rawValue) to"
        + " \(chart.hero.weight.decimalString) \(chart.hero.weight.unit.rawValue),"
        + " and the line drops back each time the microload rolls onto it."
        + " Nothing here converts."
}

func metaLine(_ chart: ExerciseChart) -> String {
    [
        equipmentName(chart.equipment),
        "\(chart.plannedSets) × \(chart.repRange.bottom)–\(chart.repRange.top)",
        modeName(chart.mode)
    ].joined(separator: " · ")
}

/// **The chip states the rule, never an offer** (§7.6).
func chipText(_ chart: ExerciseChart) -> String? {
    if let target = chart.target {
        return "All \(target.sets) sets at \(target.reps) → \(weightText(target.to))"
    }
    guard let blocker = chart.blocker else { return nil }
    return "All \(chart.plannedSets) sets at \(chart.thresholdReps) · \(blockerReason(blocker))"
}

func gainText(_ gain: Weight) -> String {
    "\(gain.hundredths > 0 ? "+" : "")\(gain.decimalString) \(gain.unit.rawValue)"
}

// MARK: - The plot, in text

/// The chart as `ExerciseChartScreen`'s `Canvas` draws it, on a grid of characters.
///
/// The geometry is the screen's own: `ChartScale.fraction` places every value between the
/// padded floor and ceiling, and the x axis is **real time** — a missed week is a wider
/// gap, and a Skipped Exercise simply has no column.
func plot(_ chart: ExerciseChart, width: Int = 62, height: Int = 13) -> [String] {
    guard chart.hasLine, let scale = chart.scale,
          let first = chart.points.first, let last = chart.points.last
    else { return ["  (no line — an exercise gets one once it has two sessions)"] }

    let span = last.startedAt - first.startedAt
    // The last session sits short of the right edge, so the dashed step has room.
    let usable = chart.next == nil ? width - 1 : width - 5
    func column(_ at: Timestamp) -> Int {
        span > 0 ? Int((Double(usable) * (at - first.startedAt) / span).rounded()) : usable
    }
    func row(_ value: Weight) -> Int {
        let fraction = scale.fraction(of: value)
        return max(0, min(height - 1, Int(((1 - fraction) * Double(height - 1)).rounded())))
    }

    var grid = Array(repeating: Array(repeating: Character(" "), count: width), count: height)

    // The gridlines, so the ticks the screen labels are visible as lines here too.
    var tickRows: [Int: Weight] = [:]
    for tick in scale.ticks {
        let r = row(tick)
        tickRows[r] = tick
        for x in 0..<width where grid[r][x] == " " { grid[r][x] = "·" }
    }

    // The line: steel, and a One-off is never on it.
    for (a, b) in zip(chart.points, chart.points.dropFirst()) {
        let x0 = column(a.startedAt), x1 = column(b.startedAt)
        let y0 = row(a.line), y1 = row(b.line)
        guard x1 > x0 else { continue }
        for x in x0...x1 {
            let t = Double(x - x0) / Double(x1 - x0)
            let y = Int((Double(y0) + t * Double(y1 - y0)).rounded())
            if grid[y][x] == " " || grid[y][x] == "·" { grid[y][x] = "─" }
        }
    }

    // The dashed step, and the hollow marker it ends at.
    if let next = chart.next {
        let x0 = column(last.startedAt), x1 = width - 1
        let y0 = row(last.line), y1 = row(next.to)
        for x in x0...x1 where (x - x0) % 2 == 0 {
            let t = Double(x - x0) / Double(max(1, x1 - x0))
            let y = Int((Double(y0) + t * Double(y1 - y0)).rounded())
            grid[y][x] = next.isProgression ? "+" : "-"
        }
        grid[y1][x1] = "O"
    }

    // The One-off, off the line, with its dotted drop.
    for point in chart.points {
        guard let oneOff = point.oneOff else { continue }
        let x = column(point.startedAt)
        let top = min(row(point.line), row(oneOff)), bottom = max(row(point.line), row(oneOff))
        for y in top...bottom { grid[y][x] = ":" }
        grid[row(oneOff)][x] = "o"
    }

    // The markers last, so nothing is drawn over them.
    for point in chart.points where point.oneOff == nil {
        grid[row(point.line)][column(point.startedAt)] = point.progressed ? "#" : "*"
    }

    var lines = grid.enumerated().map { index, row -> String in
        let label = tickRows[index].map { $0.decimalString } ?? ""
        return label.leftPadded(to: 7) + " │" + String(row)
    }
    if let unit = chart.axisUnit {
        lines.insert("+ \(unit.rawValue.uppercased())".leftPadded(to: 7) + "  ", at: 0)
    }

    // The month strip, then the Set grid: one column per session, one cell per Set.
    var months = Array(repeating: Character(" "), count: width)
    var lastMonth = ""
    for point in chart.points {
        let name = month(point.startedAt)
        guard name != lastMonth else { continue }
        lastMonth = name
        let x = column(point.startedAt)
        for (offset, character) in name.enumerated() where x + offset < width {
            months[x + offset] = character
        }
    }
    lines.append("".leftPadded(to: 7) + " │" + String(months))

    let setRows = chart.points.map(\.setMarks.count).max() ?? 0
    for index in 0..<setRows {
        var cells = Array(repeating: Character(" "), count: width)
        for point in chart.points where index < point.setMarks.count {
            cells[column(point.startedAt)] = point.setMarks[index] ? "■" : "□"
        }
        lines.append((index == 0 ? "SETS" : "").leftPadded(to: 7) + " │" + String(cells))
    }
    return lines
}

extension String {
    func leftPadded(to width: Int) -> String {
        count >= width ? self : String(repeating: " ", count: width - count) + self
    }
}

/// The whole screen, top to bottom, as the ring prints it.
func draw(_ chart: ExerciseChart) {
    print("")
    print("── \(chart.name.uppercased()) " + String(repeating: "─", count: max(0, 56 - chart.name.count)))
    print("   " + metaLine(chart))
    if chart.isMixedUnitPin {
        print("   \(weightText(ChartWeight(weight: chart.hero.weight)))   PIN")
        let micro = chart.hero.microload ?? .zero(.kg)
        print("   + \(micro.decimalString) \(micro.unit.rawValue)   MICROLOAD ON THE PIN")
    } else {
        print("   \(chart.hero.weight.decimalString) \(chart.hero.weight.unit.rawValue)"
              + "   WORKING WEIGHT")
    }
    if let chip = chipText(chart) { print("   [ \(chip.uppercased()) ]") }
    print("")
    for line in plot(chart) { print(line) }
    print("")
    if chart.isMixedUnitPin { print("   " + mixedUnitNote(chart)); print("") }
    if chart.points.isEmpty {
        print("   NOTHING HERE YET")
    } else {
        print("   LAST SESSIONS")
        for point in chart.lastSessions {
            let reps = point.reps.enumerated()
                .map { "\(point.setMarks[$0.offset] ? "*" : " ")\($0.element)" }
                .joined(separator: " ·")
            let oneOff = point.oneOff == nil ? "" : "  [ONE-OFF]"
            print("   \(week(point.startedAt).leftPadded(to: 7))  \(reps)\(oneOff)"
                  + "   \(weightText(point.performed))")
        }
    }
    if let totals = chart.totals {
        let firstLabel = chart.isMixedUnitPin && !totals.pinMoved
            ? "PIN, UNCHANGED" : "ON \(week(totals.firstDate))"
        let firstValue = chart.isMixedUnitPin && !totals.pinMoved
            ? "\(chart.hero.weight.decimalString) \(chart.hero.weight.unit.rawValue)"
            : "\(totals.first.decimalString) \(totals.first.unit.rawValue)"
        print("")
        print("   \(firstValue) \(firstLabel)   |   \(gainText(totals.gain)) "
              + (chart.isMixedUnitPin ? "ON THE PIN" : "SINCE THEN")
              + "   |   \(totals.timesUp) TIMES UP")
    }
}

// MARK: - Sixteen weeks of Rob's own Program

// The seed the phone gets, run here: every Workout goes through `Rules.reduce`, so the
// weights climb, the reps plateau, one week is missed, one Exercise is skipped and one
// Workout is at a One-off Weight.
let book = HarnessSeed.trained(
    HarnessSeed.starterBook, weeks: 16, endingOn: at("2026-08-26 18:00"))

print("=== §6.7's chart, over the seeded sixteen weeks ===")
print("    # went up   * stayed   o one-off (off the line)   : its drop")
print("    + next step (a progression)   - next step (set by hand)   O where it lands")
print("    ■ set met the threshold   □ set did not")

let charted = book.allExercises.map { Rules.exerciseChart($0.id, in: book)! }
for chart in charted { draw(chart) }

print("")
print("=== What the chart must state ===")

check("Every seeded Exercise has a line", charted.allSatisfy(\.hasLine))
check(
    "A skipped session is not a point",
    charted.contains { chart in
        book.workouts.filter { workout in
            workout.exercises.contains { $0.exerciseId == chart.exerciseId }
        }.count > chart.points.count
    })

let oneOffCharts = charted.filter { chart in chart.points.contains { $0.oneOff != nil } }
check("The seed puts a One-off on a chart", oneOffCharts.count == 1)
if let chart = oneOffCharts.first, let index = chart.points.firstIndex(where: { $0.oneOff != nil }) {
    let point = chart.points[index]
    check("The One-off is off the line, under it", point.oneOff! < point.line)
    check("Its Set grid column is empty, whatever the reps", !point.setMarks.contains(true))
    check("It never progressed", !point.progressed)
    check(
        "The line walks straight through it",
        index + 1 < chart.points.count && chart.points[index + 1].line == point.line)
}

for chart in charted {
    check(
        "\(chart.name): the line only ever climbs",
        zip(chart.points, chart.points.dropFirst()).allSatisfy { $1.line >= $0.line })
    check(
        "\(chart.name): every marker is inside the plot",
        chart.scale.map { scale in
            chart.points.allSatisfy { $0.line >= scale.low && $0.line <= scale.high }
                && (chart.next.map { $0.to >= scale.low && $0.to <= scale.high } ?? true)
        } ?? false)
    check(
        "\(chart.name): the foot's gain matches the line",
        chart.totals.map { $0.gain == (chart.next?.to ?? chart.points.last!.line) - $0.first } ?? false)
    check(
        "\(chart.name): three filled cells is the rule",
        chart.points.allSatisfy { $0.progressed == $0.metEverySet })
}

// MARK: - The mixed-unit pin, which Rob's phone cannot reach

// **His rack is kg and his stacks are kg**, so a chart whose two numbers never convert is
// unreachable for him — the same class as the lbs rack and as ticket 0042's MICRO stepper.
// It is built, and it is walked here.

print("")
print("=== The mixed-unit pin (unreachable on Rob's phone — kg rack, kg stacks) ===")

var rack = PlateInventory.standard(.kg)
rack.setPlate(Weight(decimalString: "1", unit: .kg)!, on: true)
var mixed = Logbook(
    nextId: 100,
    plateInventory: rack,
    programs: [
        Program(
            id: ProgramID(1), name: "Upper / Lower",
            defaultWeightUnit: .kg, mode: .progressiveOverload,
            days: [WorkoutDay(id: WorkoutDayID(2), name: "Upper A", exercises: [
                Exercise(
                    id: ExerciseID(10), name: "Lat pulldown", equipment: .stack,
                    ownWeightUnit: .lbs,
                    plannedSets: 3, repRange: RepRange(10, 12),
                    workingWeight: Weight(decimalString: "90", unit: .lbs)!,
                    increment: Weight(decimalString: "10", unit: .lbs)!,
                    microloadingIncrement: Weight(decimalString: "1", unit: .kg)!,
                    modeOverride: .microloading,
                    storedStackStep: Weight(decimalString: "10", unit: .lbs)!,
                    microload: Weight(decimalString: "0", unit: .kg)!)
            ])])
    ])

var clock = at("2026-05-04 18:00")
for session in 0..<15 {
    func send(_ action: Action) {
        clock += 9
        mixed = Rules.reduce(mixed, action, at: clock)
    }
    send(.startWorkout(programId: ProgramID(1), workoutDayId: WorkoutDayID(2)))
    // Every fourth session is short, so the line has a plateau in it.
    let reps = session % 4 == 3 ? 9 : 12
    for _ in 0..<3 { send(.logSet(reps: reps)) }
    send(.finish)
    clock += 7 * 86_400
}

let pulldown = Rules.exerciseChart(ExerciseID(10), in: mixed)!
draw(pulldown)

check("The chart says it plots the Microload", pulldown.axisUnit == .kg)
check("The line is in the rack's unit", pulldown.points.allSatisfy { $0.line.unit == .kg })
check("The pin keeps its own unit", pulldown.hero.weight.unit == .lbs)
check("The two heroes convert nothing", pulldown.hero.microload?.unit == .kg)
check(
    "The Last-sessions row prints the pin and the Microload together",
    pulldown.lastSessions.first.map { weightText($0.performed).contains(" + ") } ?? false)
check("The gain is in the unit that moved", pulldown.totals?.gain.unit == .kg)
// The open item, stated rather than hidden: this fixture's pin **does** move, so the
// Microload line saw-tooths — up on every progression, back to nearly nothing on every
// roll-up. §6.7 chose the Microload as the line for a reference case whose pin never
// moved. The screen says so in words; nothing pretends the line is a climb.
check("The pin moved, so the line is not monotonic", pulldown.totals?.pinMoved == true)
check(
    "And the screen says why the line drops",
    mixedUnitNote(pulldown).contains("drops back"))

// MARK: - The ring: the Exercise card's two doors (ticket 0050)

/// The sparkline as `Sparkline.swift`'s `Canvas` draws it, on a grid of characters.
///
/// **A copy, and it can rot** — the same bargain the plot above takes. What it copies is
/// only the flip and the inset: every point is `ExerciseChart.sparkline`, which is the
/// shipping rule, linked from the built package.
func spark(_ chart: ExerciseChart, width: Int = 22, height: Int = 5) -> [String] {
    let marks = chart.sparkline
    guard !marks.isEmpty else { return Array(repeating: String(repeating: " ", count: width), count: height) }

    var grid = Array(repeating: Array(repeating: Character(" "), count: width), count: height)
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
    // The one filled dot the mark ends on: *here is where you are now*.
    let last = at(marks[marks.count - 1])
    grid[last.y][last.x] = "●"
    return grid.map { String($0) }
}

extension String {
    func rightPadded(to width: Int) -> String {
        count >= width ? self : self + String(repeating: " ", count: width - count)
    }
}

/// One Exercise card as `WorkoutDayScreen` draws it: the Name, the meta line, the Working
/// Weight — and, **only where `hasSpark`**, the sparkline that is the second door.
func card(_ chart: ExerciseChart, _ exercise: ResolvedExercise) -> [String] {
    let inner = 62, markWidth = 22, textWidth = inner - markWidth - 2
    let weight = exercise.workingWeight.map {
        "\($0.decimalString) \(exercise.unit.rawValue)"
    } ?? "—"
    let text = [exercise.name.uppercased(), "", weight, "", ""]
    let mark = chart.hasSpark
        ? spark(chart, width: markWidth, height: text.count)
        : Array(repeating: "", count: text.count)
    let door = chart.hasSpark ? " → chart " : " no door — nothing plotted yet "

    var lines = ["  ┌" + String(repeating: "─", count: inner) + "┐"]
    for (line, marked) in zip(text, mark) {
        lines.append("  │ " + line.rightPadded(to: textWidth)
                     + marked.rightPadded(to: markWidth) + " │")
    }
    lines.append("  └" + String(repeating: "─", count: max(0, inner - door.count))
                 + door + "┘")
    return lines
}

print("")
print("=== The Day screen's cards, and which of them carry a second door ===")
print("    The sparkline **is** the door (ticket 0050): no mark, no way to the chart.")

for exercise in book.allExercises {
    let chart = Rules.exerciseChart(exercise.id, in: book)!
    for line in card(chart, book.resolvedExercise(exercise.id)!) { print(line) }
}

print("")
check(
    "Every trained Exercise carries a door",
    book.allExercises.allSatisfy { Rules.exerciseChart($0.id, in: book)!.hasSpark })
check(
    "The mark plots the chart's own points, one for one",
    book.allExercises.allSatisfy {
        let chart = Rules.exerciseChart($0.id, in: book)!
        return chart.sparkline.count == chart.points.count
    })
check(
    "Nothing on a mark falls outside its box",
    book.allExercises.allSatisfy {
        Rules.exerciseChart($0.id, in: book)!.sparkline.allSatisfy {
            $0.x >= 0 && $0.x <= 1 && $0.y >= 0 && $0.y <= 1
        }
    })

// MARK: - Before there is a line

print("")
print("=== The empty state ===")

let bare = HarnessSeed.starterBook
let cold = Rules.exerciseChart(bare.allExercises[0].id, in: bare)!
check("No Workouts: no points, no line, no totals",
      cold.points.isEmpty && !cold.hasLine && cold.totals == nil)
check("The heroes and the chip stand without a line", chipText(cold) != nil)
for line in plot(cold) { print(line) }

let onceBook = HarnessSeed.trained(bare, weeks: 1, endingOn: at("2026-08-26 18:00"))
let once = Rules.exerciseChart(bare.allExercises[0].id, in: onceBook)!
check("One session is a dot, not a climb", once.points.count == 1 && !once.hasLine)

// Ticket 0050's gate, from both sides. **No sparkline, no door** — and the two gates are
// deliberately not one gate: two sessions make a *line*, one makes a *screen worth
// reaching*, which still states the hero, the chip and the condition for the next step.
check("An Exercise nobody has trained carries no door", !cold.hasSpark)
check("So the card draws no mark at all", cold.sparkline.isEmpty)
for line in card(cold, bare.resolvedExercise(bare.allExercises[0].id)!) { print(line) }
check("One session opens the door, though there is still no line", once.hasSpark && !once.hasLine)
check("And the mark is the one dot", once.sparkline.count == 1 && once.sparkline[0].x == 1)
for line in card(once, onceBook.resolvedExercise(bare.allExercises[0].id)!) { print(line) }

print("")
print(failures == 0 ? "All checks passed." : "\(failures) check(s) FAILED.")
exit(failures == 0 ? 0 : 1)
