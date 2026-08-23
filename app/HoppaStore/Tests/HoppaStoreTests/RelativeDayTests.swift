import Foundation
import Testing
@testable import HoppaStore

// Ticket 0032 — §3.1's picker line.
//
// Every case runs against a **fixed** calendar and a **named** time zone. `Calendar.current`
// would make the suite read the machine it runs on, and the whole reason this is not a rule
// is that the answer depends on a zone.

@Suite("Relative day (SPEC.md §3.1)")
struct RelativeDayTests {

    private static let zone = TimeZone(identifier: "Europe/Amsterdam")!

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Self.zone
        return calendar
    }

    private func at(_ text: String) -> Double {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = Self.zone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: text)!.timeIntervalSince1970
    }

    private func text(_ then: Double?, at now: String) -> String {
        RelativeDay.text(then, now: at(now), calendar: calendar)
    }

    /// Every Day of a Program the user has just created. The common first case.
    @Test("A Day never done reads Never")
    func never() {
        #expect(text(nil, at: "2026-08-23 07:00") == "Never")
    }

    @Test("Earlier the same day reads Today")
    func today() {
        #expect(text(at("2026-08-23 06:00"), at: "2026-08-23 07:00") == "Today")
    }

    /// The pair that says why this is not a rule. Ten hours apart and it reads *Yesterday*;
    /// seven hours apart and it reads *Today*. Elapsed time cannot tell them apart — a
    /// calendar and a time zone can, and a lifter in another zone would correctly disagree.
    @Test("It counts calendar days, not 24-hour periods")
    func calendarDays() {
        #expect(text(at("2026-08-22 21:00"), at: "2026-08-23 07:00") == "Yesterday")
        #expect(text(at("2026-08-23 00:10"), at: "2026-08-23 07:00") == "Today")
    }

    @Test("Then it counts", arguments: [
        ("2026-08-21 18:00", "2 days ago"),
        ("2026-08-17 18:00", "6 days ago"),
        ("2026-06-23 18:00", "61 days ago")
    ])
    func counts(then: String, expected: String) {
        #expect(text(at(then), at: "2026-08-23 07:00") == expected)
    }

    /// A phone whose clock moved back, or a Workout logged on a plane. It must not print a
    /// negative count on the picker.
    @Test("A timestamp in the future reads Today, never a minus")
    func future() {
        #expect(text(at("2026-08-25 18:00"), at: "2026-08-23 07:00") == "Today")
    }

    /// Twenty-five hours long, and still exactly one day. This is the case a subtraction
    /// followed by a divide-by-86400 gets wrong.
    @Test("The DST fall-back is one day, not one and a bit")
    func daylightSaving() {
        #expect(text(at("2026-10-24 20:00"), at: "2026-10-25 20:00") == "Yesterday")
    }
}
