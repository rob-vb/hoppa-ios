import SwiftUI
import HoppaRules
import HoppaStore

// Ticket 0049 — §6.7's per-Exercise chart, the last screen in `SPEC.md` and the only one
// that draws a series.
//
// **The view holds no arithmetic.** Every point, every filled cell, the dashed step, the
// gridlines and the three figures at the foot come out of `Rules.exerciseChart(_:in:)`,
// which is a rule and has its own suite. What is left here is arrangement, English and
// dates — a date is a calendar and a zone, which is the same clause that keeps
// `HistoryDate` and `Streak` out of `HoppaRules`.
//
// **No plate colour ever enters a chart** (§7.1). The line, every stayed dot, the One-off
// marker and the Set grid's empty cells are steel; green is the single exception, because
// §7.3 already made green mean progression everywhere in Hoppa.
//
// Four things this screen decided, because §6.7 and the artboards left them open. Each is
// a judgment call under the map's 2026-08-27 rule, and each is on the walk list.
//
// - **No `•••`.** The artboard draws one. §6.7 hangs delete off a *Workout* row and gives
//   this menu nothing at all, and a menu of nothing is a control that does not work. It
//   comes back the moment something belongs in it.
// - **The reps in `Last sessions` are green Set by Set**, not row by row. The artboard
//   colours the whole row when every Set met the threshold. Marking each Set is the same
//   fact the grid column above already draws — and §6.7's own rule is that the two views
//   can never disagree about one Set. On every session the artboard drew, the two render
//   identically; they differ only where some Sets met and others did not, and there the
//   artboard's row would hide it.
// - **`NOTHING HERE YET` covers one session as well as none.** §6.7's empty state says an
//   Exercise gets a line once it has two, so a single dot is not a chart. The screen keeps
//   its heroes and its chip, and says so where the plot would be.
// - **The dashed step is steel where the user set the weight by hand** — see
//   `ChartNextStep.isProgression`, which carries the reasoning.
//
// **Reached from the Progress page since ticket 0058.** The chevron reads `Progress`, the
// room this was opened from, and the Day's Name moved into the meta line ahead of the
// equipment — so two Exercises with one Name still read apart once the chart is open, which
// is the one thing the Progress row could tell you that the chart's title cannot. Ticket
// 0050 had opened this screen from a sparkline on the Exercise card, with the Day in the
// chevron; the screen itself states nothing different.
//
// Artboards: `design/0015-history/Main.dc.html`, `Plateau.dc.html`, `Mixed.dc.html`.

struct ExerciseChartScreen: View {
    @Environment(LogbookStore.self) private var store
    @Binding var path: [Route]
    let exerciseId: ExerciseID

    private var chart: ExerciseChart? {
        store.logbook.flatMap { Rules.exerciseChart(exerciseId, in: $0) }
    }

