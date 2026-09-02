import SwiftUI
import HoppaRules
import HoppaStore

// Ticket 0046 — §6.6's Re-weigh list.
//
// **Nothing writes this list down.** It is `Rules.reweighList`, which is *every Exercise
// with no Working Weight* — which is what the rack's unit switch has just made them, and
// what a new Exercise is before the user types. Leave the screen, close the app, come
// back a day later, and the same Exercises still have none, so the same list appears.
// The count in §6.6's warning is the same rule asked before the switch instead of after.
//
// Three things this screen decided, because §6.6 left them open. Each is a judgment call
// and each is on the walk list.
//
// - **The weight is typed inline, not in `WeightSheet`.** §6.6's own argument for this
//   screen is that *paying its cost once at the kitchen table beats meeting it twelve
//   times at the rack*. Twelve full-screen keypads, each opened and dismissed, puts the
//   twelve back. The Exercise sheet is the other kitchen-table screen that asks for a
//   Working Weight and it asks with a `decimalPad` field, so this is the idiom the user
//   already has. §5.4's line comes along anyway — the row draws `ClosestLine` under the
//   number the moment it parses — so nothing the keypad states is lost.
// - **The list is frozen while the screen is open.** The rule is *has no Working Weight*,
//   so a row would leave the list on the first digit typed and the rows under the user's
//   thumb would move. The ids are read once, on appear, and every one of them keeps its
//   place until the screen is left. Re-entering re-derives, which is the whole point.
// - **A row states what else the switch cleared, and the statement is the door.** The
//   switch clears the Increment and the Base Weight too, and this list shows one field.
//   An Exercise re-weighed but still without an Increment does not progress (§4.1), and
//   §7.6 says Hoppa states its condition where the user stands rather than fixing it
//   quietly. So the note under the name says `no increment`, and tapping it opens the
//   Exercise sheet, which is where the rest lives.
//
// Consult `SPEC.md` §6.6, §5.1, §5.4, §2.8.

struct ReweighScreen: View {
    @Environment(LogbookStore.self) private var store
    @Binding var path: [Route]

    /// The list as it stood when the screen opened — see the note above. Empty until
    /// `.task` fills it, which is also the one place it is ever read from the rules.
    @State private var frozen: [ExerciseID] = []
    /// What is in each field. A `String`, because `72.` is a real state of a field being
    /// typed and no `Weight` can hold it — the same reason the Exercise sheet holds text.
    @State private var text: [ExerciseID: String] = [:]
    @FocusState private var focus: ExerciseID?
    @State private var sheetTarget: ExerciseSheetTarget?

    private var rack: PlateInventory { store.logbook?.plateInventory ?? .standard(.kg) }

