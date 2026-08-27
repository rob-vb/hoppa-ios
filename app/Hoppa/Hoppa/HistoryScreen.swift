import SwiftUI
import HoppaRules
import HoppaStore

// Ticket 0047 — §6.7's first door, and the first Flow 4 screen.
//
// Two views on one screen and **both are rules**, so neither is computed here: the strip
// and its figure are `Streak.read`, the list is `Rules.history`. What is left in this file
// is arrangement, English and dates — which is exactly what ticket 0029 says a view may
// hold.
//
// Three things this screen decided, because §6.7 left them open. Each is a judgment call
// and each is on the walk list.
//
// - **The strip is drawn only where there is history.** §6.7 gives the streak no empty
//   state of its own, and a card reading `0` over sixteen dark blocks is the shortfall
//   §7.6 forbids. Before the first Workout the screen is the empty state and nothing else.
// - **The month sits under the day, in the label grey.** The artboard writes `18` over
//   `AUG` and no year. A Workout eight months back would then read the same as one from
//   this month, so the year joins the label the moment the date leaves the current one —
//   `18` over `AUG 25`. Nothing is invented for the common case.
// - **The rows are doors and the room is not built.** Ticket 0048 opens a past Workout;
//   until it lands, a row pushes `NotBuiltYet`, which is ticket 0032's own answer to a
//   door with no room — a disabled row proves nothing about the spine.
//
// Artboards: `design/0015-history/History.dc.html` and `Empty.dc.html`.

struct HistoryScreen: View {
    @Environment(LogbookStore.self) private var store
    @Binding var path: [Route]

    private var rows: [HistoryRow] {
        store.logbook.map { Rules.history(in: $0) } ?? []
    }

