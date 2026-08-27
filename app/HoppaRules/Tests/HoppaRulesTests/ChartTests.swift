import Testing
@testable import HoppaRules

// Ticket 0049 — §6.7's per-Exercise chart.
//
// Two halves. The first walks the chart on hand-built sessions, where every number is
// visible in the test itself. The second runs it over **the committed 56-Workout
// history** — the only fixture in this repo with a missed week, a One-off, a skip and a
// mixed-unit pin in it — because a chart is a screen about fifteen sessions and a
// two-session fixture cannot fail the way it fails.

@Suite("SPEC.md §6.7 — the per-Exercise chart")
struct ChartTests {

    // MARK: - What lands on the line, and what does not

    @Test("A session plots the weight it was performed at, not the weight it earned")
    func theLineIsWhatWasLifted() {
        var session = Session()
        session.start()
        session.logSets(3)                      // 12, 12, 12 — it goes up
        session.send(.skipRemainingAndFinish)

        let chart = Rules.exerciseChart(Ids.smith, in: session.book)!
        #expect(chart.points.count == 1)
        // Finish already wrote 75 kg. The point stays at 72.5: that is what was lifted,
        // and the dashed step is what says the Exercise has moved on.
        #expect(chart.points[0].line == kg("72.5"))
        #expect(chart.points[0].progressed)
        #expect(chart.hero.weight == kg("75"))
        #expect(chart.next == ChartNextStep(to: kg("75"), isProgression: true))
    }

    @Test("A Skipped Exercise draws nothing at all — no point, no gap marker")
    func aSkipIsNotAPoint() {
        var session = Session()
        session.start()
        session.logSets(3)
        session.goTo(Ids.row)
        session.send(.skip)
        session.send(.skipRemainingAndFinish)

        #expect(Rules.exerciseChart(Ids.smith, in: session.book)!.points.count == 1)
        #expect(Rules.exerciseChart(Ids.row, in: session.book)!.points.isEmpty)
    }

    @Test("An Exercise gets a line once it has two")
    func oneSessionIsNotAClimb() {
        var session = Session()
        session.start()
        session.logSets(3, reps: 9)
        session.send(.skipRemainingAndFinish)
        #expect(Rules.exerciseChart(Ids.smith, in: session.book)!.hasLine == false)

        session.start()
        session.logSets(3, reps: 9)
        session.send(.skipRemainingAndFinish)
        #expect(Rules.exerciseChart(Ids.smith, in: session.book)!.hasLine)
    }

    @Test("A deleted Exercise has no chart; a deleted Workout loses its point")
    func whatDisappears() {
        var session = Session()
        session.start()
        session.logSets(3, reps: 9)
        session.send(.skipRemainingAndFinish)
        let first = session.lastFinished!.id

        session.start()
        session.logSets(3, reps: 9)
        session.send(.skipRemainingAndFinish)
        #expect(Rules.exerciseChart(Ids.smith, in: session.book)!.points.count == 2)

        session.send(.deleteWorkout(first))
        #expect(Rules.exerciseChart(Ids.smith, in: session.book)!.points.count == 1)

        session.send(.deleteExercise(Ids.smith))
        #expect(Rules.exerciseChart(Ids.smith, in: session.book) == nil)
    }

    // MARK: - A One-off Weight

    @Test("A One-off sits off the line, and the line does not dip")
    func aOneOffNeverJoinsTheLine() {
        var session = Session()
        session.start()
        session.logSets(3, reps: 9)             // 72.5 kg, stayed
        session.send(.skipRemainingAndFinish)

        session.start()
        session.send(.setOneOffWeight(kg("65")))
        session.logSets(3, reps: 12)            // every Set met — and it still cannot move
        session.send(.skipRemainingAndFinish)

        let chart = Rules.exerciseChart(Ids.smith, in: session.book)!
        #expect(chart.points.map(\.line) == [kg("72.5"), kg("72.5")])
        #expect(chart.points[1].oneOff == kg("65"))
        #expect(chart.points[1].progressed == false)
        // A full green column beside a step that never came would be a lie (§6.7).
        #expect(chart.points[1].setMarks == [false, false, false])
        // The Last-sessions list prints what was lifted, which is the One-off itself.
        #expect(chart.points[1].performed.weight == kg("65"))
        // Nothing moved, so there is no step to draw.
        #expect(chart.next == nil)
    }

