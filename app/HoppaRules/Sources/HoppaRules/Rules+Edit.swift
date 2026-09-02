/// Flow 5: editing a Program (`SPEC.md` §6.6).
///
/// Beside `Rules.swift` rather than inside it, because §6.6 is a different flow — but it
/// is the **same** `reduce`, the same `Logbook` in and out, and the same one door. The
/// moment an edit becomes a plain struct mutation in a view, rules live in two places.
///
/// > Decision record:
/// > [Program edits, and which of them are rules](../../../../issues/0026-program-edits-and-the-rules-boundary.md).

// MARK: - The sheet, as one value

/// One Exercise sheet as the user left it (`SPEC.md` §6.2 — Model B: one full sheet,
/// saved in one act).
///
/// It carries **`Weight?`** for the two typed weights, so *the user did not type one* and
/// *the user typed zero* are different values all the way from the keypad to the disk.
///
/// It also carries **`shownUnit`** — the unit its numbers were typed in. Without it the
/// clearing rule below cannot tell a stale number from a retyped one, and §6.6's promise
/// that *the same sheet asks for them again in the new unit* cannot be kept: the retyped
/// number arrives in the same draft as the unit change and is cleared with it. Proved on
/// both paths while building
/// [The Exercise sheet](../../../../issues/0035-the-exercise-sheet.md), settled at
/// [A weight retyped after a unit change](../../../../issues/0041-a-weight-retyped-after-a-unit-change.md).
public struct ExerciseDraft: Sendable, Hashable {
    public var name: String
    public var equipment: EquipmentType
    /// Meaningful for Dumbbell and Machine (Stack). The sheet locks the row for
    /// the three types that read the rack (§2.3), so what it carries for those is ignored.
    public var ownWeightUnit: WeightUnit
    public var plannedSets: Int
    public var repRange: RepRange
    public var workingWeight: Weight?
    public var increment: Weight?
    public var microloadingIncrement: Weight?
    public var modeOverride: ProgressionMode?
    /// Machine (Plates) only. `nil` from a sheet that showed no row for it, which
    /// is why it is written back only where the new Equipment Type has one.
    public var baseWeight: Weight?
    /// Machine (Stack) only, same rule.
    public var stackStep: Weight?
    /// **The unit this draft's numbers are written in** — the unit the sheet showed while
    /// the user typed, which is the unit the Exercise *resolved to* then (§5.1).
    ///
    /// It has no default on purpose. There are five places that build a draft, and a
    /// default would make *in which unit are these numbers* the one thing a caller can
    /// forget — which is exactly the bug this field closes. `ownWeightUnit` cannot stand
    /// in for it: the three types loaded off the rack ignore that field entirely.
    public var shownUnit: WeightUnit

    public init(
        name: String,
        equipment: EquipmentType,
        ownWeightUnit: WeightUnit = .kg,
        plannedSets: Int,
        repRange: RepRange,
        workingWeight: Weight? = nil,
        increment: Weight? = nil,
        microloadingIncrement: Weight? = nil,
        modeOverride: ProgressionMode? = nil,
        baseWeight: Weight? = nil,
        stackStep: Weight? = nil,
        shownUnit: WeightUnit
    ) {
        self.name = name
        self.equipment = equipment
        self.ownWeightUnit = ownWeightUnit
        self.plannedSets = plannedSets
        self.repRange = repRange
        self.workingWeight = workingWeight
        self.increment = increment
        self.microloadingIncrement = microloadingIncrement
        self.modeOverride = modeOverride
        self.baseWeight = baseWeight
        self.stackStep = stackStep
        self.shownUnit = shownUnit
    }

    /// The sheet as it reads the moment it opens on an existing Exercise.
    ///
    /// It takes the `PlateInventory` because it cannot work out `shownUnit` without one:
    /// every type except Machine (Stack) reads the rack, and `ownWeightUnit` is ignored
    /// (§5.1).
    public init(_ exercise: Exercise, in inventory: PlateInventory) {
        self.init(
            name: exercise.name,
            equipment: exercise.equipment,
            ownWeightUnit: exercise.ownWeightUnit,
            plannedSets: exercise.plannedSets,
            repRange: exercise.repRange,
            workingWeight: exercise.workingWeight,
            increment: exercise.increment,
            microloadingIncrement: exercise.microloadingIncrement,
            modeOverride: exercise.modeOverride,
            baseWeight: exercise.storedBaseWeight,
            stackStep: exercise.storedStackStep,
            shownUnit: exercise.weightUnit(in: inventory))
    }

