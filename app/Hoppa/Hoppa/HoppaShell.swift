import SwiftUI
import HoppaRules
import HoppaStore
import UIKit

// Ticket 0059 — the native tab bar.
//
// Four peer rooms, one `HoppaTab` each, each with its own `NavigationStack` and its own
// path. History, Progress and Settings are not pushes off the picker: they are roots.
// A path is still view state and still not in the store
// ([The view layer around the rules](0024-the-view-layer-around-the-rules.md)).
//
// The bar is the system's. The rooms keep the Plate Rack language. SF Symbols live in
// the bar and nowhere else — ticket 0056 kept §7's glyphs for Hoppa's own drawing, and
// this chrome is not Hoppa's drawing.
//
// The bar hides when there is no Program, during onboarding, and on the logging screen
// and the Summary: those are not rooms you switch out of with a thumb on the foot.

enum HoppaTab: Hashable {
    case home, history, progress, settings
}

struct HoppaShell: View {
    @Environment(LogbookStore.self) private var store
    @State private var tab = HoppaTab.home
    @State private var homePath: [Route] = []
    @State private var historyPath: [Route] = []
    @State private var progressPath: [Route] = []
    @State private var settingsPath: [Route] = []

    private var hasProgram: Bool { store.logbook?.programs.first != nil }

    var body: some View {
        TabView(selection: $tab) {
            pane(.home, "Home", "house", path: $homePath) {
                WorkoutDayPicker(path: $homePath)
            }
            pane(.history, "History", "clock", path: $historyPath) {
                HistoryScreen(path: $historyPath)
            }
            pane(.progress, "Progress", "chart.line.uptrend.xyaxis", path: $progressPath) {
                ProgressScreen(path: $progressPath)
            }
            pane(.settings, "Settings", "gearshape", path: $settingsPath) {
                settingsRoot
            }
        }
    }

    @ViewBuilder
    private var settingsRoot: some View {
        if let id = store.logbook?.programs.first?.id {
            ProgramSheet(path: $settingsPath, programId: id, onboarding: false) {
                tab = .home
            }
        } else {
            Color.floor.ignoresSafeArea()
        }
    }

    private func pane<Root: View>(
        _ tab: HoppaTab,
        _ title: String,
        _ icon: String,
        path: Binding<[Route]>,
        @ViewBuilder root: () -> Root
    ) -> some View {
        NavigationStack(path: path) {
            root()
                .navigationDestination(for: Route.self) { destination($0, path: path) }
                .background(SwipeBackEnabler().frame(width: 0, height: 0))
                .toolbar(hasProgram ? .automatic : .hidden, for: .tabBar)
        }
        .tabItem { Label(title, systemImage: icon) }
        .tag(tab)
    }

    @ViewBuilder
    private func destination(_ route: Route, path: Binding<[Route]>) -> some View {
        switch route {
        case .createProgram:
            NameYourProgram(path: path)
        case .plateRack(let draft):
            PlateRackScreen(path: path, draft: draft)
        case .programSheet(let id, let onboarding):
            ProgramSheet(path: path, programId: id, onboarding: onboarding) {
                path.wrappedValue = []
            }
        case .workoutDay(let id):
            WorkoutDayScreen(path: path, workoutDayId: id)
        case .programSettings(let id):
            ProgramSettings(path: path, programId: id)
        case .logging(let id):
            LoggingScreen(path: path, workoutDayId: id)
        case .summary(let id):
            SummaryScreen(path: path, workoutId: id)
        case .reweigh:
            ReweighScreen(path: path)
        case .pastWorkout(let id):
            PastWorkoutScreen(path: path, workoutId: id)
        case .exerciseChart(let id):
            ExerciseChartScreen(path: path, exerciseId: id)
        }
    }
}

enum HoppaChrome {
    static func install() {
        let bar = UITabBarAppearance()
        bar.configureWithOpaqueBackground()
        bar.backgroundColor = UIColor(Color.floor)
        bar.shadowColor = UIColor(Color.line)
        UITabBar.appearance().standardAppearance = bar
        UITabBar.appearance().scrollEdgeAppearance = bar
        UITabBar.appearance().unselectedItemTintColor = UIColor(Color.labelText)
    }
}
