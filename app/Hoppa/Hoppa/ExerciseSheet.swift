import SwiftUI
import HoppaRules
import HoppaStore

// Ticket 0035 — §6.2's full sheet, and §6.3's name field.
//
// **Model B**: every field on one sheet, picked by hand, saved in one act. It is the
// largest screen in Flow 1 and Flow 5 reuses it whole, which is why add and edit are the
// same file and not two.
//
// Three things this sheet does **not** decide, because rules already do:
//
// - **The clearing rule.** A change of Equipment Type across the rack boundary is a
//   change of unit (§6.6), and `Rules.edited` drops the Working Weight, the Increment and
//   the Stack Step when the draft was typed in a unit the Exercise no longer resolves to
//   (ticket 0041). The sheet takes the same three off the screen the moment the unit on
//   screen changes, so the user is never typing under a label that has moved under him —
//   it agrees with the rule rather than working around it. **The sheet keeps them**
//   (ticket 0043): they go into a per-unit stash and come back if the unit does, because
//   closing an edit sheet is the save and a mis-tap must not be the last word.
// - **What a Microloading Increment moves.** `Rules.progressionMove` owns the doubling on
//   a bar and the roll-up on a pin; the row below reads the move out of it rather than
//   multiplying by two itself, exactly as ticket 0034's Exercise card does.
// - **The suggestions.** `Rules.nameSuggestions(in:query:)` is built and tested (§6.3);
//   this draws six rows of it and re-decides nothing.
//
// Artboards: `design/0006-onboarding/AddExercise.dc.html` (add) and `Exercise.dc.html`
// (edit). `SPEC.md` beats them where they disagree.