    /// **The unit this draft resolves to** (§5.1) — the same derivation `Exercise` makes,
    /// asked of a sheet that has not been saved yet.
    func weightUnit(in inventory: PlateInventory) -> WeightUnit {
        equipment.takesUnitFromInventory ? inventory.unit : ownWeightUnit
    }

    /// §6.6, and the whole of it: **a number typed in a unit the Exercise no longer
    /// resolves to is not a number in this one**, so it goes.
    ///
    /// The test is `shownUnit != unit`, and **not** *did the unit move*. Those two came
    /// apart the moment §6.6 promised the same sheet would ask for the weights again: the
    /// sheet saves once (§6.2), so a number retyped after the flip rides in the very draft
    /// that carries the flip. What the draft was **shown** in is the only thing that tells
    /// a stale number from a retyped one — the number's own label cannot, because a stored
    /// label may be stale by design (§2.8) and `ExerciseDraft(_:in:)` copies stored labels.
    ///
    /// **Exactly the three fields §6.6 names.** The Microloading Increment keeps the Plate
    /// Inventory's unit whatever the Exercise does (§5.1), so it is never stale here. The
    /// Base Weight is in the rack's unit too, and that unit moves only when the *rack*
    /// moves — `setPlateInventoryUnit`, which does its own clearing. No edit to an
    /// Exercise can leave a Base Weight labelled wrong.
    func withoutStaleWeights(resolvingTo unit: WeightUnit) -> ExerciseDraft {
        guard shownUnit != unit else { return self }
        var kept = self
        kept.workingWeight = nil
        kept.increment = nil
        kept.stackStep = nil
        return kept
    }

    /// A brand-new Exercise. A Microload is created at zero where the pin needs one
    /// (§2.3); everything else is exactly what the sheet holds.
    ///
    /// It passes through the **same** guard as an edit. An add sheet can change its
    /// Equipment Type after a weight is typed, and a rule that defended only the edit path
    /// would leave the other half of the same sheet open.
    func exercise(id: ExerciseID, inventory: PlateInventory) -> Exercise {
        let sheet = withoutStaleWeights(resolvingTo: weightUnit(in: inventory))
        var made = Exercise(
            id: id,
            name: sheet.name,
            equipment: sheet.equipment,
            ownWeightUnit: sheet.ownWeightUnit,
            plannedSets: max(1, sheet.plannedSets),
            repRange: sheet.repRange,
            workingWeight: sheet.workingWeight,
            increment: sheet.increment,
            microloadingIncrement: sheet.microloadingIncrement,
            modeOverride: sheet.modeOverride)
        if sheet.equipment.takesBaseWeight { made.storedBaseWeight = sheet.baseWeight }
        if sheet.equipment.hasPin { made.storedStackStep = sheet.stackStep }
        made.microload = made.needsMicroload(in: inventory) ? .zero(inventory.unit) : nil
        return made
    }
}

/// Why a Workout Day cannot be deleted (`SPEC.md` §6.6). A block is stated **before** the
/// user commits, so the delete control can refuse with its reason where the user taps it.
public enum DeleteBlock: Sendable, Hashable {
    case openWorkoutRunsOnIt
    case lastDayInProgram
}

// MARK: - Locating

extension Exercise {
    /// Whether this Exercise has somewhere to hang a Microload: a pin, in a unit that is
    /// not the rack's (`SPEC.md` §2.3).
    func needsMicroload(in inventory: PlateInventory) -> Bool {
        equipment.hasPin && weightUnit(in: inventory) != inventory.unit
    }
}

extension Logbook {
    /// Where an Exercise lives. Positions, because every edit writes in place.
    struct Site {
        var program: Int
        var day: Int
        var exercise: Int
    }

    func site(of id: ExerciseID) -> Site? {
        for program in programs.indices {
            for day in programs[program].days.indices {
                if let exercise = programs[program].days[day].exercises
                    .firstIndex(where: { $0.id == id }) {
                    return Site(program: program, day: day, exercise: exercise)
                }
            }
        }
        return nil
    }

