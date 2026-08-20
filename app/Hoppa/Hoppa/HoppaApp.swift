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

    var body: some Scene {
        WindowGroup {
            AcceptanceHarness()
                .environment(store)
                // The spec is dark-first throughout. Whether a light mode ever
                // exists is still open on the build map, so this pins the
                // appearance rather than assuming an answer.
                .preferredColorScheme(.dark)
        }
    }
}

extension Logbook {
    /// `Documents/logbook.json`.
    ///
    /// `Documents` and not `Application Support`, because `UIFileSharingEnabled` and
    /// `LSSupportsOpeningDocumentsInPlace` expose exactly this folder in the Files app —
    /// which is how the file comes off the phone. There is no export screen; there is no
    /// export screen in the five flows.
    static var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("logbook.json")
    }
}
