import Foundation
import HoppaRules

// Ticket 0032 — the Workout Day picker.
//
// **This is not a rule, and the map's `is-this-a-rule` test says why.** The *instant* a
// Workout Day was last done is `Logbook.lastTrained(_:)` in `HoppaRules`: it falls out of
// the Logbook alone, and two lifters holding the same Logbook must read the same answer.
// Turning that instant into "4 days ago" fails the second half of the clause — it needs a
// calendar and a time zone, and two lifters in two zones may then correctly *disagree*
// about whether the same instant was yesterday.
//
// It was written in the app target and moved here the same session, on ticket 0029's rule:
// **if a screen grows logic worth testing, that logic does not belong in the view** — it
// belongs in `HoppaRules` or `HoppaStore`, where a test is cheap and runs on this machine.
// It is the whole of what the picker computes, so it is the whole of what can be wrong.

/// §3.1's picker line: *when the user last did each Day*. Information, not advice (§7.6).
public enum RelativeDay {

    /// Sentence case, as the artboard writes it: `Yesterday`, `2 days ago`.
    ///
    /// - `nil` — the Day has never been done. Every Day a fresh Program creates is in this
    ///   state, so it is the common first case and not an edge.
    /// - The comparison is in **calendar days**, not in 24-hour periods: a Workout at
    ///   21:00 and a glance at 07:00 the next morning reads *Yesterday*, which is what a
    ///   person means. That is the whole reason a time zone is involved.
    /// - A timestamp in the future — a phone whose clock moved back — reads `Today`
    ///   rather than a negative count.
    public static func text(_ then: Timestamp?, now: Timestamp, calendar: Calendar = .current) -> String {
        guard let then else { return "Never" }
        let days = daysBetween(then, and: now, calendar: calendar)
        return switch days {
        case ..<1: "Today"
        case 1: "Yesterday"
        default: "\(days) days ago"
        }
    }

    /// Whole calendar days from the start of `then`'s day to the start of `now`'s day.
    public static func daysBetween(_ then: Timestamp, and now: Timestamp, calendar: Calendar) -> Int {
        let from = calendar.startOfDay(for: Date(timeIntervalSince1970: then))
        let to = calendar.startOfDay(for: Date(timeIntervalSince1970: now))
        return calendar.dateComponents([.day], from: from, to: to).day ?? 0
    }
}
