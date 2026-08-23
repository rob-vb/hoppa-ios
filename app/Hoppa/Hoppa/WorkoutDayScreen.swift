import SwiftUI
import HoppaRules
import HoppaStore

// Ticket 0034 — one Workout Day, and the Exercises in it.
//
// The room under the hub. It draws the Day's Exercise list, `ADD AN EXERCISE`, and the
// way back. **Reorder handles and deleting an Exercise are not here** — both mirror into
// an Open Workout, and `HoppaRules` has held those rules since ticket 0028 waiting for
// Flow 5's own screen.
//
// Two things the artboard draws that this does not, and both are named in the hand-off so
// they are never read as defects:
//
// - **The sparkline on an Exercise card** (§6.7). It is a door to a chart that does not
//   exist: Flow 4 is not scheduled. Drawing the door without the room would be the one
//   thing ticket 0032 refused.
// - **The Exercise card opens the sheet, not the chart.** §6.7 says an Exercise card in
//   the Program sheet opens that Exercise's chart; the Day artboard's own caption says
//   *tap a row to open it*, and the sheet is the only room that will exist. Recorded as a
//   finding on the map rather than settled here.
//
// Artboard: `design/0006-onboarding/Day.dc.html`.

struct WorkoutDayScreen: View {
    @Environment(LogbookStore.self) private var store
    @Binding var path: [Route]
    let workoutDayId: WorkoutDayID

    @State private var renaming = false
    /// Ticket 0035's sheet. `nil` while it is closed; the Exercise it opens on when it is
    /// an edit, and `.some(nil)` — a target with no Exercise — when it is an add.
    @State private var sheetTarget: ExerciseSheetTarget? = nil

    /// The Day **with the Program that holds it**: the header draws the Program's Name,
    /// and every Exercise resolves against the Program's Mode and the rack (§5.1).
    private var found: (program: Program, day: WorkoutDay)? {
        store.logbook?.workoutDay(workoutDayId)
    }

    private var rack: PlateInventory { store.logbook?.plateInventory ?? .standard(.kg) }

