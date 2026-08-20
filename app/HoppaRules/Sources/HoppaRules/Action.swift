/// Everything Hoppa can be told to do.
///
/// It said *everything a Workout can be told to do* until §6.6's Program edits arrived,
/// and that was too small from the start: progression already wrote to the Program, and
/// `.setWorkingWeight` was already a Program edit made at the rack. There is **one door**
/// — `LogbookStore.send(Action)` — and nothing writes into a `Logbook` anywhere else.
///
/// The enum is **flat**: an edit case sits beside a logging case and names the id it acts
/// on, because §6.6 opens the same sheet from the kitchen table and from the rack. The
/// split lives in the file layout — `Rules+Edit.swift` beside `Rules.swift` — not here.
///
/// View state is **not** here. The prototype's reducer mixed real rules with the screen,
/// the overlay, the keypad buffer and a narration log; those stay in SwiftUI and cannot
/// fail a rules test. What the keypad produces arrives as a finished `Weight`, and the
/// rep counter arrives as `reps` on `.logSet`.
public enum Action: Sendable, Hashable {
    /// A Workout starts on an explicit action, never on the first logged Set (§3.1).
    case startWorkout(programId: ProgramID, workoutDayId: WorkoutDayID)
    /// Navigation. Leaving an Open Exercise means "later", so nothing about it changes.
    case selectExercise(index: Int)
    /// Move to the next Open Exercise, wrapping. Hoppa never jumps by itself (§6.4).
    case nextOpen
    case logSet(reps: Int)
    /// Complete an Exercise with fewer Sets than planned. Real work, so not a Skip —
    /// and it does not progress (§3.2, §4.1).
    case doneEarly
    /// Not at all, not later. Logs no Sets, never progresses, reversible in the same
    /// Workout (§3.2).
    case skip
    case reopen
    /// From now on. Raising always sticks; lowering has already been answered by the
    /// time this arrives (§4.3). An edit at the rack is a Program edit (§6.6).
    case setWorkingWeight(Weight)
    /// Just today. Hoppa logs its Sets, but it never becomes the Working Weight and it
    /// never progresses (§4.3).
    case setOneOffWeight(Weight)
    /// Gated: refused while any Exercise is Open (§3.3).
    case finish
    /// The one-tap way out of the gate: skip everything still Open, then finish.
    case skipRemainingAndFinish
    /// Ends the Workout and keeps nothing.
    case discard

    // MARK: - Flow 5, editing a Program (`SPEC.md` §6.6)
    //
    // Every one of these names its target. They are rules, not field writes: a raise to
    // the planned Sets reopens a Completed Exercise, a change of unit clears three fields
    // and destroys a Microload, and every structural edit mirrors into an Open Workout.
    //
    // > Decision record: [Program edits, and which of them are rules](../../../../issues/0026-program-edits-and-the-rules-boundary.md).

    /// A Program with no Workout Days yet. §6.1 sends `addWorkoutDay` next; a Program
    /// with no Days cannot be started, which is also why deleting the last one is blocked.
    case createProgram(name: String, defaultWeightUnit: WeightUnit, mode: ProgressionMode)
    /// Free, and it migrates nothing: a Name identifies nothing (§2.7).
    case renameProgram(ProgramID, name: String)
    /// The default for **new** Exercises only, so it touches nothing that exists (§2.1).
    case setProgramDefaultWeightUnit(ProgramID, WeightUnit)
    /// Changes the default only — an override is a deliberate act (§4.4) — and fills the
    /// default Microloading Increment on the Exercises that move and have none.
    case setProgramMode(ProgramID, ProgressionMode)

    case addWorkoutDay(programId: ProgramID, name: String)
    case renameWorkoutDay(WorkoutDayID, name: String)
    /// Cosmetic: a Workout records **which** Day was performed, and picking is a free
    /// pick with no rotation (§3.1).
    case moveWorkoutDay(WorkoutDayID, to: Int)
    /// Blocked while the Open Workout runs on it, and blocked on the last Day in a
    /// Program. `deleteBlock(forWorkoutDay:in:)` is the same rule, asked before the tap.
    case deleteWorkoutDay(WorkoutDayID)

    /// The whole sheet, saved in one act (§6.2 is Model B). **One action and not ten
    /// field writes**: §6.6's rules are a *diff*, and a sheet that changed the unit and
    /// typed the new weight would otherwise clear the weight it was just given.
    case addExercise(workoutDayId: WorkoutDayID, at: Int, draft: ExerciseDraft)
    case saveExercise(ExerciseID, draft: ExerciseDraft)
    /// The user does not move with it: Hoppa keeps him on the Exercise he was standing
    /// at, not the position he was standing in (§6.4).
    case moveExercise(ExerciseID, to: Int)
    /// It leaves the Program from today forward. Past Workouts keep their Sets (§2.8),
    /// and so does an Open Workout — where it stops holding the Finish gate (§6.6).
    case deleteExercise(ExerciseID)

    /// The full blast radius of §6.6: it clears the weight on every Exercise that reads
    /// its unit off the rack, resets every Microloading Increment, and creates or
    /// destroys the Microload on every pin.
    case setPlateInventoryUnit(WeightUnit)
    /// Writes nothing else. Stranding is **derived**, so switching a plate back on
    /// un-strands what it stranded (§6.6).
    case setPlate(Weight, on: Bool)
}
