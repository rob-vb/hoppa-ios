import SwiftUI
import HoppaRules
import HoppaStore

// Ticket 0034 — §6.1 step 3, **the hub**.
//
// One screen with two lives, like `PlateRackScreen` before it: it is onboarding's third
// step when it is reached from the rack's confirm, and Flow 5's hub when it is reached
// from the picker's `•••`. The difference is two words of chrome — the step count and the
// bottom control — and nothing about what it draws, because a Program the user has just
// made and a Program the user has trained on for a year are the same thing.
//
// **Scope was cut at ticket 0029 and this file keeps most of the cut**: the Workout Days
// with their Exercise counts, `ADD A DAY`, and the door to Program settings. Deleting a
// Day, deleting the Program and the Re-weigh list are not here — each carries a warning of
// its own. **Reorder handles landed at ticket 0044**, on `ReorderColumn`: reordering Days
// is cosmetic (§3.1 picks freely, with no rotation), so it is the one Flow 5 edit with
// neither a warning to state nor an Open Workout to reach into.
//
// Artboard: `design/0006-onboarding/Program.dc.html`.

struct ProgramSheet: View {
    @Environment(LogbookStore.self) private var store
    @Binding var path: [Route]
    let programId: ProgramID
    /// §6.1 step 3, rather than Flow 5's hub. See `Route.programSheet`.
    let onboarding: Bool

    /// The `ADD A DAY` sheet, held as the name being typed into it.
    @State private var newDay = false
    /// True while a reorder handle is held, so the ScrollView stops (ticket 0054).
    @State private var isReordering = false

    /// Read from the store on every pass, never copied into `@State`: a Day added on this
    /// screen has to appear on it, and a rename made one screen down has to arrive back.
    private var program: Program? { store.logbook?.program(programId) }