    func daySite(of id: WorkoutDayID) -> (program: Int, day: Int)? {
        for program in programs.indices {
            if let day = programs[program].days.firstIndex(where: { $0.id == id }) {
                return (program, day)
            }
        }
        return nil
    }

    func programIndex(_ id: ProgramID) -> Int? {
        programs.firstIndex { $0.id == id }
    }

    subscript(site: Site) -> Exercise {
        get { programs[site.program].days[site.day].exercises[site.exercise] }
        set { programs[site.program].days[site.day].exercises[site.exercise] = newValue }
    }

    func day(at site: Site) -> WorkoutDay {
        programs[site.program].days[site.day]
    }
}

// MARK: - The edits

extension Rules {

    /// The §6.6 half of `reduce`. `Rules.reduce` routes here and nowhere else calls it.
    static func applyEdit(_ logbook: Logbook, _ action: Action, at now: Timestamp) -> Logbook {
        var book = logbook

        switch action {

        // MARK: Program

        case .createProgram(let name, let defaultWeightUnit, let mode):
            book.programs.append(Program(
                id: ProgramID(book.mintId()),
                name: name,
                defaultWeightUnit: defaultWeightUnit,
                mode: mode,
                days: []))
            return book

        case .renameProgram(let id, let name):
            guard let index = book.programIndex(id) else { return logbook }
            book.programs[index].name = name
            return book

        case .setProgramDefaultWeightUnit(let id, let unit):
            // The default for new Exercises only (§2.1). Nothing that exists moves.
            guard let index = book.programIndex(id) else { return logbook }
            book.programs[index].defaultWeightUnit = unit
            return book

        case .setProgramMode(let id, let mode):
            guard let index = book.programIndex(id), book.programs[index].mode != mode
            else { return logbook }
            book.programs[index].mode = mode
            // §4.4: the Exercises that move to Microloading and hold no Microplate get
            // the default — the smallest one switched on, and none when the rack has
            // none on, which §5.2 makes the common case.
            guard mode == .microloading,
                  let smallest = book.plateInventory.enabledMicroplates.last
            else { return book }
            for day in book.programs[index].days.indices {
                for exercise in book.programs[index].days[day].exercises.indices
                where book.programs[index].days[day].exercises[exercise].modeOverride == nil
                    && book.programs[index].days[day].exercises[exercise].microloadingIncrement == nil {
                    book.programs[index].days[day].exercises[exercise].microloadingIncrement = smallest
                }
            }
            return book

        // MARK: Workout Days

        case .addWorkoutDay(let programId, let name):
            guard let index = book.programIndex(programId) else { return logbook }
            book.programs[index].days.append(
                WorkoutDay(id: WorkoutDayID(book.mintId()), name: name, exercises: []))
            return book

        case .renameWorkoutDay(let id, let name):
            guard let site = book.daySite(of: id) else { return logbook }
            book.programs[site.program].days[site.day].name = name
            return book

        case .moveWorkoutDay(let id, let to):
            guard let site = book.daySite(of: id) else { return logbook }
            var days = book.programs[site.program].days
            let target = min(max(0, to), days.count - 1)
            guard target != site.day else { return logbook }
            days.insert(days.remove(at: site.day), at: target)
            book.programs[site.program].days = days
            return book

        case .deleteWorkoutDay(let id):
            // The same rule the screen asked before the tap. A confirm that quietly does
            // nothing is not a block; it is a bug the user gets to diagnose.
            guard deleteBlock(forWorkoutDay: id, in: book) == nil,
                  let site = book.daySite(of: id)
            else { return logbook }
            // Past Workouts keep their Sets and the Day's Name: they are top-level values
            // that point at an id, and the store lets that link survive its target (§2.8).
            book.programs[site.program].days.remove(at: site.day)
            return book

        // MARK: Exercises

        case .addExercise(let workoutDayId, let at, let draft):
            guard let site = book.daySite(of: workoutDayId) else { return logbook }
            var exercises = book.programs[site.program].days[site.day].exercises
            let position = min(max(0, at), exercises.count)
            // The Exercise that will follow the new one, so the mirror below can put it
            // in the same place in a Workout whose list is not the Day's list.
            let following = position < exercises.count ? exercises[position].id : nil
            let made = draft.exercise(id: ExerciseID(book.mintId()), inventory: book.plateInventory)
            exercises.insert(made, at: position)
            book.programs[site.program].days[site.day].exercises = exercises

            // §6.6: it arrives **Open**, so it gates Finish like any other, and it
            // arrives at its place in the Workout Day, not at the end of the Workout.
            if var workout = book.openWorkout, workout.workoutDayId == workoutDayId {
                let index = following
                    .flatMap { id in workout.exercises.firstIndex { $0.exerciseId == id } }
                    ?? workout.exercises.count
                workout.exercises.insert(
                    PerformedExercise(exerciseId: made.id, name: made.name), at: index)
                // The user does not move: he keeps the card under his thumb (§6.4).
                if index <= workout.currentIndex { workout.currentIndex += 1 }
                book.openWorkout = workout
            }
            return book

        case .saveExercise(let id, let draft):
            guard let site = book.site(of: id) else { return logbook }
            let old = book[site]
            book[site] = edited(old, with: draft, inventory: book.plateInventory)
            book.openWorkout = mirrorSetsEdit(
                book.openWorkout, of: id, from: old.plannedSets, to: book[site].plannedSets)
            return book

        case .moveExercise(let id, let to):
            guard let site = book.site(of: id) else { return logbook }
            var exercises = book.day(at: site).exercises
            let target = min(max(0, to), exercises.count - 1)
            guard target != site.exercise else { return logbook }
            exercises.insert(exercises.remove(at: site.exercise), at: target)
            book.programs[site.program].days[site.day].exercises = exercises

            if var workout = book.openWorkout,
               workout.workoutDayId == book.day(at: site).id,
               let from = workout.exercises.firstIndex(where: { $0.exerciseId == id }) {
                // Whom the user is standing at, **before** the list moves under him.
                let standing = workout.current?.exerciseId
                let performed = workout.exercises.remove(at: from)
                let following = target + 1 < exercises.count ? exercises[target + 1].id : nil
                let index = following
                    .flatMap { id in workout.exercises.firstIndex { $0.exerciseId == id } }
                    ?? workout.exercises.count
                workout.exercises.insert(performed, at: index)
                // `currentIndex` follows the **Exercise**, not the position (§6.4).
                if let standing,
                   let now = workout.exercises.firstIndex(where: { $0.exerciseId == standing }) {
                    workout.currentIndex = now
                }
                book.openWorkout = workout
            }
            return book

        case .deleteExercise(let id):
            guard let site = book.site(of: id) else { return logbook }
            book.programs[site.program].days[site.day].exercises.remove(at: site.exercise)

            // It keeps the Sets it already logged — the user lifted them — and it stops
            // holding the Finish gate, because he cannot reach it any more (§6.6). The
            // list never shrinks, so `currentIndex` needs no repair.
            if var workout = book.openWorkout,
               let index = workout.exercises.firstIndex(where: { $0.exerciseId == id }),
               workout.exercises[index].state == .open {
                workout.exercises[index].state =
                    workout.exercises[index].sets.isEmpty ? .skipped : .completed
                book.openWorkout = workout
            }
            return book

        // MARK: The rack

        case .setPlateInventoryUnit(let unit):
            guard unit != book.plateInventory.unit else { return logbook }
            // The whole rack is replaced by the shipped one for the new unit: the old
            // unit's plate sizes are not sizes this rack has, and §5.2 ships every
            // Microplate off in both units.
            book.plateInventory = .standard(unit)

            for program in book.programs.indices {
                for day in book.programs[program].days.indices {
                    for index in book.programs[program].days[day].exercises.indices {
                        var exercise = book.programs[program].days[day].exercises[index]
                        // The four types whose unit the Inventory names (§5.1).
                        if exercise.equipment.takesUnitFromInventory {
                            exercise.workingWeight = nil
                            exercise.increment = nil
                            exercise.storedBaseWeight = nil
                        }
                        // Every Microloading Increment resets: the other unit's
                        // Microplates all ship off, so none of them is ownable now.
                        exercise.microloadingIncrement = nil
                        // Created or destroyed on every pin, and really destroyed (§2.8).
                        exercise.microload =
                            exercise.needsMicroload(in: book.plateInventory) ? .zero(unit) : nil
                        book.programs[program].days[day].exercises[index] = exercise
                    }
                }
            }
            // **The Open Workout's One-off Weights go with them.** A One-off is a number
            // for today in the Exercise's unit (§4.3), and `logSet` prefers it to the
            // Working Weight — so one left standing through a rack switch is the exact
            // stale number this whole section exists to prevent, and it would be written
            // into a Set under the new label. Only the four types that read the rack:
            // a Dumbbell in lbs keeps its own unit, and the switch never touched it.
            //
            // The Sets **already logged** are not touched, and must not be: a Set records
            // the weight as it was performed (§2.4), and those really were lifted.
            if var workout = book.openWorkout {
                for index in workout.exercises.indices {
                    guard let exercise = book.exercise(workout.exercises[index].exerciseId),
                          exercise.equipment.takesUnitFromInventory
                    else { continue }
                    workout.exercises[index].oneOffWeight = nil
                }
                book.openWorkout = workout
            }
            return book

        case .reweigh(let id, let weight):
            // **Zero is allowed here, and it is the whole reason this is not
            // `.setWorkingWeight`.** Zero is a real weight (§2.8): a Bodyweight Exercise
            // done with no belt. Refuse it and a chin-up that the rack switch cleared can
            // never leave the Re-weigh list, because the only true answer to *what do you
            // lift it with* is nothing.
            guard let exercise = book.exercise(id) else { return logbook }
            // Stored under the unit the Exercise resolves to now. The list types in that
            // unit — it is the one the row prints — and a label is never converted (§5.1).
            let unit = exercise.weightUnit(in: book.plateInventory)
            book.updateExercise(id) { $0.workingWeight = weight.relabelled(unit) }
            return book

        case .setPlate(let weight, let isOn):
            guard book.plateInventory.plates.contains(where: { $0.weight == weight })
                    || book.plateInventory.microplates.contains(where: { $0.weight == weight })
            else { return logbook }
            // Nothing else is written. Stranding is derived, so switching a plate back
            // on un-strands exactly what switching it off stranded (§6.6).
            book.plateInventory.setPlate(weight, on: isOn)
            return book

        default:
            // Unreachable: `reduce` routes only the cases above here, and it lists them
            // one by one, so the compiler rejects a new edit case that is not wired.
            return logbook
        }
    }

