/// Everything a Workout can be told to do.
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
}
