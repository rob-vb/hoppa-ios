import SwiftUI
import HoppaRules
import HoppaStore

// Ticket 0048 — §6.7's Workout detail, and the one delete in Hoppa that destroys something.
//
// **This is not the Summary, and it is not built out of the Summary's parts.** §6.5 is a
// verdict on a session that has just ended — a count as the hero, three sections, a
// condition line under every stayed Exercise, `NEXT TIME` beside every green one. §6.7 is
// a *record*: one Exercise after another in the order performed, every Set listed with the
// weight it was lifted at, and the progression it earned stated on the right.
//
// That is what dissolves the staleness this ticket was written for. **A past Workout
// states no future**, so nothing on this screen can go out of date; and the one number
// about the past that *would* have drifted — the weight the Exercise ended on — is now
// recorded at Finish (`ProgressionOutcome`, §2.4). The view holds no arithmetic:
// `Rules.pastWorkout(_:in:)` decides every verdict and every Set mark.
//
// Three things this screen decided, because §6.7 and the artboard left them open. Each is
// a judgment call, and each is on the walk list.
//
// - **The confirm is Hoppa's own sheet, not a `confirmationDialog`.** Every other confirm
//   in the app is the system's — §6.6 does not paint them. §6.7 paints this one: the
//   `DELETE` wears the 25 kg red `#C8322B`, deliberately, to fix the boundary of §7.1's
//   first rule. A system dialog cannot carry that red, and the artboard draws a Hoppa
//   sheet. So this one confirm is drawn, and the other four stay as they are.
// - **A Skipped Exercise reads `SKIPPED` in the label grey, with no Set rows.** The
//   artboard's Workout has none in it. §6.5 lists a skip plain — no warning colour, no
//   icon, no invitation to fix — and that is what this is.
// - **The `•••` menu holds one item.** §6.7 gives it nothing else, and a menu of one is
//   still what the artboard draws. It stays a menu rather than becoming a `DELETE` button,
//   because a destructive action one tap from a scroll is not what §6.6 does anywhere.
//
// Artboards: `design/0015-history/Workout.dc.html` and `Delete.dc.html`.

struct PastWorkoutScreen: View {
    @Environment(LogbookStore.self) private var store
    @Binding var path: [Route]
    let workoutId: WorkoutID

    @State private var confirmingDelete = false

    private var past: PastWorkout? {
        store.logbook.flatMap { Rules.pastWorkout(workoutId, in: $0) }
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
        .sheet(isPresented: $confirmingDelete) {
            if let past {
                DeleteWorkoutSheet(row: past.row) { delete() }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let past {
            VStack(alignment: .leading, spacing: 0) {
                header(past)
                Text(past.workoutDayName)
                    .typography(Typography.display(25, tracking: 0.02))
                    .foregroundStyle(Color.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 16)
                Text(meta(past.row))
                    .typography(Typography.meta())
                    .foregroundStyle(Color.dimText)
                    .padding(.top, 7)
                list(past)
            }
        } else {
            // Deleted from under this screen, or a file that failed to load. The delete
            // itself pops the screen, so this is the race and not the ordinary way out.
            VStack(alignment: .leading, spacing: 16) {
                header(nil)
                Spacer()
                Text("That workout is gone.")
                    .typography(Typography.display(26))
                    .foregroundStyle(Color.text)
                Spacer()
            }
        }
    }

    // MARK: - The way back, and the ••• menu

    private func header(_ past: PastWorkout?) -> some View {
        HStack(spacing: 0) {
            StepHeader(label: "History", back: leave)
            if past != nil {
                Menu {
                    Button("Delete workout", role: .destructive) { confirmingDelete = true }
                } label: {
                    Text("•••")
                        .typography(Typography.body(17))
                        .foregroundStyle(Color.steel)
                        .frame(width: 44, height: 50, alignment: .trailing)
                        .contentShape(Rectangle())
                }
            }
        }
    }

    private func leave() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// **One door**, `LogbookStore.send` (ticket 26), and then off the screen: the row this
    /// was opened from no longer exists, so there is nothing left here to look at.
    private func delete() {
        Haptic.destroyed()
        store.send(.deleteWorkout(workoutId))
        leave()
    }

    /// `5 exercises · 15 sets`, and `· 1 skipped` only where there was one — **the list
    /// row's own line**, so the list and the screen it opens can never state two different
    /// numbers, and the confirm counts what the header counts.
    private func meta(_ row: HistoryRow) -> String {
        var parts = [
            row.exerciseCount == 1 ? "1 exercise" : "\(row.exerciseCount) exercises",
            row.setCount == 1 ? "1 set" : "\(row.setCount) sets"
        ]
        if row.skippedCount > 0 { parts.append("\(row.skippedCount) skipped") }
        return "\(PastWorkoutDate.full(row.startedAt)) · " + parts.joined(separator: " · ")
    }

    // MARK: - The Exercises, in the order they were performed

    private func list(_ past: PastWorkout) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(past.exercises) { exercise in
                    exerciseHead(exercise)
                    ForEach(exercise.sets) { set in setRow(set) }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .padding(.top, 4)
    }

    /// The name, and **the progression it earned** on the right (§6.7). A One-off replaces
    /// that verdict with a chip under the name, the way §6.5 does — in the past tense,
    /// because this Workout is over.
    @ViewBuilder
    private func exerciseHead(_ exercise: PastExercise) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(exercise.name)
                    .typography(Typography.display(16, tracking: 0.02))
                    .foregroundStyle(Color.text)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                verdict(exercise.progression)
            }
            if case .oneOff(let stayed) = exercise.progression {
                Chip(oneOffText(stayed), tone: .steel)
                    .padding(.top, 8)
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 2)
    }

