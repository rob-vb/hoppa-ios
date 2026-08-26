import SwiftUI
import HoppaRules
import HoppaStore

// Ticket 0038 — §6.5's Workout Summary. Ticket 0039 lit it.
//
// **The count is the hero because the count is exactly what the confetti scales to**, so
// it was built that way first and the motion was added to a screen that already read.
//
// Ignition (§6.5), which is the whole of ticket 0039 on this file: each Went-up row lands
// 190 ms after the row above it and throws ~15 particles from its own plate chip, the
// sequence runs ~1.4 s, and then the screen is quiet. The physics is `ParticleField`, the
// drawing is `Confetti.swift`, and **which plates fly is `Rules.burstSource(_:)`** — a
// rule, because two lifters with the same `Logbook` must watch the same colours come off
// the same row. What is left here is the order and the timing.
//
// The view holds no arithmetic. `Rules.summary(of:in:)` decides the three sections, the
// added plate and every condition line; this file is the English (§7.6) and the drawing.
// Reference: `design/0009-summary/canvas/` — `Main`, `One`, `Mixed` and `Nothing`.

struct SummaryScreen: View {
    @Environment(LogbookStore.self) private var store
    /// **The one system setting Hoppa does not ignore** (§6.5, §7.2). With it on the rows
    /// still land in sequence and no burst fires.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var path: [Route]
    let workoutId: WorkoutID

    /// How many Went-up rows have landed. A row below this is not drawn yet.
    @State private var landedRows = 0
    /// The particle clock. False before the first burst and false again once the air is
    /// clear, because a `TimelineView` left running redraws an empty canvas forever.
    @State private var burstsAreFlying = false
    @State private var ignition = IgnitionField()

    /// The space a chip rectangle is read in, so the canvas and the chips agree.
    private static let summarySpace = "summary"

    private var rack: PlateInventory { store.logbook?.plateInventory ?? .standard(.kg) }

    private var summary: WorkoutSummary? {
        guard let logbook = store.logbook,
              let workout = logbook.workouts.last(where: { $0.id == workoutId })
        else { return nil }
        return Rules.summary(of: workout, in: logbook)
    }