    var body: some View {
        ZStack {
            Color.floor.ignoresSafeArea()
            if let found {
                content(found.program, found.day)
                    .padding(.horizontal, 20)   // §7.4 screen padding
                    .padding(.bottom, 20)
            } else {
                gone
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $renaming) {
            NameSheet(
                heading: "Rename the day",
                confirm: "Save the name",
                hint: "Renaming changes nothing else. Finished workouts keep the name they were logged with.",
                initial: found?.day.name ?? ""
            ) { name in
                store.send(.renameWorkoutDay(workoutDayId, name: name))
            }
        }
        // Ticket 0035 lands §6.2's full sheet here, and this is the only line that
        // changes: **add and edit are the same sheet**, so one presentation serves both.
        .sheet(item: $sheetTarget) { target in
            NotBuiltYet(
                screen: target.exercise == nil
                    ? "The Exercise sheet — every field of a new exercise, picked by hand."
                    : "The Exercise sheet. Add and edit are the same sheet, and neither is built.",
                ticket: "0035")
        }
    }

    @ViewBuilder
    private func content(_ program: Program, _ day: WorkoutDay) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            StepHeader(label: program.name, back: { if !path.isEmpty { path.removeLast() } })
            title(day)
            Spacer().frame(height: 8)
            Text(meta(day))
                .typography(Typography.label(10.5, tracking: 0.12))
                .foregroundStyle(Color.dimText)
            Spacer().frame(height: 16)
            list(program, day)
            Spacer(minLength: 12)
            PrimaryButton("Day done") { if !path.isEmpty { path.removeLast() } }
        }
    }

    /// The Name, and the one way to correct it. A Name is a label (§2.7), so renaming is
    /// free and migrates nothing — but a typo made during onboarding needs somewhere to
    /// be fixed, and `RENAME` says so in a word rather than hiding behind a long press.
    private func title(_ day: WorkoutDay) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(day.name)
                .typography(Typography.display(31, tracking: 0.005))
                .foregroundStyle(Color.text)
                .lineLimit(2)
            Spacer(minLength: 8)
            Button { renaming = true } label: {
                Text("Rename")
                    .typography(Typography.label(10.5))
                    .foregroundStyle(Color.steel)
                    .frame(height: 50)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func meta(_ day: WorkoutDay) -> String {
        day.exercises.isEmpty
            ? "No exercises yet"
            : "\(day.exerciseCountText) · tap a row to open it"
    }

    // MARK: - The Exercises

    @ViewBuilder
    private func list(_ program: Program, _ day: WorkoutDay) -> some View {
        ScrollView {
            VStack(spacing: 6) {
                ForEach(day.exercises, id: \.id) { exercise in
                    row(exercise.resolved(in: program, inventory: rack))
                }
                AddRow("Add an exercise") {
                    sheetTarget = ExerciseSheetTarget(day: workoutDayId, at: day.exercises.count)
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func row(_ exercise: ResolvedExercise) -> some View {
        Button {
            sheetTarget = ExerciseSheetTarget(day: workoutDayId, exercise: exercise.id)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .typography(Typography.display(16))
                        .foregroundStyle(Color.text)
                        .lineLimit(1)
                    Text(line(exercise))
                        .typography(Typography.label(10, tracking: 0.12))
                        .foregroundStyle(Color.dimText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 8)
                weight(exercise)
            }
            .padding(.horizontal, 14)
            .frame(height: 62)
            .background(Color.card)
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.line, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// `barbell · 3 × 8–12 · +2.5`, and `base 15` where a Smith or a plate-loaded
    /// machine has one — the artboard's own line. The Stack Step is deliberately not on
    /// it: the artboard leaves it off, and a card that listed every conditional field
    /// would be the sheet with worse typography.
    ///
    /// Every clause is a stored field read off `ResolvedExercise`, and the Increment is
    /// printed as it is **held**, never as a jump this view worked out. A Microloading
    /// Increment moves a bar by twice the plate (§4.2) and rolls into a Stack Step on a
    /// mixed-unit pin, and `Progression.progressionMove` is where that lives — a card
    /// that did the multiplication itself would be a second copy of a rule.
    private func line(_ exercise: ResolvedExercise) -> String {
        var parts = [exercise.equipment.screenName.lowercased()]
        if let base = exercise.baseWeight {
            parts.append("base \(base.decimalString)")
        }
        parts.append("\(exercise.plannedSets) × \(exercise.repRange.bottom)–\(exercise.repRange.top)")
        switch exercise.mode {
        case .progressiveOverload:
            if let increment = exercise.increment { parts.append("+\(increment.decimalString)") }
        case .microloading:
            if let plate = exercise.microloadingIncrement {
                parts.append("+\(plate.decimalString) \(plate.unit.rawValue) plate")
            }
        }
        // §6.6: a Microplate switched off strands the Exercises using it, and a stranded
        // Exercise does not progress. No warning colour — the user threw the switch, and
        // §7.6 keeps colour off anything the user did. Switching it back on ends it.
        if exercise.isStranded { parts.append("stranded") }
        return parts.joined(separator: " · ")
    }

    /// The Working Weight, or `—`.
    ///
    /// **An unset weight is not zero** (§2.8): a new Exercise has none until the user
    /// types one, and §6.6 clears it back to unset. Printing `0` would claim a lift at an
    /// empty bar, so the card prints a dash and no unit — there is no number, so there is
    /// nothing for a unit to qualify.
    @ViewBuilder
    private func weight(_ exercise: ResolvedExercise) -> some View {
        if let working = exercise.workingWeight {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(working.decimalString)
                    .typography(Typography.display(22))
                    .foregroundStyle(Color.text)
                Text(exercise.unit.rawValue)
                    .typography(Typography.label(10, tracking: 0.12))
                    .foregroundStyle(Color.dimText)
            }
        } else {
            Text("—")
                .typography(Typography.display(22))
                .foregroundStyle(Color.labelText)
        }
    }

    // MARK: - Plain parts

    private var gone: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("That day is gone.")
                .typography(Typography.display(26))
                .foregroundStyle(Color.text)
            PrimaryButton("Back") { if !path.isEmpty { path.removeLast() } }
        }
        .padding(.horizontal, 20)
    }
}

/// What ticket 0035's sheet opens on: a Day and a position for an add, a Day and an
/// Exercise for an edit.
///
/// It is a `sheet(item:)` and not a `Route` because §6.2's sheet **is a sheet** — it sits
/// over the list it edits and hands the list back on save. A pushed screen would put a
/// second back chevron in front of the same Day.
struct ExerciseSheetTarget: Identifiable, Hashable {
    let day: WorkoutDayID
    /// `nil` on an add. Add and edit are the same sheet (§6.2).
    var exercise: ExerciseID? = nil
    /// Where an added Exercise lands. Ignored on an edit.
    var at: Int = 0

    var id: String { "\(day.value)-\(exercise?.value.description ?? "new")-\(at)" }
}
