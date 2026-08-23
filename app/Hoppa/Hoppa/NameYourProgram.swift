import SwiftUI
import HoppaRules
import HoppaStore

// Ticket 0033 — §6.1 step 1.
//
// A name field, and under it **one card holding the three decisions Hoppa makes at
// Program level**: Weight Unit, Progression Mode, Plate Rack. They are pre-answered and
// visible, each one tap from being changed, and **nothing else is asked at Program
// level**. §6.1 allowed smart defaulting here and only here.
//
// Artboard: `design/0006-onboarding/Main.dc.html`. `SPEC.md` beats it wherever they
// disagree, and it does in two places — the label says Hoppa, not Fitty, and the rack row
// draws the rack the Logbook actually holds rather than a fixed row of five chips.

/// What step 1 collects, carried to step 2 and spent there in one `.createProgram`.
///
/// **The Program is not created until the rack is confirmed.** Creating it here would
/// leave a Program with no Workout Days on the phone the moment the user backs out of
/// step 2 — and the picker shows `programs.first`, so its `CREATE A PROGRAM` button
/// would be gone and there would be no way back in until ticket 0034 lands. The rack
/// edits of step 2 are a different matter and write through at once: the Plate Inventory
/// is Logbook-level, not part of any Program (§5.2).
struct ProgramDraft: Hashable {
    var name: String = ""
    /// §2.1 — the default for **new** Exercises only, and only for the three types that
    /// carry their own unit. It is not the rack's unit; §5.1 keeps those apart.
    var weightUnit: WeightUnit = .kg
    var mode: ProgressionMode = .progressiveOverload
    /// Whether the user has tapped the Weight unit row.
    ///
    /// Until they do, the Program's default **follows the rack**. A lifter who switches
    /// the rack to lbs at step 2 is standing in an lbs gym, and defaulting their first
    /// dumbbell to kg would be Hoppa asking a question it just answered. §6.1 allows
    /// exactly this kind of defaulting at Program level. One deliberate tap ends it.
    var unitChosenByHand: Bool = false

    func defaultWeightUnit(rack: WeightUnit) -> WeightUnit {
        unitChosenByHand ? weightUnit : rack
    }
}

struct NameYourProgram: View {
    @Environment(LogbookStore.self) private var store
    @Binding var path: [Route]

    @State private var draft = ProgramDraft()
    /// Set by a `CONTINUE` on an empty field, cleared by the next keystroke. §5.2's
    /// principle, applied to a button instead of a switch: Hoppa never disables the
    /// control and never hides the reason — it states the condition where the user taps.
    @State private var nameIsMissing = false
    /// §5.2 — choosing Microloading with no Microplate on opens the Microplate group
    /// **as a sheet, in place**. On a fresh install that is every time, because every
    /// Microplate ships off.
    @State private var microplateSheet = false
    @FocusState private var nameFocused: Bool

    private var rack: PlateInventory { store.logbook?.plateInventory ?? .standard(.kg) }