    var body: some View {
        ZStack {
            Color.floor.ignoresSafeArea()
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)   // §7.4 screen padding
                .padding(.bottom, 20)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private var content: some View {
        if let chart {
            VStack(alignment: .leading, spacing: 0) {
                StepHeader(label: "Progress", back: leave)
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(chart.name)
                            .typography(Typography.display(25, tracking: 0.02))
                            .foregroundStyle(Color.text)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(meta(chart))
                            .typography(Typography.meta())
                            .foregroundStyle(Color.dimText)
                            .padding(.top, 7)
                        heroes(chart)
                        if let chip = chipText(chart) {
                            Chip(chip, tone: .steel)
                                .padding(.top, 18)
                        }
                        plot(chart)
                        lastSessions(chart)
                        totals(chart)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollIndicators(.hidden)
            }
        } else {
            // Deleted from under the screen. The chart is about an Exercise that exists;
            // its Sets survive the delete in §6.7's Workout detail, which is where
            // history lives (§2.8).
            VStack(alignment: .leading, spacing: 16) {
                StepHeader(label: nil, back: leave)
                Spacer()
                Text("That exercise is gone.")
                    .typography(Typography.display(26))
                    .foregroundStyle(Color.text)
                Spacer()
            }
        }
    }

    private func leave() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// The Workout Day this Exercise sits in. Read live off the Program, so a renamed Day
    /// reads its new Name here as it does on the Progress row.
    private var dayName: String? {
        store.logbook?.programs
            .flatMap(\.days)
            .first { $0.exercises.contains { $0.id == exerciseId } }?
            .name
    }

    /// `Upper A · Smith machine · 3 × 8–12 · Progressive overload`. The Day first, because
    /// it is what tells two Exercises with one Name apart (§2.7).
    private func meta(_ chart: ExerciseChart) -> String {
        var parts: [String] = []
        if let dayName { parts.append(dayName) }
        parts += [
            chart.equipment.screenName,
            "\(chart.plannedSets) × \(chart.repRange.bottom)–\(chart.repRange.top)",
            chart.mode.screenName
        ]
        return parts.joined(separator: " · ")
    }

    // MARK: - The heroes

    /// One number, or **two stacked on a mixed-unit pin** — `90 LBS` over `+ 3 KG`, each
    /// with its own label, converting nothing (§5.1).
    @ViewBuilder
    private func heroes(_ chart: ExerciseChart) -> some View {
        if chart.isMixedUnitPin {
            hero(chart.hero.weight, label: "Pin", size: 46, prefix: nil)
                .padding(.top, 16)
            hero(chart.hero.microload ?? .zero(chart.axisUnit ?? .kg),
                 label: "Microload\non the pin", size: 46, prefix: "+ ")
                .padding(.top, 10)
        } else {
            hero(chart.hero.weight, label: "Working\nweight", size: 58, prefix: nil)
                .padding(.top, 14)
        }
    }

    private func hero(_ weight: Weight, label: String, size: CGFloat, prefix: String?) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            Text((prefix ?? "") + weight.decimalString)
                .typography(Typography.display(size, tracking: 0))
                .foregroundStyle(Color.text)
            Text(weight.unit.rawValue)
                .typography(Typography.display(size * 0.36, tracking: 0.02))
                .foregroundStyle(Color.steel)
                .padding(.bottom, size * 0.09)
            Spacer(minLength: 8)
            Text(label)
                .typography(Typography.label(10))
                .foregroundStyle(Color.labelText)
                .multilineTextAlignment(.trailing)
                .padding(.bottom, size * 0.09)
        }
    }

    /// **The chip states the rule, never an offer** (§7.6) — the logging screen's own chip,
    /// restated on a screen the user is not standing at the rack for. Where the plate has
    /// nowhere to go it names the condition instead, from the same function §6.5 names it
    /// with, so the two screens cannot give one stopped plate two reasons.
    private func chipText(_ chart: ExerciseChart) -> String? {
        if let target = chart.target {
            return "All \(target.sets) sets at \(target.reps) → \(weightText(target.to))"
        }
        guard let blocker = chart.blocker else { return nil }
        return "All \(chart.plannedSets) sets at \(chart.thresholdReps) · \(blocker.reason)"
    }

    // MARK: - The plot

    @ViewBuilder
    private func plot(_ chart: ExerciseChart) -> some View {
        if chart.hasLine, let scale = chart.scale {
            ChartPlot(chart: chart, scale: scale)
                .frame(height: ChartPlot.height)
                .padding(.top, 18)
            legend(chart)
                .padding(.top, 14)
            if chart.isMixedUnitPin {
                Text(mixedUnitNote(chart))
                    .typography(Typography.body(12, lineSpacing: 4))
                    .foregroundStyle(Color.dimText)
                    .padding(.top, 12)
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("Nothing here yet")
                    .typography(Typography.display(20))
                    .foregroundStyle(Color.text)
                Text(chart.points.isEmpty
                     ? "This exercise gets a line once you have trained it twice."
                     : "One session is a dot, not a climb. Train it once more.")
                    .typography(Typography.body(13, lineSpacing: 4))
                    .foregroundStyle(Color.dimText)
            }
            .padding(.top, 28)
        }
    }

    /// §6.7's own sentence about the reference case, written from the chart in front of
    /// the user rather than from the artboard's fifteen weeks.
    ///
    /// **The second sentence is the one that earns its place.** §6.7 chose the Microload
    /// as the line because its reference case is a pin that has not moved in fifteen
    /// weeks. When the pin *does* move, the roll-up empties the Microload into it (§4.2)
    /// and the line falls — while the weight on the machine went up. That is the shape
    /// §6.7 refused volume for, and it is unreachable on Rob's phone (his rack is kg and
    /// his stacks are kg), so nothing here fixes it: the line states what it plots, and
    /// the sentence states why it drops. Recorded on ticket 0049 as an open item for
    /// §6.7 rather than solved behind the user's back.
    private func mixedUnitNote(_ chart: ExerciseChart) -> String {
        guard chart.totals?.pinMoved == true, let start = chart.points.first?.performed.weight else {
            return "The line is the microload. The pin has not moved, so the pin is not on"
                + " it. Nothing here converts."
        }
        return "The line is the microload. The pin has gone from"
            + " \(start.decimalString) \(start.unit.rawValue) to"
            + " \(chart.hero.weight.decimalString) \(chart.hero.weight.unit.rawValue),"
            + " and the line drops back each time the microload rolls onto it."
            + " Nothing here converts."
    }

    private func legend(_ chart: ExerciseChart) -> some View {
        HStack(spacing: 16) {
            legendItem("Went up") { Circle().fill(Color.go).frame(width: 8, height: 8) }
            legendItem("Stayed") { Circle().fill(Color.steel).frame(width: 6.4, height: 6.4) }
            if chart.points.contains(where: { $0.oneOff != nil }) {
                legendItem("One-off") {
                    Circle().stroke(Color.steel, lineWidth: 1.6).frame(width: 8, height: 8)
                }
            }
            legendItem("Set at \(chart.thresholdReps)") {
                RoundedRectangle(cornerRadius: 1.5).fill(Color.go).frame(width: 7, height: 7)
            }
            Spacer(minLength: 0)
        }
    }

    private func legendItem<Mark: View>(
        _ text: String, @ViewBuilder mark: () -> Mark
    ) -> some View {
        HStack(spacing: 6) {
            mark()
            Text(text)
                .typography(Typography.label(9, tracking: 0.12))
                .foregroundStyle(Color.dimText)
                .lineLimit(1)
        }
    }

    // MARK: - Last sessions

    /// The grid abstracts the reps to met / not met. **This carries the exact numbers**,
    /// so nothing on the screen lives only in a picture (§6.7).
    @ViewBuilder
    private func lastSessions(_ chart: ExerciseChart) -> some View {
        if !chart.points.isEmpty {
            Text("Last sessions")
                .typography(Typography.label())
                .foregroundStyle(Color.labelText)
                .padding(.top, 24)
            ForEach(chart.lastSessions) { point in
                HStack(spacing: 0) {
                    Text(HistoryDate.week(point.startedAt))
                        .typography(Typography.label(10, tracking: 0.1))
                        .foregroundStyle(Color.steel)
                        .frame(width: 58, alignment: .leading)
                    repsLine(point)
                    Spacer(minLength: 8)
                    if point.oneOff != nil {
                        Chip("One-off", tone: .steel)
                            .padding(.trailing, 8)
                    }
                    Text(weightText(point.performed))
                        .typography(Typography.meta(13))
                        .foregroundStyle(Color.rowText)
                        .lineLimit(1)
                }
                .frame(height: 40)
            }
        }
    }

    /// `12 · 12 · 12`, **green Set by Set** — the same fact the grid column above fills a
    /// cell with, and the same fact §6.7's Workout detail turns a rep count green.
    private func repsLine(_ point: ChartPoint) -> some View {
        HStack(spacing: 5) {
            ForEach(Array(point.reps.enumerated()), id: \.offset) { index, reps in
                if index > 0 {
                    Text("·")
                        .typography(Typography.meta(13))
                        .foregroundStyle(Color.labelText)
                }
                Text("\(reps)")
                    .typography(Typography.listValue(15))
                    .foregroundStyle(point.setMarks[index] ? Color.go : Color.rowText)
            }
        }
    }

    // MARK: - The three figures the screen ends on

    @ViewBuilder
    private func totals(_ chart: ExerciseChart) -> some View {
        if let totals = chart.totals {
            Rectangle()
                .fill(Color.line)
                .frame(height: 1)
                .padding(.top, 26)
            HStack(alignment: .top, spacing: 0) {
                figure(
                    firstValue(chart, totals),
                    label: chart.isMixedUnitPin && !totals.pinMoved
                        ? "Pin, unchanged"
                        : "On \(HistoryDate.week(totals.firstDate))",
                    tone: Color.text)
                figure(
                    gainText(totals.gain),
                    label: chart.isMixedUnitPin ? "On the pin" : "Since then",
                    // Green is progression everywhere (§7.3). A weight the user lowered by
                    // hand is not one, and it must not read as one.
                    tone: totals.gain.hundredths > 0 ? Color.go : Color.text)
                figure("\(totals.timesUp)", label: "Times up", tone: Color.text)
            }
            .padding(.top, 18)
        }
    }

    /// The mixed-unit foot states **the pin** where the pin is the unmoved half, because
    /// `+ 0 kg on 4 May` says nothing a reader wants. Everywhere else it is the first
    /// plotted value with the day it was lifted.
    private func firstValue(_ chart: ExerciseChart, _ totals: ChartTotals) -> String {
        if chart.isMixedUnitPin && !totals.pinMoved {
            return "\(chart.hero.weight.decimalString) \(chart.hero.weight.unit.rawValue)"
        }
        return "\(totals.first.decimalString) \(totals.first.unit.rawValue)"
    }

    private func gainText(_ gain: Weight) -> String {
        let sign = gain.hundredths > 0 ? "+" : ""
        return "\(sign)\(gain.decimalString) \(gain.unit.rawValue)"
    }

    private func figure(_ value: String, label: String, tone: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .typography(Typography.display(19, tracking: 0.02))
                .foregroundStyle(tone)
            Text(label)
                .typography(Typography.label(9, tracking: 0.12))
                .foregroundStyle(Color.labelText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// `75 kg`, and `100 lbs + 1 kg` on a mixed-unit pin. **Never a total** (§4.2) — the
    /// same text `PastWorkoutScreen` writes, for the same reason.
    private func weightText(_ value: ChartWeight) -> String {
        var text = "\(value.weight.decimalString) \(value.weight.unit.rawValue)"
        if let micro = value.microload, !micro.isZero {
            text += " + \(micro.decimalString) \(micro.unit.rawValue)"
        }
        return text
    }
}

// MARK: - The drawing

/// The line, the markers, the Set grid and the dashed step.
///
/// A `Canvas` and not a stack of `Shape`s, which is the opposite of what `PlateDrawing`
/// chose — and for the reason that file gives. A loaded bar *is* a row of rounded
/// rectangles, so shapes keep collar, sleeve and plate apart in the type system. A chart
/// is one path and a scatter of marks over a shared geometry: in a stack of shapes every
/// one of them would recompute the same `x(of:)` and `y(of:)`, and the day two of them
/// disagreed the line would leave its own dots behind.
private struct ChartPlot: View {
    let chart: ExerciseChart
    let scale: ChartScale

    /// The plot, the month strip and the Set grid, stacked. Fixed, because §7.4 fixes its
    /// sizes in points and the app pins Dynamic Type at the root.
    static let height: CGFloat = 220
    private static let plotHeight: CGFloat = 164
    private static let padLeft: CGFloat = 36
    private static let padRight: CGFloat = 34
    private static let padTop: CGFloat = 14
    private static let months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN",
                                 "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]

    var body: some View {
        Canvas { context, size in
            let geometry = Geometry(size: size, chart: chart, scale: scale)
            gridlines(&context, geometry)
            line(&context, geometry)
            nextStep(&context, geometry)
            oneOffs(&context, geometry)
            markers(&context, geometry)
            months(&context, geometry)
            setGrid(&context, geometry)
        }
    }

    /// Where every value lands. One copy, shared by every mark on the chart.
    private struct Geometry {
        let size: CGSize
        let chart: ExerciseChart
        let scale: ChartScale
        /// The last session sits short of the right edge, so the dashed step has room.
        let usableWidth: CGFloat

        init(size: CGSize, chart: ExerciseChart, scale: ChartScale) {
            self.size = size
            self.chart = chart
            self.scale = scale
            let inner = size.width - ChartPlot.padLeft - ChartPlot.padRight
            usableWidth = chart.next == nil ? inner : inner - 26
        }

        var first: Timestamp { chart.points.first?.startedAt ?? 0 }
        var last: Timestamp { chart.points.last?.startedAt ?? 1 }

        /// **Real time, not the session number** (§6.7): a missed week is a wider gap and
        /// needs no marker of its own.
        func x(_ at: Timestamp) -> CGFloat {
            let span = last - first
            guard span > 0 else { return ChartPlot.padLeft + usableWidth }
            return ChartPlot.padLeft + CGFloat((at - first) / span) * usableWidth
        }

        var rightEdge: CGFloat { size.width - ChartPlot.padRight }

        func y(_ weight: Weight) -> CGFloat {
            let inner = ChartPlot.plotHeight - ChartPlot.padTop - 22
            return ChartPlot.padTop + inner * (1 - CGFloat(scale.fraction(of: weight)))
        }
    }

    // MARK: - The parts

    private func gridlines(_ context: inout GraphicsContext, _ g: Geometry) {
        for tick in scale.ticks {
            let y = g.y(tick)
            var path = Path()
            path.move(to: CGPoint(x: Self.padLeft, y: y))
            path.addLine(to: CGPoint(x: g.rightEdge, y: y))
            context.stroke(path, with: .color(Color.line), lineWidth: 1)
            draw(&context, "\(tick.decimalString)", at: CGPoint(x: Self.padLeft - 8, y: y),
                 size: 9.5, tracking: 0.4, colour: Color.labelText, anchor: .trailing)
        }
        // `+ KG` — a mixed-unit pin plots the Microload, and the axis says which number
        // moved (§6.7). Nothing else needs a label: the line is the Working Weight and
        // the heroes above it carry the unit.
        if let unit = chart.axisUnit {
            draw(&context, "+ \(unit.rawValue.uppercased())",
                 at: CGPoint(x: Self.padLeft - 8, y: Self.padTop - 6),
                 size: 8.5, tracking: 0.85, colour: Color.labelText, anchor: .trailing)
        }
    }

    /// **2 px steel, and the One-off is never on it** — a One-off never became the
    /// Working Weight, so the line does not dip through one (§4.3).
    private func line(_ context: inout GraphicsContext, _ g: Geometry) {
        var path = Path()
        for (index, point) in chart.points.enumerated() {
            let at = CGPoint(x: g.x(point.startedAt), y: g.y(point.line))
            if index == 0 { path.move(to: at) } else { path.addLine(to: at) }
        }
        context.stroke(
            path, with: .color(Color.steel),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
    }

    /// **Solid is lifted; dashed is applied but not yet performed.** Green where Hoppa
    /// moved the weight at Finish, steel where the user set it by hand (§4.3).
    private func nextStep(_ context: inout GraphicsContext, _ g: Geometry) {
        guard let next = chart.next, let last = chart.points.last else { return }
        let colour = next.isProgression ? Color.go : Color.steel
        let from = CGPoint(x: g.x(last.startedAt), y: g.y(last.line))
        let to = CGPoint(x: g.rightEdge, y: g.y(next.to))

        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        context.stroke(
            path, with: .color(colour),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [3, 3]))

        // A hollow marker: applied, not yet lifted. The floor disc under it keeps the
        // ring legible where it lands on a gridline.
        context.fill(disc(to, radius: 6), with: .color(Color.floor))
        context.fill(disc(to, radius: 4), with: .color(Color.floor))
        context.stroke(disc(to, radius: 4), with: .color(colour), lineWidth: 1.8)
        draw(&context, next.isProgression ? "NEXT" : "NOW",
             at: CGPoint(x: to.x, y: to.y - 12),
             size: 8.5, tracking: 1.1, colour: colour, anchor: .trailing)
    }

    /// **Off the line, hollow, tied to its session by a dotted drop.** Hollow says Hoppa
    /// logged this and it never became the Working Weight; the line above it is still the
    /// truth (§4.3).
    private func oneOffs(_ context: inout GraphicsContext, _ g: Geometry) {
        for point in chart.points {
            guard let oneOff = point.oneOff else { continue }
            let x = g.x(point.startedAt)
            let onLine = g.y(point.line)
            let lifted = g.y(oneOff)

            var drop = Path()
            drop.move(to: CGPoint(x: x, y: onLine))
            drop.addLine(to: CGPoint(x: x, y: lifted))
            context.stroke(
                drop, with: .color(Color.chipBorder),
                style: StrokeStyle(lineWidth: 1, dash: [2, 3]))

            let at = CGPoint(x: x, y: lifted)
            context.fill(disc(at, radius: 4), with: .color(Color.floor))
            context.stroke(disc(at, radius: 4), with: .color(Color.steel), lineWidth: 1.6)
            draw(&context, "ONE-OFF", at: CGPoint(x: x + 9, y: lifted),
                 size: 8.5, tracking: 1.1, colour: Color.steel, anchor: .leading)
        }
    }

    /// Green where it went up, steel where it stayed. **A Skipped Exercise has no marker
    /// at all**, and the rule already left it out of `points`.
    private func markers(_ context: inout GraphicsContext, _ g: Geometry) {
        for point in chart.points {
            let at = CGPoint(x: g.x(point.startedAt), y: g.y(point.line))
            let radius: CGFloat = point.progressed ? 4 : 3.2
            context.fill(disc(at, radius: radius + 2), with: .color(Color.floor))
            context.fill(
                disc(at, radius: radius),
                with: .color(point.progressed ? Color.go : Color.steel))
        }
    }

    private func months(_ context: inout GraphicsContext, _ g: Geometry) {
        var last = -1
        for point in chart.points {
            let month = Calendar.current.component(
                .month, from: Date(timeIntervalSince1970: point.startedAt)) - 1
            guard month != last, Self.months.indices.contains(month) else { continue }
            last = month
            draw(&context, Self.months[month],
                 at: CGPoint(x: g.x(point.startedAt), y: Self.plotHeight - 4),
                 size: 9, tracking: 1.17, colour: Color.labelText, anchor: .center)
        }
    }

    /// **One column per session, one cell per Set, filled where that Set met the threshold
    /// of its Progression Mode.** Three filled cells *is* §4.1, so the grid answers *why
    /// did it not go up* with no words and no advice — and a One-off's column is never
    /// filled, whatever the reps.
    private func setGrid(_ context: inout GraphicsContext, _ g: Geometry) {
        let top = Self.plotHeight + 6
        let cell: CGFloat = 7
        let gap: CGFloat = 2.5
        for point in chart.points {
            let x = g.x(point.startedAt)
            for (index, met) in point.setMarks.enumerated() {
                let y = top + CGFloat(index) * (cell + gap)
                let box = CGRect(x: x - cell / 2, y: y, width: cell, height: cell)
                let shape = Path(roundedRect: box, cornerRadius: 1.5)
                if met {
                    context.fill(shape, with: .color(Color.go))
                } else {
                    context.stroke(
                        Path(roundedRect: box.insetBy(dx: 0.5, dy: 0.5), cornerRadius: 1.5),
                        with: .color(Color.chipBorder), lineWidth: 1)
                }
            }
        }
        draw(&context, "SETS", at: CGPoint(x: Self.padLeft - 8, y: top + 8),
             size: 8.5, tracking: 0.85, colour: Color.labelText, anchor: .trailing)
    }

    // MARK: - The two primitives

    private func disc(_ centre: CGPoint, radius: CGFloat) -> Path {
        Path(ellipseIn: CGRect(
            x: centre.x - radius, y: centre.y - radius,
            width: radius * 2, height: radius * 2))
    }

    /// Every label on the chart, in Plex at a fixed size — the face and the pinned size
    /// `Typography` guarantees everywhere else, stated here because a `Canvas` resolves a
    /// `Text` and cannot wear a `ViewModifier`.
    private func draw(
        _ context: inout GraphicsContext,
        _ text: String,
        at point: CGPoint,
        size: CGFloat,
        tracking: CGFloat,
        colour: Color,
        anchor: HorizontalAlignment
    ) {
        let resolved = context.resolve(
            Text(text)
                .font(.custom(BundledFonts.bodyMedium, fixedSize: size))
                .tracking(tracking)
                .foregroundColor(colour))
        let anchorPoint: UnitPoint
        switch anchor {
        case .leading: anchorPoint = .leading
        case .trailing: anchorPoint = .trailing
        default: anchorPoint = .center
        }
        context.draw(resolved, at: point, anchor: anchorPoint)
    }
}
