import SwiftUI
import HoppaRules
import HoppaStore

// Ticket 0032 — the app's home.
//
// **The picker is always home, and onboarding is an ordinary route to it** (§6.1). That is
// why the empty state lives here and not on a separate first-run screen: the app never has
// to decide at launch which screen it opens on.
//
// Everything on it is §3.1: a free pick, no rotation, no pre-selection, no suggestion, and
// a line per Day saying **when it was last done** — information, not advice (§7.6).
//
// Artboard: `design/0015-history/Home.dc.html`. `SPEC.md` beats it wherever they disagree.

struct WorkoutDayPicker: View {
    @Environment(LogbookStore.self) private var store
    @Binding var path: [Route]

    var body: some View {
        ZStack {
            Color.floor.ignoresSafeArea()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.horizontal, 20)   // §7.4 screen padding
                .padding(.bottom, 20)
        }
        // §7.4: **nothing is drawn in the safe top inset.** The picker is the root of the
        // stack, so hiding the bar here leaves that band empty, and a pushed screen brings
        // its own bar — and its back button — with it.
        //
        // The inset itself is the device's, not §7.4's literal 54: SwiftUI reports what the
        // phone actually has, which on every portrait iPhone this app targets is 54 or more.
        // A phone with a smaller one would be a finding, and Rob's iPhone 16 reports 59.
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private var content: some View {
        if store.isUnreadable {
            unreadable
        } else if let program = store.logbook?.programs.first {
            picker(program)
        } else {
            firstRun
        }
    }

    // MARK: - The first run (§6.1)

    /// `NOTHING HERE YET` and one `CREATE A PROGRAM` button. No header: there is no Program
    /// to name one, and a History door with no Workout behind it would be furniture.
    private var firstRun: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Text("Nothing here yet")
                .typography(Typography.display(26))
                .foregroundStyle(Color.text)
            Spacer()
            PrimaryButton("Create a program") { path.append(.createProgram) }
        }
    }

    // MARK: - The picker (§3.1)

    private func picker(_ program: Program) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header(program)
            Spacer().frame(height: 8)
            Text("Pick a day")
                .typography(Typography.label())
                .foregroundStyle(Color.labelText)
            Spacer().frame(height: 16)

            // `.everyMinute` and not a value read once: "Yesterday" becomes "2 days ago" at
            // midnight, and a phone left on the picker overnight would otherwise lie. It is
            // the same reason ticket 0024 gave the Rest Timer a `TimelineView`.
            TimelineView(.everyMinute) { timeline in
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(program.days, id: \.id) { day in
                            dayRow(day, now: timeline.date.timeIntervalSince1970)
                        }
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
            }

            Spacer(minLength: 16)
            historyRow
        }
    }

    /// The Program's Name, and the `•••` into its sheet. §6.7's *two doors* counts the doors
    /// into **History**; this is the way into Flow 5, which §6.1 step 3 calls the hub.
    private func header(_ program: Program) -> some View {
        HStack(spacing: 12) {
            Text(program.name)
                .typography(Typography.display(13, tracking: 0.1))
                .foregroundStyle(Color.steel)
            Spacer(minLength: 8)
            Button {
                path.append(.programSheet(program.id, onboarding: false))
            } label: {
                Text("•••")
                    .typography(Typography.body(17))
                    .foregroundStyle(Color.steel)
                    .frame(width: 50, height: 50, alignment: .trailing)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(height: 50)          // §7.4's smaller hit target, and the header's whole height
    }

    private func dayRow(_ day: WorkoutDay, now: Timestamp) -> some View {
        Button {
            path.append(.logging(day.id))
        } label: {
            card {
                VStack(alignment: .leading, spacing: 8) {
                    Text(day.name)
                        .typography(Typography.display(15))
                        .foregroundStyle(Color.text)
                    Text(RelativeDay.text(store.logbook?.lastTrained(day.id), now: now))
                        .typography(Typography.meta())
                        .foregroundStyle(Color.dimText)
                }
            }
        }
        .buttonStyle(.plain)
    }

    /// §6.7's first door. **The screen behind it is not built** — ticket 0032 says to say
    /// which, and this is a live row into `NotBuiltYet`, not a disabled one.
    ///
    /// The artboard reads `56 workouts · 9 weeks in a row`. The count is a fact the Logbook
    /// already holds; the streak is a §6.7 rule nobody has written, so the row states the
    /// half that is true and invents nothing.
    private var historyRow: some View {
        Button {
            path.append(.history)
        } label: {
            card {
                VStack(alignment: .leading, spacing: 8) {
                    Text("History")
                        .typography(Typography.display(15))
                        .foregroundStyle(Color.text)
                    Text(workoutCount)
                        .typography(Typography.meta())
                        .foregroundStyle(Color.dimText)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var workoutCount: String {
        let count = store.logbook?.workouts.count ?? 0
        return count == 1 ? "1 workout" : "\(count) workouts"
    }

    // MARK: - What a corrupt file looks like

    /// Kept word for word from ticket 0025's harness. The whole of what a view may do with
    /// `.unreadable` is say what is true: there is no `Logbook` in hand, so there is nothing
    /// to render and nothing to send, and Hoppa has changed no byte of the file.
    private var unreadable: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hoppa cannot read your logbook.")
                .typography(Typography.display(26))
                .foregroundStyle(Color.stop)
            Text("Nothing was changed. The file is exactly as it was.")
                .typography(Typography.body(13, lineSpacing: 4))
                .foregroundStyle(Color.dimText)
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }

    // MARK: - Plain parts

    /// The outlined row the artboard uses for a Day, for History and for an Exercise card:
    /// a `line` border on the floor, radius 3 (§7.4), and never under 50 pt tall.
    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: 12) {
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("›")
                .typography(Typography.body(13))
                .foregroundStyle(Color.labelText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .frame(minHeight: 50)
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.line, lineWidth: 1))
        .contentShape(Rectangle())
    }
}