    var body: some View {
        ZStack {
            Color.floor.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                StepHeader(label: store.logbook?.programs.first?.name, back: leave)
                Text("History")
                    .typography(Typography.display(31, tracking: 0.005))
                    .foregroundStyle(Color.text)
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)   // §7.4 screen padding
            .padding(.bottom, 20)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private var content: some View {
        let rows = self.rows
        if rows.isEmpty {
            empty
        } else {
            // `.everyMinute`, for the reason the picker's line is: the current week ends at
            // a midnight, and a phone left on this screen would otherwise keep drawing
            // yesterday's strip. The list itself does not move, but it costs nothing to
            // redraw with it.
            TimelineView(.everyMinute) { timeline in
                let now = timeline.date.timeIntervalSince1970
                VStack(alignment: .leading, spacing: 0) {
                    streak(now)
                    Spacer().frame(height: 16)
                    list(rows)
                }
            }
        }
    }

    private func leave() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    // MARK: - The streak (§6.7)

    /// The figure, the strip, and the two dates under it. **No flame, no warning, no
    /// best-ever number** — the absence of a comparison is what keeps §7.6 whole.
    @ViewBuilder
    private func streak(_ now: Timestamp) -> some View {
        let streak = store.logbook.map { Streak.read($0, now: now) } ?? Streak()
        if !streak.weeks.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Text("\(streak.run)")
                    .typography(Typography.display(44, tracking: -0.01))
                    .foregroundStyle(Color.text)
                Spacer().frame(height: 9)
                Text(streak.run == 1 ? "Week in a row" : "Weeks in a row")
                    .typography(Typography.display(14, tracking: 0.05))
                    .foregroundStyle(Color.text)
                Spacer().frame(height: 15)
                HStack(spacing: 3) {
                    ForEach(streak.weeks) { week in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(week.trained ? Color.steel : Color.weekOff)
                            .frame(height: 26)
                            .frame(maxWidth: .infinity)
                    }
                }
                Spacer().frame(height: 8)
                HStack {
                    Text(HistoryDate.week(streak.weeks.first!.start))
                        .typography(Typography.label())
                        .foregroundStyle(Color.labelText)
                    Spacer()
                    Text(HistoryDate.week(streak.weeks.last!.start))
                        .typography(Typography.label())
                        .foregroundStyle(Color.labelText)
                }
            }
            .padding(.horizontal, 15)
            .padding(.top, 16)
            .padding(.bottom, 14)
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.line, lineWidth: 1))
        }
    }

    // MARK: - The Workout list (§6.7)

    /// Reverse date order, and the count above it. Rows are separated by a rule and not by
    /// a card: the artboard draws the list as a table, which is what lets a date column
    /// line up down the screen.
    private func list(_ rows: [HistoryRow]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(rows.count == 1 ? "1 workout" : "\(rows.count) workouts")
                .typography(Typography.label())
                .foregroundStyle(Color.labelText)
            Spacer().frame(height: 10)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(rows) { row in
                        Divider().overlay(Color.line)
                        workoutRow(row)
                    }
                    Divider().overlay(Color.line)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private func workoutRow(_ row: HistoryRow) -> some View {
        Button {
            path.append(.pastWorkout(row.id))
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(HistoryDate.day(row.startedAt))
                        .typography(Typography.display(15, tracking: 0.03))
                        .foregroundStyle(Color.steel)
                    Text(HistoryDate.month(row.startedAt))
                        .typography(Typography.label(10))
                        .foregroundStyle(Color.labelText)
                }
                .frame(width: 46, alignment: .leading)
                .padding(.top, 2)

                VStack(alignment: .leading, spacing: 6) {
                    Text(row.workoutDayName)
                        .typography(Typography.display(16))
                        .foregroundStyle(Color.text)
                    Text(meta(row))
                        .typography(Typography.meta())
                        .foregroundStyle(Color.dimText)
                    if row.wentUpCount > 0 {
                        // The one green thing on the screen, and §7.3 already gives green
                        // its meaning everywhere else.
                        Text(row.wentUpCount == 1 ? "1 went up" : "\(row.wentUpCount) went up")
                            .typography(Typography.label(10, tracking: 0.11))
                            .foregroundStyle(Color.go)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("›")
                    .typography(Typography.body(13))
                    .foregroundStyle(Color.labelText)
                    .padding(.top, 2)
            }
            .padding(.vertical, 13)
            .frame(minHeight: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// `4 exercises · 13 sets`, and `· 1 skipped` only where there was one. A skip is
    /// listed plain, the way §6.5 lists it: no warning colour and no invitation to fix.
    private func meta(_ row: HistoryRow) -> String {
        var parts = [
            row.exerciseCount == 1 ? "1 exercise" : "\(row.exerciseCount) exercises",
            row.setCount == 1 ? "1 set" : "\(row.setCount) sets"
        ]
        if row.skippedCount > 0 {
            parts.append("\(row.skippedCount) skipped")
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - Before the first Workout (§6.7)

    /// Word for word the artboard's, and it states both halves: a Workout lands here when
    /// it is finished, and an Exercise gets a line once it has two.
    private var empty: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nothing here yet")
                .typography(Typography.display(26))
                .foregroundStyle(Color.text)
            Text("Finish your first workout and it lands here. "
                 + "Every exercise gets a line as soon as it has two.")
                .typography(Typography.body(13, lineSpacing: 4))
                .foregroundStyle(Color.dimText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - The dates on this screen

/// **The app's, not a rule's** — the same clause that keeps `RelativeDay` and `Streak` out
/// of `HoppaRules`. A date is a calendar and a zone, and this is only the printing of one.
enum HistoryDate {

    static func day(_ timestamp: Timestamp) -> String {
        Date(timeIntervalSince1970: timestamp).formatted(.dateTime.day())
    }

    /// `AUG`, and `AUG 25` once the date leaves the current year — see the note at the top
    /// of this file. Uppercased by `Typography.label`, so the value here is the plain one.
    static func month(_ timestamp: Timestamp, now: Date = Date()) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let calendar = Calendar.current
        let month = date.formatted(.dateTime.month(.abbreviated))
        guard calendar.component(.year, from: date) != calendar.component(.year, from: now)
        else { return month }
        return "\(month) \(date.formatted(.dateTime.year(.twoDigits)))"
    }

    /// `4 MAY` — the date under an end of the strip.
    static func week(_ timestamp: Timestamp) -> String {
        Date(timeIntervalSince1970: timestamp)
            .formatted(.dateTime.day().month(.abbreviated))
    }
}

extension Color {
    /// Ticket 0047 — a week with no Workout. §7.2 has no value for it and the artboard
    /// does: `#191B1D`, which sits between `floor` and `card` and is **not a new hue** —
    /// it is the same 210° spine every grey in §7.2 runs on. It has to be visible as a
    /// block and it must not read as a warning, so it is darker than the card it sits on
    /// rather than another colour.
    static let weekOff = Color(hex: 0x191B1D)
}