    @Test("The One-off marker is inside the plot, under the line")
    func theOneOffFitsInTheScale() {
        var session = Session()
        session.start()
        session.logSets(3, reps: 9)
        session.send(.skipRemainingAndFinish)
        session.start()
        session.send(.setOneOffWeight(kg("65")))
        session.logSets(3, reps: 12)
        session.send(.skipRemainingAndFinish)

        let scale = Rules.exerciseChart(Ids.smith, in: session.book)!.scale!
        #expect(scale.low < kg("65"))
        #expect(scale.high > kg("72.5"))
    }

    // MARK: - The dashed step

    @Test("A weight set by hand draws a steel step, not a green one")
    func handEditsAreNotProgressions() {
        var session = Session()
        session.start()
        session.logSets(3, reps: 9)             // stayed at 72.5
        session.send(.skipRemainingAndFinish)
        session.start()
        session.logSets(3, reps: 9)
        session.send(.skipRemainingAndFinish)
        #expect(Rules.exerciseChart(Ids.smith, in: session.book)!.next == nil)

        // §4.3: the user re-weighs by hand. The hero now contradicts the end of the
        // line, and the step is what says so — in steel, because Hoppa did not move it.
        session.send(.reweigh(Ids.smith, kg("80")))
        let step = Rules.exerciseChart(Ids.smith, in: session.book)!.next
        #expect(step == ChartNextStep(to: kg("80"), isProgression: false))
    }

    @Test("A weight lowered by hand steps downwards")
    func aStepCanGoDown() {
        var session = Session()
        session.start()
        session.logSets(3, reps: 9)
        session.send(.skipRemainingAndFinish)
        session.send(.reweigh(Ids.smith, kg("60")))

        let chart = Rules.exerciseChart(Ids.smith, in: session.book)!
        #expect(chart.next == ChartNextStep(to: kg("60"), isProgression: false))
        #expect(chart.scale!.low < kg("60"))
        #expect(chart.totals!.gain == kg("-12.5"))
    }

    // MARK: - The chip, and what stops the plate

    @Test("The chip states the condition live, and names the blocker when there is none")
    func theChip() {
        var session = Session()
        session.start()
        session.logSets(3, reps: 9)
        session.send(.skipRemainingAndFinish)

        let chart = Rules.exerciseChart(Ids.smith, in: session.book)!
        #expect(chart.target == ChartTarget(sets: 3, reps: 12, to: ChartWeight(weight: kg("75"))))
        #expect(chart.blocker == nil)

        // Take the Increment away and the plate has nowhere to go — the same five
        // conditions §6.5 states, from the same function.
        var draft = ExerciseDraft(session.stored(Ids.smith)!, in: session.book.plateInventory)
        draft.increment = nil
        session.send(.saveExercise(Ids.smith, draft: draft))
        let blocked = Rules.exerciseChart(Ids.smith, in: session.book)!
        #expect(blocked.target == nil)
        #expect(blocked.blocker == .noIncrement)
    }

    // MARK: - The three figures at the foot

    @Test("The foot counts from the first session to the weight carried now")
    func theTotals() {
        var session = Session()
        for _ in 0..<3 {
            session.start()
            session.logSets(3)                  // every one goes up
            session.send(.skipRemainingAndFinish)
        }

        let chart = Rules.exerciseChart(Ids.smith, in: session.book)!
        let totals = chart.totals!
        #expect(totals.first == kg("72.5"))
        #expect(totals.firstDate == chart.points[0].startedAt)
        #expect(totals.timesUp == 3)
        // 72.5 → 80 on the line, and Finish has already written 80 → the hero says 80.
        #expect(chart.hero.weight == kg("80"))
        #expect(totals.gain == kg("7.5"))
    }

    @Test("Last sessions is the four newest, newest first")
    func lastSessions() {
        var session = Session()
        for reps in [8, 9, 10, 11, 12] {
            session.start()
            session.logSets(3, reps: reps)
            session.send(.skipRemainingAndFinish)
        }

        let chart = Rules.exerciseChart(Ids.smith, in: session.book)!
        #expect(chart.points.count == 5)
        #expect(chart.lastSessions.map { $0.reps[0] } == [12, 11, 10, 9])
    }

    // MARK: - Charts never join by Name (§2.7)

