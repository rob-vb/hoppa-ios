import SwiftUI
import HoppaRules

// Ticket 0037 — §6.4's weight sheet, and §4.3's question under it.
//
// **The sheet decides nothing about progression.** It is a keypad, a stepper and a
// button; §4.3's *raising sticks, lowering asks* lives on `LoggingScreen`, where the
// Working Weight and the One-off Weight are, and where the two `Action`s already are.
// This view's whole output is one `Weight`.
//
// Three things it does ask a rule for, rather than working out again:
//
// - **What one step is worth.** §6.4 says the `−` / `+` step by *the Increment*, and on a
//   bar under Microloading the Increment is a plate that moves the bar by **twice**
//   itself (§4.2). So the step is not a field: it is what `Rules.progressionMove` moves
//   the Working Weight by, probed at zero — the same trick the Exercise sheet uses for
//   its Increment clause. That also keeps the stepper and the rule chip above it saying
//   the same number, which they must.
// - **Whether the rack can build what is being typed.** `Rules.breakdown` solves it and
//   `ClosestLine` prints §5.4's line — the only thing in Hoppa that deals with the gap.
// - **Nothing about the keypad.** The buffer is a `String` in `@State`
//   ([The view layer around the rules](0024-the-view-layer-around-the-rules.md)), and it
//   becomes a `Weight` exactly once, through `Weight(decimalString:unit:)`. **No `Double`
//   appears anywhere on the way in** ([Persistence and the data
//   model](0019-persistence-and-the-data-model.md)).
//
// Consult `SPEC.md` §4.3, §5.3, §5.4, §6.4 and §8.2.
// Prototype: `design/0007-logging/fitty-workout-logging.html`, the `weight` overlay.

struct WeightSheet: View {
    let exercise: ResolvedExercise
    /// The Exercise as stored. `Rules.progressionMove` takes a `ResolvedExercise` and the
    /// probe below has to build one, which needs the stored fields.
    let stored: Exercise
    let inventory: PlateInventory
    /// What the Exercise is performed at right now — the One-off Weight where there is
    /// one, otherwise the Working Weight. `nil` when it has never been weighed (§2.8),
    /// and that is the one state where the keypad starts empty.
    let current: Weight?
    /// True while a One-off Weight stands. The sheet then names the Working Weight that
    /// survives it, because the big number is **not** that weight (§6.4).
    let oneOffIsStanding: Bool
    let commit: (Weight) -> Void
    let cancel: () -> Void

    /// The keypad buffer. A `String`, because half-typed input is not a weight: `72.` is
    /// a real state of this field and no `Weight` can hold it.
    @State private var buffer: String

    init(
        exercise: ResolvedExercise,
        stored: Exercise,
        inventory: PlateInventory,
        current: Weight?,
        oneOffIsStanding: Bool,
        commit: @escaping (Weight) -> Void,
        cancel: @escaping () -> Void
    ) {
        self.exercise = exercise
        self.stored = stored
        self.inventory = inventory
        self.current = current
        self.oneOffIsStanding = oneOffIsStanding
        self.commit = commit
        self.cancel = cancel
        _buffer = State(initialValue: current?.decimalString ?? "")
    }

    var body: some View {
        ZStack {
            Color.floor.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                header
                hero
                steppers
                if let typed {
                    ClosestLine(
                        breakdown: Rules.breakdown(for: exercise, at: typed, inventory: inventory),
                        performedAt: typed)
                }
                keypad
                PrimaryButton("Set the weight") { if let typed { commit(typed) } }
                    .opacity(typed == nil ? 0.4 : 1)
                    .disabled(typed == nil)
            }
            .padding(.horizontal, 20)   // §7.4 screen padding
            .padding(.top, 22)
            .padding(.bottom, 24)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - The number being typed

    /// The buffer as a `Weight`, or `nil` while it is not one yet. **An unset weight is
    /// not zero** (§2.8) and neither is an empty field, so `0` is refused here rather
    /// than written and refused by the rule.
    private var typed: Weight? {
        guard let weight = Weight(decimalString: buffer, unit: exercise.unit),
              weight.hundredths > 0
        else { return nil }
        return weight
    }

    // MARK: - The header

    private var header: some View {
        HStack {
            Text("Weight")
                .typography(Typography.display(19))
                .foregroundStyle(Color.text)
            Spacer()
            Button(action: cancel) {
                Text("Cancel")
                    .typography(Typography.label(10.5))
                    .foregroundStyle(Color.steel)
                    .frame(height: 50)   // §7.4 hit target
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
        }
        .frame(height: 50)
    }

    // MARK: - The hero, and the One-off chip beside its unit (§6.4)

    private var hero: some View {
        HStack(alignment: .bottom, spacing: 10) {
            Text(buffer.isEmpty ? "0" : buffer)
                .typography(Typography.input(56))
                .foregroundStyle(buffer.isEmpty ? Color.labelText : Color.text)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.unit.rawValue)
                    .typography(Typography.label(15, tracking: 0.14))
                    .foregroundStyle(Color.dimText)
                // A One-off never writes back, so the chip names the Working Weight that
                // survives it — not just the fact of the one-off (§6.4).
                if oneOffIsStanding, let working = exercise.workingWeight {
                    Chip("one-off · \(working.decimalString) \(exercise.unit.rawValue) stays", tone: .steel)
                }
            }
            .padding(.bottom, 6)
            Spacer(minLength: 0)
        }
    }

    // MARK: - The steppers (§6.4)