    // MARK: - The diff, which is where §6.6's rules live

    /// One draft applied to one Exercise, with the old value still in hand.
    ///
    /// This is why the sheet saves once. Split into ten field writes and the order they
    /// arrive in decides the answer: a sheet that changed the unit **and** typed the new
    /// weight would clear the weight it was just given.
    static func edited(_ old: Exercise, with draft: ExerciseDraft, inventory: PlateInventory) -> Exercise {
        var new = old
        new.name = draft.name
        new.equipment = draft.equipment
        new.ownWeightUnit = draft.ownWeightUnit
        new.plannedSets = max(1, draft.plannedSets)
        new.repRange = draft.repRange
        new.modeOverride = draft.modeOverride

        // §6.6: **changing a Weight Unit clears the weights.** Converting was rejected
        // because it produces numbers no machine in the gym can make. The unit is derived
        // (§5.1), so a change of Equipment Type across the rack boundary is the same
        // event as flipping the unit switch — both leave a number labelled with a unit
        // it was never typed in.
        let oldUnit = old.weightUnit(in: inventory)
        let newUnit = new.weightUnit(in: inventory)

        // **Two triggers, not one.** They used to be the same `if`, and that is the bug
        // this ticket closes.
        //
        // - The three typed fields go stale when **the draft was typed in another unit**.
        //   A number retyped after the flip is a good number in the new unit, and §6.6
        //   promises the sheet may ask for it in the same visit.
        // - The **Microload** goes when **the Exercise's unit moves**, retyped or not. It
        //   is not a number the sheet asks for: it is a state that belongs to a unit, and
        //   the unit it belonged to is gone.
        let sheet = draft.withoutStaleWeights(resolvingTo: newUnit)
        new.workingWeight = sheet.workingWeight
        new.increment = sheet.increment
        new.microloadingIncrement = sheet.microloadingIncrement

        // Written back only where the new Equipment Type shows the row. A sheet on a
        // Barbell shows no Base Weight, so it carries none — and §2.3 refuses to re-ask
        // a fact about a machine, so the stored one survives the change of type (§2.8).
        if new.equipment.takesBaseWeight { new.storedBaseWeight = sheet.baseWeight }
        if new.equipment.hasPin {
            new.storedStackStep = sheet.stackStep
        } else if newUnit != oldUnit {
            // No pin, so no row to retype it in, and its unit has moved under it. §2.8
            // keeps a Stack Step across a change of type; it does not keep one across a
            // change of unit, and here both happened at once.
            new.storedStackStep = nil
        }

        if newUnit != oldUnit {
            // The Microload follows the unit and never carries across: deleted when the
            // pin joins the rack's unit, created at zero when it leaves it (§2.8). Hiding
            // it instead would bring the old Microload back on a second unit change.
            new.microload = new.needsMicroload(in: inventory) ? .zero(inventory.unit) : nil
        }
        // The Microloading Increment survives untouched: it keeps the Plate Inventory's
        // unit whatever the Exercise does (§5.1).
        return new
    }

