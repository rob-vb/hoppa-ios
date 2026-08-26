import Testing
@testable import HoppaRules

/// `SPEC.md` §6.5 — the Workout Summary, read off a finished Workout.
///
/// The four artboards in `design/0009-summary/canvas/` are the reference, and the
/// fixture is the same Upper A they were drawn from, so each suite below names the
/// artboard it reproduces.
@Suite("SPEC.md §6.5 — the Workout Summary")
struct SummaryTests {

    /// Everything at the top of the range: walkthrough 1, and the `Main` artboard.
    private func mainScreen() -> (Logbook, WorkoutSummary) {
        var session = Session()
        session.start()
        session.logSets(3, reps: 12)                     // Smith bench, 8-12
        session.send(.nextOpen)
        session.logSets(3, reps: 10)                     // Barbell row, 8-10
        session.send(.nextOpen)
        session.logSets(3, reps: 12)                     // Lat pulldown, 10-12
        session.send(.nextOpen)
        session.logSets(3, reps: 12)                     // Dumbbell press, 8-12
        session.send(.nextOpen)
        session.logSets(3, reps: 8)                      // Chin-up, 6-8
        session.send(.finish)
        return (session.book, Rules.summary(of: session.lastFinished!, in: session.book))
    }

    // MARK: - The hero and the three sections

