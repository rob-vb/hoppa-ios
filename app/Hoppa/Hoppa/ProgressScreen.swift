import SwiftUI
import HoppaRules
import HoppaStore

// Ticket 0058 — §6.7's second door, and the room behind it.
//
// **History's arrangement with a different list.** The chevron carries the Program's Name,
// the title is `Progress`, and under it is either the empty state or a table of rows
// separated by a rule. The list is `Rules.progress`, which is a rule and has its own suite;
// what is left here is arrangement and English, which is what ticket 0029 says a view may
// hold. The screen does no arithmetic: the session count, the went-up count and the
// sparkline all arrive on the row.
//
// **Why this page exists**, in one paragraph, because ticket 0050 had put the door
// elsewhere. The chart's door was a sparkline on the Exercise card, one room down from the
// picker, on the trailing edge of a card that is otherwise about *building* a Day. Nobody
// looks for a statistic there, and it split Flow 4 across two kinds of door that did not
// rhyme: History was a row at the foot of the picker, the chart was a sliver on a card.
// Rob asked for a sibling of History. Statistics was the word offered and refused — it
// names aggregates §6.7 does not keep. **Progress** names the climb §6.7 already draws.
//
// **The whole row is the door**, the way a History row is. The sparkline sits on it as a
// mark and not as a nested button: tapping the mark is tapping the row. `hasSpark` is
// still the gate, applied by the rule at the list — an Exercise nobody has trained is not
// a row, so a door to an empty room is never offered, and one session is still enough to
// reach a screen that states the hero and the condition for the next step.
//
// **Two Exercises with one Name are two rows**, each labelled with its Day. Charts never
// join by Name (§2.7), and neither does this list.

struct ProgressScreen: View {
    @Environment(LogbookStore.self) private var store
    @Binding var path: [Route]

    private var rows: [ProgressRow] {
        store.logbook.map { Rules.progress(in: $0) } ?? []
    }

    var body: some View {
        ZStack {
            Color.floor.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                StepHeader(label: store.logbook?.programs.first?.name, back: leave)
                Text("Progress")
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
            Spacer().frame(height: 16)
            list(rows)
        }
    }

    private func leave() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    // MARK: - The Exercise list (§6.7)

    /// Program order, and the count above it — the same count the picker's door reads.
    /// Rows are separated by a rule and not by a card, so this page and History rhyme.
    private func list(_ rows: [ProgressRow]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(rows.count == 1 ? "1 exercise" : "\(rows.count) exercises")
                .typography(Typography.label())
                .foregroundStyle(Color.labelText)
            Spacer().frame(height: 10)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(rows) { row in
                        Divider().overlay(Color.line)
                        exerciseRow(row)
                    }
                    Divider().overlay(Color.line)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    /// The Name, the Day and the sessions, the green line where there was one, the mark,
    /// and the chevron. **One Button, the whole row**: the mark is inside the label and
    /// owns no gesture of its own.
    ///
    /// The chart it opens is read again on arrival, from the id and not from this row:
    /// `ExerciseChartScreen` asks `Rules.exerciseChart` itself, so nothing stale travels
    /// through the `Route`.
    private func exerciseRow(_ row: ProgressRow) -> some View {
        Button {
            path.append(.exerciseChart(row.id))
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(row.name)
                        .typography(Typography.display(16))
                        .foregroundStyle(Color.text)
                        .lineLimit(1)
                    Text(meta(row))
                        .typography(Typography.meta())
                        .foregroundStyle(Color.dimText)
                    if row.timesUp > 0 {
                        // The one green thing on the row, and §7.3 already gives green
                        // its meaning everywhere else.
                        Text(row.timesUp == 1 ? "1 went up" : "\(row.timesUp) went up")
                            .typography(Typography.label(10, tracking: 0.11))
                            .foregroundStyle(Color.go)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Sparkline(marks: row.sparkline)
                    .padding(.top, 4)

                Text("›")
                    .typography(Typography.body(13))
                    .foregroundStyle(Color.labelText)
                    .padding(.top, 2)
            }
            .padding(.vertical, 13)
            .frame(minHeight: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("Chart for \(row.name), \(row.workoutDayName)")
    }

    /// `Upper A · 12 sessions`, and `1 session` at one. The Day comes first because it is
    /// what tells two Exercises with one Name apart (§2.7).
    private func meta(_ row: ProgressRow) -> String {
        let sessions = row.sessionCount == 1 ? "1 session" : "\(row.sessionCount) sessions"
        return "\(row.workoutDayName) · \(sessions)"
    }

    // MARK: - Before the first session (§6.7)

    /// The same clause History's empty state uses, said about Exercises: a Workout lands
    /// on History when it is finished, and every Exercise it trained lands here.
    private var empty: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nothing here yet")
                .typography(Typography.display(26))
                .foregroundStyle(Color.text)
            Text("Finish a workout and every exercise you trained lands here.")
                .typography(Typography.body(13, lineSpacing: 4))
                .foregroundStyle(Color.dimText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