    var body: some View {
        ZStack {
            Color.floor.ignoresSafeArea()
            if let program {
                content(program)
                    .padding(.horizontal, 20)   // §7.4 screen padding
                    .padding(.bottom, 20)
            } else {
                // The Program is gone. Nothing here is a rule and nothing here can put it
                // back, so the screen says what is true and offers the way home.
                gone
            }
        }
        // §7.4: nothing is drawn in the safe top inset, so the bar is hidden and
        // `StepHeader` draws the way back in content — as every screen before this does.
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $newDay) {
            NameSheet(
                heading: "Name the day",
                confirm: "Add the day",
                hint: "Push, Upper A, Legs — whatever you call it in the gym.",
                initial: ""
            ) { name in
                store.send(.addWorkoutDay(programId: programId, name: name))
            }
        }
    }

    @ViewBuilder
    private func content(_ program: Program) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            StepHeader(step: onboarding ? 3 : nil, back: goBack)
            Text(program.name)
                .typography(Typography.display(31, tracking: 0.005))
                .foregroundStyle(Color.text)
            Spacer().frame(height: 8)
            Text(summary(program))
                .typography(Typography.label(10.5, tracking: 0.12))
                .foregroundStyle(Color.dimText)
            Spacer().frame(height: 20)
            Text("Workout days")
                .typography(Typography.label(10.5))
                .foregroundStyle(Color.labelText)
            Spacer().frame(height: 8)
            days(program)
            Spacer(minLength: 12)
            settingsRow
            Spacer().frame(height: 10)
            // Onboarding ends on the artboard's own words. Reached from the picker there
            // is nothing to start here — the picker is where a Workout is picked (§3.1) —
            // so the same tap is simply the way out.
            PrimaryButton(onboarding ? "Start a workout" : "Done") { path = [] }
        }
    }

    /// `4 days · 22 exercises · kg · progressive overload`. Every part of it is a count or
    /// a stored field, so nothing here is a rule; the two Program-level decisions are on
    /// the line because §6.1 put them on the card at step 1 and this is where they land.
    private func summary(_ program: Program) -> String {
        let days = program.days.count == 1 ? "1 day" : "\(program.days.count) days"
        let count = program.days.reduce(0) { $0 + $1.exercises.count }
        let exercises = count == 1 ? "1 exercise" : "\(count) exercises"
        return "\(days) · \(exercises) · \(program.defaultWeightUnit.rawValue) · \(program.mode.screenName)"
    }

    // MARK: - The Workout Days

    @ViewBuilder
    private func days(_ program: Program) -> some View {
        ScrollView {
            VStack(spacing: 6) {
                if program.days.isEmpty {
                    // §6.1: Hoppa starts empty and invents no Day. The line states the
                    // rule §6.6 already enforces at the other end — the last Day cannot
                    // be deleted — rather than telling the user what to do (§7.6).
                    Text("A program needs at least one workout day.")
                        .typography(Typography.body(12, lineSpacing: 3))
                        .foregroundStyle(Color.dimText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 2)
                }
                ReorderColumn(
                    items: program.days, id: \.id, isReordering: $isReordering
                ) { (id: WorkoutDayID, to: Int) in
                    store.send(.moveWorkoutDay(id, to: to))
                } row: { (day: WorkoutDay, index: Int) in
                    dayRow(index: index, day: day)
                }
                AddRow("Add a day") { newDay = true }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        // Ticket 0054: a held handle pins the list. A reorder that scrolls at the same
        // time slides the content under the finger the card is following, which is a
        // shake — and it is not what the user asked for either.
        .scrollDisabled(isReordering)
    }

    /// The card's content only: `ReorderColumn` draws the card and the handle beside it,
    /// so the tap that opens the Day stops where the grip starts.
    ///
    /// `index` is **the position the row is drawn at**, which under a finger is the
    /// previewed one — so the numbers renumber as the card is dragged, before the drop.
    private func dayRow(index: Int, day: WorkoutDay) -> some View {
        Button { path.append(.workoutDay(day.id)) } label: {
            HStack(spacing: 12) {
                // The position, not an id. §6.6 calls reordering Days cosmetic, so this
                // number means "third in the list" and nothing more. It stays now the
                // handle is beside it: it is what the handle is seen to change.
                Text("\(index + 1)")
                    .typography(Typography.display(17))
                    .foregroundStyle(Color.labelText)
                    .frame(width: 14, alignment: .leading)
                VStack(alignment: .leading, spacing: 4) {
                    Text(day.name)
                        .typography(Typography.display(17))
                        .foregroundStyle(Color.text)
                        .lineLimit(1)
                    Text(day.exerciseCountText)
                        .typography(Typography.label(10.5, tracking: 0.12))
                        .foregroundStyle(Color.dimText)
                }
                Spacer(minLength: 8)
                Text("›")
                    .typography(Typography.body(15))
                    .foregroundStyle(Color.labelText)
            }
            .padding(.trailing, 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
    }

    // MARK: - Program settings

    /// The artboard's row, and the **only** door to the Plate Inventory outside
    /// onboarding: until this landed, `Route.plateRack(nil)` had no way in and the rack's
    /// own `DONE` branch was unreachable.
    private var settingsRow: some View {
        DoorRow(
            title: "Program settings",
            detail: "unit, progression, plate rack"
        ) {
            path.append(.programSettings(programId))
        }
    }

    // MARK: - Plain parts

    private var gone: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("That program is gone.")
                .typography(Typography.display(26))
                .foregroundStyle(Color.text)
            PrimaryButton("Back") { path = [] }
        }
        .padding(.horizontal, 20)
    }

    private func goBack() {
        if !path.isEmpty { path.removeLast() }
    }
}

// MARK: - Program settings (§6.6's Program-level edits)

/// The Name, and the three decisions step 1 pre-answered.
///
/// Every one of them is an `Action` that `HoppaRules` already owns and tests — the unit
/// touches nothing that exists (§2.1), the Mode changes every Exercise that does not
/// override it and fills their Microloading Increments (§4.4), renaming migrates nothing
/// (§2.7). This screen picks the value and sends it; it decides none of that.
struct ProgramSettings: View {
    @Environment(LogbookStore.self) private var store
    @Binding var path: [Route]
    let programId: ProgramID

    @State private var renaming = false

    private var program: Program? { store.logbook?.program(programId) }
    private var rack: PlateInventory { store.logbook?.plateInventory ?? .standard(.kg) }

    var body: some View {
        ZStack {
            Color.floor.ignoresSafeArea()
            if let program {
                VStack(alignment: .leading, spacing: 0) {
                    StepHeader(label: program.name, back: { if !path.isEmpty { path.removeLast() } })
                    Text("Program settings")
                        .typography(Typography.display(31, tracking: 0.005))
                        .foregroundStyle(Color.text)
                    Spacer().frame(height: 20)
                    rows(program)
                    Spacer(minLength: 16)
                    Text("The weight unit is the default for new exercises only. Changing the progression mode moves every exercise that does not override it.")
                        .typography(Typography.body(12, lineSpacing: 3))
                        .foregroundStyle(Color.dimText)
                    Spacer().frame(height: 12)
                    PrimaryButton("Done") { if !path.isEmpty { path.removeLast() } }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $renaming) {
            NameSheet(
                heading: "Rename the program",
                confirm: "Save the name",
                hint: "Renaming changes nothing else. Finished workouts keep the name they were logged with.",
                initial: program?.name ?? ""
            ) { name in
                store.send(.renameProgram(programId, name: name))
            }
        }
    }

    @ViewBuilder
    private func rows(_ program: Program) -> some View {
        VStack(spacing: 6) {
            SettingRow(label: "Name", value: program.name) { renaming = true }
            SettingRow(label: "Weight unit", value: program.defaultWeightUnit.rawValue) {
                store.send(.setProgramDefaultWeightUnit(
                    programId, program.defaultWeightUnit == .kg ? .lbs : .kg))
            }
            SettingRow(label: "Progression", value: program.mode.screenName) {
                store.send(.setProgramMode(programId, program.mode.next))
            }
            SettingRow(label: "Plate rack", value: rackName) {
                path.append(.plateRack(nil))
            }
        }
    }

    /// The same sentence step 1 draws, and for the same reason: the row exists to say what
    /// the rack is, so it has to stop saying *standard* the moment that stops being true.
    private var rackName: String {
        "\(rack == .standard(rack.unit) ? "Standard" : "Custom") \(rack.unit.rawValue)"
    }
}

/// A label, a value and a chevron, at §7.4's 50 pt hit target. Step 1's `assumptionRow`
/// drawn without the plate chips, which belong to the screen that is about to show the
/// rack and not to a settings list.
struct SettingRow: View {
    let label: String
    let value: String
    let act: () -> Void

    var body: some View {
        Button(action: act) {
            HStack(spacing: 12) {
                Text(label)
                    .typography(Typography.label(10.5, tracking: 0.12))
                    .foregroundStyle(Color.dimText)
                Spacer(minLength: 8)
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
        .buttonStyle(.pressable)
    }
}

// MARK: - The parts the hub and the Day screen share

/// The artboard's dashed `ADD A DAY` / `ADD EXERCISE` row.
///
/// Dashed and not filled, because it is the one row in the list that is not a thing the
/// user owns yet. The `+` is Plex and not an SF Symbol: every glyph this app draws so far
/// comes out of a bundled face, and one imported symbol set would be a §7 decision nobody
/// has made.
struct AddRow: View {
    let title: String
    let act: () -> Void

    init(_ title: String, act: @escaping () -> Void) {
        self.title = title
        self.act = act
    }

    var body: some View {
        Button(action: act) {
            HStack(spacing: 10) {
                Text("+")
                    .typography(Typography.body(16))
                    .foregroundStyle(Color.dimText)
                Text(title)
                    .typography(Typography.label(11))
                    .foregroundStyle(Color.dimText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.chipBorder, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
    }
}

/// One field and one button: the whole of naming something.
///
/// Add and rename are the same sheet, for the same reason §6.2's Exercise sheet is: a
/// Name is a label and typing one is one act (§2.7). The empty name is refused **where
/// the user taps** and never by disabling the button — §5.2's principle, which
/// `NameYourProgram` applies to `CONTINUE` and this applies here.
struct NameSheet: View {
    let heading: String
    let confirm: String
    let hint: String
    let onSave: (String) -> Void

    @State private var name: String
    @State private var isMissing = false
    @FocusState private var focused: Bool
    @Environment(\.dismiss) private var dismiss

    init(
        heading: String, confirm: String, hint: String, initial: String,
        onSave: @escaping (String) -> Void
    ) {
        self.heading = heading
        self.confirm = confirm
        self.hint = hint
        self.onSave = onSave
        _name = State(initialValue: initial)
    }

    var body: some View {
        ZStack {
            Color.floor.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Text(heading)
                    .typography(Typography.display(26))
                    .foregroundStyle(Color.text)
                Spacer().frame(height: 16)
                field
                Spacer().frame(height: 8)
                Text(isMissing ? "Give it a name first." : hint)
                    .typography(Typography.body(12, lineSpacing: 4))
                    .foregroundStyle(isMissing ? Color.stop : Color.dimText)
                Spacer(minLength: 16)
                PrimaryButton(confirm, action: save)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 20)
        }
        .presentationBackground(Color.floor)
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
        // The sheet exists to be typed into, so the keyboard arrives with it.
        .onAppear { focused = true }
    }

    private var field: some View {
        TextField("", text: $name)
            .typography(Typography.input(26))
            .foregroundStyle(Color.text)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .focused($focused)
            .tint(Color.go)     // the artboard's green caret
            .onChange(of: name) { isMissing = false }
            .onSubmit(save)
            .padding(.horizontal, 16)
            .frame(height: 64)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(isMissing ? Color.stop : Color.text, lineWidth: 1.5))
            .contentShape(Rectangle())
            .onTapGesture { focused = true }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            isMissing = true
            focused = true
            return
        }
        onSave(trimmed)
        dismiss()
    }
}
