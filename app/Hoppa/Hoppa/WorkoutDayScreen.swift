import SwiftUI
import HoppaRules
import HoppaStore

// Ticket 0034 — one Workout Day, and the Exercises in it.
//
// The room under the hub. It draws the Day's Exercise list, `ADD AN EXERCISE`, and the
// way back. **Reorder handles are here as of ticket 0044**, on `ReorderColumn`: the drop
// sends `.moveExercise`, and the rule that mirrors it into an Open Workout — keeping the
// user on the Exercise he was standing at and not on the position (§6.4) — has been in
// `HoppaRules` since ticket 0028 and is proved by four tests written for 0044.
// Deleting an Exercise **is** here as of ticket 0035, on the sheet the artboard draws it
// on: `REMOVE EXERCISE` is the Exercise sheet's own bottom control, §6.6 gives the delete
// no block to state, and a card that opens a sheet with no way to remove what it opened
// is a door with half a room behind it.
// **Deleting the Day landed at ticket 0045**, and it is the one delete with blocks to
// state: `REMOVE DAY` sits at the foot of this screen, above `DAY DONE`, because this is
// the room for one Day exactly as the sheet is the room for one Exercise. It is never
// disabled — see `removeRow` for why, and for where the two refusals are printed.
//
// **The card is grip and sheet, and nothing else.** Between tickets 0050 and 0058 it had a
// third region: §6.7 had put the door to an Exercise's chart on this card, as a sparkline
// on the trailing edge, and ticket 0050 made the mark the door — for three reasons that
// still hold for *which half of a card* should open the sheet. An Exercise card is edited
// far more often than it is charted; the mark announced itself; and a card with nothing to
// plot offered no empty room. What those reasons never settled was *where the chart is
// reached from*, and this screen was the wrong room for it: it is the room for building a
// Day, nobody looks for a statistic on the trailing edge of a card here, and it split
// Flow 4 across two kinds of door that did not rhyme — History a row at the foot of the
// picker, the chart a sliver on a card one room down.
//
// **Ticket 0058 moved the door.** The chart is reached from the Progress page, a sibling of
// History at the foot of the picker, where every trained Exercise is a row and the whole
// row is the door. The sparkline left this card with it. So the caption under the Day's
// Name — `5 exercises · tap a row to open it` — is fully true again: a tap anywhere the
// grip is not opens §6.2's sheet, and there is no second thing a tap might do.
//
// **Where §6.7's "Program sheet" actually is.** §6.7 puts the Exercise card in the Program
// sheet; in this app the Program sheet lists Workout *Days*, and Exercise cards are here.
// The artboard settles it — `design/0015-history/Program.dc.html` is headed
// `‹ Upper / Lower · Upper A · 5 exercises`, which is this screen. `SPEC.md` §6.7 carries
// the correction. That artboard also draws the sparkline on the card; it is historical.
//
// Artboard: `design/0006-onboarding/Day.dc.html`.

struct WorkoutDayScreen: View {
    @Environment(LogbookStore.self) private var store
    @Binding var path: [Route]
    let workoutDayId: WorkoutDayID