    var body: some View {
        ZStack {
            Color.floor.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                StepHeader(step: 1, back: { if !path.isEmpty { path.removeLast() } })
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Name your\nprogram")
                            .typography(Typography.display(38, tracking: 0.005))
                            .foregroundStyle(Color.text)
                        Spacer().frame(height: 16)
                        nameField
                        Spacer().frame(height: 8)
                        Text(nameIsMissing ? "Give it a name first." : "You can rename it later.")
                            .typography(Typography.body(12, lineSpacing: 4))
                            .foregroundStyle(nameIsMissing ? Color.stop : Color.dimText)
                        Spacer().frame(height: 24)
                        Text("What Hoppa already picked")
                            .typography(Typography.label(10.5))
                            .foregroundStyle(Color.labelText)
                        Spacer().frame(height: 8)
                        assumptions
                        Spacer().frame(height: 16)
                        Text("Hoppa picked these three for you. Tap one only if it is wrong.")
                            .typography(Typography.body(12, lineSpacing: 4))
                            .foregroundStyle(Color.dimText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollBounceBehavior(.basedOnSize)
                Spacer(minLength: 16)
                PrimaryButton("Continue", action: cont)
            }
            .padding(.horizontal, 20)   // §7.4 screen padding
            .padding(.bottom, 20)
        }
        // §7.4 again: **nothing is drawn in the safe top inset**, so the bar is hidden
        // here as it is on the picker, and `StepHeader` draws the way back in content —
        // which is what both onboarding artboards do.
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $microplateSheet) { MicroplateSheet() }
    }

    // MARK: - The name (§2.7 — a label, not an identity)

    private var nameField: some View {
        HStack(spacing: 3) {
            TextField("", text: $draft.name)
                .typography(Typography.input(26))
                .foregroundStyle(Color.text)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($nameFocused)
                .tint(Color.go)     // the artboard's green caret
                .onChange(of: draft.name) { nameIsMissing = false }
                .onSubmit(cont)
        }
        .padding(.horizontal, 16)
        .frame(height: 64)          // §7.4's bottom-control target, and the artboard's
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(nameIsMissing ? Color.stop : Color.text, lineWidth: 1.5))
        .contentShape(Rectangle())
        .onTapGesture { nameFocused = true }
    }

    // MARK: - The three decisions Hoppa makes at Program level

    private var assumptions: some View {
        VStack(spacing: 6) {
            // One tap flips it, because there are two values and a picker for two values
            // is ceremony. §5.2 calls the Mode row "one tap away" in those words.
            assumptionRow("Weight unit", value: draft.defaultWeightUnit(rack: rack.unit).rawValue) {
                draft.weightUnit = draft.defaultWeightUnit(rack: rack.unit) == .kg ? .lbs : .kg
                draft.unitChosenByHand = true
            }
            assumptionRow("Progression", value: draft.mode.screenName) {
                draft.mode = draft.mode == .progressiveOverload ? .microloading : .progressiveOverload
                // §5.2 — Hoppa never blocks the Mode and never disables the option. It
                // opens the Microplate group in place so the user switches on what they
                // own and lands back here.
                if draft.mode == .microloading, rack.enabledMicroplates.isEmpty {
                    microplateSheet = true
                }
            }
            assumptionRow("Plate rack", value: rackName, chips: true) {
                path.append(.plateRack(draft))
            }
        }
    }

    /// **Standard until the user edits it.** The row exists to say *Hoppa already picked
    /// this*, so it has to stop saying it the moment that stops being true. `PlateInventory`
    /// is `Equatable` and `.standard(_:)` is the shipped rack, so the question needs no
    /// stored flag and survives an edit made two screens away.
    private var rackName: String {
        let shape = rack == .standard(rack.unit) ? "Standard" : "Custom"
        return "\(shape) \(rack.unit.rawValue)"
    }

    private func assumptionRow(
        _ label: String, value: String, chips: Bool = false, _ act: @escaping () -> Void
    ) -> some View {
        Button(action: act) {
            HStack(spacing: 12) {
                Text(label)
                    .typography(Typography.label(10.5, tracking: 0.12))
                    .foregroundStyle(Color.dimText)
                Spacer(minLength: 8)
                if chips { rackChips }
                Text(value)
                    .typography(Typography.display(17, tracking: 0.03))
                    .foregroundStyle(Color.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("›")
                    .typography(Typography.body(15))
                    .foregroundStyle(Color.labelText)
            }
            .padding(.horizontal, 14)
            .frame(height: 56)
            .background(Color.card)
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.line, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// The artboard draws five fixed chips. This draws **the rack the Logbook holds** —
    /// the five biggest plates that are switched on, ascending — because the row claims
    /// to describe that rack and a picture that cannot change would start lying at
    /// step 2. Sized by rank inside the row, like every other chip on this screen.
    private var rackChips: some View {
        let shown = Array(rack.enabledPlates.prefix(5)).reversed()
        return HStack(alignment: .bottom, spacing: 3) {
            ForEach(Array(shown.enumerated()), id: \.offset) { index, plate in
                PlateChip(
                    weight: plate, isOn: true, width: 5,
                    height: PlateChip.height(rank: shown.count - 1 - index,
                                             of: shown.count, tallest: 22, shortest: 9))
            }
        }
    }

    // MARK: - Continue

    private func cont() {
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            nameIsMissing = true
            nameFocused = true
            return
        }
        draft.name = name
        nameFocused = false
        path.append(.plateRack(draft))
    }
}

// MARK: - Shared parts of the onboarding steps

/// `‹  STEP n OF 3`, drawn in content because §7.4 leaves the safe top inset empty.
///
/// Step 1's artboard has no back control at all. It gets one anyway: the picker is home
/// (§6.1) and a screen with no drawn way out depends on the swipe-back gesture surviving
/// a hidden navigation bar, which is not a thing this side can test.
struct StepHeader: View {
    /// `nil` on the same screen reached outside onboarding, where there is no step 2 of
    /// anything — the chevron stays, the count goes.
    let label: String?
    let back: () -> Void

    init(step: Int?, back: @escaping () -> Void) {
        self.label = step.map { "Step \($0) of 3" }
        self.back = back
    }

    /// Ticket 0034's Day screen, which draws the Program's Name where onboarding draws
    /// the step count — the same chevron, the same band, a different word.
    init(label: String?, back: @escaping () -> Void) {
        self.label = label
        self.back = back
    }

    var body: some View {
        HStack(spacing: 10) {
            Button(action: back) {
                // Plex, not Anton: `WorkoutDayPicker` draws its `›` in the body face for
                // the same reason — a display face is not guaranteed to carry the glyph.
                Text("‹")
                    .typography(Typography.body(22))
                    .foregroundStyle(Color.steel)
                    .frame(width: 30, height: 50, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if let label {
                Text(label)
                    .typography(Typography.label(11))
                    .foregroundStyle(Color.dimText)
                    .lineLimit(1)
            }
            Spacer()
        }
        .frame(height: 50)
    }
}

/// §7.4's 64 pt bottom control, in the artboard's inverted fill. Lifted out of
/// `WorkoutDayPicker`, which drew the same button first.
struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .typography(Typography.display(20, tracking: 0.06))
                .foregroundStyle(Color.floor)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(Color.text)
                .clipShape(RoundedRectangle(cornerRadius: 3))
        }
        .buttonStyle(.plain)
    }
}