    /// **A stack grows a second stepper**, because a stack moves in pin steps and not in
    /// Increments (§6.4). Everything else keeps the single `−` / `+`.
    ///
    /// The MICRO row is absent on a **mixed-unit pin**, and §6.4 now says so — this is a
    /// decision, not a gap. There the Microplates are a Microload — a second stored number
    /// in the rack's unit, which the Working Weight can never absorb because units never
    /// convert (§5.1). Stepping it by hand is a different write with a different rule, and
    /// a `−` past zero would be a roll-down that §4.2 does not have. **The pin is the way
    /// down**, and it already asks what §4.3 asks. Ruled out of scope at
    /// [The MICRO stepper on a mixed-unit pin](../../../issues/0042-the-micro-stepper-on-a-mixed-unit-pin.md),
    /// which records the answer should a mixed-unit rack ever arrive.
    @ViewBuilder
    private var steppers: some View {
        if exercise.equipment.hasPin {
            VStack(spacing: 8) {
                if let step = pinStep { stepperRow("Pin", step) }
                if let step = microStep { stepperRow("Micro", step) }
            }
        } else if let step = incrementStep {
            HStack(spacing: 12) {
                stepButton("−") { nudge(step, -1) }
                Text("− / + step by \(step.decimalString) \(step.unit.rawValue)")
                    .typography(Typography.meta(11))
                    .foregroundStyle(Color.dimText)
                    .frame(maxWidth: .infinity)
                stepButton("+") { nudge(step, +1) }
            }
        }
    }

    private func stepperRow(_ label: String, _ step: Weight) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .typography(Typography.label(10, tracking: 0.12))
                .foregroundStyle(Color.labelText)
                .frame(width: 44, alignment: .leading)
            stepButton("−") { nudge(step, -1) }
            Text("\(step.decimalString) \(step.unit.rawValue)")
                .typography(Typography.listValue(13))
                .foregroundStyle(Color.dimText)
                .frame(maxWidth: .infinity)
            stepButton("+") { nudge(step, +1) }
        }
    }

    private func stepButton(_ glyph: String, act: @escaping () -> Void) -> some View {
        Button(action: act) {
            Text(glyph)
                .typography(Typography.body(20))
                .foregroundStyle(Color.text)
                .frame(width: 62, height: 56)   // §6.4's flanking buttons
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.chipBorder, lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
    }

    /// What one `+` is worth on anything that is not a pin: **the move the rule makes**,
    /// probed at zero. Under Progressive Overload that is the Increment exactly; under
    /// Microloading on a bar it is the Microplate doubled, because a bar takes a pair
    /// (§4.2). `nil` where the Exercise has nowhere to move — no Increment, no Microplate
    /// switched on, or a stranded one — and then there is no stepper, only the keypad.
    private var incrementStep: Weight? {
        var probe = stored
        probe.workingWeight = .zero(exercise.unit)
        let resolved = probe.resolved(mode: exercise.mode, inventory: inventory)
        guard let move = Rules.progressionMove(for: resolved, inventory: inventory),
              move.workingWeight.hundredths > 0
        else { return nil }
        return move.workingWeight
    }

    /// The pin steps by the Stack Step (§6.4). It is a fact about the machine, so it does
    /// not depend on the Progression Mode.
    private var pinStep: Weight? {
        guard let step = exercise.stackStep, step.hundredths > 0 else { return nil }
        return step
    }

    /// A pin takes **one** plate, not a pair, so the Microplate and the jump are the same
    /// number here. Only where the two units already agree — see `steppers`.
    private var microStep: Weight? {
        guard !exercise.isMixedUnitPin,
              let plate = exercise.microloadingIncrement, plate.hundredths > 0
        else { return nil }
        return plate.relabelled(exercise.unit)
    }

    /// Steps the buffer, never below zero. The arithmetic is in hundredths, so a `+` on
    /// `72.5` cannot land on `74.99999`.
    private func nudge(_ step: Weight, _ direction: Int) {
        Haptic.stepped()
        let base = Weight(decimalString: buffer, unit: exercise.unit) ?? .zero(exercise.unit)
        let moved = max(0, base.hundredths + direction * step.hundredths)
        buffer = Weight(hundredths: moved, unit: exercise.unit).decimalString
    }

    // MARK: - The keypad

    private var keypad: some View {
        VStack(spacing: 8) {
            ForEach(Array(Self.keys.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { glyph in
                        keyButton(glyph)
                    }
                }
            }
        }
    }

    private static let keys: [[String]] = [
        ["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], [".", "0", "⌫"],
    ]

    private func keyButton(_ glyph: String) -> some View {
        Button { press(glyph) } label: {
            Text(glyph)
                .typography(Typography.listValue(20))
                .foregroundStyle(Color.text)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.card)
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.line, lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
    }

    /// **A keystroke that cannot become a weight never reaches the buffer.** A `Weight` is
    /// hundredths (§2.8), so a third decimal digit is not a number this app can hold —
    /// refusing the key is kinder than accepting it and refusing the save.
    private func press(_ glyph: String) {
        switch glyph {
        case "⌫":
            buffer = String(buffer.dropLast())
        case ".":
            guard !buffer.contains(".") else { return }
            buffer = (buffer.isEmpty ? "0" : buffer) + "."
        default:
            if let dot = buffer.firstIndex(of: "."),
               buffer.distance(from: dot, to: buffer.endIndex) > 2 { return }
            if !buffer.contains("."), buffer.count >= 5 { return }
            buffer = (buffer == "0" ? "" : buffer) + glyph
        }
    }
}
