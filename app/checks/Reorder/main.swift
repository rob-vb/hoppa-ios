// Ticket 0044 — the reorder handle's arithmetic, walked on this machine.
//
// `ReorderDrag.swift` is the **real file**, compiled in beside this one, so every number
// here is the one the phone uses. What it cannot say is whether the drag *feels* right —
// that is the hand-off's job, and it is why the checks below are about where a card lands
// and never about how it got there.
//
// The last block is the one that matters most: **what the finger sees is what the rule
// does**. `preview()` is compared against `remove(at:) / insert(at:)` — the two lines
// `Rules.moveExercise` runs — for every start and every landing in a five-row list. A
// preview that disagreed with the rule would leave the user watching one order and getting
// another, and no rules test can catch that, because the preview is not a rule.
//
// Run it with `./run.sh`.
import Foundation

nonisolated(unsafe) var failures = 0
func check(_ what: String, _ ok: Bool) {
    print((ok ? "ok   " : "FAIL ") + what)
    if !ok { failures += 1 }
}

/// The list both screens draw: a 62 pt card with a 6 pt gap under it.
let pitch = 68.0

func drag(_ origin: Int, _ travel: Double, count: Int = 5) -> ReorderDrag {
    ReorderDrag(origin: origin, count: count, pitch: pitch, travel: travel)
}

/// The move as `HoppaRules` performs it (`Rules+Edit.swift`).
func moved(_ order: [Int], from: Int, to: Int) -> [Int] {
    var order = order
    order.insert(order.remove(at: from), at: to)
    return order
}

// MARK: - A finger that has not moved

do {
    let d = drag(2, 0)
    check("no travel lands where it started", d.landing == 2)
    check("and nothing is displaced", (0..<5).allSatisfy { d.shift($0) == 0 })
    check("and the order on screen is the stored one", d.preview() == [0, 1, 2, 3, 4])
}

// MARK: - Half a row is the tipping point

do {
    check("a third of a row down holds its place", drag(1, 22).landing == 1)
    check("just under half still holds", drag(1, 33).landing == 1)
    check("just over half moves one", drag(1, 35).landing == 2)
    check("just under half up holds", drag(1, -33).landing == 1)
    check("just over half up moves one", drag(1, -35).landing == 0)
}

// MARK: - The hole a drag opens is one row wide, however far it goes

do {
    let d = drag(0, 3 * pitch)
    check("three rows down lands on the fourth", d.landing == 3)
    check("the dragged card follows the finger exactly", d.shift(0) == 3 * pitch)
    check("row 1 steps up one place, not three", d.shift(1) == -pitch)
    check("so does row 2", d.shift(2) == -pitch)
    check("so does row 3", d.shift(3) == -pitch)
    check("and row 4, which was never passed, does not move", d.shift(4) == 0)
    check("the order on screen", d.preview() == [1, 2, 3, 0, 4])
}

do {
    let d = drag(4, -3 * pitch)
    check("three rows up lands on the second", d.landing == 1)
    check("the rows it passed step down one place", d.shift(1) == pitch && d.shift(3) == pitch)
    check("and row 0 does not move", d.shift(0) == 0)
    check("the order on screen", d.preview() == [0, 4, 1, 2, 3])
}

// MARK: - A finger that leaves the list

do {
    check("a drag far past the end lands on the end", drag(0, 40 * pitch).landing == 4)
    check("a drag far past the top lands on the top", drag(4, -40 * pitch).landing == 0)
    // The view clamps so the preview is drawable; `Rules.moveExercise` clamps again,
    // because a rule never trusts a view for a range.
    check("a one-row list has nowhere to go", drag(0, 9 * pitch, count: 1).landing == 0)
    check("an empty list does not divide by anything", drag(0, 100, count: 0).landing == 0)
}

// MARK: - What the finger sees is what the rule does

do {
    let stored = [0, 1, 2, 3, 4]
    var agreed = 0
    for origin in 0..<5 {
        for landing in 0..<5 {
            let d = drag(origin, Double(landing - origin) * pitch)
            guard d.landing == landing else {
                check("landing \(origin)→\(landing) is reachable", false)
                continue
            }
            if d.preview() == moved(stored, from: origin, to: landing) { agreed += 1 }
            else { check("preview \(origin)→\(landing) matches the rule", false) }
        }
    }
    check("all 25 previews match remove-then-insert", agreed == 25)
}

// MARK: - The preview is always a real list

do {
    var sound = true
    for count in 1...8 {
        for origin in 0..<count {
            for step in -10...10 {
                let order = drag(origin, Double(step) * pitch, count: count).preview()
                if order.sorted() != Array(0..<count) { sound = false }
            }
        }
    }
    check("every preview is a permutation, at every length and every travel", sound)
}

print(failures == 0 ? "\nall green" : "\n\(failures) FAILED")
// A red check exits 1, so a runner never reads a failure as a pass.
exit(failures == 0 ? 0 : 1)
