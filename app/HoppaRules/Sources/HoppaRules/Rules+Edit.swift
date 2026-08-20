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
public struct ExerciseDraft: Sendable, Hashable {
    public var name: String
    public var equipment: EquipmentType
    /// Meaningful for Dumbbell, Machine (stack) and Cable. The sheet locks the row for
    /// the four types that read the rack (§2.3), so what it carries for those is ignored.
    public var ownWeightUnit: WeightUnit
    public var plannedSets: Int
    public var repRange: RepRange
    public var workingWeight: Weight?
    public var increment: Weight?
    public var microloadingIncrement: Weight?
    public var modeOverride: ProgressionMode?
    /// Smith and plate-loaded only. `nil` from a sheet that showed no row for it, which
    /// is why it is written back only where the new Equipment Type has one.
    public var baseWeight: Weight?
    /// Machine (stack) and Cable only, same rule.
    public var stackStep: Weight?

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
        stackStep: Weight? = nil
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
    }

    /// The sheet as it reads the moment it opens on an existing Exercise.
    public init(_ exercise: Exercise) {
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
            stackStep: exercise.storedStackStep)
    }

    /// A brand-new Exercise. A Microload is created at zero where the pin needs one
    /// (§2.3); everything else is exactly what the sheet holds.
    func exercise(id: ExerciseID, inventory: PlateInventory) -> Exercise {
        var made = Exercise(
            id: id,
            name: name,
            equipment: equipment,
            ownWeightUnit: ownWeightUnit,
            plannedSets: max(1, plannedSets),
            repRange: repRange,
            workingWeight: workingWeight,
            increment: increment,
            microloadingIncrement: microloadingIncrement,
            modeOverride: modeOverride)
        if equipment.takesBaseWeight { made.storedBaseWeight = baseWeight }
        if equipment.hasPin { made.storedStackStep = stackStep }
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
        new.workingWeight = draft.workingWeight
        new.increment = draft.increment
        new.microloadingIncrement = draft.microloadingIncrement
        new.modeOverride = draft.modeOverride

        // Written back only where the new Equipment Type shows the row. A sheet on a
        // Barbell shows no Base Weight, so it carries none — and §2.3 refuses to re-ask
        // a fact about a machine, so the stored one survives the change of type (§2.8).
        if new.equipment.takesBaseWeight { new.storedBaseWeight = draft.baseWeight }
        if new.equipment.hasPin { new.storedStackStep = draft.stackStep }

        // §6.6: **changing a Weight Unit clears the weights.** Converting was rejected
        // because it produces numbers no machine in the gym can make. The unit is derived
        // (§5.1), so a change of Equipment Type across the rack boundary is the same
        // event as flipping the unit switch — both leave a number labelled with a unit
        // it was never typed in.
        let oldUnit = old.weightUnit(in: inventory)
        let newUnit = new.weightUnit(in: inventory)
        if newUnit != oldUnit {
            new.workingWeight = nil
            new.increment = nil
            new.storedStackStep = nil
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