    /// §3.2 in an Open Workout, after the planned Sets changed.
    ///
    /// Two rules, and each is the other's mirror:
    ///
    /// - A **raise** above the Sets logged reopens what Hoppa completed *by itself*.
    ///   Done early is the exception — it never earned a progression, so a raise takes
    ///   none away, and it is a deliberate act an edit made afterwards must not argue
    ///   with. The old planned Sets tell the two apart, which is why no field has to.
    /// - **Lowering** to the number already logged Completes an Open Exercise. Without
    ///   it the Exercise is stuck: the plan is full so no Set can be logged, nothing
    ///   fires to complete it, and it holds the Finish gate until the user finds
    ///   *Done early* — at the rack, mid-set.
    static func mirrorSetsEdit(
        _ workout: Workout?, of id: ExerciseID, from old: Int, to new: Int
    ) -> Workout? {
        guard var workout,
              let index = workout.exercises.firstIndex(where: { $0.exerciseId == id })
        else { return workout }

        let logged = workout.exercises[index].sets.count
        switch workout.exercises[index].state {
        case .completed where logged >= old && logged < new:
            workout.exercises[index].state = .open
        case .open where logged >= new:
            workout.exercises[index].state = .completed
        default:
            break
        }
        return workout
    }

    // MARK: - The four questions a screen asks before the act

