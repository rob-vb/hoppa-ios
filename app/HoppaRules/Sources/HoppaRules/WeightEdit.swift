/// What a weight typed at the rack does (`SPEC.md` §4.3).
public enum WeightEdit: Sendable, Hashable {
    /// The number did not move. Nothing is written — writing it would clear a standing
    /// One-off Weight for no reason.
    case unchanged
    /// **Raising always sticks, with no question**: `.setWorkingWeight`, and the sheet
    /// closes at once.
    case sticks
    /// **Lowering asks once** — *Just today, or from now on?* The answer is the user's,
    /// and it is `.setOneOffWeight` or `.setWorkingWeight`.
    case asks
}

extension Rules {

    /// Does this edit stick, or does it ask? (`SPEC.md` §4.3)
    ///
    /// A rule by the map's own test: it falls out of the `Logbook` alone, and two lifters
    /// with the same `Logbook` typing the same number must be asked the same question.
    /// It lived in a view in the prototype, which is why the prototype gets it wrong.
    ///
    /// **The question guards the Working Weight, not the big number.** §4.3 gives its own
    /// reason in the same breath as the rule: *without the prompt, dropping 100 → 90
    /// because of illness erases the record of 100*. So the test is whether the write
    /// would move the **Working Weight** down — which is the same test as "is it lower
    /// than what I am lifting" right up until a One-off Weight stands.
    ///
    /// Under a One-off of 65 kg on a 72.5 kg Exercise, typing 70 reads as a raise against
    /// the big number. But a raise sticks by writing the Working Weight, and that write
    /// clears the One-off — so the record would go 72.5 → 70 with no question asked, which
    /// is the exact case §4.3 exists to prevent. `SPEC.md` §8.2 carries the row; the
    /// prototype compares against the performed weight.
    ///
    /// An Exercise with no Working Weight is neither raising nor lowering: there is
    /// nothing to come down from, so the first number typed sticks (§2.8).
    public static func weightEdit(
        _ typed: Weight,
        performed: PerformedExercise,
        exercise: ResolvedExercise
    ) -> WeightEdit {
        // Not a weight. The sheet refuses it before this, and the actions refuse it after.
        guard typed.hundredths > 0 else { return .unchanged }

        let performedAt = (performed.oneOffWeight ?? exercise.workingWeight)?
            .relabelled(exercise.unit)
        if typed == performedAt { return .unchanged }

        guard let working = exercise.workingWeight, typed < working else { return .sticks }
        return .asks
    }
}
