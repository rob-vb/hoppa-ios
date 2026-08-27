import HoppaRules

// Ticket 0034 — the English a screen prints for a domain value.
//
// **Copy is a view thing** (§7.6), so it lives in the app target and not in `HoppaRules`:
// two lifters holding the same `Logbook` must see the same *answer*, not the same word,
// and the word is what a translation would change. `HoppaRules` keeps `rawValue`, which
// is a storage key — `machine-stack` is what the file on disk holds, and it is not a
// thing to show a lifter.
//
// Everything here is **sentence case**. `Typography.label` and `Typography.display`
// uppercase at the point of use (§7.6), so a screen that wants shouting gets it from the
// type role and a screen that wants a sentence is not left uppercasing back.

extension ProgressionMode {
    var screenName: String {
        switch self {
        case .progressiveOverload: "Progressive overload"
        case .microloading: "Microloading"
        }
    }
}

extension EquipmentType {
    /// What the Exercise card and the Exercise sheet call it (§2.6). The artboard's own
    /// words: `barbell`, `smith`, `stack`, `cable`.
    var screenName: String {
        switch self {
        case .barbell: "Barbell"
        case .smith: "Smith"
        case .plateLoaded: "Plate-loaded"
        case .bodyweight: "Bodyweight"
        case .dumbbell: "Dumbbell"
        case .stack: "Stack"
        case .cable: "Cable"
        }
    }
}

extension WorkoutDay {
    /// `6 exercises`, `1 exercise`, `No exercises`. Drawn on the hub's Day row and in the
    /// Day screen's own meta line, so it is written once.
    var exerciseCountText: String {
        switch exercises.count {
        case 0: "No exercises"
        case 1: "1 exercise"
        default: "\(exercises.count) exercises"
        }
    }
}

extension DeleteBlock {
    /// Why the delete refused (`SPEC.md` §6.6). One sentence, written once, because both
    /// blocks are stated in the same slot under the same control — and because a block
    /// the user cannot read is the bug the paragraph rules out.
    ///
    /// The first is the spec's own `FINISH YOUR WORKOUT FIRST`. The second is the line
    /// `ProgramSheet` already prints over an empty Day list, said again at the other end
    /// of the same rule: **it states the condition, not what the user should do** (§7.6).
    var reason: String {
        switch self {
        case .openWorkoutRunsOnIt: "Finish your workout first."
        case .lastDayInProgram: "A program needs at least one workout day."
        }
    }
}

extension ProgressionBlocker {
    /// Why the plate did not move (§4.1's four, and a missing Increment). **It states the
    /// condition, not what the user should do** (§7.6).
    ///
    /// Written once, since ticket 0049: §6.5's `STAYED` row and §6.7's chart chip name the
    /// same stopped plate from the same `Rules.progressionBlocker`, and two copies of the
    /// English could give one condition two names.
    var reason: String {
        switch self {
        case .noWorkingWeight: "no weight yet"
        case .noIncrement: "no increment yet"
        case .noMicroplate: "no microplates · set up your rack"
        case .stranded: "microplate switched off · set up your rack"
        case .unitMismatch: "microplate is in the other unit"
        case .noStackStep: "no stack step yet"
        }
    }
}
