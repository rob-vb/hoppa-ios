import HoppaRules

// Ticket 0043 — the Exercise sheet's memory of a unit change.
//
// **It imports no SwiftUI on purpose.** `ExerciseSheet` cannot be compiled anywhere but
// the Mac, and ticket 0029's rule says logic worth a test does not belong in a view. This
// is not a rule either — it decides nothing from the `Logbook`, and two lifters with the
// same `Logbook` are not owed the same answer, because it is the state of one visit to
// one sheet — so it does not belong in `HoppaRules`. It sits in the app target as a plain
// value, where `swiftc -typecheck` against the built modules reaches it and a throwaway
// harness can walk every flip.

/// The three fields a change of unit takes off the Exercise sheet (`SPEC.md` §6.6), held
/// as the **text** the user typed rather than as `Weight`s.
///
/// Text, because the text is the truth while the sheet is open: a half-typed `72.` is not
/// a `Weight` and has to survive a flip like any other. And text carries no unit label, so
/// nothing in here can go stale — the unit is the key it is filed under, and nothing else.
///
/// The two `…` chips ride along because they are part of the same answer: a custom
/// Increment or Stack Step that comes back to a row of offer chips is not the row the
/// user left.
struct TypedWeights: Equatable {
    var working = ""
    var increment = ""
    var stack = ""
    var incrementTyped = false
    var stackTyped = false

    var isEmpty: Bool { working.isEmpty && increment.isEmpty && stack.isEmpty }
}

/// **What the Exercise sheet remembers across a change of unit.**
///
/// §6.6 takes the Working Weight, the Increment and the Stack Step off the screen when the
/// unit the Exercise resolves to moves, and the save writes that emptiness — on an edit
/// sheet, closing *is* the save (§6.2) and there is no cancel, so one wrong tap on the
/// unit chip was the last word on three numbers.
///
/// **A file per unit, and not one memory of the unit at open.** After a flip and a retype
/// two numbers compete for the same field, and *which unit was it typed in* is the only
/// thing that tells them apart — the same answer ticket 0041 gave the rule. Filed that
/// way, both survive, each under its own label, and nothing is ever converted or merged
/// (§5.1). It also means there is nothing special about the first unit the sheet drew: the
/// add sheet's one free move, from the Program's default to whatever the first Equipment
/// Type resolves to, carries an empty screen and so files nothing.
///
/// The stash lives and dies with the sheet. What the save writes is what is on the screen.
struct UnitStash: Equatable {
    private var filed: [WeightUnit: TypedWeights] = [:]

    /// The unit the outgoing numbers went under, when the last move filed any. The sheet
    /// says so under the fields; `forget()` ends the sentence.
    private(set) var heldUnit: WeightUnit?
    /// Whether the last move brought numbers back out. Both can be true at once — flip,
    /// retype, flip back.
    private(set) var numbersReturned = false

    /// Whether anything is filed away. An add sheet's `✕` asks before it throws this out,
    /// because numbers held under the other unit are one tap from the screen.
    var hasNumbers: Bool { filed.values.contains { !$0.isEmpty } }

    /// File what is on the screen under the unit that is leaving, and hand back what was
    /// filed under the unit that is arriving — empty, if nothing was.
    ///
    /// **An empty screen files nothing *and* forgets what the leaving unit held.** Those
    /// numbers were handed back once already and then cleared by hand, which is the user
    /// saying they are gone.
    mutating func move(from leaving: WeightUnit, to arriving: WeightUnit,
                       onScreen: TypedWeights) -> TypedWeights {
        filed[leaving] = onScreen.isEmpty ? nil : onScreen
        let returning = filed.removeValue(forKey: arriving) ?? TypedWeights()
        heldUnit = onScreen.isEmpty ? nil : leaving
        numbersReturned = !returning.isEmpty
        return returning
    }

    /// The note answers the last move, so the next keystroke ends it. **What is filed
    /// stays filed**: typing in this unit says nothing about the numbers under the other.
    mutating func forget() {
        heldUnit = nil
        numbersReturned = false
    }

    /// What the sheet says under the fields — **and it no longer says *cleared***, because
    /// nothing is. It says where the numbers went and how to get them back, which is the
    /// sentence that makes a mis-tap survivable.
    ///
    /// `nil` when the last move did nothing worth reporting, which is every move on a
    /// sheet with no numbers on it.
    func note(showing unit: WeightUnit) -> String? {
        var parts: [String] = []
        if numbersReturned {
            parts.append(
                "The weight, the increment and the stack step you typed in \(unit.rawValue) are back.")
        }
        if let held = heldUnit {
            parts.append(
                "What you typed in \(held.rawValue) is kept under \(held.rawValue) — go back to \(held.rawValue) and it returns.")
        }
        guard !parts.isEmpty else { return nil }
        return (["The unit is now \(unit.rawValue)."] + parts).joined(separator: " ")
    }
}
