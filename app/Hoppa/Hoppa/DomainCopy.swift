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
