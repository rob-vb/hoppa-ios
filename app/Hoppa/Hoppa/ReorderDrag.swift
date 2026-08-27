// Ticket 0044 — where a dragged card is, in list positions.
//
// The whole of the reorder handle's arithmetic with the SwiftUI dropped. It **imports
// nothing**, so `app/checks/Reorder/run.sh` walks it on the machine that cannot build a
// view — the same trick ticket 0043 used for `UnitStash`. A hand-rolled drag whose maths
// nobody can run is exactly the thing that comes back off the Mac as a defect.
//
// It is not a rule: it decides nothing from the `Logbook`, and two lifters with the same
// `Logbook` and different fingers get different answers, which is the whole point of it.
// What it produces is a **position**, and `Rules.moveExercise` clamps that again before it
// believes it (§6.6).
struct ReorderDrag {
    /// Where the dragged item sits in the stored list.
    let origin: Int
    /// How many items the list holds. A drop can never land outside it.
    let count: Int
    /// One row plus the gap under it: the distance a card travels to pass its neighbour.
    let pitch: Double
    /// How far the finger has travelled, positive down.
    var travel: Double = 0

    /// The position the finger is over now.
    ///
    /// Rounded, not truncated: a card lands on the neighbour it has covered **half** of,
    /// so the drop happens where the eye says it does rather than a whole row later.
    var landing: Int {
        guard count > 0, pitch > 0 else { return origin }
        return min(max(0, origin + Int((travel / pitch).rounded())), count - 1)
    }

    /// How far the row at `index` is drawn from where it was laid out.
    ///
    /// The dragged row follows the finger exactly. Every row between where it started and
    /// where it is now moves **one** place to make the gap — never more, because a drag
    /// past three rows still only opens one hole.
    func shift(_ index: Int) -> Double {
        let landing = landing
        if index == origin { return travel }
        if origin < landing, index > origin, index <= landing { return -pitch }
        if origin > landing, index >= landing, index < origin { return pitch }
        return 0
    }

    /// The position the row at `index` is drawn **at**: the previewed order, so a numbered
    /// list renumbers under the finger and the drop confirms what was already on screen.
    func position(_ index: Int) -> Int {
        let landing = landing
        if index == origin { return landing }
        if origin < landing, index > origin, index <= landing { return index - 1 }
        if origin > landing, index >= landing, index < origin { return index + 1 }
        return index
    }

    /// The whole list as the eye reads it right now. Nothing on screen uses this — it is
    /// what the check asserts against, because *every row in the right place* is one
    /// statement and eight offsets are not.
    func preview() -> [Int] {
        var order = Array(repeating: 0, count: count)
        for index in 0..<count { order[position(index)] = index }
        return order
    }
}