    @Test("Two Exercises with one Name keep two lines")
    func namesAreNotIdentities() {
        var book = upperALogbook()
        book.programs[0].days.append(WorkoutDay(
            id: WorkoutDayID(50), name: "Upper B",
            exercises: [Exercise(
                id: ExerciseID(50), name: "Smith machine bench press", equipment: .smith,
                plannedSets: 3, repRange: RepRange(8, 12),
                workingWeight: kg("40"), increment: kg("2.5"), storedBaseWeight: kg("15"))]))

        var session = Session(book)
        session.start()
        session.logSets(3, reps: 9)
        session.send(.skipRemainingAndFinish)
        session.start(WorkoutDayID(50))
        session.logSets(3, reps: 9)
        session.send(.skipRemainingAndFinish)

        let a = Rules.exerciseChart(Ids.smith, in: session.book)!
        let b = Rules.exerciseChart(ExerciseID(50), in: session.book)!
        #expect(a.name == b.name)
        #expect(a.points.map(\.line) == [kg("72.5")])
        #expect(b.points.map(\.line) == [kg("40")])
    }

    // MARK: - The y axis

    @Test("The gridlines are clean steps of the unit, and never more than four")
    func theLadder() {
        let scale = Rules.scale(
            points: [point(kg("65")), point(kg("80"))], next: nil)!
        #expect(scale.ticks == [kg("65"), kg("70"), kg("75"), kg("80")])
        #expect(scale.low < kg("65"))
        #expect(scale.high > kg("80"))
    }

    @Test("A flat series still gets air above and below it")
    func aFlatSeries() {
        let scale = Rules.scale(points: [point(kg("60")), point(kg("60"))], next: nil)!
        #expect(scale.low == kg("59"))
        #expect(scale.high == kg("61"))
        #expect(scale.fraction(of: kg("60")) == 0.5)
    }

    @Test("A Microload series starting at zero puts its first gridline inside the plot")
    func aMicroloadLadder() {
        let scale = Rules.scale(
            points: [point(kg("0")), point(kg("0.75"))], next: kg("1"))!
        #expect(scale.low < kg("0"))
        for tick in scale.ticks {
            #expect(tick >= scale.low && tick <= scale.high)
        }
        #expect(scale.ticks.first == kg("0"))
    }

    private func point(_ weight: Weight) -> ChartPoint {
        ChartPoint(
            id: WorkoutID(1), startedAt: 0, line: weight, oneOff: nil, progressed: false,
            setMarks: [], reps: [], performed: ChartWeight(weight: weight))
    }
}

// MARK: - The chart over sixteen weeks

/// The chart read off **the committed 56-Workout history**, which is the only fixture
/// with a missed week, a One-off, a skip and a mixed-unit pin in it at once.
@Suite("The chart over the 56-Workout history")
struct ChartHistoryTests {

    static let book = SnapshotTests.run(assertInvariants: false).book

    /// Smith machine bench press — Upper A, kg, Progressive Overload, with the One-off in
    /// week 13.
    static let smith = ExerciseID(101)
    /// Lat pulldown — an lbs stack with a kg Microplate: §6.7's mixed-unit reference case.
    static let pulldown = ExerciseID(103)
    /// Weighted chin-up — the Exercise skipped in week 14.
    static let chin = ExerciseID(105)

    @Test("Fifteen Upper A sessions make fifteen points, and the skip makes fourteen")
    func whatIsOnTheLine() {
        let upperA = Self.book.workouts.filter { $0.workoutDayId == WorkoutDayID(1) }
        #expect(upperA.count == 15)
        #expect(Rules.exerciseChart(Self.smith, in: Self.book)!.points.count == 15)
        #expect(Rules.exerciseChart(Self.chin, in: Self.book)!.points.count == 14)
    }

    @Test("The x axis is real time: every point carries the day its Workout started")
    func realTime() {
        let chart = Rules.exerciseChart(Self.smith, in: Self.book)!
        let upperA = Self.book.workouts.filter { $0.workoutDayId == WorkoutDayID(1) }
        #expect(chart.points.map(\.startedAt) == upperA.map(\.startedAt))
        // The missed week is a wider gap and nothing else: the two points either side of
        // it are two weeks apart, with no marker in between.
        let gaps = zip(chart.points, chart.points.dropFirst()).map { $1.startedAt - $0.startedAt }
        #expect(gaps.filter { $0 > 8 * 86_400 }.count == 1)
    }