    @State private var renaming = false
    /// Ticket 0045's confirm. Plain, with **no** count of destroyed Sets, because nothing
    /// is destroyed (§6.6).
    @State private var removeDialog = false
    /// Set by a `REMOVE DAY` that the rule refused, cleared the moment the rule stops
    /// refusing. §5.2's principle, the same shape `NameYourProgram` gives `CONTINUE`:
    /// **Hoppa never disables the control and never hides the reason** — it states the
    /// condition where the user taps, before he commits to anything.
    @State private var refused = false
    /// Ticket 0035's sheet. `nil` while it is closed; the Exercise it opens on when it is
    /// an edit, and `.some(nil)` — a target with no Exercise — when it is an add.
    @State private var sheetTarget: ExerciseSheetTarget? = nil
    /// True while a reorder handle is held, so the ScrollView stops (ticket 0054).
    @State private var isReordering = false

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
        .confirmationDialog(
            "Remove this day?", isPresented: $removeDialog, titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) { remove() }
            Button("Cancel", role: .cancel) {}
        } message: {
            // §6.6, and the same sentence the Exercise sheet's own confirm prints, with
            // the one clause a Day adds: the Workout keeps the Day's Name too (§2.4).
            Text("It leaves the program from today. Finished workouts keep their name and the sets you logged.")
        }
        // Ticket 0035 landed §6.2's full sheet here, and ticket 0034's line held: **add
        // and edit are the same sheet**, so one presentation serves both.
        .sheet(item: $sheetTarget) { target in
            if let found {
                ExerciseSheet(
                    target: target,
                    initial: initialDraft(target, found.program, found.day),
                    carriedOver: target.exercise == nil
                        && carrySource(found.program, found.day, at: target.at) != nil)
            }
        }
    }

    // MARK: - What the sheet opens on (§6.2)

    /// An edit opens on the Exercise; an add opens on **the two fields §6.2 carries
    /// over** and nothing else.
    ///
    /// The carry-over is a **pre-filled field and not a rule**: it decides nothing that is
    /// stored, the user changes it with two taps, and it is gone the moment the sheet
    /// saves. Where it comes from is the whole of it — see `carrySource`.
    private func initialDraft(
        _ target: ExerciseSheetTarget, _ program: Program, _ day: WorkoutDay
    ) -> ExerciseDraft {
        if let id = target.exercise, let exercise = program.exercise(id) {
            return ExerciseDraft(exercise, in: rack)
        }
        let previous = carrySource(program, day, at: target.at)
        return ExerciseDraft(
            name: "",
            // Nothing is lit until the user picks one — `ExerciseSheet` holds *unpicked*
            // in view state, because a draft is the value a rule consumes and a rule is
            // never handed half an Exercise.
            equipment: .barbell,
            ownWeightUnit: program.defaultWeightUnit,
            // The first Exercise of the first Day has nothing behind it. Three sets of
            // 8–12 is the artboard's own row and §4's worked example; the sheet says
            // `CARRIED OVER` only where something really was.
            plannedSets: previous?.plannedSets ?? 3,
            repRange: previous?.repRange ?? RepRange(8, 12),
            // **The unit the sheet draws at open**, which on an add is the Program's
            // default: no Equipment Type is picked yet, so there is nothing to resolve and
            // §2.1's default is what the row shows. Not `rack.unit` — that is what the
            // *first pick* will resolve to, and the two come apart in a Program whose
            // default is not the rack's unit, where a weight typed before the pick would
            // then be thrown away at the save (ticket 0043).
            //
            // `ExerciseSheet` moves this with the unit row from here, because a number
            // typed under one label is not a number under the other (§6.6).
            shownUnit: program.defaultWeightUnit)
    }

    /// The Exercise before this one: the one above it in the Day, or — for the first
    /// Exercise of a Day — the last Exercise of the Day before it. A second Workout Day
    /// usually opens on the same kind of work as the first, and asking for `3 × 8–12`
    /// again at the top of every Day is four of the 400 taps for nothing.
    private func carrySource(_ program: Program, _ day: WorkoutDay, at index: Int) -> Exercise? {
        if index > 0, index <= day.exercises.count { return day.exercises[index - 1] }
        guard let position = program.days.firstIndex(where: { $0.id == day.id }) else { return nil }
        for earlier in program.days[..<position].reversed() {
            if let last = earlier.exercises.last { return last }
        }
        return nil
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
            removeRow
            Spacer().frame(height: 10)
            PrimaryButton("Day done") { if !path.isEmpty { path.removeLast() } }
        }
    }

    // MARK: - Removing the Day (§6.6)

    /// Why this Day cannot be deleted, or `nil` when it can. **The rule, asked before the
    /// tap** — `Rules.deleteBlock` is the very same call `Action.deleteWorkoutDay` guards
    /// itself with, so the sentence under the control and the refusal inside the rule can
    /// never come apart.
    private var block: DeleteBlock? {
        guard let logbook = store.logbook else { return nil }
        return Rules.deleteBlock(forWorkoutDay: workoutDayId, in: logbook)
    }

    /// `REMOVE DAY`, and the reason it refused.
    ///
    /// **Where it lives**: here, on the room for one Day — the mirror of `REMOVE EXERCISE`
    /// on the Exercise sheet, which is the room for one Exercise. Not a swipe and not a
    /// `•••` on the hub's row: a swipe hides the control, a `•••` puts it on a row that
    /// already has a grip on its leading edge and a tap through its middle, and §6.6's
    /// block has to be **read** before it can do its job. A word in a room has space for a
    /// sentence beside it; a gesture has none.
    ///
    /// **How it refuses**: it stays live and answers in place. The line under it is the
    /// reason, in the stop red, and it goes the moment the rule stops refusing — which
    /// happens elsewhere, at Finish or at `ADD A DAY`, so it is read off the rule on every
    /// pass rather than remembered.
    @ViewBuilder
    private var removeRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                if block == nil { removeDialog = true } else { refused = true }
            } label: {
                Text("Remove day")
                    .typography(Typography.label(11))
                    .foregroundStyle(Color.steel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.chipBorder, lineWidth: 1))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
            if refused, let block {
                Text(block.reason)
                    .typography(Typography.body(12, lineSpacing: 3))
                    .foregroundStyle(Color.stop)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        // A Day whose block has just ended stops shouting about it without a tap.
        .onChange(of: block) { if block == nil { refused = false } }
    }

    /// The Day is gone, so the room for it is gone: this screen pops to the hub that drew
    /// the row. The rule guards itself, so a refusal that reached here would leave the
    /// user on a Day that still exists — which is why the tap above never sends one.
    private func remove() {
        Haptic.destroyed()
        store.send(.deleteWorkoutDay(workoutDayId))
        if !path.isEmpty { path.removeLast() }
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
            .buttonStyle(.pressable)
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
                // §6.6: the handles reorder the **Day**, and the Open Workout follows.
                // The rule owns all of that; this hands it an id and a position.
                ReorderColumn(
                    items: day.exercises, id: \.id, isReordering: $isReordering
                ) { (id: ExerciseID, to: Int) in
                    store.send(.moveExercise(id, to: to))
                } row: { (exercise: Exercise, _: Int) in
                    row(exercise.resolved(in: program, inventory: rack))
                }
                AddRow("Add an exercise") {
                    sheetTarget = ExerciseSheetTarget(day: workoutDayId, at: day.exercises.count)
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        // Ticket 0054, and the same reason as the Program sheet: a held handle pins the
        // list, because a reorder and a scroll must never run at the same time.
        .scrollDisabled(isReordering)
    }

    /// The card's content only: `ReorderColumn` owns the card itself, and the handle on
    /// the leading edge owns the drag. So the tap target stops where the handle starts and
    /// the two never fight — the row opens the sheet, everywhere the grip is not.
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
            .padding(.trailing, 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
    }

    /// `barbell · 3 × 8–12 · +2.5`, and `base 15` where a Machine (Plates)
    /// has one — the artboard's own line. The Stack Step is deliberately not on
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
        case .none:
            break
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