    var body: some View {
        ZStack {
            Color.floor.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                StepHeader(label: nil, back: leave)
                Text("Re-weigh")
                    .typography(Typography.display(31, tracking: 0.005))
                    .foregroundStyle(Color.text)
                Spacer().frame(height: 12)
                Text(intro)
                    .typography(Typography.body(12, lineSpacing: 3))
                    .foregroundStyle(Color.dimText)
                Spacer().frame(height: 20)
                list
                Spacer(minLength: 12)
                PrimaryButton("Done", action: leave)
            }
            .padding(.horizontal, 20)   // §7.4 screen padding
            .padding(.bottom, 20)
        }
        .toolbar(.hidden, for: .navigationBar)
        // **Commit on leaving the field, never on the keystroke.** A write per digit sends
        // `13` to disk on the way to `135`, and each of those is a Working Weight the
        // Summary could progress from.
        .onChange(of: focus) { old, _ in if let old { commit(old) } }
        .task { freeze() }
        .sheet(item: $sheetTarget) { target in
            if let program = store.logbook?.workoutDay(target.day)?.program,
               let id = target.exercise, let exercise = program.exercise(id) {
                ExerciseSheet(
                    target: target,
                    initial: ExerciseDraft(exercise, in: rack),
                    carriedOver: false)
            }
        }
    }

    /// Read once. `frozen` is empty only before the first appearance, so a screen re-entered
    /// with everything weighed shows the finished list rather than snapping to empty.
    private func freeze() {
        guard frozen.isEmpty, let logbook = store.logbook else { return }
        frozen = Rules.reweighList(in: logbook)
    }

    private func leave() {
        if let focus { commit(focus) }
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    // MARK: - The one write

    /// The field as a `Weight`, or `nil` while it is not one yet.
    ///
    /// **Zero is kept.** Zero is a real weight (§2.8) — a Bodyweight Exercise done with no
    /// belt — and it is the only true answer for a chin-up the switch has just cleared.
    /// `WeightSheet` refuses zero because a Working Weight at the rack always had one; the
    /// kitchen table is where an Exercise gets its first.
    private func typed(_ id: ExerciseID) -> Weight? {
        guard let unit = resolved(id)?.unit else { return nil }
        return Weight(decimalString: text[id] ?? "", unit: unit)
    }

    /// **The field writes on the way out, not on the keystroke.** One consequence, and it
    /// is on the walk list: `Weight(decimalString:)` reads `185.` as 185 — the same parser
    /// the Exercise sheet types through — so tapping away mid-decimal commits the whole
    /// number. Coming back and typing the rest is one more write on a screen that expects
    /// several, which is cheaper than a field that refuses to leave.
    private func commit(_ id: ExerciseID) {
        guard let weight = typed(id), weight != resolved(id)?.workingWeight else { return }
        store.send(.reweigh(id, weight))
    }

    // MARK: - The rows, in Program order

    /// Programs, then Days, then position — the order `Logbook.allExercises` fixes, and
    /// the order §6.6's lists are drawn in. Walked here rather than mapped from the ids,
    /// because a row needs the Day it lives in for its heading and for its Exercise sheet.
    private var list: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(store.logbook?.programs ?? [], id: \.id) { program in
                    ForEach(program.days, id: \.id) { day in
                        let rows = day.exercises.filter { frozen.contains($0.id) }
                        if !rows.isEmpty {
                            // The list crosses Programs, so a Day is named by its Program
                            // wherever there is more than one to confuse it with (§2.7).
                            heading(manyPrograms ? "\(program.name) · \(day.name)" : day.name)
                            VStack(spacing: 8) {
                                ForEach(rows, id: \.id) { exercise in
                                    row(exercise, in: day)
                                }
                            }
                            Spacer().frame(height: 20)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
    }

    private var manyPrograms: Bool { (store.logbook?.programs.count ?? 0) > 1 }

    private func heading(_ name: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(name)
                .typography(Typography.label(10.5))
                .foregroundStyle(Color.labelText)
            Spacer().frame(height: 8)
        }
    }

    private func row(_ exercise: Exercise, in day: WorkoutDay) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text(exercise.name)
                    .typography(Typography.display(15))
                    .foregroundStyle(Color.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                field(exercise.id)
            }
            note(exercise, in: day)
            // §5.4, at the moment the number is typed rather than at the rack. It is the
            // only thing in Hoppa that deals with the gap, and a weight the user's own
            // rack cannot build is exactly what a change of gym produces.
            if let resolved = resolved(exercise.id), let weight = typed(exercise.id) {
                ClosestLine(
                    breakdown: Rules.breakdown(for: resolved, at: weight, inventory: rack),
                    performedAt: weight)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .frame(minHeight: 50)
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.line, lineWidth: 1))
    }

    private func field(_ id: ExerciseID) -> some View {
        HStack(spacing: 8) {
            ZStack(alignment: .trailing) {
                if (text[id] ?? "").isEmpty {
                    Text("—")
                        .typography(Typography.display(19))
                        .foregroundStyle(Color.labelText)
                }
                TextField("", text: binding(id))
                    .typography(Typography.input(19))
                    .foregroundStyle(Color.text)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
                    .focused($focus, equals: id)
                    .tint(Color.go)
            }
            .padding(.horizontal, 12)
            .frame(minWidth: 74, minHeight: 44)
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.chipBorder, lineWidth: 1))
            .contentShape(Rectangle())
            .onTapGesture { focus = id }
            .onChange(of: focus) { _, new in
                if new == id {
                    DispatchQueue.main.async {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.selectAll(_:)), to: nil, from: nil, for: nil)
                    }
                }
            }
            Text(resolved(id)?.unit.rawValue ?? rack.unit.rawValue)
                .typography(Typography.label(10.5))
                .foregroundStyle(Color.dimText)
                .frame(width: 20, alignment: .leading)
        }
    }

    /// The Equipment Type, and **what else this Exercise is still missing**. The note is
    /// the door: the Increment and the Base Weight are the Exercise sheet's rows, and this
    /// screen shows one field on purpose.
    @ViewBuilder
    private func note(_ exercise: Exercise, in day: WorkoutDay) -> some View {
        if let missing = missing(exercise) {
            Button { sheetTarget = ExerciseSheetTarget(day: day.id, exercise: exercise.id) } label: {
                HStack(spacing: 8) {
                    Text("\(exercise.equipment.screenName) · \(missing)")
                        .typography(Typography.meta())
                        .foregroundStyle(Color.dimText)
                    Text("›")
                        .typography(Typography.body(13))
                        .foregroundStyle(Color.labelText)
                    Spacer(minLength: 0)
                }
                .frame(height: 22)
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
        } else {
            Text(exercise.equipment.screenName)
                .typography(Typography.meta())
                .foregroundStyle(Color.dimText)
                .frame(height: 22)
        }
    }

    /// One clause, and the one that bites soonest. A Base Weight missing on a Smith makes
    /// every Plate Breakdown wrong; an Increment missing stops the Exercise progressing
    /// (§4.1); a Microloading Exercise with no Microplate is §5.2's empty state.
    private func missing(_ exercise: Exercise) -> String? {
        guard let resolved = resolved(exercise.id) else { return nil }
        if resolved.equipment.takesBaseWeight, resolved.baseWeight == nil { return "no base weight" }
        switch resolved.mode {
        case .none:
            return nil
        case .progressiveOverload:
            return resolved.increment == nil ? "no increment" : nil
        case .microloading:
            return resolved.microloadingIncrement == nil ? "no microplate" : nil
        }
    }

    // MARK: - Plain parts

    private var intro: String {
        let left = store.logbook.map { Rules.reweighList(in: $0).count } ?? 0
        let done = frozen.count - left
        guard done > 0 else {
            return "An exercise with no weight logs no set and does not progress. "
                + "Type what you lift it with now."
        }
        return left == 0
            ? "Every exercise has a weight."
            : "\(done) of \(frozen.count) done. \(left) still \(left == 1 ? "has" : "have") no weight."
    }

    private func binding(_ id: ExerciseID) -> Binding<String> {
        Binding(get: { text[id] ?? "" }, set: { text[id] = $0 })
    }

    private func resolved(_ id: ExerciseID) -> ResolvedExercise? {
        store.logbook?.resolvedExercise(id)
    }
}
