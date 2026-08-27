import Foundation
import Testing
@testable import HoppaStore

// Ticket 0047 — §6.7's streak.
//
// Every case runs against a **fixed** calendar and a **named** time zone, for the same
// reason `RelativeDayTests` does: `Calendar.current` would make the suite read the machine
// it runs on, and the whole reason this is not a rule is that the answer depends on a zone
// and on a first weekday.

@Suite("The streak (SPEC.md §6.7)")
struct StreakTests {

    private static let zone = TimeZone(identifier: "Europe/Amsterdam")!

    /// Rob's own: Monday first, which is what makes `2026-08-17` a week start below.
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Self.zone
        calendar.firstWeekday = 2
        return calendar
    }

    /// The other half of the world, to prove the first weekday is the calendar's and not
    /// Hoppa's opinion.
    private var sundayCalendar: Calendar {
        var calendar = self.calendar
        calendar.firstWeekday = 1
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

    private func day(_ timestamp: Double) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = Self.zone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date(timeIntervalSince1970: timestamp))
    }

    private func read(_ dates: [String], now: String, calendar: Calendar? = nil) -> Streak {
        Streak.read(
            startedAt: dates.map { at($0) }, now: at(now), calendar: calendar ?? self.calendar)
    }

    // MARK: - Which week an instant falls in

    @Test("A week starts on the calendar's first weekday, not on Hoppa's")
    func firstWeekday() {
        // Wednesday 19 August 2026.
        let wednesday = at("2026-08-19 18:00")
        #expect(day(Streak.weekStart(wednesday, calendar)) == "2026-08-17")       // Monday
        #expect(day(Streak.weekStart(wednesday, sundayCalendar)) == "2026-08-16") // Sunday
    }

    @Test("A week starts at midnight local, so a 23:30 workout is still that week")
    func lateNight() {
        #expect(day(Streak.weekStart(at("2026-08-23 23:30"), calendar)) == "2026-08-17")
        // Half an hour later is the next week.
        #expect(day(Streak.weekStart(at("2026-08-24 00:30"), calendar)) == "2026-08-24")
    }

    // MARK: - The strip

    @Test("Before the first Workout there is no strip and no figure")
    func empty() {
        let streak = read([], now: "2026-08-26 09:00")
        #expect(streak.weeks.isEmpty)
        #expect(streak.run == 0)
    }

    @Test("The strip starts at the first Workout, not sixteen weeks before it")
    func startsAtTheFirstWorkout() {
        // Two weeks in. Fourteen dark blocks would be fourteen weeks he did not own the app.
        let streak = read(["2026-08-11 18:00", "2026-08-19 18:00"], now: "2026-08-19 20:00")
        #expect(streak.weeks.count == 2)
        #expect(streak.weeks.map(\.trained) == [true, true])
        #expect(day(streak.weeks[0].start) == "2026-08-10")
    }

    @Test("It ends on the week that holds now, trained or not")
    func endsOnThisWeek() {
        let streak = read(["2026-08-11 18:00"], now: "2026-08-26 09:00")
        #expect(streak.weeks.count == 3)
        #expect(streak.weeks.map(\.trained) == [true, false, false])
        #expect(day(streak.weeks.last!.start) == "2026-08-24")
    }

    @Test("A missed week is one dark block between two lit ones")
    func aHoleInTheMiddle() {
        let streak = read(
            ["2026-07-06 18:00", "2026-07-20 18:00", "2026-07-27 18:00"], now: "2026-07-29 09:00")
        #expect(streak.weeks.map(\.trained) == [true, false, true, true])
    }

    @Test("One Workout is enough to light a week, and four light it no brighter")
    func oneWorkoutLightsAWeek() {
        let one = read(["2026-08-19 18:00"], now: "2026-08-21 09:00")
        let four = read(
            ["2026-08-17 18:00", "2026-08-18 18:00", "2026-08-20 18:00", "2026-08-21 18:00"],
            now: "2026-08-21 09:00")
        #expect(one.weeks == four.weeks)
    }

    @Test("The strip never draws more than sixteen blocks")
    func sixteenBlocks() {
        // One Workout a week for thirty weeks, ending this week.
        let dates = (0..<30).map { week -> String in
            let monday = at("2026-08-17 18:00") - Double(week * 7 * 86_400)
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.timeZone = Self.zone
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            return formatter.string(from: Date(timeIntervalSince1970: monday))
        }
        let streak = read(dates, now: "2026-08-19 09:00")
        #expect(streak.weeks.count == Streak.blocks)
        #expect(streak.weeks.filter(\.trained).count == Streak.blocks)
        // The figure is not capped with the strip: thirty weeks read thirty.
        #expect(streak.run == 30)
    }

    // MARK: - The figure

    @Test("The run counts back from this week")
    func run() {
        let streak = read(
            ["2026-08-03 18:00", "2026-08-11 18:00", "2026-08-19 18:00"], now: "2026-08-19 20:00")
        #expect(streak.run == 3)
    }

    @Test("An empty current week does not break the run — Monday morning still reads three")
    func mondayMorning() {
        let streak = read(
            ["2026-08-03 18:00", "2026-08-11 18:00", "2026-08-19 18:00"], now: "2026-08-24 07:00")
        #expect(streak.run == 3)
        #expect(streak.weeks.last!.trained == false)
    }

    @Test("A whole week missed does break it")
    func aWholeWeekMissed() {
        let streak = read(
            ["2026-08-03 18:00", "2026-08-11 18:00", "2026-08-19 18:00"], now: "2026-08-31 07:00")
        #expect(streak.run == 0)
    }

    @Test("The run stops at the hole and counts only what follows it")
    func runStopsAtTheHole() {
        let streak = read(
            ["2026-07-06 18:00", "2026-07-20 18:00", "2026-07-27 18:00"], now: "2026-07-29 09:00")
        #expect(streak.run == 2)
    }

    @Test("A clock moved back behind the history invents no weeks after it")
    func clockMovedBack() {
        let streak = read(["2026-08-19 18:00"], now: "2026-01-01 09:00")
        #expect(streak.weeks.count == 1)
        #expect(streak.weeks[0].trained)
    }
}
