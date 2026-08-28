import SwiftUI
import HoppaRules
import HoppaStore

// Ticket 0036 — §6.4, the screen Rob stands in front of at the rack.
//
// Its prototype was **approved outright on the first pass**, so the arrangement is settled
// and this file transposes it. It also carries the most of §8.2's nine defects, and not
// one of them ports: every one is already a named, green test in `HoppaRules`, and this
// view calls the rules rather than repeating them.
//
// Three things about the split, because they are what keeps the rules testable:
//
// - **The rep counter is view state.** `Action.logSet(reps:)` takes a finished number, and
//   `Action`'s own doc-comment says so: the prototype's reducer mixed the screen, the
//   overlay and the keypad buffer in with real rules, and none of that can fail a test.
//   `pendingReps` lives here and reaches the rules once, as an argument.
// - **The Rest Timer holds no clock.** `Workout.restStartedAt` is a `Timestamp` the rules
//   write, and a `TimelineView` reads `now − restStartedAt` — which is why a lock, a
//   background and a phone call cost no code here
//   ([The view layer around the rules](0024-the-view-layer-around-the-rules.md)).
// - **The Workout starts here, not at the picker.** `Route.logging` carries a Workout Day
//   and not a Workout, so a tap on the picker cannot strand an Open Workout on the phone
//   with no screen to finish or discard it.
//
// Consult `SPEC.md` §3.2, §3.3, §5.5, §6.4, §7.4, §7.5 and §8.2.
// Prototype: `design/0007-logging/fitty-workout-logging.html`.

struct LoggingScreen: View {
    @Environment(LogbookStore.self) private var store
    @Binding var path: [Route]
    let workoutDayId: WorkoutDayID

    /// The reps the bottom button will log. `nil` means *the Target Reps* — the top of the
    /// Rep Range — so a `−` on one Exercise never leaks into the next one.
    @State private var pendingReps: Int?
    @State private var sheet: LoggingSheet?
    @State private var showingList = false
    /// The drawer's own `FINISH WORKOUT`, held until the cover has actually gone. A sheet
    /// presented while a full-screen cover is dismissing is dropped, and the Finish gate
    /// is the one thing on this screen that must never be dropped.
    @State private var finishAfterList = false
    /// `.startWorkout` fires once. Without this the screen would start a second Workout
    /// the moment Finish cleared the first, in the frame before the pop lands.
    @State private var didStart = false

    private var logbook: Logbook? { store.logbook }
    private var rack: PlateInventory { logbook?.plateInventory ?? .standard(.kg) }

    /// The Open Workout, **only when it is this Day's**. One Open Workout at a time
    /// (§3.1), so arriving here with another Day's Workout running is a real state and it
    /// gets a real screen rather than a silent refusal.
    private var workout: Workout? {
        guard let open = logbook?.openWorkout, open.workoutDayId == workoutDayId else { return nil }
        return open
    }

