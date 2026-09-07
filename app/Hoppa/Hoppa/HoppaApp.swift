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
        HoppaChrome.install()
    }

    var body: some Scene {
        WindowGroup {
            HoppaShell()
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
}