    @ViewBuilder
    private func verdict(_ progression: PastProgression) -> some View {
        switch progression {
        case .wentUp(let from, let to):
            // The one green thing on the row, and §7.3 already gives green its meaning.
            // Without the recorded number the row still says it went up, rather than
            // inventing a weight from an Increment that has since moved.
            Text(to.map { "\(weightText(from)) → \(weightText($0))" } ?? "Went up")
                .typography(Typography.label(10, tracking: 0.12))
                .foregroundStyle(Color.go)
                .fixedSize(horizontal: false, vertical: true)
        case .stayed:
            verdictLabel("Stayed")
        case .skipped:
            verdictLabel("Skipped")
        case .oneOff:
            // The chip under the name carries it. Nothing here, so the name is not
            // competing with two statements about the same Exercise.
            EmptyView()
        case .gone:
            // Deleted mid-Workout: Finish wrote no outcome, so there is no verdict to
            // state and this says why the row has none (§2.7, and §6.5's own sentence).
            verdictLabel("Removed from the program")
        }
    }

    private func verdictLabel(_ text: String) -> some View {
        Text(text)
            .typography(Typography.label(10, tracking: 0.12))
            .foregroundStyle(Color.labelText)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func oneOffText(_ stayed: PastWeight?) -> String {
        guard let stayed else { return "One-off" }
        return "One-off · \(weightText(stayed)) stayed"
    }

    // MARK: - The Sets, exactly as they were logged

    /// The index, the reps, and the weight it was lifted at. **The reps are green where
    /// the Set met the threshold** — the same fact §6.7's Set grid fills a cell with, so
    /// the chart and this screen can never disagree, and never on a One-off.
    private func setRow(_ set: PastSet) -> some View {
        HStack(spacing: 0) {
            Text("\(set.id + 1)")
                .typography(Typography.meta())
                .foregroundStyle(Color.labelText)
                .frame(width: 26, alignment: .leading)
            Text("\(set.reps)")
                .typography(Typography.display(19, tracking: 0.02))
                .foregroundStyle(set.metThreshold ? Color.go : Color.text)
                .frame(width: 54, alignment: .leading)
            Text("Reps")
                .typography(Typography.label(9, tracking: 0.13))
                .foregroundStyle(Color.labelText)
            Spacer(minLength: 8)
            Text(weightText(set.weight))
                .typography(Typography.meta(13))
                .foregroundStyle(Color.rowText)
                .lineLimit(1)
        }
        .frame(height: 44)
    }

    /// `75 kg`, and `100 lbs + 1 kg` on a mixed-unit pin. **Never a total** (§4.2) — the
    /// two numbers keep their own units and Hoppa converts nothing the user can see.
    ///
    /// Written in sentence case, which is what a Set row prints: `90 lbs + 2.5 kg`, a
    /// number in a table. The verdict beside a name wears `Typography.label`, and that
    /// role uppercases the same string into `25 → 27.5 KG`.
    private func weightText(_ value: PastWeight) -> String {
        var text = "\(value.weight.decimalString) \(value.weight.unit.rawValue)"
        if let micro = value.microload, !micro.isZero {
            text += " + \(micro.decimalString) \(micro.unit.rawValue)"
        }
        return text
    }
}

// MARK: - The confirm (§6.7)

/// **It states both halves before the tap**: what is removed, and that the working weights
/// stay. The second sentence is the one that matters — Hoppa applied the progression at
/// Finish and never lowers a weight by itself (§4.1), and recomputing the chain would
/// reach past any weight the user has since set by hand (§4.3). The user restores one
/// himself if he wants to.
///
/// The `DELETE` wears the 25 kg plate red, and §6.7 says why that is allowed: **a plate
/// colour is a plate only inside a Plate Breakdown.** Nothing near this button is a
/// drawing of a bar, so outside one the palette is simply Hoppa's palette.
struct DeleteWorkoutSheet: View {
    @Environment(\.dismiss) private var dismiss
    let row: HistoryRow
    let confirm: () -> Void