    var body: some View {
        ZStack {
            Color.floor.ignoresSafeArea()
            content
                .padding(.horizontal, 20)   // §7.4 screen padding
                .padding(.bottom, 20)
        }
        // §7.4: nothing is drawn in the safe top inset, and the header below carries its
        // own way back — a navigation bar would put a second chevron above it.
        .toolbar(.hidden, for: .navigationBar)
        .task { start() }
        .sheet(item: $sheet) { which in
            sheetBody(which)
                .presentationBackground(Color.floor)
        }
        .fullScreenCover(isPresented: $showingList, onDismiss: {
            guard finishAfterList else { return }
            finishAfterList = false
            attemptFinish()
        }) {
            if let workout {
                ExerciseListDrawer(
                    workout: workout,
                    pick: { index in
                        store.send(.selectExercise(index: index))
                        // A `−` on one Exercise must not follow the user to the next one.
                        pendingReps = nil
                        showingList = false
                    },
                    finish: {
                        finishAfterList = true
                        showingList = false
                    },
                    close: { showingList = false })
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.isUnreadable {
            stopped("Hoppa could not read the logbook.",
                    detail: "Nothing was changed and nothing was written. The file is still on the phone.")
        } else if let workout {
            screen(workout)
        } else if let elsewhere = logbook?.openWorkout {
            oneAtATime(elsewhere)
        } else if logbook?.workoutDay(workoutDayId) == nil {
            stopped("That day is gone.", detail: nil)
        } else {
            // Two states, and both are one frame long: before `.task` has started the
            // Workout, and after Finish cleared it while the path swaps this screen for
            // §6.5's Summary — or, on a Discard, pops it. Neither is worth
            // a screen, and **neither is "that day is gone"** — a Day that still exists
            // must never say it does not, least of all in the frame before it appears.
            Color.clear
        }
    }

    // MARK: - Starting (§3.1)

    /// A Workout starts on an **explicit action** (§3.1) — and the tap on the picker was
    /// it. The screen is the action's landing place, not a second decision.
    private func start() {
        guard !didStart else { return }
        didStart = true
        guard logbook?.openWorkout == nil,
              let found = logbook?.workoutDay(workoutDayId)
        else { return }
        store.send(.startWorkout(programId: found.program.id, workoutDayId: workoutDayId))
    }

    // MARK: - The screen (§6.4)

    @ViewBuilder
    private func screen(_ workout: Workout) -> some View {
        if let performed = workout.current,
           let exercise = logbook?.resolvedExercise(performed.exerciseId) {
            VStack(alignment: .leading, spacing: 16) {   // §7.4's 8 / 16 rhythm
                header(workout)
                title(performed, exercise)
                weightBlock(performed, exercise)
                if let breakdown = Rules.breakdown(
                    for: exercise, performedAt: performed.oneOffWeight, inventory: rack) {
                    PlateBreakdownView(
                        breakdown: breakdown,
                        exercise: exercise,
                        performedAt: performedWeight(performed, exercise))
                } else {
                    unweighed
                }
                setRows(workout, performed, exercise)
                restRow(workout)
                bottomRow(workout, performed, exercise)
            }
        } else {
            // The Exercise was deleted mid-Workout (§6.6). History survives it; the card
            // does not, so the screen says so and hands the user the way on.
            VStack(alignment: .leading, spacing: 16) {
                header(workout)
                Spacer()
                Text("That exercise is gone.")
                    .typography(Typography.display(26))
                    .foregroundStyle(Color.text)
                Text("It was removed from the program. What you logged is kept.")
                    .typography(Typography.body(13, lineSpacing: 4))
                    .foregroundStyle(Color.dimText)
                Spacer()
                // Ticket 0045: **the same control the bottom row draws when an Exercise
                // is done** — `NEXT: …`, or `FINISH WORKOUT` when nothing is Open. The
                // rule leaves `currentIndex` where it was on purpose (§6.4: Hoppa keeps
                // him on the Exercise, not the position), and a dead card whose only
                // drawn way on was Finish would strand him behind the gate §3.3 puts
                // there. **Hoppa still does not jump by itself**; it offers the jump.
                moveOn(workout)
            }
        }
    }

    /// `NEXT: …` while an Open Exercise is left, `FINISH WORKOUT` when none is. Written
    /// once, because the bottom row and the deleted-Exercise card ask the same question.
    @ViewBuilder
    private func moveOn(_ workout: Workout) -> some View {
        if let next = workout.nextOpenIndex(after: workout.currentIndex),
           next != workout.currentIndex {
            PrimaryButton("Next: \(workout.exercises[next].name)") {
                store.send(.nextOpen)
                pendingReps = nil
            }
        } else {
            PrimaryButton("Finish workout") { attemptFinish() }
        }
    }

    /// The Day, the way back, **the exercise counter as navigation**, and the menu.
    ///
    /// `3 / 5 ▾` is the navigation (§6.4) and the chevron is the way out of the Workout
    /// without ending it — leaving is not finishing, and §3.3 says Hoppa never ends a
    /// Workout by itself. The Open Workout is waiting on the picker when he comes back.
    private func header(_ workout: Workout) -> some View {
        HStack(spacing: 10) {
            Button { if !path.isEmpty { path.removeLast() } } label: {
                Text("‹")
                    .typography(Typography.body(22))
                    .foregroundStyle(Color.steel)
                    .frame(width: 26, height: 50, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Text(workout.workoutDayName)
                .typography(Typography.display(15, tracking: 0.06))
                .foregroundStyle(Color.text)
                .lineLimit(1)
            Spacer(minLength: 8)
            Button { showingList = true } label: {
                Text("\(workout.currentIndex + 1) / \(workout.exercises.count) ▾")
                    .typography(Typography.label(10.5, tracking: 0.12))
                    .foregroundStyle(Color.dimText)
                    .frame(height: 50)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button { sheet = .menu } label: {
                Text("•••")
                    .typography(Typography.body(17))
                    .foregroundStyle(Color.steel)
                    .frame(width: 34, height: 50, alignment: .trailing)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(height: 50)
    }

    private func title(_ performed: PerformedExercise, _ exercise: ResolvedExercise) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.name)
                .typography(Typography.display(31, tracking: 0.005))
                .foregroundStyle(Color.text)
                .lineLimit(2)
            HStack(spacing: 0) {
                Text(metaLine(performed, exercise))
                    .typography(Typography.label(10.5, tracking: 0.12))
                    .foregroundStyle(Color.dimText)
                if performed.state == .completed {
                    Text(" · completed")
                        .typography(Typography.label(10.5, tracking: 0.12))
                        .foregroundStyle(Color.go)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
    }

    private func metaLine(_ performed: PerformedExercise, _ exercise: ResolvedExercise) -> String {
        var parts = ["\(exercise.repRange.bottom)–\(exercise.repRange.top) reps"]
        switch performed.state {
        case .skipped:
            parts.append("skipped")
        case .completed:
            parts.append("\(performed.sets.count) of \(exercise.plannedSets) sets done")
        case .open:
            parts.append("set \(min(performed.sets.count + 1, exercise.plannedSets)) of \(exercise.plannedSets)")
        }
        // A Barbell's bar is standard, so only a Smith and a plate-loaded machine name one.
        if let base = exercise.baseWeight {
            parts.append("base \(base.decimalString) \(base.unit.rawValue)")
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - The Working Weight as the hero

    /// The big number, its unit, and the rule chip beside it.
    ///
    /// **Mixed units stack two numbers** (§5.5): the Working Weight big, the Microload
    /// under it, each with its own unit label, and **no combined total anywhere** — Hoppa
    /// converts only inside itself.
    ///
    /// **Ticket 0053 cut the hero from 88 pt to 64, and the Microload from 38 to 30** to
    /// keep the step between them. Rob at the walk: *"ik vind dat de tekst van het gewicht
    /// een te grote lettertype heeft en teveel ruimte inneemt."* 88 was the artboard's, not
    /// §7.4's — §7.4 pins the small sizes and never named this one — and the artboard is a
    /// reference with known errors (§8.2). The Working Weight is still the hero: the next
    /// biggest thing on the screen is the 31 pt Set number, so the step is unambiguous.
    /// What the 24 pt buys is the block under it, which is what he actually reads.
    ///
    /// Tapping it opens ticket 0037's sheet.
    private func weightBlock(_ performed: PerformedExercise, _ exercise: ResolvedExercise) -> some View {
        Button { sheet = .weight } label: {
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(performedWeight(performed, exercise)?.decimalString ?? "—")
                        .typography(Typography.display(64, tracking: -0.01))
                        .foregroundStyle(Color.text)
                    if let micro = exercise.microload, !micro.isZero {
                        HStack(alignment: .bottom, spacing: 8) {
                            Text("+\(micro.decimalString)")
                                .typography(Typography.display(30))
                                .foregroundStyle(Color.steel)
                            Text(micro.unit.rawValue)
                                .typography(Typography.label(15, tracking: 0.14))
                                .foregroundStyle(Color.dimText)
                                .padding(.bottom, 4)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(exercise.unit.rawValue)
                        .typography(Typography.label(15, tracking: 0.14))
                        .foregroundStyle(Color.dimText)
                    if let chip = ruleChip(performed, exercise) {
                        Chip(chip.text, tone: chip.tone)
                    }
                }
                .padding(.bottom, 4)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// The weight this Exercise is performed at: a One-off Weight wins over the Working
    /// Weight for as long as it stands (§4.3).
    ///
    /// **Relabelled, never converted** (§2.8): the Weight Unit is derived, so a One-off
    /// stored before a unit change carries a stale label — and every comparison and
    /// subtraction below traps on a unit mismatch rather than converting behind the user.
    private func performedWeight(_ performed: PerformedExercise, _ exercise: ResolvedExercise) -> Weight? {
        (performed.oneOffWeight ?? exercise.workingWeight)?.relabelled(exercise.unit)
    }

    /// **The chip states the rule, never an offer** (§7.6). Every branch below asks
    /// `HoppaRules` — `evaluateProgression` is what decides whether the Exercise moved,
    /// and a view that worked it out again would be a second copy of §4.1.
    private func ruleChip(
        _ performed: PerformedExercise, _ exercise: ResolvedExercise
    ) -> (text: String, tone: ChipTone)? {
        let unit = exercise.unit.rawValue

        // A One-off never writes back, so the chip names the Working Weight that survives
        // — not just the fact of the one-off (§6.4).
        if performed.oneOffWeight != nil {
            guard let working = exercise.workingWeight else { return ("one-off", .steel) }
            return ("one-off · \(working.decimalString) \(unit) stays", .steel)
        }

        if performed.state == .completed {
            let result = Rules.evaluateProgression(
                performed: performed, exercise: exercise, inventory: rack)
            if result.outcome.progressed, let move = result.move {
                if exercise.isMixedUnitPin, let micro = move.microload {
                    return ("→ \(move.workingWeight.decimalString) \(unit) "
                            + "+\(micro.decimalString) \(micro.unit.rawValue) next time", .go)
                }
                return ("→ \(move.workingWeight.decimalString) \(unit) next time", .go)
            }
            guard let working = exercise.workingWeight else { return nil }
            return ("stays \(working.decimalString) \(unit)", .steel)
        }

        // While logging: the condition, printed as the Increment is **held**. A
        // Microloading Increment moves a bar by twice the plate and rolls into a Stack
        // Step on a mixed pin, and `Rules.progressionMove` is where that lives.
        let increment = exercise.mode == .microloading
            ? exercise.microloadingIncrement
            : exercise.increment
        guard let increment else { return nil }
        return ("+\(increment.decimalString) \(increment.unit.rawValue) "
                + "if all \(exercise.thresholdReps)", .steel)
    }

    /// **An unset weight is not zero** (§2.8), so there is nothing to draw and nothing to
    /// log. §6.6's Re-weigh list is the other end of this.
    private var unweighed: some View {
        Text("No weight yet. Tap the dash above and type one.")
            .typography(Typography.body(12, lineSpacing: 4))
            .foregroundStyle(Color.dimText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 118)
    }

    // MARK: - The Set rows

    private func setRows(
        _ workout: Workout, _ performed: PerformedExercise, _ exercise: ResolvedExercise
    ) -> some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(Array(performed.sets.enumerated()), id: \.offset) { index, set in
                    loggedRow(index + 1, set, exercise)
                }
                if performed.state == .open, performed.sets.count < exercise.plannedSets {
                    nextRow(performed.sets.count + 1, exercise)
                }
                let firstEmpty = performed.sets.count + (performed.state == .open ? 1 : 0)
                if firstEmpty < exercise.plannedSets {
                    ForEach(firstEmpty..<exercise.plannedSets, id: \.self) { index in
                        emptyRow(index + 1, skipped: performed.state == .skipped)
                    }
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxHeight: .infinity)
    }

    /// **Reps over the range read `14 reps · 8–12` — plain, no colour** (§6.4, §7.6). The
    /// user did the work; nothing he did wears a warning.
    private func loggedRow(_ number: Int, _ set: LoggedSet, _ exercise: ResolvedExercise) -> some View {
        setRow(number, isNext: false) {
            HStack(spacing: 8) {
                Text("\(set.reps) reps")
                    .typography(Typography.listValue(14))
                    .foregroundStyle(Color.text)
                if set.reps > exercise.repRange.top {
                    Text("· \(exercise.repRange.bottom)–\(exercise.repRange.top)")
                        .typography(Typography.meta(12))
                        .foregroundStyle(Color.dimText)
                }
                // §6.4 marks a One-off twice, and this is the second mark: a plain chip on
                // **every** Set logged under it.
                if set.oneOff { Chip("one-off", tone: .steel) }
                Spacer(minLength: 8)
                Text("✓")
                    .typography(Typography.body(14))
                    .foregroundStyle(Color.go)
            }
        }
    }

    private func nextRow(_ number: Int, _ exercise: ResolvedExercise) -> some View {
        let reps = pendingReps ?? exercise.targetReps
        return setRow(number, isNext: true) {
            HStack(spacing: 8) {
                Text(reps == exercise.targetReps ? "Target \(reps) reps" : "\(reps) reps")
                    .typography(Typography.listValue(14))
                    .foregroundStyle(Color.text)
                if reps > exercise.repRange.top {
                    Text("· \(exercise.repRange.bottom)–\(exercise.repRange.top)")
                        .typography(Typography.meta(12))
                        .foregroundStyle(Color.dimText)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func emptyRow(_ number: Int, skipped: Bool) -> some View {
        setRow(number, isNext: false) {
            HStack {
                Text(skipped ? "skipped" : "not done")
                    .typography(Typography.meta(12))
                    .foregroundStyle(Color.dimText)
                Spacer(minLength: 0)
            }
        }
        .opacity(0.4)
    }

    /// §7.4's **50 px hit target** for a Set row.
    private func setRow<Body: View>(
        _ number: Int, isNext: Bool, @ViewBuilder body: () -> Body
    ) -> some View {
        HStack(spacing: 14) {
            Text("\(number)")
                .typography(Typography.display(15))
                .foregroundStyle(isNext ? Color.text : Color.dimText)
                .frame(width: 14, alignment: .leading)
            body()
        }
        .padding(.horizontal, 14)
        .frame(height: 50)
        .background(isNext ? Color.clear : Color.card)
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(isNext ? Color.text : Color.line, lineWidth: isNext ? 1.5 : 1))
    }

    // MARK: - The Rest Timer

    /// A count-up stopwatch, started by the rules after each logged Set. `.periodic` and
    /// not a `Timer`: the view reads `now − restStartedAt`, so a lock or a background
    /// costs nothing and there is no clock to keep in sync.
    private func restRow(_ workout: Workout) -> some View {
        HStack(spacing: 9) {
            if let started = workout.restStartedAt {
                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    HStack(spacing: 9) {
                        Text("Resting")
                            .typography(Typography.label())
                            .foregroundStyle(Color.labelText)
                        Text(clock(timeline.date.timeIntervalSince1970 - started))
                            .typography(Typography.display(21, tracking: 0.01))
                            .foregroundStyle(Color.text)
                    }
                }
            } else {
                Text("Ready")
                    .typography(Typography.label())
                    .foregroundStyle(Color.labelText)
            }
            Spacer(minLength: 8)
            Text("\(workout.openExerciseCount) open")
                .typography(Typography.label())
                .foregroundStyle(Color.labelText)
        }
    }

    private func clock(_ seconds: Timestamp) -> String {
        let whole = max(0, Int(seconds))
        let minutes = whole / 60
        let rest = whole % 60
        return "\(minutes):\(rest < 10 ? "0" : "")\(rest)"
    }

    // MARK: - The bottom control row

    /// `−` · `LOG n REPS` · `+` while there is a Set to log, and after that the one tap
    /// that moves on.
    ///
    /// **Completing costs no tap; moving on costs one** (§6.4). The last Set completes the
    /// Exercise by itself — that is `Rules.reduce`, not this view — and the button then
    /// becomes `NEXT: …`, or `FINISH WORKOUT` when nothing is Open. **Hoppa does not jump
    /// by itself.**
    @ViewBuilder
    private func bottomRow(
        _ workout: Workout, _ performed: PerformedExercise, _ exercise: ResolvedExercise
    ) -> some View {
        if performed.state == .open, performed.sets.count < exercise.plannedSets {
            let reps = pendingReps ?? exercise.targetReps
            HStack(spacing: 9) {
                adjust("−") { pendingReps = max(0, reps - 1) }
                // The `+` is what makes logging **above** the range reachable by design.
                PrimaryButton("Log \(reps) reps") { log(reps) }
                adjust("+") { pendingReps = reps + 1 }
            }
        } else {
            moveOn(workout)
        }
    }

    /// §7.4's **62 × 64 px** adjust button.
    private func adjust(_ glyph: String, act: @escaping () -> Void) -> some View {
        Button(action: act) {
            Text(glyph)
                .typography(Typography.body(26))
                .foregroundStyle(Color.text)
                .frame(width: 62, height: 64)
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.chipBorder, lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - What the buttons do

    private func log(_ reps: Int) {
        store.send(.logSet(reps: reps))
        pendingReps = nil
    }

    /// **Finish is gated** (§3.3), and the gate has a one-tap way out — because it would
    /// otherwise bite hardest exactly when the user wants to leave.
    private func attemptFinish() {
        guard let workout else { return }
        if workout.canFinish {
            sheet = nil
            finish(.finish)
        } else {
            // **Not** `sheet = nil` first: dismissing and presenting in one tick loses
            // the second sheet. `.sheet(item:)` swaps the menu for the gate on its own.
            sheet = .gate
        }
    }

    /// Finish, Skip-and-finish and Discard all end the Workout, and they do not end it
    /// in the same place: **a Finish lands on §6.5's Summary and a Discard lands on the
    /// picker**, because a discarded Workout has nothing to summarise.
    ///
    /// The two are told apart by the finished list growing, not by the `Action` — a
    /// Finish the rules refuse (the gate still holds) must not push a Summary either,
    /// and this covers both.
    private func finish(_ action: Action) {
        let before = store.logbook?.workouts.count ?? 0
        store.send(action)
        guard store.logbook?.openWorkout == nil else { return }
        if let finished = store.logbook?.workouts.last,
           (store.logbook?.workouts.count ?? 0) > before {
            // **Replacing** the path, not pushing onto it: §6.5 has no way back, and a
            // finished Workout has no logging screen to go back to.
            path = [.summary(finished.id)]
        } else {
            path.removeAll()
        }
    }

    // MARK: - The sheets

    @ViewBuilder
    private func sheetBody(_ which: LoggingSheet) -> some View {
        if let workout, let performed = workout.current,
           let exercise = logbook?.resolvedExercise(performed.exerciseId) {
            switch which {
            case .menu:
                menuSheet(workout, performed, exercise)
            case .gate:
                gateSheet(workout)
            case .discard:
                discardSheet()
            case .weight:
                if let stored = logbook?.exercise(performed.exerciseId) {
                    WeightSheet(
                        exercise: exercise,
                        stored: stored,
                        inventory: rack,
                        current: performedWeight(performed, exercise),
                        oneOffIsStanding: performed.oneOffWeight != nil,
                        commit: { commitWeight($0, performed: performed, exercise: exercise) },
                        cancel: { sheet = nil })
                }
            case .lower(let weight):
                lowerSheet(weight, exercise)
            }
        }
    }

    /// §3.3 puts **Discard in a menu, never beside Finish**, and this is that menu. Skip,
    /// Reopen and Done early are §3.2's three, and the sheet says which is which in the
    /// user's words: *later* is what the counter does, *not at all* is what Skip does.
    private func menuSheet(
        _ workout: Workout, _ performed: PerformedExercise, _ exercise: ResolvedExercise
    ) -> some View {
        SheetStack(heading: exercise.name) {
            if performed.state == .skipped {
                SheetRow("Put it back", sub: "reopen") { act(.reopen) }
            } else {
                SheetRow("Skip this exercise", sub: "not at all") { act(.skip) }
            }
            if performed.state == .open, !performed.sets.isEmpty {
                SheetRow(
                    "Done early",
                    sub: "\(performed.sets.count) of \(exercise.plannedSets) sets · will not progress"
                ) { act(.doneEarly) }
            }
            SheetRow(
                "Change the weight",
                sub: performedWeight(performed, exercise)
                    .map { "\($0.decimalString) \(exercise.unit.rawValue)" } ?? "not set yet"
            ) { sheet = .weight }
            SheetRow("Finish the workout", sub: nil) { attemptFinish() }
            SheetRow("Discard the workout", sub: nil, tone: .stop) {
                // A Workout with no logged Sets discards without a question (§3.3).
                if workout.hasLoggedAnything {
                    sheet = .discard
                } else {
                    sheet = nil
                    finish(.discard)
                }
            }
        }
    }

    private func gateSheet(_ workout: Workout) -> some View {
        let open = workout.openExerciseCount
        return SheetStack(
            heading: "\(open) exercise\(open == 1 ? " is" : "s are") still open",
            note: "Skip \(open == 1 ? "it" : "them") and finish? "
                + "Every exercise still ends completed or skipped."
        ) {
            SheetPrimary("Skip and finish") {
                sheet = nil
                finish(.skipRemainingAndFinish)
            }
            SheetRow("Keep logging", sub: nil, centred: true) { sheet = nil }
        }
    }

    private func discardSheet() -> some View {
        SheetStack(
            heading: "Discard this workout?",
            note: "Every logged set goes. Hoppa keeps nothing."
        ) {
            SheetRow("Discard", sub: nil, tone: .stop, centred: true) {
                sheet = nil
                finish(.discard)
            }
            SheetRow("Keep it", sub: nil, centred: true) { sheet = nil }
        }
    }

    // MARK: - Changing the weight (§4.3)

    /// **Raising always sticks; lowering asks once** (§4.3). `Rules.weightEdit` is the
    /// rule — including the case the prototype gets wrong, where a number above a standing
    /// One-off Weight would still take the Working Weight down. A view that decided this
    /// itself would be a second copy of §4.3, and it would be the wrong copy: the rule was
    /// in a view in the prototype, which is exactly how the defect survived.
    private func commitWeight(
        _ typed: Weight, performed: PerformedExercise, exercise: ResolvedExercise
    ) {
        switch Rules.weightEdit(typed, performed: performed, exercise: exercise) {
        case .unchanged:
            // Nothing moved. Writing it would clear a standing One-off for no reason.
            sheet = nil
        case .sticks:
            setWeight(.setWorkingWeight(typed))
        case .asks:
            // **Not** `sheet = nil` first: `.sheet(item:)` swaps one for the other, and
            // dismissing and presenting in one tick loses the second.
            sheet = .lower(typed)
        }
    }

    /// *Just today, or from now on?* — the one question §4.3 asks, and it asks it once.
    private func lowerSheet(_ weight: Weight, _ exercise: ResolvedExercise) -> some View {
        SheetStack(
            heading: "Down to \(weight.decimalString) \(exercise.unit.rawValue)",
            note: "Just today, or from now on?"
        ) {
            SheetRow("Just today", sub: "a one-off weight · never written back") {
                setWeight(.setOneOffWeight(weight))
            }
            SheetRow("From now on", sub: "this becomes the working weight") {
                setWeight(.setWorkingWeight(weight))
            }
            SheetRow("Cancel", sub: nil, centred: true) { sheet = nil }
        }
    }

    /// A weight change leaves `pendingReps` alone: it is the *reps* the next Set will
    /// carry, and the user adjusted those on this Exercise, for this Exercise.
    private func setWeight(_ action: Action) {
        store.send(action)
        sheet = nil
    }

    private func act(_ action: Action) {
        store.send(action)
        pendingReps = nil
        sheet = nil
    }

    // MARK: - The two screens that are not the screen

    /// **One Open Workout at a time** (§3.1). The rules refuse the second `.startWorkout`
    /// and refusing in silence would leave this screen blank, so it says which Day is
    /// running and offers the one door to it.
    ///
    /// Ticket 0040 answers the *other* shape of this — an Open Workout from an earlier day,
    /// found at launch — and it is a different question: that one asks resume, finish or
    /// discard, and this one only has to point.
    private func oneAtATime(_ open: Workout) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()
            Text("\(open.workoutDayName) is still running")
                .typography(Typography.display(26))
                .foregroundStyle(Color.text)
            Text("Hoppa keeps one workout open at a time. Finish or discard that one first.")
                .typography(Typography.body(13, lineSpacing: 4))
                .foregroundStyle(Color.dimText)
            Spacer()
            PrimaryButton("Go to \(open.workoutDayName)") {
                if !path.isEmpty { path.removeLast() }
                path.append(.logging(open.workoutDayId))
            }
        }
    }

    private func stopped(_ heading: String, detail: String?) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()
            Text(heading)
                .typography(Typography.display(26))
                .foregroundStyle(Color.text)
            if let detail {
                Text(detail)
                    .typography(Typography.body(13, lineSpacing: 4))
                    .foregroundStyle(Color.dimText)
            }
            Spacer()
            PrimaryButton("Back") { if !path.isEmpty { path.removeLast() } }
        }
    }
}

/// Which sheet is up. The exercise list is **not** here: §6.4 makes it a full-screen list
/// and not a sheet, because it is navigation and it replaces the screen.
enum LoggingSheet: Identifiable {
    case menu, gate, discard, weight
    /// §4.3's question, carrying the number that raised it. It is on the enum and not in
    /// `WeightSheet` because the weight sheet must be **gone** by the time it is asked:
    /// the two are one flow with one outcome, and a sheet stacked on a sheet would let
    /// the user step the number behind the question.
    case lower(Weight)

    var id: String {
        switch self {
        case .menu: "menu"
        case .gate: "gate"
        case .discard: "discard"
        case .weight: "weight"
        case .lower(let weight): "lower-\(weight.hundredths)-\(weight.unit.rawValue)"
        }
    }
}

// MARK: - The exercise counter as navigation (§6.4)

/// `3 / 5 ▾` opens this: every Exercise with its state as a pill, under the line that
/// names the distinction the UI must never conflate (§3.2).
struct ExerciseListDrawer: View {
    let workout: Workout
    let pick: (Int) -> Void
    let finish: () -> Void
    let close: () -> Void

    var body: some View {
        ZStack {
            Color.floor.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(workout.workoutDayName)
                        .typography(Typography.display(15, tracking: 0.06))
                        .foregroundStyle(Color.text)
                    Spacer()
                    Button(action: close) {
                        Text("Close ✕")
                            .typography(Typography.label(10.5))
                            .foregroundStyle(Color.steel)
                            .frame(height: 50)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .frame(height: 50)

                Text("Leaving an open exercise means later, never \"not at all\".")
                    .typography(Typography.body(12, lineSpacing: 4))
                    .foregroundStyle(Color.dimText)

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(workout.exercises.enumerated()), id: \.offset) { index, performed in
                            row(index, performed)
                        }
                    }
                }
                .scrollBounceBehavior(.basedOnSize)

                PrimaryButton("Finish workout", action: finish)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private func row(_ index: Int, _ performed: PerformedExercise) -> some View {
        Button { pick(index) } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(performed.name)
                        .typography(Typography.body(14))
                        .foregroundStyle(Color.text)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(setLine(performed))
                        .typography(Typography.label(10, tracking: 0.12))
                        .foregroundStyle(Color.dimText)
                }
                Spacer(minLength: 8)
                StatePill(state: performed.state)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(Color.card)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(index == workout.currentIndex ? Color.text : Color.line, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// The Sets logged, and nothing else. The **planned** Sets live on the Exercise and a
    /// drawer that resolved every one of them would be the logging screen five times over.
    private func setLine(_ performed: PerformedExercise) -> String {
        switch performed.sets.count {
        case 0: "No sets yet"
        case 1: "1 set logged"
        default: "\(performed.sets.count) sets logged"
        }
    }
}

/// Open / Completed / Skipped (§3.2). **No warning colour** — §7.6 keeps colour off
/// anything the user did, and skipping is a decision, not a mistake.
struct StatePill: View {
    let state: ExerciseState

    var body: some View {
        Text(state.rawValue)
            .typography(Typography.label(10, tracking: 0.08))
            .foregroundStyle(colour)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(colour, lineWidth: 1))
    }

    private var colour: Color {
        switch state {
        case .open: Color.steel
        case .completed: Color.go
        case .skipped: Color.labelText
        }
    }
}

// MARK: - The small parts

enum ChipTone { case steel, go }

/// §7.6's chip: uppercase, a 1 px border, never filled — which is §7.1 rule 2 read from
/// the other side. A chip is steel or green and never a plate colour, because a plate
/// colour is a plate **only inside a Plate Breakdown** (§7.1).
struct Chip: View {
    let text: String
    let tone: ChipTone

    init(_ text: String, tone: ChipTone) {
        self.text = text
        self.tone = tone
    }

    var body: some View {
        Text(text)
            .typography(Typography.label(10, tracking: 0.1))
            .foregroundStyle(colour)
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(border, lineWidth: 1))
    }

    private var colour: Color { tone == .go ? Color.go : Color.steel }
    private var border: Color { tone == .go ? Color.go : Color.chipBorder }
}

/// The bottom sheets of §6.4 and §3.3, which are all the same shape: a heading, an
/// optional sentence, and a column of 54 pt rows.
struct SheetStack<Content: View>: View {
    let heading: String
    var note: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Color.floor.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 14) {
                Text(heading)
                    .typography(Typography.display(19))
                    .foregroundStyle(Color.text)
                    .lineLimit(2)
                if let note {
                    Text(note)
                        .typography(Typography.body(13, lineSpacing: 3))
                        .foregroundStyle(Color.dimText)
                }
                content
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
            .padding(.bottom, 24)
        }
        .presentationDetents([.medium])
    }
}

enum SheetTone { case plain, stop }

struct SheetRow: View {
    let title: String
    let sub: String?
    var tone: SheetTone = .plain
    var centred: Bool = false
    let act: () -> Void

    init(
        _ title: String, sub: String?, tone: SheetTone = .plain, centred: Bool = false,
        act: @escaping () -> Void
    ) {
        self.title = title
        self.sub = sub
        self.tone = tone
        self.centred = centred
        self.act = act
    }

    var body: some View {
        Button(action: act) {
            HStack(spacing: 10) {
                if centred { Spacer(minLength: 0) }
                Text(title)
                    .typography(Typography.body(15))
                    .foregroundStyle(tone == .stop ? Color.stop : Color.text)
                Spacer(minLength: 8)
                if let sub, !centred {
                    Text(sub)
                        .typography(Typography.meta(11))
                        .foregroundStyle(Color.dimText)
                        .lineLimit(1)
                }
                if centred { Spacer(minLength: 0) }
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(tone == .stop ? Color.stop : Color.chipBorder, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// The one-tap way out of the Finish gate, in the inverted fill the rest of the app gives
/// its bottom control.
struct SheetPrimary: View {
    let title: String
    let act: () -> Void

    init(_ title: String, act: @escaping () -> Void) {
        self.title = title
        self.act = act
    }

    var body: some View {
        Button(action: act) {
            Text(title)
                .typography(Typography.display(18, tracking: 0.02))
                .foregroundStyle(Color.floor)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.text)
                .clipShape(RoundedRectangle(cornerRadius: 3))
        }
        .buttonStyle(.plain)
    }
}
