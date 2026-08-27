import Foundation
import HoppaRules

// Ticket 0047 — §6.7's streak.
//
// **This is not a rule, and it is the same clause that kept `RelativeDay` out of
// `HoppaRules`.** Which Workouts there are falls out of the `Logbook` alone; which *week*
// one of them fell in does not — it needs a calendar, a first weekday and a time zone, and
// two lifters in two zones may then correctly disagree about the same instant. So it sits
// beside `RelativeDay`, which already owns the app's calendar, and **the app holds one week
// rule and not two**: every block, the foot labels and the figure above the strip all come
// out of this one call.
//
// The compiler had the last word on that, as the map's `is-this-a-rule` test demands: a
// week boundary cannot be reached without `Foundation`. Dividing epoch seconds by 604 800
// would compile in `HoppaRules` and would be wrong — it fixes every week to a Thursday in
// UTC, which is nobody's week.
//
// Artboard: `design/0015-history/History.dc.html`, sixteen blocks with one dark.

/// §6.7's streak: one block per week, and the current run as a figure.
///
/// **A week counts as soon as it holds one Workout** — the question is whether the user
/// went, and a busy week with one session does not wipe the run.
public struct Streak: Sendable, Hashable {

    /// One block. `trained` is the whole of what it carries: §6.7 refuses a count, a
    /// flame, a warning and a best-ever number, so a week is on or it is off.
    public struct Week: Sendable, Hashable, Identifiable {
        /// The first instant of that week, in the calendar that built it.
        public var start: Timestamp
        public var trained: Bool

        public var id: Timestamp { start }

        public init(start: Timestamp, trained: Bool) {
            self.start = start
            self.trained = trained
        }
    }

    /// Oldest first, left to right, ending on the week that holds `now`. Empty before the
    /// first Workout — §6.7's empty state is what draws that.
    public var weeks: [Week]
    /// `9` · `WEEKS IN A ROW`. Counted over **all** of history and not only the blocks on
    /// screen, so a run longer than the strip still reads true.
    public var run: Int

    public init(weeks: [Week] = [], run: Int = 0) {
        self.weeks = weeks
        self.run = run
    }

    /// How many blocks the strip draws at most. Sixteen, as the artboard has it: the strip
    /// is one screen wide and a seventeenth block is a sliver.
    public static let blocks = 16

    /// Read the strip and the figure off the dates Workouts were **started** on (§2.4).
    ///
    /// Two decisions live here, both judgment calls this ticket made rather than asked:
    ///
    /// - **The strip starts at the first Workout, never before it.** A lifter two weeks in
    ///   sees two blocks, not two blocks and fourteen dark ones. Fourteen dark blocks are
    ///   fourteen weeks he did not train before he owned the app, and drawing them would be
    ///   the comparison §6.7 removed the best-ever number to avoid (§7.6).
    /// - **The current week never breaks the run while it is still running.** A run counts
    ///   back from the week that holds `now` when that week already has a Workout, and from
    ///   the week before it when it does not. Otherwise the figure would fall to zero every
    ///   Monday morning and climb back on the first session — Hoppa would be reporting the
    ///   day of the week, not the run.
    public static func read(
        startedAt: [Timestamp], now: Timestamp, calendar: Calendar = .current
    ) -> Streak {
        let trained = Set(startedAt.map { weekStart($0, calendar) })
        guard let first = trained.min() else { return Streak() }

        let thisWeek = weekStart(now, calendar)
        // A clock moved back behind the whole history: the last week there is evidence
        // for is the end of the strip, and nothing is invented after it.
        let last = max(thisWeek, first)

        var starts: [Timestamp] = []
        var cursor = last
        while cursor >= first, starts.count < blocks {
            starts.append(cursor)
            guard let previous = calendar.date(
                byAdding: .weekOfYear, value: -1,
                to: Date(timeIntervalSince1970: cursor))
            else { break }
            cursor = previous.timeIntervalSince1970
        }

        return Streak(
            weeks: starts.reversed().map { Week(start: $0, trained: trained.contains($0)) },
            run: run(from: last, trained: trained, calendar: calendar))
    }

    /// Consecutive trained weeks, counted backwards. The week `from` is the current one,
    /// and an empty current week is stepped over once — see the note on `read`.
    private static func run(
        from start: Timestamp, trained: Set<Timestamp>, calendar: Calendar
    ) -> Int {
        var cursor = start
        if !trained.contains(cursor) {
            guard let previous = week(before: cursor, calendar) else { return 0 }
            cursor = previous
        }
        var count = 0
        while trained.contains(cursor) {
            count += 1
            guard let previous = week(before: cursor, calendar) else { break }
            cursor = previous
        }
        return count
    }

    private static func week(before start: Timestamp, _ calendar: Calendar) -> Timestamp? {
        calendar.date(
            byAdding: .weekOfYear, value: -1, to: Date(timeIntervalSince1970: start)
        )?.timeIntervalSince1970
    }

    /// The first instant of the week one instant falls in. **The calendar's own first
    /// weekday**, so a Dutch phone starts on Monday and an American one on Sunday, and
    /// neither is Hoppa's opinion.
    static func weekStart(_ timestamp: Timestamp, _ calendar: Calendar) -> Timestamp {
        let date = Date(timeIntervalSince1970: timestamp)
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return calendar.startOfDay(for: date).timeIntervalSince1970
        }
        return interval.start.timeIntervalSince1970
    }
}

extension Streak {

    /// The whole of what a screen needs: §6.7 reads the strip off the finished Workouts,
    /// and the Open Workout is not one of them — it has been started, not done, the same
    /// clause `Logbook.lastTrained` and `Rules.history` both apply.
    public static func read(_ logbook: Logbook, now: Timestamp, calendar: Calendar = .current) -> Streak {
        read(startedAt: logbook.workouts.map(\.startedAt), now: now, calendar: calendar)
    }
}