    var body: some View {
        ZStack {
            Color.floor.ignoresSafeArea()
            content
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        // The canvas is laid over this `ZStack` and matches it exactly, so a chip
        // rectangle read here is the rectangle the burst comes from — no safe-area
        // arithmetic in between, and a particle leaves the screen where the screen ends.
        .coordinateSpace(.named(Self.summarySpace))
        .overlayPreferenceValue(ChipFrames.self) { frames in
            IgnitionCanvas(field: ignition, running: burstsAreFlying)
                .onAppear { ignition.chipFrames = frames }
                .onChange(of: frames) { _, moved in ignition.chipFrames = moved }
        }
        .task { await ignite() }
        .onDisappear {
            burstsAreFlying = false
            ignition.clear()
        }
        // §7.4: nothing is drawn in the safe top inset. **And there is no way back** —
        // §6.5 has no Accept and no Undo, and a chevron to a finished Workout would be a
        // third thing to argue with. `DONE` is the only exit.
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Ignition (§6.5)

    /// The sequence: one row at a time, 190 ms apart, each throwing from its own chip.
    ///
    /// **Zero progressed fires nothing at all** — no sequence, no clock, no canvas — and
    /// there is no `WENT UP` section to land in that case anyway.
    private func ignite() async {
        guard let summary, !summary.wentUp.isEmpty else { return }

        // A chip cannot throw before it has been laid out. This waits for the first
        // layout pass to report the rectangles, which in practice is the first frame;
        // the bound is there so a Summary that never reports cannot hang the sequence.
        var frames = 0
        while ignition.chipFrames.isEmpty, frames < 30 {
            try? await Task.sleep(nanoseconds: 16_000_000)
            frames += 1
        }

        burstsAreFlying = !reduceMotion
        for (index, row) in summary.wentUp.enumerated() {
            if index > 0 {
                try? await Task.sleep(
                    nanoseconds: UInt64(ParticleField.rowInterval * 1_000_000_000))
            }
            // The land: 14 pt up and into view, on the artboard's own curve.
            withAnimation(.timingCurve(0.2, 0.8, 0.3, 1, duration: 0.42)) {
                landedRows = index + 1
            }
            // **Reduce Motion keeps the sequence and drops the particles.** The sequence
            // is what makes the count *a count you watch land*, which is why Ignition won
            // (§6.5); the cloud is the part that causes motion trouble.
            if !reduceMotion {
                ignition.burst(from: row.exerciseId, throwing: slabs(for: row))
            }
        }

        // Then the screen goes quiet, and the clock stops with it. **The cancellation
        // check is not politeness**: a cancelled `Task.sleep` returns at once, and the
        // canvas that empties the field stops rendering when the screen goes, so without
        // it a dismissed Summary spins here forever.
        while burstsAreFlying, !ignition.isQuiet, !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        burstsAreFlying = false
    }

    /// **The burst throws what the Plate Breakdown draws** (§6.5) — one rule, on every
    /// Equipment Type, and `Rules.burstSource(_:)` holds it. This only paints the answer:
    /// §7.3 has colours for the kg rack, and anything else throws steel, which is the
    /// same fallback the chip beside it makes.
    ///
    /// Solved at **the new Working Weight the row already carries** (§4.1) rather than at
    /// whatever the Exercise holds now, so an edit made after Finish cannot repaint a
    /// statement about what happened.
    private func slabs(for row: SummaryWentUp) -> [ConfettiSlab] {
        guard let exercise = store.logbook?.resolvedExercise(row.exerciseId) else {
            // Deleted mid-Workout (§2.7). The row stands, so the row still lands.
            return [.steel]
        }
        let breakdown = Rules.breakdown(for: exercise, at: row.to.weight, inventory: rack)
        return Rules.burstSource(breakdown).map(ConfettiSlab.init)
    }

    @ViewBuilder
    private var content: some View {
        if let summary {
            VStack(alignment: .leading, spacing: 0) {
                header(summary)
                hero(summary)
                sections(summary)
                // The ScrollView above takes the slack, so the bar sits on the bottom
                // edge the way the artboard's `margin-top:auto` puts it.
                statsBar(summary)
                PrimaryButton("Done") { path.removeAll() }
                    .padding(.top, 14)
            }
        } else {
            // The Workout is not in the Logbook: a discard that raced the push, or a file
            // that failed to load. There is nothing to summarise and one way out.
            VStack(alignment: .leading, spacing: 16) {
                Spacer()
                Text("That workout is gone.")
                    .typography(Typography.display(26))
                    .foregroundStyle(Color.text)
                Spacer()
                PrimaryButton("Done") { path.removeAll() }
            }
        }
    }

    // MARK: - The Day, and the label

    private func header(_ summary: WorkoutSummary) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(summary.workoutDayName)
                .typography(Typography.display(13, tracking: 0.1))
                .foregroundStyle(Color.steel)
                .lineLimit(1)
            Spacer(minLength: 8)
            Text("Summary")
                .typography(Typography.label())
                .foregroundStyle(Color.labelText)
        }
    }

    // MARK: - The hero (§6.5)

