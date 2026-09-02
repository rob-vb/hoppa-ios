import SwiftUI
import HoppaRules
import HoppaStore

// Ticket 0033 — §5.2's Plate Inventory, which is §6.1 step 2 when a draft arrives with it.
//
// **It is a toggle list for any gym, not a picture of one rack.** The 25 kg ships in the
// list switched off, every Microplate ships off, and there is no 15 kg plate — the Gym
// artboard draws one, and §7.3 says it never existed. `SPEC.md` beats the artboard, so
// this screen also carries the §7.3 colours rather than the artboard's (5 kg white,
// 2.5 kg red, 1.25 kg light grey were the prototype's invention, §8.2 defect 4).
//
// Hoppa holds **one** Plate Inventory, so every edit here writes straight through to the
// Logbook and reaches every Program at once. That is why both of §6.6's warnings live on
// this screen and not on the Program sheet: this is where the switch is.
//
// Artboard: `design/0006-onboarding/Gym.dc.html`.

struct PlateRackScreen: View {
    @Environment(LogbookStore.self) private var store
    @Binding var path: [Route]
    /// §6.1 step 2 when it is there; the rack on its own when it is not.
    let draft: ProgramDraft?

    /// The plate whose switch is about to strand somebody (§6.6). Held rather than
    /// applied, because the count has to be stated **before** the switch.
    @State private var pendingMicroplateOff: Weight?
    /// The unit the user asked for, while the count of cleared weights is on screen.
    @State private var pendingUnit: WeightUnit?

    private var rack: PlateInventory { store.logbook?.plateInventory ?? .standard(.kg) }

