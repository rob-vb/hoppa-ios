import Testing
import HoppaRules

/// §4.3 — changing the weight by hand, and the one question Hoppa asks about it.
///
/// The weight sheet is a keypad and a stepper; **the decision under it is a rule**, and it
/// is here rather than in the view because two lifters with the same `Logbook` typing the
/// same number must be asked the same question. Ticket 0037 found it in a view.
///
/// > Decision record: [The weight sheet](../../../../issues/0037-the-weight-sheet.md).
@Suite("SPEC.md §4.3 — raising sticks, lowering asks")
struct WeightEditTests {

    /// The Barbell row: 60 kg, kg rack, Progressive Overload.
    private func rowAt(_ session: Session) -> (PerformedExercise, ResolvedExercise) {
        (session.performed(Ids.row)!, session.resolved(Ids.row)!)
    }

    @Test("Raising sticks, with no question")
    func raising() {
        var session = Session()
        session.start()
        session.goTo(Ids.row)
        let (performed, exercise) = rowAt(session)
        #expect(Rules.weightEdit(kg("65"), performed: performed, exercise: exercise) == .sticks)
    }

    @Test("Lowering asks once")
    func lowering() {
        var session = Session()
        session.start()
        session.goTo(Ids.row)
        let (performed, exercise) = rowAt(session)
        #expect(Rules.weightEdit(kg("55"), performed: performed, exercise: exercise) == .asks)
    }

    @Test("The same number moves nothing, so nothing is written")
    func unchanged() {
        var session = Session()
        session.start()
        session.goTo(Ids.row)
        let (performed, exercise) = rowAt(session)
        #expect(Rules.weightEdit(kg("60"), performed: performed, exercise: exercise) == .unchanged)
    }

    /// **§8.2's tenth defect.** Under a One-off Weight the prototype compares against the
    /// big number, so 70 reads as a raise — and a raise sticks by writing the Working
    /// Weight, which would take the record 72.5 → 70 with nothing asked.
    @Test("A raise above a One-off that still lowers the Working Weight asks")
    func raiseAboveOneOffThatLowersTheRecord() {
        var session = Session()
        session.start()
        session.send(.setOneOffWeight(kg("65")))

        let performed = session.performed(Ids.smith)!
        let exercise = session.resolved(Ids.smith)!
        #expect(performed.oneOffWeight == kg("65"))
        #expect(exercise.workingWeight == kg("72.5"))

        // Above what he is lifting today, below the record. The question is asked.
        #expect(Rules.weightEdit(kg("70"), performed: performed, exercise: exercise) == .asks)
        // Above the record. It sticks.
        #expect(Rules.weightEdit(kg("75"), performed: performed, exercise: exercise) == .sticks)
        // The One-off itself. Nothing moved.
        #expect(Rules.weightEdit(kg("65"), performed: performed, exercise: exercise) == .unchanged)
    }

    /// **An unset weight is not zero** (§2.8). There is nothing to come down from, so the
    /// first number typed is neither a raise nor a lowering — it simply sticks.
    @Test("The first weight an Exercise ever gets never asks")
    func firstWeightSticks() {
        var book = upperALogbook()
        book.updateExercise(Ids.row) { $0.workingWeight = nil }
        var session = Session(book)
        session.start()
        session.goTo(Ids.row)
        let (performed, exercise) = rowAt(session)
        #expect(exercise.workingWeight == nil)
        #expect(Rules.weightEdit(kg("60"), performed: performed, exercise: exercise) == .sticks)
    }

    @Test("Zero is not a weight")
    func zeroIsNotAWeight() {
        var session = Session()
        session.start()
        session.goTo(Ids.row)
        let (performed, exercise) = rowAt(session)
        #expect(Rules.weightEdit(kg("0"), performed: performed, exercise: exercise) == .unchanged)
    }

    // MARK: - What each answer writes

    @Test("From now on writes the Working Weight and clears the One-off")
    func fromNowOn() {
        var session = Session()
        session.start()
        session.send(.setOneOffWeight(kg("65")))
        session.send(.setWorkingWeight(kg("70")))
        #expect(session.stored(Ids.smith)?.workingWeight == kg("70"))
        #expect(session.performed(Ids.smith)?.oneOffWeight == nil)
    }

    /// A One-off never becomes the Working Weight and never progresses (§4.3).
    @Test("Just today leaves the Working Weight where it was")
    func justToday() {
        var session = Session()
        session.start()
        session.send(.setOneOffWeight(kg("65")))
        session.logSets(3)
        // The other four Exercises are still Open, and Finish is gated on that (§3.3).
        session.send(.skipRemainingAndFinish)

        #expect(session.stored(Ids.smith)?.workingWeight == kg("72.5"))
        #expect(session.performed(Ids.smith)?.outcome?.progressed == false)
        #expect(session.performed(Ids.smith)?.sets.allSatisfy(\.oneOff) == true)
    }

    // MARK: - What the sheet steps by (§6.4)

    /// The `−` / `+` step by **what the rule moves the Working Weight by**, probed at
    /// zero — not by the Increment field. On a bar under Microloading those differ: the
    /// plate is 0.25 kg and the bar moves 0.5 kg, because a bar takes a pair (§4.2).
    @Test("A bar under Microloading steps by the pair, not the plate")
    func stepIsTheMove() {
        let book = upperALogbook()
        var probe = book.exercise(Ids.row)!
        probe.workingWeight = .zero(.kg)
        probe.modeOverride = .microloading

        let resolved = probe.resolved(mode: .microloading, inventory: book.plateInventory)
        #expect(resolved.microloadingIncrement == kg("0.25"))
        #expect(Rules.progressionMove(for: resolved, inventory: book.plateInventory)?
            .workingWeight == kg("0.5"))

        probe.modeOverride = .progressiveOverload
        let plain = probe.resolved(mode: .progressiveOverload, inventory: book.plateInventory)
        #expect(Rules.progressionMove(for: plain, inventory: book.plateInventory)?
            .workingWeight == kg("2.5"))
    }
}
