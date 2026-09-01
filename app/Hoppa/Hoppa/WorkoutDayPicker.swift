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

    /// §3.3's last line, and ticket 0040's whole screen. `nil` is the ordinary picker.
    @State private var sheet: PickerSheet?
    /// **Once per launch, not once per appearance.** Hoppa never ends a Workout by itself
    /// (§3.3), so a swipe is not an answer and the question comes back — but it comes back
    /// at the next launch, not every time the user pops home from the Program sheet. It is
    /// set when the sheet is *shown*, so a swipe cannot re-raise it inside the same run.
    @State private var asked = false

    private var openWorkout: Workout? { store.logbook?.openWorkout }

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
        .task { askAboutAnEarlierDay() }
        .sheet(item: $sheet) { which in
            sheetBody(which)
                .presentationBackground(Color.floor)
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - The Open Workout from an earlier day (§3.3) — ticket 0040

    /// > An Open Workout from an earlier day is **not** closed silently. On next open
    /// > Hoppa asks: resume, finish, or discard.
    ///
    /// *On next open* means *on the picker*, because the picker is home (§6.1) and the app
    /// never decides at launch which screen it opens on. Everything this needs is already
    /// in hand: `RelativeDay.isEarlierDay` is the calendar test, and `startedAt` is the one
    /// clock a Workout carries.
    private func askAboutAnEarlierDay() {
        guard !asked, let open = openWorkout else { return }
        asked = true
        guard RelativeDay.isEarlierDay(open.startedAt, than: Date().timeIntervalSince1970)
        else { return }
        sheet = .earlierDay
    }

    @ViewBuilder
    private func sheetBody(_ which: PickerSheet) -> some View {
        if let open = openWorkout {
            switch which {
            case .earlierDay: earlierDaySheet(open)
            case .discard: discardSheet()
            }
        }
    }

    /// The three answers §3.3 names, and no fourth. `Resume` is the primary because it is
    /// the common one — the user came back to train — and Discard carries the stop tone
    /// because it is the one that keeps nothing.
    private func earlierDaySheet(_ open: Workout) -> some View {
        SheetStack(
            heading: "\(open.workoutDayName) is still open",
            note: "You started it \(started(open)). Hoppa never ends a workout by itself."
        ) {
            SheetPrimary("Resume") {
                sheet = nil
                path.append(.logging(open.workoutDayId))
            }
            SheetRow("Finish it", sub: finishSub(open)) {
                sheet = nil
                // §3.3's shortcut, said where the user taps rather than in a second sheet:
                // one tap skips what is still Open and finishes, and nothing is ambiguous
                // — every Exercise still ends Completed or Skipped.
                end(open.canFinish ? .finish : .skipRemainingAndFinish)
            }
            SheetRow("Discard it", sub: nil, tone: .stop) {
                // A Workout with no logged Sets discards without a question (§3.3).
                if open.hasLoggedAnything {
                    // **Not** `sheet = nil` first: dismissing and presenting in one tick
                    // loses the second. `.sheet(item:)` swaps one for the other.
                    sheet = .discard
                } else {
                    sheet = nil
                    end(.discard)
                }
            }
        }
    }

    /// Word for word the logging screen's, because it is the same question about the same
    /// Workout and two wordings would be two promises.
    private func discardSheet() -> some View {
        SheetStack(
            heading: "Discard this workout?",
            note: "Every logged set goes. Hoppa keeps nothing."
        ) {
            SheetRow("Discard", sub: nil, tone: .stop, centred: true) {
                sheet = nil
                end(.discard)
            }
            SheetRow("Keep it", sub: nil, centred: true) { sheet = nil }
        }
    }

    /// `3 exercises still open · will be skipped`, or the count of what a Finish keeps.
    private func finishSub(_ open: Workout) -> String {
        let stillOpen = open.openExerciseCount
        guard stillOpen > 0 else {
            let sets = open.loggedSetCount
            return sets == 1 ? "1 set logged" : "\(sets) sets logged"
        }
        return "\(stillOpen) exercise\(stillOpen == 1 ? "" : "s") still open · will be skipped"
    }

    private func started(_ open: Workout) -> String {
        RelativeDay.text(open.startedAt, now: Date().timeIntervalSince1970).lowercased()
    }

    /// **A Finish lands on §6.5's Summary and a Discard lands on the picker** — the same
    /// rule the logging screen follows, and told apart the same way: by the finished list
    /// growing, not by the `Action`. The picker is already home, so a Discard pushes
    /// nothing and the row it came from goes back to reading its last-trained line.
    private func end(_ action: Action) {
        let before = store.logbook?.workouts.count ?? 0
        store.send(action)
        guard store.logbook?.openWorkout == nil else { return }
        if let finished = store.logbook?.workouts.last,
           (store.logbook?.workouts.count ?? 0) > before {
            Haptic.finished()
            path = [.summary(finished.id)]
        } else {
            Haptic.destroyed()
        }
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
            // Ticket 0057: no header on this screen, so the wordmark takes its place.
            Wordmark(height: 22)
                .foregroundStyle(Color.steel)
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
            reweighBanner
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
    ///
    /// Ticket 0057, second pass, on Rob's words: the wordmark **white, top-left**, the
    /// Program name beside it in steel and **cut off with an ellipsis** when it is long,
    /// and a drawn gear where `•••` was.
    ///
    /// Third pass, same day: the wordmark **twice the size**, the gear on its line, and the
    /// Program name **under** them. Two rows, so the header is no longer one 50 pt band.
    private func header(_ program: Program) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 12) {
                Wordmark(height: 28)
                    .foregroundStyle(Color.text)
                Spacer(minLength: 8)
                Button {
                    path.append(.programSheet(program.id, onboarding: false))
                } label: {
                    GearGlyph()
                        .stroke(Color.steel, style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
                        .frame(width: 22, height: 22)
                        .frame(width: 50, height: 50, alignment: .trailing)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
                .accessibilityLabel("Program settings")
            }
            .frame(height: 50)      // §7.4's smaller hit target, and the gear's whole row
            Text(program.name)
                .typography(Typography.display(13, tracking: 0.1))
                .foregroundStyle(Color.steel)
                .lineLimit(1)
                .truncationMode(.tail)
        }
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
                    if isRunning(day) {
                        // Ticket 0040. `Rules.reduce` refuses a second `.startWorkout`, so
                        // a row that says nothing is a row that lies about what a tap does.
                        // It replaces the last-trained line rather than joining it: §3.1's
                        // line reads the newest **finished** Workout, and *running now* is
                        // the more useful of the two facts while it is true.
                        Text("Running")
                            .typography(Typography.meta())
                            .foregroundStyle(Color.go)
                    } else {
                        Text(RelativeDay.text(store.logbook?.lastTrained(day.id), now: now))
                            .typography(Typography.meta())
                            .foregroundStyle(Color.dimText)
                    }
                }
            }
        }
        .buttonStyle(.pressable)
    }

    // MARK: - The second door to the Re-weigh list (§6.6) — ticket 0046

    /// §6.6 gives the list one door — *the confirm leads to it* — and stops there. Without
    /// a second, a user who leaves the screen never finds it again: nothing wrote the list
    /// down, so nothing brings it back. **This is that second door**, and it is a banner on
    /// the picker rather than a sheet at launch.
    ///
    /// A sheet was the obvious answer and it is the wrong one. The list holds *every*
    /// Exercise with no Working Weight, which includes one added last night and not yet
    /// weighed — so a sheet would ambush the user with a modal for a thing he already knows
    /// about. §7.6: Hoppa states its condition where the user stands. A banner does that,
    /// it is there every time he opens the app while the condition is true, and it goes by
    /// itself when the last weight is typed.
    ///
    /// It sits **at the top**, under the Program's Name. The foot of the picker is §6.7's
    /// History door.
    @ViewBuilder
    private var reweighBanner: some View {
        let count = store.logbook.map { Rules.reweighList(in: $0).count } ?? 0
        if count > 0 {
            Spacer().frame(height: 8)
            Button { path.append(.reweigh) } label: {
                card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(count == 1 ? "1 exercise has no weight" : "\(count) exercises have no weight")
                            .typography(Typography.display(15))
                            .foregroundStyle(Color.text)
                        // No blame and no advice (§7.6) — the condition, and what it costs.
                        Text(count == 1 ? "It logs no set until you weigh it" : "They log no sets until you weigh them")
                            .typography(Typography.meta())
                            .foregroundStyle(Color.dimText)
                    }
                }
            }
            .buttonStyle(.pressable)
        }
    }

    /// §6.7's first door. Ticket 0047 built the room behind it.
    ///
    /// The artboard reads `56 workouts · 9 weeks in a row`, and it reads both halves now:
    /// ticket 0032 could only state the count, because the streak was a §6.7 rule nobody
    /// had written. `Streak.read` is that rule, and it is the **same** call the history
    /// screen draws its strip from — the app holds one week rule and not two.
    ///
    /// Its own `TimelineView`, for the reason the day rows have one: the run is counted
    /// against the week that holds *now*, and a phone left on the picker crosses midnight.
    private var historyRow: some View {
        TimelineView(.everyMinute) { timeline in
            DoorRow(
                title: "History",
                detail: historyLine(now: timeline.date.timeIntervalSince1970)
            ) {
                path.append(.history)
            }
        }
    }

    /// `56 workouts · 9 weeks in a row`. **The run is dropped where it is zero**, not
    /// printed as `0 weeks in a row`: a run of nothing is the shortfall §6.7 removed the
    /// best-ever number to avoid, and the count on its own is still true (§7.6).
    private func historyLine(now: Timestamp) -> String {
        let count = store.logbook?.workouts.count ?? 0
        let workouts = count == 1 ? "1 workout" : "\(count) workouts"
        let run = store.logbook.map { Streak.read($0, now: now).run } ?? 0
        guard run > 0 else { return workouts }
        return "\(workouts) · \(run) week\(run == 1 ? "" : "s") in a row"
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

    /// The outlined row the artboard uses for a Day and for an Exercise card:
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

    private func isRunning(_ day: WorkoutDay) -> Bool {
        openWorkout?.workoutDayId == day.id
    }
}

/// Which sheet is up on the picker. **Every other row stays tappable** while a Workout is
/// Open: the rules refuse the second `.startWorkout`, and the logging screen already meets
/// that with a screen naming the Day that is running and one door back to it. A dead row
/// would refuse in silence, and silence explains nothing.
enum PickerSheet: String, Identifiable {
    /// §3.3's three answers, asked once per launch.
    case earlierDay
    /// Its confirmation, which §3.3 requires of a Discard that would throw away a Set.
    case discard

    var id: String { rawValue }
}
