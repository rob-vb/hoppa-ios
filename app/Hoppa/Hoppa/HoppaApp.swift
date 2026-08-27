import SwiftUI
import HoppaRules
import HoppaStore

// Ticket 0025 — "The Logbook on disk".
//
// The store is created once, here, and injected into the environment. There is one
// store and every screen needs it, so threading it through initialisers would be
// carrying without gain.

@main
struct HoppaApp: App {
    // `HarnessSeed.prepare()` runs first and returns the same URL — a `@State` default is
    // assigned before `init()`'s body, so seeding in `init()` would come too late.
    @State private var store = LogbookStore(url: HarnessSeed.prepare())

    init() {
        BundledFonts.register()
    }

    /// The one navigation path (§6.7 — two doors, no tab bar). It lives here, in `@State`
    /// on the root, and never in the store: a path is view state, and ticket 0024 drew that
    /// line on purpose.
    @State private var path: [Route] = []

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $path) {
                WorkoutDayPicker(path: $path)
                    .navigationDestination(for: Route.self) { destination($0) }
            }
            .environment(store)
            // Dark only, and locked — settled at
            // [Dark only, or a light mode too](0030). This pins the SwiftUI hierarchy;
            // `UIUserInterfaceStyle = Dark` pins the launch screen and the UIKit chrome.
            .preferredColorScheme(.dark)
            // And Dynamic Type with it. §7.4 fixes its sizes in points and its line
            // heights below 1.0, neither of which survives a text scale.
            // `Typography.swift` is the other half: every face is built with `fixedSize`.
            .dynamicTypeSize(.large)
            .tint(Color.text)
        }
    }

    /// One line per screen ticket. A ticket lands its screen by replacing its own case.
    @ViewBuilder
    private func destination(_ route: Route) -> some View {
        switch route {
        case .createProgram:
            NameYourProgram(path: $path)
        case .plateRack(let draft):
            PlateRackScreen(path: $path, draft: draft)
        case .programSheet(let id, let onboarding):
            ProgramSheet(path: $path, programId: id, onboarding: onboarding)
        case .workoutDay(let id):
            WorkoutDayScreen(path: $path, workoutDayId: id)
        case .programSettings(let id):
            ProgramSettings(path: $path, programId: id)
        case .logging(let id):
            LoggingScreen(path: $path, workoutDayId: id)
        case .summary(let id):
            SummaryScreen(path: $path, workoutId: id)
        case .reweigh:
            ReweighScreen(path: $path)
        case .history:
            HistoryScreen(path: $path)
        case .pastWorkout:
            NotBuiltYet(screen: "A past Workout, opened from the history list — every Set as "
                        + "performed, and the delete behind its ••• menu.",
                        ticket: "0048")
        }
    }
}