    /// One Anton numeral in green over `EXERCISES WENT UP`, or §6.5's zero-progressed
    /// screen — which **neither scolds nor consoles**, because it is a fact.
    @ViewBuilder
    private func hero(_ summary: WorkoutSummary) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if summary.count == 0 {
                Text("Nothing went up")
                    .typography(Typography.display(33, tracking: 0.03))
                    .foregroundStyle(Color.text)
                Text(performedLine(summary.performedCount))
                    .typography(Typography.body(12, lineSpacing: 6))
                    .foregroundStyle(Color.dimText)
                    .padding(.top, 6)
            } else {
                Text("\(summary.count)")
                    .typography(Typography.display(96, tracking: -0.01))
                    .foregroundStyle(Color.go)
                Text(summary.count == 1 ? "Exercise went up" : "Exercises went up")
                    .typography(Typography.display(19, tracking: 0.05))
                    .foregroundStyle(Color.text)
                    .padding(.top, 10)
                // The statement of fact that replaces an Accept button (§7.6).
                Text("Hoppa already changed the weight. Next time it is on the bar.")
                    .typography(Typography.body(12, lineSpacing: 6))
                    .foregroundStyle(Color.dimText)
                    .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 18)
        .padding(.bottom, 6)
    }

    /// §6.5's `n Exercises performed. Every Set is logged.` — and the one case it does
    /// not cover: a Workout where everything was skipped has no Set to call logged.
    private func performedLine(_ count: Int) -> String {
        switch count {
        case 0: "No exercises performed."
        case 1: "1 Exercise performed. Every Set is logged."
        default: "\(count) Exercises performed. Every Set is logged."
        }
    }

    // MARK: - The three sections

    private func sections(_ summary: WorkoutSummary) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !summary.wentUp.isEmpty {
                    section("Went up") {
                        VStack(spacing: 0) {
                            ForEach(Array(summary.wentUp.enumerated()), id: \.element.id) {
                                index, row in
                                wentUpRow(row)
                                    // Ignition: a row below the front of the sequence is
                                    // not there yet. The named trade-off, accepted at
                                    // §6.5 — the list is not fully readable until the
                                    // last row lands.
                                    .opacity(index < landedRows ? 1 : 0)
                                    .offset(y: index < landedRows ? 0 : 14)
                            }
                        }
                        .overlay(alignment: .bottom) { hairline(Color.line) }
                    }
                }
                if !summary.stayed.isEmpty {
                    section("Stayed") {
                        VStack(spacing: 0) {
                            ForEach(summary.stayed) { stayedRow($0) }
                        }
                    }
                }
                if !summary.skipped.isEmpty {
                    section("Skipped") {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(summary.skipped) { skippedRow($0) }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .padding(.top, 16)
    }

    private func section<Content: View>(
        _ label: String, @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .typography(Typography.label())
                .foregroundStyle(Color.labelText)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - WENT UP

    /// The plate chip, the name, `72.5 KG → 75 KG` and a small steel `NEXT TIME`.
    ///
    /// The chip is **the plate the progression put on** — `Rules.addedPlate(for:)` —
    /// and the burst comes from exactly this rectangle, which is why it reports its
    /// frame.
    private func wentUpRow(_ row: SummaryWentUp) -> some View {
        HStack(alignment: .top, spacing: 12) {
            PlateChip(plate: row.addedPlate)
                .padding(.top, 3)
                .reportsChipFrame(row.exerciseId, in: Self.summarySpace)
            VStack(alignment: .leading, spacing: 7) {
                Text(row.name)
                    .typography(Typography.display(17, tracking: 0.02))
                    .foregroundStyle(Color.text)
                    .fixedSize(horizontal: false, vertical: true)
                arrow(row)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 11)
        .overlay(alignment: .top) { hairline(Color.line) }
    }

    private func arrow(_ row: SummaryWentUp) -> some View {
        // A wrapping baseline row: a mixed-unit pin prints four numbers and two units,
        // which does not fit one line on a 390 pt phone.
        FlowRow(spacing: 7, lineSpacing: 5) {
            Text(weightText(row.from))
                .typography(Typography.meta(14))
                .foregroundStyle(Color.dimText)
            Text("→")
                .typography(Typography.meta(13))
                .foregroundStyle(Color.labelText)
            Text(weightText(row.to))
                .typography(Typography.display(22, tracking: 0.02))
                .foregroundStyle(Color.go)
            Text("Next time")
                .typography(Typography.label(9))
                .foregroundStyle(Color.steel)
        }
    }

    // MARK: - STAYED

    private func stayedRow(_ row: SummaryStayed) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(row.name)
                .typography(Typography.body(14))
                .foregroundStyle(Color.rowText)
                .fixedSize(horizontal: false, vertical: true)
            if let meta = metaLine(row) {
                Text(meta)
                    .typography(Typography.meta(11.5))
                    .foregroundStyle(Color.labelText)
                    .padding(.top, 3)
            }
            condition(row.condition)
                .padding(.top, 5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 9)
        .overlay(alignment: .top) { hairline(Color.hairline) }
    }

    /// `72.5 KG · 12 · 11 · 10 reps` — **the weight actually lifted** (§6.5), which on a
    /// One-off row is not the Working Weight the condition names.
    private func metaLine(_ row: SummaryStayed) -> String? {
        var parts: [String] = []
        if let performed = row.performed { parts.append(weightText(performed)) }
        if !row.reps.isEmpty {
            parts.append(row.reps.map(String.init).joined(separator: " · ") + " reps")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// **Every stayed Exercise carries its condition, in every state** (§6.5).
    @ViewBuilder
    private func condition(_ condition: SummaryCondition) -> some View {
        switch condition {
        case .oneOff(let stays):
            // §7.6's chip, so it is the same object the logging screen draws.
            if let stays {
                Chip("One-off · \(stays.decimalString) \(stays.unit.rawValue) stays", tone: .steel)
            } else {
                Chip("One-off", tone: .steel)
            }
        case .target(let sets, let reps, let to):
            conditionText("All \(sets) sets at \(reps) → \(weightText(to))")
        case .blocked(let blocker, let sets, let reps):
            // §6.6: the blocking condition stands **in place of the green line**, so the
            // rep condition still reads and only the target is replaced.
            conditionText("All \(sets) sets at \(reps) · \(reason(blocker))")
        case .gone:
            conditionText("Removed from the program")
        }
    }

    private func conditionText(_ text: String) -> some View {
        Text(text)
            .typography(Typography.label(10, tracking: 0.1))
            .foregroundStyle(Color.steel)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// What the user does about it. §5.2's principle: Hoppa states its condition where
    /// the user stands, so each of these names the screen that fixes it.
    private func reason(_ blocker: ProgressionBlocker) -> String {
        switch blocker {
        case .noWorkingWeight: "no weight yet"
        case .noIncrement: "no increment yet"
        case .noMicroplate: "no microplates · set up your rack"
        case .stranded: "microplate switched off · set up your rack"
        case .unitMismatch: "microplate is in the other unit"
        case .noStackStep: "no stack step yet"
        }
    }

    // MARK: - SKIPPED

    /// **Listed plain**: no warning colour, no icon, no invitation to fix (§6.5).
    private func skippedRow(_ row: SummarySkipped) -> some View {
        Text(row.name)
            .typography(Typography.body(14))
            .foregroundStyle(Color.dimText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
    }

    // MARK: - The steel bar

    private func statsBar(_ summary: WorkoutSummary) -> some View {
        HStack(spacing: 0) {
            stat(clock(summary.durationSeconds), "Duration")
            stat("\(summary.setCount)", "Sets")
            // **The one number that converts** (§5.1), to the Program's default unit.
            stat(grouped(summary.volume), "\(summary.volume.unit.rawValue) volume")
        }
        .overlay(alignment: .top) { hairline(Color.line) }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .typography(Typography.display(20, tracking: 0.02))
                .foregroundStyle(Color.text)
            Text(label)
                .typography(Typography.label(9, tracking: 0.13))
                .foregroundStyle(Color.labelText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
    }

    private func clock(_ seconds: Int) -> String {
        let whole = max(0, seconds)
        let hours = whole / 3600
        let minutes = (whole % 3600) / 60
        let rest = whole % 60
        func pad(_ v: Int) -> String { v < 10 ? "0\(v)" : "\(v)" }
        return hours > 0 ? "\(hours):\(pad(minutes)):\(pad(rest))" : "\(minutes):\(pad(rest))"
    }

    /// `7 796`. **Whole units, and a thin space.**
    ///
    /// Volume is the one number that converts (§5.1), so a Workout with an lbs Exercise
    /// in it lands on hundredths — `8022.6 kg`. §6.5 calls volume a rough progress
    /// number and every artboard prints it whole, so the decimal is noise here and the
    /// rounding is the view's: `Rules.totalVolume` keeps the exact weight.
    ///
    /// The group separator is a thin space, not a comma or a full stop — both of those
    /// are a decimal separator somewhere, and the artboards group with a space.
    private func grouped(_ weight: Weight) -> String {
        let rounded = (weight.hundredths + (weight.hundredths < 0 ? -50 : 50)) / 100
        let digits = Array(String(rounded))
        guard digits.count > 3 else { return String(digits) }
        var out: [Character] = []
        for (offset, character) in digits.reversed().enumerated() {
            if offset > 0, offset % 3 == 0 { out.append("\u{2009}") }
            out.append(character)
        }
        return String(out.reversed())
    }

    /// `75 KG`, and `100 LBS + 1 KG` on a mixed-unit pin. **Never a total** (§4.2).
    private func weightText(_ value: SummaryWeight) -> String {
        var text = "\(value.weight.decimalString) \(value.weight.unit.rawValue.uppercased())"
        if let micro = value.microload, !micro.isZero {
            text += " + \(micro.decimalString) \(micro.unit.rawValue.uppercased())"
        }
        return text
    }

    private func hairline(_ colour: Color) -> some View {
        Rectangle().fill(colour).frame(height: 1)
    }
}

// MARK: - The added plate, as a chip

/// The 9 x 34 slab §6.5 puts at the head of a Went-up row, **in the added plate's
/// colour**. §7.3 paints kg only, so an lbs plate — and a pin Increment that is no plate
/// size — falls back to steel, which is what §7.1 rule 2 already does everywhere else.
///
/// It is a plate, so it is filled and rimmed like every other plate the app draws; the
/// steel fallback is hollow, for the reason §6.5 gives the steel particle.
struct PlateChip: View {
    let plate: Weight?

    private var hex: String? { plate.flatMap(PlatePalette.hex(for:)) }

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color(plateHex: hex) ?? .clear)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color(plateRimHex: hex) ?? Color.steel, lineWidth: 1))
            .frame(width: 9, height: 34)
    }
}

// MARK: - A row that wraps

/// `HStack` cannot wrap, and the mixed-unit arrow line is four numbers wide. SwiftUI's
/// own answer is `Layout`, which is exact and costs one small type.
struct FlowRow: Layout {
    var spacing: CGFloat = 7
    var lineSpacing: CGFloat = 5

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let lines = wrap(subviews, in: width)
        let height = lines.reduce(0) { $0 + $1.height } +
            lineSpacing * CGFloat(max(0, lines.count - 1))
        let widest = lines.map(\.width).max() ?? 0
        return CGSize(width: min(widest, width), height: height)
    }

    func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    ) {
        var y = bounds.minY
        for line in wrap(subviews, in: bounds.width) {
            var x = bounds.minX
            for index in line.items {
                let size = subviews[index].sizeThatFits(.unspecified)
                // Baseline-aligned, because a 22 pt Anton number and a 9 pt label sitting
                // on their box tops would not read as one sentence.
                let baseline = line.baseline - (subviews[index]
                    .dimensions(in: .unspecified)[VerticalAlignment.firstTextBaseline])
                subviews[index].place(
                    at: CGPoint(x: x, y: y + baseline),
                    proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += line.height + lineSpacing
        }
    }

    private struct Line {
        var items: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
        var baseline: CGFloat = 0
    }

    private func wrap(_ subviews: Subviews, in width: CGFloat) -> [Line] {
        var lines: [[Int]] = []
        var current: [Int] = []
        var used: CGFloat = 0
        for index in subviews.indices {
            let itemWidth = subviews[index].sizeThatFits(.unspecified).width
            let advance = current.isEmpty ? itemWidth : itemWidth + spacing
            if !current.isEmpty, used + advance > width {
                lines.append(current)
                current = []
                used = 0
            }
            current.append(index)
            used += current.count == 1 ? itemWidth : advance
        }
        if !current.isEmpty { lines.append(current) }

        // The baseline is the deepest of the line, and the line is tall enough for the
        // item that hangs furthest below it — a 22 pt Anton number beside a 9 pt label.
        return lines.map { items in
            var line = Line(items: items)
            for index in items {
                let size = subviews[index].sizeThatFits(.unspecified)
                let baseline = subviews[index]
                    .dimensions(in: .unspecified)[VerticalAlignment.firstTextBaseline]
                line.width += line.width == 0 ? size.width : size.width + spacing
                line.baseline = max(line.baseline, baseline)
            }
            for index in items {
                let size = subviews[index].sizeThatFits(.unspecified)
                let baseline = subviews[index]
                    .dimensions(in: .unspecified)[VerticalAlignment.firstTextBaseline]
                line.height = max(line.height, line.baseline - baseline + size.height)
            }
            return line
        }
    }
}