struct ExerciseSheet: View {
    @Environment(LogbookStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let target: ExerciseSheetTarget

    /// Whether the Sets and the Rep Range arrived from the Exercise before this one
    /// (§6.2). Only the add life carries anything over, so only it draws `CARRIED OVER`.
    /// The Day screen decides it, because it is the one that knows what is behind.
    private let carriedOver: Bool

    @State private var draft: ExerciseDraft
    /// **The Equipment Type starts empty on an add** (§6.2). `ExerciseDraft` cannot hold
    /// *unpicked* — it is the value a rule consumes, and a rule is never handed a half
    /// Exercise — so the sheet keeps the question in view state and refuses to save until
    /// it is answered.
    @State private var equipmentChosen: Bool

    // The typed fields, held as text and parsed on every keystroke. A `Weight` cannot
    // hold `72.` and the user has to be able to type it, so the text is the truth while
    // the sheet is open and the draft carries what parses.
    @State private var workingText = ""
    @State private var incrementText = ""
    @State private var baseText = ""
    @State private var stackText = ""
    @State private var bottomText = ""
    @State private var topText = ""
    /// The artboard's `…` chip, which swaps the Increment offers for a field.
    @State private var incrementTyped = false

    @State private var nameIsMissing = false
    @State private var equipmentIsMissing = false
    /// **The sheet's memory of the numbers a unit change took off the screen** (ticket
    /// 0043). It is a plain value in `UnitStash.swift`, which imports no SwiftUI, so the
    /// whole of it is provable off the Mac.
    @State private var stash = UnitStash()

    @State private var progressionDialog = false
    @State private var removeDialog = false
    @State private var discardDialog = false
    @State private var microplateSheet = false

    @FocusState private var focus: Field?

    private enum Field: Hashable { case name, working, increment, base, stack, bottom, top }

    init(target: ExerciseSheetTarget, initial: ExerciseDraft, carriedOver: Bool) {
        self.target = target
        self.carriedOver = carriedOver
        _draft = State(initialValue: initial)
        // An edit opens on an Exercise that already has one; an add asks for it.
        _equipmentChosen = State(initialValue: target.exercise != nil)
        _workingText = State(initialValue: initial.workingWeight?.decimalString ?? "")
        _incrementText = State(initialValue: initial.increment?.decimalString ?? "")
        _baseText = State(initialValue: initial.baseWeight?.decimalString ?? "")
        _stackText = State(initialValue: initial.stackStep?.decimalString ?? "")
        _bottomText = State(initialValue: "\(initial.repRange.bottom)")
        _topText = State(initialValue: "\(initial.repRange.top)")
    }

    // MARK: - What the sheet is looking at

    private var isAdd: Bool { target.exercise == nil }
    private var rack: PlateInventory { store.logbook?.plateInventory ?? .standard(.kg) }
    private var program: Program? { store.logbook?.workoutDay(target.day)?.program }
    private var dayName: String { store.logbook?.workoutDay(target.day)?.day.name ?? "" }

    /// The Exercise's own Mode: its override, or the Program's (§2.3, §4.4).
    private var mode: ProgressionMode {
        draft.modeOverride ?? program?.mode ?? .progressiveOverload
    }

    /// **The unit the Exercise resolves to** (§5.1) — the rack's for the four types loaded
    /// off it, its own for the other three. Before an Equipment Type is picked there is
    /// nothing to resolve, so the sheet shows the Program's default, which is what §2.1
    /// keeps that default for.
    private var unit: WeightUnit {
        guard equipmentChosen else { return draft.ownWeightUnit }
        return draft.equipment.takesUnitFromInventory ? rack.unit : draft.ownWeightUnit
    }

    /// True where §2.3 locks the Weight Unit row: you cannot load a plate you do not own.
    private var unitIsLocked: Bool {
        equipmentChosen && draft.equipment.takesUnitFromInventory
    }

    /// §2.6's one refused combination: Microloading on a Dumbbell in the other unit. No
    /// pin to hang a plate on, and no Stack Step to roll it into.
    private var microloadingIsRefused: Bool {
        equipmentChosen && draft.equipment == .dumbbell
            && mode == .microloading && unit != rack.unit
    }

    /// The number in the header. An edit reads the Exercise's own place in the Day; an
    /// add counts the position it will land at.
    private var position: Int {
        if let id = target.exercise,
           let day = store.logbook?.workoutDay(target.day)?.day,
           let index = day.exercises.firstIndex(where: { $0.id == id }) {
            return index + 1
        }
        return target.at + 1
    }

    var body: some View {
        ZStack {
            Color.floor.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        nameBlock
                        Spacer().frame(height: 16)
                        Text("Equipment type")
                            .typography(Typography.label(10.5))
                            .foregroundStyle(equipmentIsMissing ? Color.stop : Color.labelText)
                        Spacer().frame(height: 8)
                        EquipmentChips(chosen: equipmentChosen ? draft.equipment : nil, pick: pick)
                        Spacer().frame(height: 16)
                        fields
                        Spacer().frame(height: 12)
                        notes
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    // A tap beside a field puts the keyboard away. It has to sit *inside*
                    // the ScrollView: the scroll view hit-tests its own bounds, so a tap
                    // here never reaches the floor behind it. Buttons and fields are
                    // children, and a child wins the tap.
                    .contentShape(Rectangle())
                    .onTapGesture { focus = nil }
                }
                .scrollBounceBehavior(.basedOnSize)
                // And a drag down does it too, which is the gesture a number pad teaches.
                .scrollDismissesKeyboard(.interactively)
                Spacer(minLength: 12)
                bottomControl
            }
            .padding(.horizontal, 20)   // §7.4 screen padding
            .padding(.top, 20)
            .padding(.bottom, 20)
        }
        .presentationBackground(Color.floor)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        // The two lives leave differently — see `close()` — and neither reading survives
        // a swipe: a drag would save an edit the user was still looking at, or throw an
        // add away without asking. One visible way out, and it is the `✕`.
        .interactiveDismissDisabled()
        .toolbar {
            // A number pad has no return key, and six of this sheet's fields are number
            // pads. Without this the keyboard covers the sheet until the user taps a
            // non-field, which on a scrolling sheet is not always reachable.
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focus = nil }
                    .typography(Typography.label(11))
                    .foregroundStyle(Color.text)
            }
        }
        .sheet(isPresented: $microplateSheet) { MicroplateSheet() }
        .confirmationDialog(
            "Progression for this exercise", isPresented: $progressionDialog,
            titleVisibility: .visible
        ) {
            // Three states and not a flip, because a cycle through three cannot say which
            // way it is going. An override is a deliberate act (§4.4).
            Button("Program default") { draft.modeOverride = nil }
            Button(ProgressionMode.progressiveOverload.screenName) {
                draft.modeOverride = .progressiveOverload
            }
            Button(ProgressionMode.microloading.screenName) {
                draft.modeOverride = .microloading
                openRackIfNoMicroplates()
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "Discard this exercise?", isPresented: $discardDialog, titleVisibility: .visible
        ) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Keep editing", role: .cancel) {}
        } message: {
            Text("Nothing is saved until you tap save.")
        }
        .confirmationDialog(
            "Remove this exercise?", isPresented: $removeDialog, titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) { remove() }
            Button("Cancel", role: .cancel) {}
        } message: {
            // §6.6: plain, with **no** count of destroyed Sets — because nothing is
            // destroyed. A finished Workout keeps its Sets and the Name it logged them
            // under (§2.4).
            Text("It leaves the program from today. Finished workouts keep the sets you logged.")
        }
        // The unit is derived, so it can move without the user touching the unit row —
        // one tap on a chip is enough. §6.6 clears the three fields that were typed in
        // the old unit, and the sheet does it where the user can see it happen.
        .onChange(of: unit) { clearForUnitChange() }
    }

    // MARK: - The header

    /// `✕  UPPER A · EXERCISE 6`. The `✕` is Plex, like every other glyph this app draws:
    /// importing a symbol set is a §7 decision nobody has made (ticket 0034).
    private var header: some View {
        HStack(spacing: 10) {
            Button(action: close) {
                Text("✕")
                    .typography(Typography.body(17))
                    .foregroundStyle(Color.steel)
                    .frame(width: 30, height: 50, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
            Text("\(dayName) · Exercise \(position)")
                .typography(Typography.label(11))
                .foregroundStyle(Color.dimText)
                .lineLimit(1)
            Spacer()
        }
        .frame(height: 50)
    }

    // MARK: - The name (§6.3)

    @ViewBuilder
    private var nameBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isAdd {
                Text("New exercise")
                    .typography(Typography.display(31, tracking: 0.005))
                    .foregroundStyle(Color.text)
                Spacer().frame(height: 12)
            }
            nameField
                .overlay(alignment: .topLeading) { suggestions }
        }
        // Above the rows below it, so the suggestion list covers them instead of being
        // painted over by them — the artboard's own `z-index: 2`.
        .zIndex(2)
    }

    private var nameField: some View {
        TextField("", text: $draft.name)
            .typography(Typography.input(22))
            .foregroundStyle(Color.text)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .focused($focus, equals: .name)
            .tint(Color.go)     // the artboard's green caret
            .onChange(of: draft.name) { nameIsMissing = false }
            .onSubmit { focus = nil }
            .padding(.horizontal, 14)
            .frame(height: 60)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(nameIsMissing ? Color.stop : Color.text, lineWidth: 1.5))
            .contentShape(Rectangle())
            .onTapGesture { focus = .name }
    }

    /// Six rows at most, on focus and while typing alike (§6.3). On focus before typing
    /// they are the user's own names only; on a first run there are none and the list
    /// does not appear at all.
    @ViewBuilder
    private var suggestions: some View {
        if focus == .name, let logbook = store.logbook {
            let rows = Rules.nameSuggestions(in: logbook, query: draft.name)
            let typed = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
            // **Free text always wins** (§6.3). The row says so where the list could
            // otherwise look like the only way out of it.
            let offerTyped = !typed.isEmpty
                && !rows.contains { $0.caseInsensitiveCompare(typed) == .orderedSame }
            if !rows.isEmpty || offerTyped {
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { index, name in
                        suggestionRow(name, divider: index > 0) {
                            // A suggestion sets the Name and **nothing else** — never the
                            // Equipment Type, never the Increment (§6.3).
                            draft.name = name
                            focus = nil
                        }
                    }
                    if offerTyped {
                        suggestionRow("Use “\(typed)” as you typed it", divider: !rows.isEmpty) {
                            focus = nil
                        }
                    }
                }
                .background(Color.card)
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.chipBorder, lineWidth: 1))
                .offset(y: 66)
            }
        }
    }

    private func suggestionRow(
        _ text: String, divider: Bool, act: @escaping () -> Void
    ) -> some View {
        Button(action: act) {
            HStack {
                Text(text)
                    .typography(Typography.body(14))
                    .foregroundStyle(Color.text)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .frame(height: 50)          // §7.4's hit target
            .overlay(alignment: .top) {
                if divider { Rectangle().fill(Color.line).frame(height: 1) }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
    }

    // MARK: - The rows that make an Exercise

    /// **The sheet grows with the Equipment Type** (§6.2). Base Weight appears for Smith
    /// and plate-loaded, Stack Step for Machine (stack) and Cable, and it never grows for
    /// a Barbell. Both sit at the top, next to the chips that produced them: they are
    /// facts about the machine, not about the plan.
    @ViewBuilder
    private var fields: some View {
        VStack(spacing: 0) {
            if equipmentChosen, draft.equipment.takesBaseWeight {
                row("Base weight") {
                    weightBox($baseText, field: .base, width: 78) { draft.baseWeight = $0 }
                }
            }
            if equipmentChosen, draft.equipment.hasPin {
                row("Stack step") {
                    weightBox($stackText, field: .stack, width: 78) { draft.stackStep = $0 }
                }
            }
            row("Weight unit") { unitControl }
            row("Sets", note: carriedOver && isAdd ? "Carried over" : nil) { setsStepper }
            row("Rep range", note: carriedOver && isAdd ? "Carried over" : nil) { repRange }
            row("Working weight") {
                weightBox($workingText, field: .working, width: 78) { draft.workingWeight = $0 }
            }
            incrementRow
            row("Progression") {
                Button { progressionDialog = true } label: {
                    HStack(spacing: 10) {
                        Text(draft.modeOverride?.screenName ?? "Program default")
                            .typography(Typography.body(13))
                            .foregroundStyle(Color.text)
                        Text("›")
                            .typography(Typography.body(15))
                            .foregroundStyle(Color.labelText)
                    }
                    .frame(height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
            }
        }
    }

    /// One tap flips it, because there are two values and a picker for two values is
    /// ceremony (§5.2) — but only where the Exercise owns its unit. For Barbell, Smith,
    /// plate-loaded and Bodyweight the row is **locked** and the note below says why
    /// (§2.3).
    @ViewBuilder
    private var unitControl: some View {
        if unitIsLocked {
            HStack(spacing: 8) {
                Text(unit.rawValue)
                    .typography(Typography.display(17, tracking: 0.03))
                    .foregroundStyle(Color.steel)
                Text("Locked")
                    .typography(Typography.label(9, tracking: 0.12))
                    .foregroundStyle(Color.labelText)
            }
            .frame(height: 44)
        } else {
            Button {
                draft.ownWeightUnit = unit == .kg ? .lbs : .kg
            } label: {
                Text(unit.rawValue)
                    .typography(Typography.display(17, tracking: 0.03))
                    .foregroundStyle(Color.text)
                    .frame(minWidth: 56, minHeight: 44)
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.chipBorder, lineWidth: 1))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
        }
    }

    private var setsStepper: some View {
        HStack(spacing: 8) {
            stepButton("−") { draft.plannedSets = max(1, draft.plannedSets - 1) }
            Text("\(draft.plannedSets)")
                .typography(Typography.display(21))
                .foregroundStyle(Color.text)
                .frame(width: 24)
            stepButton("+") { draft.plannedSets += 1 }
        }
    }

    private func stepButton(_ glyph: String, act: @escaping () -> Void) -> some View {
        Button(action: act) {
            Text(glyph)
                .typography(Typography.body(18))
                .foregroundStyle(Color.text)
                .frame(width: 46, height: 44)
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.chipBorder, lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
    }

    private var repRange: some View {
        HStack(spacing: 8) {
            countBox($bottomText, field: .bottom)
            Text("–")
                .typography(Typography.body(15))
                .foregroundStyle(Color.labelText)
            countBox($topText, field: .top)
        }
        // The two ends are one value, so both are read at once — and the range is put in
        // order at the save, never while the user is mid-keystroke (`8`–`1` on the way to
        // `8`–`12` is not an inverted range, it is an unfinished one).
        .onChange(of: bottomText) { readRepRange() }
        .onChange(of: topText) { readRepRange() }
    }

    /// The Increment row **swaps with the Progression Mode** (§6.2), and the two halves
    /// have nothing in common: one is any number the user types, the other is a plate the
    /// user owns and is never typed at all (§2.3).
    @ViewBuilder
    private var incrementRow: some View {
        switch mode {
        case .progressiveOverload:
            row("Increment") {
                if incrementTyped || (draft.increment.map { !offeredIncrements.contains($0) } ?? false) {
                    weightBox($incrementText, field: .increment, width: 78) { draft.increment = $0 }
                } else {
                    HStack(spacing: 6) {
                        ForEach(offeredIncrements, id: \.hundredths) { offer in
                            chip(offer.decimalString, on: draft.increment == offer) {
                                draft.increment = offer
                                incrementText = offer.decimalString
                            }
                        }
                        // The artboard's `…`: any number, not only the offers (§2.3).
                        chip("…", on: false) {
                            incrementTyped = true
                            focus = .increment
                        }
                    }
                }
            }
        case .microloading:
            row("Microloading increment") { microplateChips }
            microloadingNote
        }
    }

    /// The offers, in the unit on screen. They are **offers and not a default**: §6.2
    /// starts the Increment empty and has the user pick it, and §2.3 lets it be any
    /// number at all, which is what `…` is for.
    private var offeredIncrements: [Weight] {
        switch unit {
        case .kg: [.kg(hundredths: 125), .kg(hundredths: 250), .kg(hundredths: 500)]
        case .lbs: [.lbs(hundredths: 250), .lbs(hundredths: 500), .lbs(hundredths: 1000)]
        }
    }

    /// Picked from the Microplates in the Plate Inventory, never typed (§2.3).
    @ViewBuilder
    private var microplateChips: some View {
        let plates = rack.enabledMicroplates
        if plates.isEmpty {
            // §5.2's empty state, which §6.6 also sends a stranded Exercise to. It taps
            // through to the Microplate group rather than telling the user to go and find
            // it (§7.6).
            Button { microplateSheet = true } label: {
                HStack(spacing: 8) {
                    Text("No microplates · set up your rack")
                        .typography(Typography.label(10, tracking: 0.12))
                        .foregroundStyle(Color.steel)
                    Text("›")
                        .typography(Typography.body(15))
                        .foregroundStyle(Color.labelText)
                }
                .frame(height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
        } else {
            HStack(spacing: 6) {
                ForEach(plates, id: \.hundredths) { plate in
                    chip(plate.decimalString, on: picked(plate)) {
                        draft.microloadingIncrement = plate
                    }
                }
            }
        }
    }

    private func picked(_ plate: Weight) -> Bool {
        draft.microloadingIncrement?.relabelled(rack.unit) == plate.relabelled(rack.unit)
    }

    /// What the picked plate actually moves — read out of `Rules.progressionMove`, never
    /// multiplied here. A bar takes a pair, so one 0.25 kg plate is `+0.5 KG ON THE BAR`
    /// (§4.2); a pin hangs it instead and rolls it into the stack a Stack Step at a time.
    @ViewBuilder
    private var microloadingNote: some View {
        if microloadingIsRefused {
            note("A dumbbell has nowhere to hang a plate — set this exercise in \(rack.unit.rawValue), or use progressive overload.")
        } else if let plate = draft.microloadingIncrement, isStranded(plate) {
            note("Your \(plate.decimalString) \(rack.unit.rawValue) plate is switched off. Pick another, or switch it back on in your rack.")
        } else if let clause = microloadingClause {
            note(clause)
        }
    }

    private func isStranded(_ plate: Weight) -> Bool {
        !rack.enabledMicroplates.contains(plate.relabelled(rack.unit))
    }

    private var microloadingClause: String? {
        guard equipmentChosen, let plate = draft.microloadingIncrement else { return nil }
        // Probed at zero: the move is what the rule says it is, and the difference from
        // zero is the jump. Everything else about the Exercise is the draft as it stands.
        let probe = probeExercise(workingWeight: .zero(unit))
        guard let move = Rules.progressionMove(for: probe, inventory: rack) else { return nil }
        let jump = move.workingWeight
        if probe.isMixedUnitPin {
            guard let step = probe.stackStep else { return nil }
            return "\(plate.decimalString) \(rack.unit.rawValue) hangs on the pin, and rolls into the stack at \(step.decimalString) \(unit.rawValue)."
        }
        guard jump.hundredths > 0 else { return nil }
        return draft.equipment.isBarLoaded
            ? "+\(jump.decimalString) \(unit.rawValue) on the bar."
            : "+\(jump.decimalString) \(unit.rawValue) per progression."
    }

    /// The draft as a `ResolvedExercise`, so a rule can be asked about a sheet nobody has
    /// saved yet. The id is a placeholder: nothing here reads it.
    private func probeExercise(workingWeight: Weight?) -> ResolvedExercise {
        Exercise(
            id: target.exercise ?? ExerciseID(0),
            name: draft.name,
            equipment: draft.equipment,
            ownWeightUnit: draft.ownWeightUnit,
            plannedSets: max(1, draft.plannedSets),
            repRange: draft.repRange,
            workingWeight: workingWeight,
            increment: draft.increment,
            microloadingIncrement: draft.microloadingIncrement,
            modeOverride: draft.modeOverride,
            storedBaseWeight: draft.baseWeight,
            storedStackStep: draft.stackStep
        )
        .resolved(mode: mode, inventory: rack)
    }

    // MARK: - What the sheet says under the fields

    @ViewBuilder
    private var notes: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let text = stash.note(showing: unit) {
                note(text)
            }
            if unitIsLocked {
                // The artboard's lock line, without its padlock: no SF Symbols (ticket
                // 0034), and the sentence carries the meaning on its own.
                note("The unit is \(unit.rawValue), from your plate rack. \(draft.equipment.screenName) exercises cannot use the other unit.")
            }
            if !equipmentChosen {
                note("Base weight appears as soon as you pick smith or plate-loaded.")
            }
            if !isAdd {
                note("Your changes save when you close this sheet.")
            }
        }
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .typography(Typography.body(11.5, lineSpacing: 3))
            .foregroundStyle(Color.dimText)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - The bottom control

    /// The add life saves and opens empty again, which is the 14-tap floor's one save tap
    /// (§6.2). The edit life has nothing to save there — closing is the save — so it
    /// carries the artboard's own control instead.
    @ViewBuilder
    private var bottomControl: some View {
        if isAdd {
            PrimaryButton("Save", action: save)
        } else {
            Button { removeDialog = true } label: {
                Text("Remove exercise")
                    .typography(Typography.label(11))
                    .foregroundStyle(Color.steel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.chipBorder, lineWidth: 1))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
        }
    }

    // MARK: - Reading the fields

    private func weightBox(
        _ text: Binding<String>, field: Field, width: CGFloat, keep: @escaping (Weight?) -> Void
    ) -> some View {
        typedBox(text, field: field, width: width, decimal: true) { value in
            keep(weight(value))
        }
    }

    private func countBox(_ text: Binding<String>, field: Field) -> some View {
        typedBox(text, field: field, width: 60, decimal: false) { _ in }
    }

    private func typedBox(
        _ text: Binding<String>, field: Field, width: CGFloat, decimal: Bool,
        read: @escaping (String) -> Void
    ) -> some View {
        ZStack(alignment: .trailing) {
            if text.wrappedValue.isEmpty {
                Text("—")
                    .typography(Typography.display(19))
                    .foregroundStyle(Color.labelText)
            }
            TextField("", text: text)
                .typography(Typography.input(19))
                .foregroundStyle(Color.text)
                .multilineTextAlignment(.trailing)
                .keyboardType(decimal ? .decimalPad : .numberPad)
                .focused($focus, equals: field)
                .tint(Color.go)
                .onChange(of: text.wrappedValue) {
                    stash.forget()
                    read(text.wrappedValue)
                }
        }
        .padding(.horizontal, 12)
        .frame(minWidth: width, minHeight: 44)
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.chipBorder, lineWidth: 1))
        .contentShape(Rectangle())
        .onTapGesture { focus = field }
    }

    /// The Rep Range is read as two numbers and put in order at the save, so a half-typed
    /// `8`–`1` never rewrites itself under the user's thumb.
    private func readRepRange() {
        draft.repRange = RepRange(
            Int(bottomText) ?? draft.repRange.bottom,
            Int(topText) ?? draft.repRange.top)
    }

    private func chip(_ title: String, on: Bool, act: @escaping () -> Void) -> some View {
        Button(action: act) {
            Text(title)
                .typography(Typography.meta(13))
                // A chip is its own width. Without this the row's `Spacer` wins the
                // squeeze and `1.25` breaks over two lines — found on the phone.
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(on ? Color.floor : Color.dimText)
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(on ? Color.text : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(on ? Color.clear : Color.chipBorder, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
    }

    @ViewBuilder
    private func row<Content: View>(
        _ label: String, note: String? = nil, @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .typography(Typography.label(10.5, tracking: 0.12))
                    .foregroundStyle(Color.dimText)
                if let note {
                    Text(note)
                        .typography(Typography.label(9, tracking: 0.12))
                        .foregroundStyle(Color.labelText)
                }
            }
            Spacer(minLength: 8)
            content()
        }
        .frame(minHeight: 58)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.line).frame(height: 1) }
    }

    // MARK: - Picking an Equipment Type

    private func pick(_ type: EquipmentType) {
        equipmentChosen = true
        equipmentIsMissing = false
        draft.equipment = type
        // §2.3 refuses to re-ask a fact about a machine, so nothing stored is thrown away
        // here: `Rules.edited` writes a Base Weight back only where the new type shows the
        // row, and the sheet shows the row for the same reason.
        openRackIfNoMicroplates()
    }

    /// §5.2 again: Microloading with no Microplate switched on opens the Microplate group
    /// **in place**, exactly as step 1 does. On a fresh install that is every time.
    private func openRackIfNoMicroplates() {
        if mode == .microloading, rack.enabledMicroplates.isEmpty, !microloadingIsRefused {
            microplateSheet = true
        }
    }

    /// §6.6, where the user can see it: a change of unit takes the Working Weight, the
    /// Increment and the Stack Step off the screen. The Base Weight is not touched here —
    /// it belongs to a type that reads the rack, and it is written back only where the new
    /// type has the row, so it survives a change of type the way §2.3 asks.
    ///
    /// **The numbers are put away, not destroyed** (ticket 0043). An edit sheet has no
    /// cancel — closing *is* the save (§6.2) — so one mis-tap on the unit row used to
    /// destroy three numbers with no way back. `UnitStash` files them under the unit they
    /// were typed in and hands back whatever was filed under the unit arriving; tapping
    /// the row again is a full undo. The sheet keeps none of that reasoning — it hands
    /// over what is on the screen and draws what comes back.
    private func clearForUnitChange() {
        // **The label moves first, and it moves whether or not anything was put away.**
        // The draft carries the unit its numbers are written in (§6.6), and an empty sheet
        // that has just picked a Cable in lbs is about to be typed into in lbs. Leave this
        // under a guard and a first number typed on a fresh sheet is cleared at the save,
        // which is the very bug the field exists to close.
        let leaving = draft.shownUnit
        draft.shownUnit = unit
        guard leaving != unit else { return }

        show(stash.move(
            from: leaving, to: unit,
            onScreen: TypedWeights(
                working: workingText, increment: incrementText, stack: stackText,
                incrementTyped: incrementTyped)))
    }

    /// Put a filed set of numbers on the screen, in the unit the sheet now shows. The
    /// text is copied back as typed; the draft's `Weight`s are re-read from it under the
    /// **current** unit, which is the unit that text was typed under — that is what the
    /// key means.
    private func show(_ typed: TypedWeights) {
        workingText = typed.working
        incrementText = typed.increment
        stackText = typed.stack
        incrementTyped = typed.incrementTyped
        draft.workingWeight = weight(typed.working)
        draft.increment = weight(typed.increment)
        draft.stackStep = weight(typed.stack)
    }

    /// A typed field as a `Weight` in the unit the sheet is showing. **An unset weight
    /// is `nil`, not zero** (§2.8): an empty field is *the user has not typed one*, and
    /// zero is a real Bodyweight lift. Both the keypad and the stash read a field through
    /// here, so a restored number is parsed exactly as a typed one.
    private func weight(_ text: String) -> Weight? {
        text.isEmpty ? nil : Weight(decimalString: text, unit: unit)
    }

    // MARK: - Saving, which happens once (§6.2)

    /// **The two lives leave differently, and each says so where the user taps.**
    ///
    /// An edit sheet has an Exercise behind it and every row on it is already true of
    /// that Exercise, so closing is the save — the one act §6.2 allows, and the note
    /// under the fields states it. There is no *cancel*: half this sheet is reachable
    /// from the rack mid-Workout (§6.6), where a change the user made and watched land is
    /// not a thing to ask about twice.
    ///
    /// An add sheet has nothing behind it. Its save is the control that says `SAVE`, and
    /// the `✕` asks before it throws a filled-in sheet away — 14 taps is too many to lose
    /// to a mis-tap, and too few to make the user save something they were abandoning.
    private func close() {
        guard isAdd else {
            if commit() { dismiss() }
            return
        }
        guard hasContent else {
            dismiss()
            return
        }
        discardDialog = true
    }

    /// The add life's save. **It closes the sheet**, and the Day screen behind it shows
    /// the Exercise that just landed — the confirmation the sheet itself cannot give.
    ///
    /// It costs one tap per Exercise over `SAVE AND ADD ANOTHER`, which reopened the sheet
    /// empty. Rob asked for the tap back on the phone: a sheet that empties itself reads
    /// like a sheet that threw the work away. The carry-over is unharmed — the next
    /// `ADD AN EXERCISE` reads it off the Exercise this one just saved.
    private func save() {
        guard commit() else { return }
        dismiss()
    }

    /// Whether anything on an add sheet would be lost by closing it. **The stash counts**
    /// (ticket 0043): numbers held under the other unit are one tap from the screen, and a
    /// `✕` that dismissed them without asking is the mis-tap that ticket closed, moved to
    /// a different control.
    private var hasContent: Bool {
        !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || equipmentChosen || !workingText.isEmpty || !incrementText.isEmpty
            || !baseText.isEmpty || !stackText.isEmpty
            || stash.hasNumbers
    }

    /// One action carrying the whole sheet (§6.2, ticket 0026) — never ten field writes,
    /// because §6.6's rules are a **diff** and a sheet that changed the unit and typed the
    /// new weight would otherwise clear the weight it was just given.
    ///
    /// Returns `false` when the sheet refused to save, and it refuses **where the user
    /// taps**: §5.2's principle, the same one `NameYourProgram` applies to `CONTINUE`.
    private func commit() -> Bool {
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            nameIsMissing = true
            focus = .name
            return false
        }
        guard equipmentChosen else {
            equipmentIsMissing = true
            return false
        }
        var saved = draft
        saved.name = name
        // Two ends of one range, put in order at the one moment it matters.
        saved.repRange = RepRange(
            min(draft.repRange.bottom, draft.repRange.top),
            max(draft.repRange.bottom, draft.repRange.top))
        saved.plannedSets = max(1, draft.plannedSets)

        if let id = target.exercise {
            store.send(.saveExercise(id, draft: saved))
        } else {
            store.send(.addExercise(workoutDayId: target.day, at: target.at, draft: saved))
        }
        return true
    }

    private func remove() {
        guard let id = target.exercise else { return }
        Haptic.destroyed()
        store.send(.deleteExercise(id))
        dismiss()
    }
}

// MARK: - The Equipment Type chips (§2.6)

/// Seven chips that wrap, in `SPEC.md` §2.6's own order: the four types loaded off the
/// user's own rack first, then the three that carry the unit the machine is marked with.
/// That grouping is the lock rule made visible — the first four lock the Weight Unit row,
/// the last three do not.
///
/// `chosen` is an `Optional` because **the Equipment Type starts empty** (§6.2): on an add
/// no chip is lit until the user picks one.
struct EquipmentChips: View {
    let chosen: EquipmentType?
    let pick: (EquipmentType) -> Void

    var body: some View {
        WrapRows(spacing: 6, lineSpacing: 6) {
            ForEach(EquipmentType.allCases, id: \.self) { type in
                Button { pick(type) } label: {
                    Text(type.screenName)
                        .typography(Typography.label(11, tracking: 0.10))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .foregroundStyle(type == chosen ? Color.floor : Color.dimText)
                        .padding(.horizontal, 14)
                        .frame(height: 44)      // §7.4's hit target; the artboard's own
                        .background(type == chosen ? Color.text : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(type == chosen ? Color.clear : Color.chipBorder,
                                        lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
            }
        }
    }
}

/// A row of views that wraps to the next line when it runs out of width.
///
/// SwiftUI ships no such stack, and the alternatives all fail this list: a `LazyVGrid`
/// gives every chip the same width, and `BODYWEIGHT` beside `SMITH` in equal columns is
/// either clipped or four chips of white space. The chips are text, so their widths are
/// their own.
struct WrapRows: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let lines = lines(subviews, in: width)
        let height = lines.reduce(0) { $0 + $1.height }
            + lineSpacing * CGFloat(max(0, lines.count - 1))
        return CGSize(width: proposal.width ?? (lines.map(\.width).max() ?? 0), height: height)
    }

    func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    ) {
        var y = bounds.minY
        for line in lines(subviews, in: bounds.width) {
            var x = bounds.minX
            for index in line.first..<line.end {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y + (line.height - size.height) / 2),
                    proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += line.height + lineSpacing
        }
    }

    private struct Line {
        var first: Int
        var end: Int
        var width: CGFloat
        var height: CGFloat
    }

    private func lines(_ subviews: Subviews, in width: CGFloat) -> [Line] {
        var out: [Line] = []
        var current = Line(first: 0, end: 0, width: 0, height: 0)
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let next = current.width == 0 ? size.width : current.width + spacing + size.width
            if next > width, current.end > current.first {
                out.append(current)
                current = Line(first: index, end: index, width: 0, height: 0)
            }
            current.width = current.width == 0 ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.end = index + 1
        }
        if current.end > current.first { out.append(current) }
        return out
    }
}