    /// **The Re-weigh list is every Exercise with no Working Weight** (`SPEC.md` §6.6) —
    /// which is what a change of unit has just made them, and what a new Exercise is
    /// before the user types. Nothing writes it down: leave the screen, close the app,
    /// come back a day later, and the same Exercises still have none.
    public static func reweighList(in logbook: Logbook) -> [ExerciseID] {
        logbook.allExercises.filter { $0.workingWeight == nil }.map(\.id)
    }

    /// What `setPlateInventoryUnit` is about to clear — `THIS CLEARS THE WEIGHT ON 12
    /// EXERCISES`, asked before the switch instead of after.
    ///
    /// The Exercises that **have a weight to lose**: one already unset loses nothing, and
    /// counting it would overstate the damage the user is being warned about.
    public static func exercisesClearedByInventoryUnit(
        _ unit: WeightUnit, in logbook: Logbook
    ) -> [ExerciseID] {
        guard unit != logbook.plateInventory.unit else { return [] }
        return logbook.allExercises
            .filter { $0.equipment.takesUnitFromInventory && $0.workingWeight != nil }
            .map(\.id)
    }

    /// What switching this Microplate off would strand — `3 EXERCISES USE THIS PLATE`.
    /// The same rule `ResolvedExercise.isStranded` states afterwards.
    public static func exercisesUsingMicroplate(
        _ plate: Weight, in logbook: Logbook
    ) -> [ExerciseID] {
        let wanted = plate.relabelled(logbook.plateInventory.unit)
        return logbook.allExercises
            .filter { $0.microloadingIncrement?.relabelled(logbook.plateInventory.unit) == wanted }
            .map(\.id)
    }

    /// Why this Workout Day cannot be deleted, or `nil` when it can (`SPEC.md` §6.6).
    public static func deleteBlock(
        forWorkoutDay id: WorkoutDayID, in logbook: Logbook
    ) -> DeleteBlock? {
        guard let site = logbook.daySite(of: id) else { return nil }
        if logbook.openWorkout?.workoutDayId == id { return .openWorkoutRunsOnIt }
        // A Program with no Days cannot be started.
        if logbook.programs[site.program].days.count == 1 { return .lastDayInProgram }
        return nil
    }
}