    @Test("Main — five went up, nothing stayed, nothing skipped")
    func mainArtboard() {
        let (_, summary) = mainScreen()
        #expect(summary.workoutDayName == "Upper A")
        #expect(summary.count == 5)
        #expect(summary.stayed.isEmpty)
        #expect(summary.skipped.isEmpty)
        #expect(summary.wentUp.map(\.name) == [
            "Smith machine bench press", "Barbell row", "Lat pulldown",
            "Dumbbell shoulder press", "Weighted chin-up"])
    }

    @Test("A went-up row states what was lifted and what Hoppa already wrote")
    func wentUpArrow() {
        let (_, summary) = mainScreen()
        let bench = summary.wentUp[0]
        #expect(bench.from.weight == kg("72.5"))
        #expect(bench.from.microload == nil)
        #expect(bench.to.weight == kg("75"))
        #expect(bench.to.microload == nil)
    }

    /// §4.2's own example, at the other end of the roll-up: two numbers, two units, and
    /// **no total anywhere**.
    @Test("A mixed-unit pin stacks two numbers and converts neither")
    func mixedUnitRow() {
        let (_, summary) = mainScreen()
        let pulldown = summary.wentUp[2]
        #expect(pulldown.from.weight == lbs("100"))
        #expect(pulldown.from.microload == kg("1"))
        #expect(pulldown.to.weight == lbs("100"))
        #expect(pulldown.to.microload == kg("2"))
    }

    // MARK: - The added plate (§6.5, §7.3)

    /// **A bar takes a pair** (§4.2), so a 2.5 kg Increment is a 1.25 kg plate per side —
    /// light grey, not the mid grey of the 2.5. The `Main` artboard paints every bar row
    /// red, which is the prototype's invented palette (§8.2) and does not port.
    @Test("Progressive Overload on a bar adds half the Increment")
    func addedPlateOnABar() {
        let (book, summary) = mainScreen()
        #expect(summary.wentUp[0].addedPlate == kg("1.25"))          // Smith
        #expect(summary.wentUp[1].addedPlate == kg("1.25"))          // Barbell row
        #expect(PlatePalette.hex(for: kg("1.25")) == "#70767C")
        _ = book
    }

    @Test("Everything else takes one plate, and Microloading's Increment is one already")
    func addedPlateElsewhere() {
        let (_, summary) = mainScreen()
        #expect(summary.wentUp[2].addedPlate == kg("1"))             // pulldown, Microloading
        #expect(summary.wentUp[3].addedPlate == kg("2.5"))           // dumbbell, one plate
        #expect(summary.wentUp[4].addedPlate == kg("2.5"))           // bodyweight, the belt
        #expect(PlatePalette.hex(for: kg("1")) == "#C8322B")
    }

    @Test("An Increment that does not halve into a plate names none")
    func addedPlateThatIsNoPlate() {
        var book = upperALogbook()
        book.updateExercise(Ids.row) { $0.increment = kg("2.55") }
        let exercise = book.resolvedExercise(Ids.row)!
        #expect(Rules.addedPlate(for: exercise) == nil)
    }

    // MARK: - STAYED states the condition (§6.5)

    /// The `Nothing` artboard: four performed, none progressed, one skipped.
    @Test("Nothing — every stayed row restates the logging screen's chip")
    func nothingArtboard() {
        var session = Session()
        session.start()
        session.logSets(3, reps: 11)                     // Smith bench, short of 12
        session.send(.nextOpen)
        session.logSets(3, reps: 9)                      // Barbell row, short of 10
        session.send(.nextOpen)
        session.logSets(3, reps: 9)                      // Lat pulldown, short of 10
        session.send(.nextOpen)
        session.logSets(3, reps: 10)                     // Dumbbell press, short of 12
        session.send(.nextOpen)
        session.send(.skip)                              // Weighted chin-up
        session.send(.finish)

        let summary = Rules.summary(of: session.lastFinished!, in: session.book)
        #expect(summary.count == 0)
        #expect(summary.performedCount == 4)
        #expect(summary.skipped.map(\.name) == ["Weighted chin-up"])

        let bench = summary.stayed[0]
        #expect(bench.performed?.weight == kg("72.5"))
        #expect(bench.reps == [11, 11, 11])
        #expect(bench.condition == .target(
            sets: 3, reps: 12, to: SummaryWeight(weight: kg("75"))))

        // Microloading reads the **bottom** of the range, and the pin's target keeps its
        // two units apart.
        let pulldown = summary.stayed[2]
        #expect(pulldown.condition == .target(
            sets: 3, reps: 10,
            to: SummaryWeight(weight: lbs("100"), microload: kg("2"))))
    }

    /// The `Mixed` artboard's Dumbbell press: three perfect Sets under a One-off Weight
    /// progress nothing, and the row says which weight survives.
    @Test("A One-off replaces the condition and shows the weight actually lifted")
    func oneOffRow() {
        var session = Session()
        session.start()
        session.goTo(Ids.press)
        session.send(.setOneOffWeight(kg("20")))
        session.logSets(3, reps: 12)
        session.send(.skipRemainingAndFinish)

        let summary = Rules.summary(of: session.lastFinished!, in: session.book)
        let press = summary.stayed.first { $0.exerciseId == Ids.press }!
        #expect(press.performed?.weight == kg("20"))         // lifted, not the 22.5 that stays
        #expect(press.condition == .oneOff(stays: kg("22.5")))
        #expect(summary.count == 0)
    }

    // MARK: - Nowhere to put the plate (§4.1, §6.6)

    @Test("An Exercise with no Working Weight states that, not a target")
    func blockedByNoWeight() {
        var session = Session()
        session.start()
        session.send(.setOneOffWeight(kg("60")))
        session.logSets(3, reps: 12)
        session.book.updateExercise(Ids.smith) { $0.workingWeight = nil }
        session.send(.skipRemainingAndFinish)

        let summary = Rules.summary(of: session.lastFinished!, in: session.book)
        let bench = summary.stayed.first { $0.exerciseId == Ids.smith }!
        // The One-off wins the row — it is why nothing progressed — and it has no
        // Working Weight left to name.
        #expect(bench.condition == .oneOff(stays: nil))
    }

    /// §6.6: switching a Microplate off strands, "and the Summary states that condition
    /// in place of the green line".
    @Test("A stranded Exercise states the stranding")
    func blockedByStranding() {
        var session = Session()
        session.book.updateExercise(Ids.smith) { $0.modeOverride = .microloading }
        session.start()
        session.logSets(3, reps: 8)                      // Microloading reads the bottom
        session.send(.setPlate(kg("0.25"), on: false))   // strands it mid-Workout
        session.send(.skipRemainingAndFinish)

        let summary = Rules.summary(of: session.lastFinished!, in: session.book)
        let bench = summary.stayed.first { $0.exerciseId == Ids.smith }!
        #expect(bench.condition == .blocked(.stranded, sets: 3, reps: 8))
    }

    @Test("Microloading with no Microplate picked yet states that")
    func blockedByNoMicroplate() {
        var session = Session()
        session.book.updateExercise(Ids.smith) {
            $0.modeOverride = .microloading
            $0.microloadingIncrement = nil
        }
        session.start()
        session.logSets(3, reps: 8)
        session.send(.skipRemainingAndFinish)

        let summary = Rules.summary(of: session.lastFinished!, in: session.book)
        let bench = summary.stayed.first { $0.exerciseId == Ids.smith }!
        #expect(bench.condition == .blocked(.noMicroplate, sets: 3, reps: 8))
    }

    // MARK: - The recorded outcome, and §2.5's defect in a second place

    /// The whole reason §2.4 stores the planned Sets and the threshold on the Workout.
    /// Edit the Rep Range after Finish and the Summary must say what it said — a screen
    /// that re-derived them would rewrite history from a field the user just changed.
    @Test("Editing the Rep Range afterwards does not move the condition line")
    func conditionReadsTheRecordedOutcome() {
        var session = Session()
        session.start()
        session.logSets(3, reps: 11)
        session.send(.skipRemainingAndFinish)

        let before = Rules.summary(of: session.lastFinished!, in: session.book)
        session.book.updateExercise(Ids.smith) {
            $0.repRange = RepRange(5, 6)
            $0.plannedSets = 9
        }
        let after = Rules.summary(of: session.lastFinished!, in: session.book)

        let condition = SummaryCondition.target(
            sets: 3, reps: 12, to: SummaryWeight(weight: kg("75")))
        #expect(before.stayed[0].condition == condition)
        #expect(after.stayed[0].condition == condition)
    }

    /// §2.7: the Name is a label. History keeps the copy it wrote down, and there is no
    /// Rep Range left to state a condition from.
    @Test("An Exercise deleted mid-Workout keeps its Name and loses its condition")
    func deletedExercise() {
        var session = Session()
        session.start()
        session.logSets(3, reps: 11)
        session.send(.deleteExercise(Ids.smith))
        session.send(.skipRemainingAndFinish)

        let summary = Rules.summary(of: session.lastFinished!, in: session.book)
        let bench = summary.stayed.first { $0.exerciseId == Ids.smith }!
        #expect(bench.name == "Smith machine bench press")
        #expect(bench.condition == .gone)
    }

    // MARK: - The steel bar (§6.5)

    @Test("Duration, Sets and volume — and volume is the one number that converts")
    func theStatsBar() {
        let (book, summary) = mainScreen()
        #expect(summary.setCount == 15)
        #expect(summary.durationSeconds > 0)
        #expect(summary.volume.unit == .kg)
        #expect(summary.volume == Rules.totalVolume(of: book.workouts.last!, in: book))
    }

    /// A skipped Exercise logs no Sets, so it weighs nothing and counts nothing.
    @Test("A skipped Exercise is listed plain and adds no Sets")
    func skippedIsPlain() {
        var session = Session()
        session.start()
        session.send(.skip)
        session.send(.skipRemainingAndFinish)

        let summary = Rules.summary(of: session.lastFinished!, in: session.book)
        #expect(summary.skipped.count == 5)
        #expect(summary.setCount == 0)
        #expect(summary.volume.isZero)
        #expect(summary.performedCount == 0)
    }
}