    @Test("The line never dips through the One-off, and the One-off is 7.5 kg under it")
    func theOneOffWeek() {
        let chart = Rules.exerciseChart(Self.smith, in: Self.book)!
        let marked = chart.points.filter { $0.oneOff != nil }
        #expect(marked.count == 1)
        let one = marked[0]
        #expect(one.oneOff! == one.line - kg("7.5"))
        #expect(one.progressed == false)
        #expect(one.setMarks.allSatisfy { $0 == false })
        // A One-off never became the Working Weight, so the line walks straight through
        // it: the session after it starts at exactly the height this one stood at.
        let index = chart.points.firstIndex { $0.oneOff != nil }!
        #expect(chart.points[index - 1].line <= one.line)
        #expect(chart.points[index + 1].line == one.line)
    }

    @Test("The Working Weight only ever climbs along the line")
    func theLineNeverGoesBackwards() {
        for spec in History.specs {
            let chart = Rules.exerciseChart(spec.id, in: Self.book)!
            guard chart.axisUnit == nil else { continue }   // the mixed pin plots its Microload
            for (earlier, later) in zip(chart.points, chart.points.dropFirst()) {
                #expect(later.line >= earlier.line, "\(spec.name) went backwards")
            }
        }
    }

    @Test("Every Set cell says exactly what the Workout detail says about that Set")
    func theTwoScreensAgree() {
        for spec in History.specs {
            let chart = Rules.exerciseChart(spec.id, in: Self.book)!
            for point in chart.points {
                let past = Rules.pastWorkout(point.id, in: Self.book)!
                let exercise = past.exercises.first { $0.exerciseId == spec.id }!
                #expect(point.setMarks == exercise.sets.map(\.metThreshold), "\(spec.name)")
                #expect(point.reps == exercise.sets.map(\.reps), "\(spec.name)")
            }
        }
    }

    @Test("Three filled cells is the progression rule, and the grid shows it")
    func theGridIsTheRule() {
        let chart = Rules.exerciseChart(Self.smith, in: Self.book)!
        for point in chart.points {
            #expect(point.progressed == point.metEverySet)
        }
        // And it is not a chart of all-green columns: the plateaus are what make it worth
        // drawing.
        #expect(chart.points.contains { !$0.metEverySet })
    }

    @Test("The mixed-unit pin plots the Microload, and converts nothing")
    func theMixedUnitPin() {
        let chart = Rules.exerciseChart(Self.pulldown, in: Self.book)!
        #expect(chart.isMixedUnitPin)
        #expect(chart.axisUnit == .kg)
        // Two heroes, each in its own unit.
        #expect(chart.hero.weight.unit == .lbs)
        #expect(chart.hero.microload?.unit == .kg)
        #expect(chart.points.allSatisfy { $0.line.unit == .kg })
        // The Last-sessions row still prints the pin and the Microload together.
        #expect(chart.points.allSatisfy { $0.performed.weight.unit == .lbs })
        #expect(chart.totals!.first.unit == .kg)
        #expect(chart.totals!.gain.unit == .kg)
        // This one *does* roll up: sixteen weeks on a 1 kg Microplate reaches a Stack Step.
        #expect(chart.totals!.pinMoved)
    }

    @Test("Every chart's scale holds every marker it has to draw")
    func nothingIsDrawnOffThePlot() {
        for spec in History.specs {
            guard let chart = Rules.exerciseChart(spec.id, in: Self.book),
                  let scale = chart.scale
            else { continue }
            for point in chart.points {
                #expect(point.line >= scale.low && point.line <= scale.high, "\(spec.name)")
                if let oneOff = point.oneOff {
                    #expect(oneOff >= scale.low && oneOff <= scale.high, "\(spec.name)")
                }
            }
            if let next = chart.next {
                #expect(next.to >= scale.low && next.to <= scale.high, "\(spec.name)")
            }
            #expect(scale.ticks.count <= 5, "\(spec.name) drew \(scale.ticks.count) gridlines")
            #expect(!scale.ticks.isEmpty, "\(spec.name) drew none")
        }
    }

    @Test("Times up counts the green dots, and the gain matches the climb")
    func theFootAgreesWithTheLine() {
        for spec in History.specs {
            let chart = Rules.exerciseChart(spec.id, in: Self.book)!
            guard let totals = chart.totals else { continue }
            #expect(totals.timesUp == chart.points.filter(\.progressed).count)
            let ends = chart.next?.to ?? chart.points.last!.line
            #expect(totals.gain == ends - totals.first, "\(spec.name)")
        }
    }
}