    var body: some View {
        ZStack {
            Color.floor.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Text("Delete this workout?")
                    .typography(Typography.display(22, tracking: 0.03))
                    .foregroundStyle(Color.text)
                Text(removes)
                    .typography(Typography.body(13, lineSpacing: 5))
                    .foregroundStyle(Color.rowText)
                    .padding(.top, 14)
                Text("Your working weights stay where they are.")
                    .typography(Typography.body(13, lineSpacing: 5))
                    .foregroundStyle(Color.steel)
                    .padding(.top, 10)
                HStack(spacing: 10) {
                    button("Cancel", fill: nil) { dismiss() }
                    button("Delete", fill: Color.stop) {
                        dismiss()
                        confirm()
                    }
                }
                .padding(.top, 20)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 22)
        }
        .presentationDetents([.height(260)])
        .presentationDragIndicator(.visible)
    }

    /// The counts are the list row's, so the confirm removes exactly what the header above
    /// it said was there. A skip is named separately or not at all, the way it is
    /// everywhere else — it holds no Sets, and this sentence is about what is destroyed.
    private var removes: String {
        let exercises = row.exerciseCount == 1 ? "1 exercise" : "\(row.exerciseCount) exercises"
        let sets = row.setCount == 1 ? "1 set" : "\(row.setCount) sets"
        return "This removes \(exercises) and \(sets) from your history."
    }

    private func button(_ title: String, fill: Color?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .typography(Typography.display(16, tracking: 0.06))
                .foregroundStyle(fill == nil ? Color.text : Color.floor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(fill ?? Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(fill ?? Color.line, lineWidth: 1))
        }
        .buttonStyle(.pressable)
    }
}

// MARK: - The date at the head of the screen

/// **The app's, not a rule's** — the same clause that keeps `RelativeDay`, `Streak` and
/// `HistoryDate` out of `HoppaRules`. A date is a calendar and a zone.
enum PastWorkoutDate {
    /// `3 AUG 2026`. The year is always written here, unlike the list's two-line date:
    /// this screen shows one Workout with nothing to compare it against, so the row's
    /// "same year, drop the year" shorthand has nothing to lean on.
    ///
    /// **The three fields are composed here rather than asked for as one**, which is what
    /// `HistoryDate` already does for the same reason: `.dateTime.day().month().year()`
    /// orders itself by the phone's locale, and on a US one it answers `Aug 3, 2026`. The
    /// artboard writes day, month, year, and this screen is not the place a Program's
    /// dates start reading in two different orders.
    static func full(_ timestamp: Timestamp) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        return [
            date.formatted(.dateTime.day()),
            date.formatted(.dateTime.month(.abbreviated)),
            date.formatted(.dateTime.year())
        ].joined(separator: " ").uppercased()
    }
}