    var body: some View {
        ZStack {
            Color.floor.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                // `STEP 2 OF 3` only while onboarding: the same screen reached from
                // Flow 5 is not a step in anything.
                StepHeader(step: draft == nil ? nil : 2, back: goBack)
                Text("Your plate rack")
                    .typography(Typography.display(31, tracking: 0.005))
                    .foregroundStyle(Color.text)
                Spacer().frame(height: 12)
                unitToggle
                Spacer().frame(height: 10)
                Text("This unit applies to every barbell, dumbbell, machine (plates) and bodyweight exercise in the program.")
                    .typography(Typography.body(12, lineSpacing: 3))
                    .foregroundStyle(Color.dimText)
                Spacer().frame(height: 16)
                groups
                Spacer(minLength: 12)
                footer
                Spacer().frame(height: 12)
                PrimaryButton(draft == nil ? "Done" : "This is my rack", action: confirm)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog(
            strandTitle, isPresented: strandIsPresented, titleVisibility: .visible,
            presenting: pendingMicroplateOff
        ) { plate in
            // Not `.destructive`: §6.6 switches nothing off in the data. Stranding is
            // **derived**, so switching the plate back on un-strands exactly what
            // switching it off stranded, and nothing is written and nothing is cleared.
            Button("Switch it off") { store.send(.setPlate(plate, on: false)) }
            Button("Cancel", role: .cancel) {}
        } message: { plate in
            Text(strandMessage(plate))
        }
        .confirmationDialog(
            clearTitle, isPresented: unitIsPresented, titleVisibility: .visible,
            presenting: pendingUnit
        ) { unit in
            // This one **is** destructive: it clears a real Working Weight on every
            // Exercise that reads its unit off the rack (§6.6).
            Button("Switch to \(unit.rawValue.uppercased())", role: .destructive) {
                store.send(.setPlateInventoryUnit(unit))
                // **The confirm leads to the Re-weigh list** (§6.6, ticket 0046). Only
                // this path: `ask` sends the switch straight through when it clears
                // nothing, and a list with no rows is a screen with nothing to say.
                path.append(.reweigh)
            }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("""
                Every barbell, dumbbell, machine (plates) and bodyweight exercise loses its \
                weight, its increment and its base weight, and every microloading \
                increment resets. The next screen asks for the weights again.
                """)
        }
    }

    // MARK: - The unit (§5.2)

    private var unitToggle: some View {
        HStack(spacing: 8) {
            ForEach(WeightUnit.allCases, id: \.self) { unit in
                Button { ask(unit) } label: {
                    Text(unit.rawValue)
                        .typography(Typography.display(19, tracking: 0.04))
                        .foregroundStyle(unit == rack.unit ? Color.floor : Color.dimText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)      // §7.4's hit target; the artboard's 48
                        .background(unit == rack.unit ? Color.text : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(unit == rack.unit ? Color.clear : Color.chipBorder,
                                        lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
            }
        }
    }

    /// The switch asks its question **before** it throws, and it asks it of the rules:
    /// `exercisesClearedByInventoryUnit` is the same rule the Re-weigh list is made of,
    /// asked ahead of the damage instead of after it (§6.6).
    private func ask(_ unit: WeightUnit) {
        guard unit != rack.unit else { return }
        guard let logbook = store.logbook else { return }
        if Rules.exercisesClearedByInventoryUnit(unit, in: logbook).isEmpty {
            store.send(.setPlateInventoryUnit(unit))    // nothing to lose, nothing to ask
        } else {
            pendingUnit = unit
        }
    }

    // MARK: - The two groups

    private var groups: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                groupLabel("Plates you own")
                plateRows(rack.plates, tallest: 26, shortest: 11, width: 8)
                Spacer().frame(height: 16)
                groupLabel("Microplates")
                plateRows(rack.microplates, tallest: 10, shortest: 7, width: 7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func groupLabel(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(text)
                .typography(Typography.label(10.5))
                .foregroundStyle(Color.labelText)
            Spacer().frame(height: 8)
        }
    }

    /// The plates in the order `PlateInventory` stores them: biggest first, which is the
    /// order the artboard draws and the order a rack stands in.
    private func plateRows(
        _ plates: [PlateSize], tallest: CGFloat, shortest: CGFloat, width: CGFloat
    ) -> some View {
        VStack(spacing: 6) {
            ForEach(Array(plates.enumerated()), id: \.element.weight) { index, plate in
                plateRow(
                    plate, width: width,
                    height: PlateChip.height(rank: index, of: plates.count,
                                             tallest: tallest, shortest: shortest))
            }
        }
    }

    private func plateRow(_ plate: PlateSize, width: CGFloat, height: CGFloat) -> some View {
        Button { toggle(plate) } label: {
            HStack(spacing: 14) {
                // A fixed lane, so the chips read as one ramp rather than as a ragged
                // left edge. §7.1's first rule is that size means weight, and a ramp is
                // only legible against a common baseline.
                PlateChip(weight: plate.weight, isOn: plate.isOn, width: width, height: height)
                    .frame(width: 22)
                Text("\(plate.weight.decimalString) \(rack.unit.rawValue)")
                    .typography(Typography.listValue())
                    .foregroundStyle(plate.isOn ? Color.text : Color.labelText)
                Spacer(minLength: 8)
                RackSwitch(isOn: plate.isOn)
            }
            .padding(.horizontal, 14)
            .frame(height: 50)              // §7.4; the artboard's 44 is HTML at 390 px
            .background(plate.isOn ? Color.card : Color.clear)
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.line, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
    }

    /// Switching **on** is free. Switching a Microplate **off** strands every Exercise
    /// using it as its Microloading Increment, so it states the count first (§6.6).
    private func toggle(_ plate: PlateSize) {
        guard plate.isOn else {
            store.send(.setPlate(plate.weight, on: true))
            return
        }
        guard let logbook = store.logbook,
              !Rules.exercisesUsingMicroplate(plate.weight, in: logbook).isEmpty
        else {
            store.send(.setPlate(plate.weight, on: false))
            return
        }
        pendingMicroplateOff = plate.weight
    }

    // MARK: - The footer (§5.2), which states only what is true

    private var footer: some View {
        RackFooter(rack: rack)
    }

    // MARK: - Confirm

    /// §6.1 step 2's confirm is where the Program is finally created — one action
    /// carrying everything step 1 collected — and step 3 replaces the whole path, so
    /// back from the hub goes **home to the picker** and never into onboarding again.
    private func goBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    private func confirm() {
        guard let draft else {
            goBack()
            return
        }
        store.send(.createProgram(
            name: draft.name,
            defaultWeightUnit: draft.defaultWeightUnit(rack: rack.unit),
            mode: draft.mode))
        guard let created = store.logbook?.programs.last?.id else { return }
        path = [.programSheet(created, onboarding: true)]
    }

    // MARK: - The copy of the two warnings

    private var strandIsPresented: Binding<Bool> {
        Binding(get: { pendingMicroplateOff != nil }, set: { if !$0 { pendingMicroplateOff = nil } })
    }

    private var unitIsPresented: Binding<Bool> {
        Binding(get: { pendingUnit != nil }, set: { if !$0 { pendingUnit = nil } })
    }

    private var strandTitle: String {
        let count = strandCount
        return count == 1 ? "1 EXERCISE USES THIS PLATE" : "\(count) EXERCISES USE THIS PLATE"
    }

    private var strandCount: Int {
        guard let plate = pendingMicroplateOff, let logbook = store.logbook else { return 0 }
        return Rules.exercisesUsingMicroplate(plate, in: logbook).count
    }

    private func strandMessage(_ plate: Weight) -> String {
        let one = strandCount == 1
        return """
            \(one ? "It stops" : "They stop") progressing until you pick another plate. \
            Nothing is cleared: switch the \(plate.decimalString) \(rack.unit.rawValue) \
            back on and \(one ? "it progresses" : "they progress") again.
            """
    }

    private var clearTitle: String {
        guard let unit = pendingUnit, let logbook = store.logbook else { return "" }
        let count = Rules.exercisesClearedByInventoryUnit(unit, in: logbook).count
        return count == 1
            ? "THIS CLEARS THE WEIGHT ON 1 EXERCISE"
            : "THIS CLEARS THE WEIGHT ON \(count) EXERCISES"
    }
}

// MARK: - The Microplate group on its own (§5.2)

/// *"Choosing Microloading with no Microplate on opens the Microplate group of the Plate
/// Inventory **as a sheet, in place**. The user switches on what they own and lands back
/// where they were."*
///
/// Step 1's Progression row opens it today; §6.2's `NO MICROPLATES · SET UP YOUR RACK`
/// row opens the same sheet at ticket 0035. Switching a Microplate **on** is the only
/// thing it does, so it carries no warning: only switching one off can strand anybody.
struct MicroplateSheet: View {
    @Environment(LogbookStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var rack: PlateInventory { store.logbook?.plateInventory ?? .standard(.kg) }

    var body: some View {
        ZStack {
            Color.floor.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Text("Microplates")
                    .typography(Typography.display(26))
                    .foregroundStyle(Color.text)
                Spacer().frame(height: 8)
                Text("Microloading needs a microplate you own. Switch on what is in your gym.")
                    .typography(Typography.body(12, lineSpacing: 3))
                    .foregroundStyle(Color.dimText)
                Spacer().frame(height: 16)
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(Array(rack.microplates.enumerated()), id: \.element.weight) { index, plate in
                            Button { store.send(.setPlate(plate.weight, on: !plate.isOn)) } label: {
                                HStack(spacing: 14) {
                                    PlateChip(
                                        weight: plate.weight, isOn: plate.isOn, width: 7,
                                        height: PlateChip.height(
                                            rank: index, of: rack.microplates.count,
                                            tallest: 10, shortest: 7))
                                        .frame(width: 22)
                                    Text("\(plate.weight.decimalString) \(rack.unit.rawValue)")
                                        .typography(Typography.listValue())
                                        .foregroundStyle(plate.isOn ? Color.text : Color.labelText)
                                    Spacer(minLength: 8)
                                    RackSwitch(isOn: plate.isOn)
                                }
                                .padding(.horizontal, 14)
                                .frame(height: 50)
                                .background(plate.isOn ? Color.card : Color.clear)
                                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.line, lineWidth: 1))
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.pressable)
                        }
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                Spacer(minLength: 12)
                RackFooter(rack: rack)
                Spacer().frame(height: 12)
                PrimaryButton("Done") { dismiss() }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 20)
        }
        .presentationBackground(Color.floor)
        .presentationDragIndicator(.visible)
    }
}

// MARK: - The parts both of them draw

/// §5.2's footer. It is Program-level and knows no Exercise's Mode, so it states both —
/// but **only what is true**: the Microloading half appears the moment a Microplate is
/// switched on and not before.
///
/// The number itself is a rule and lives in `HoppaRules`
/// (`PlateInventory.smallestJumpOnTheBar(for:)`), where six tests run it.
struct RackFooter: View {
    let rack: PlateInventory

    var body: some View {
        let normal = rack.smallestJumpOnTheBar(for: .progressiveOverload)
        let micro = rack.enabledMicroplates.isEmpty
            ? nil : rack.smallestJumpOnTheBar(for: .microloading)

        if normal == nil, micro == nil {
            // A rack emptied on purpose. Printing `0 kg` would read as a bar that moves
            // in steps of nothing, which is a different claim from *it does not move*.
            Text("No plate is switched on.")
                .typography(Typography.body(12))
                .foregroundStyle(Color.dimText)
        } else {
            (Text(normal.map(text) ?? "nothing").foregroundStyle(Color.text)
                + microClause(micro))
                .typography(Typography.body(12, lineSpacing: 3))
        }
    }

    private func microClause(_ micro: Weight?) -> Text {
        guard let micro else { return Text("") }
        return Text(" · ").foregroundStyle(Color.dimText)
            + Text(text(micro)).foregroundStyle(Color.text)
            + Text(" with microloading").foregroundStyle(Color.dimText)
    }

    private func text(_ weight: Weight) -> String {
        "\(weight.decimalString) \(weight.unit.rawValue)"
    }
}

/// A plate seen edge-on: a colour chip **sized to the plate** (§5.2).
///
/// §7.1's size law binds the Plate Breakdown — *"Both rules are rules about the Plate
/// Breakdown"* — and a toggle list is not one, so this ramp is **scaled inside its own
/// group** rather than against §7.3's quarter-of-the-smallest. A 0.25 kg microplate drawn
/// at a quarter of an 11 pt chip is under 3 pt of colour, which tells the reader nothing.
/// Within a group the chips still say what §7.1 asks them to: bigger plate, taller chip.
///
/// The ramp is by **rank**, not by weight, so it holds for an lbs rack and for a rack the
/// user has taken plates out of.
struct PlateChip: View {
    let weight: Weight
    let isOn: Bool
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color(plateHex: PlatePalette.hex(for: weight)) ?? Color.steel)
            .frame(width: width, height: height)
            // The artboard's off state. The plate is still in the list and still that
            // colour; it is simply not in this gym.
            .opacity(isOn ? 1 : 0.3)
    }

    /// Rank 0 is the biggest plate in the group and gets `tallest`.
    static func height(rank: Int, of count: Int, tallest: CGFloat, shortest: CGFloat) -> CGFloat {
        guard count > 1 else { return tallest }
        let step = (tallest - shortest) / CGFloat(count - 1)
        return tallest - step * CGFloat(rank)
    }
}

/// The artboard's 44 × 26 pill, drawn rather than a `Toggle`, because switching a plate
/// off has to be able to **ask a question first** (§6.6) and a `Toggle` bound to the
/// store has already switched by the time anyone could ask.
struct RackSwitch: View {
    let isOn: Bool

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            RoundedRectangle(cornerRadius: 13)
                .fill(isOn ? Color.text : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 13)
                        .stroke(isOn ? Color.clear : Color.chipBorder, lineWidth: 1))
            Circle()
                .fill(isOn ? Color.floor : Color.labelText)
                .frame(width: 18, height: 18)
                .padding(.horizontal, 3)
        }
        .frame(width: 44, height: 26)
        .animation(.easeOut(duration: 0.12), value: isOn)
    }
}
