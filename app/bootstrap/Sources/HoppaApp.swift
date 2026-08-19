import SwiftUI

// Ticket 0018 — "An empty app on the phone".
// This file and ContentView.swift are the smoke test: they exist to prove the
// toolchain, not to be a Hoppa screen. Nothing here is a design decision, and
// all of it is expected to be replaced once the real build starts.

@main
struct HoppaApp: App {
    init() {
        BundledFonts.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // The spec is dark-first throughout. Whether a light mode ever
                // exists is still open on the build map, so the smoke test
                // pins the appearance rather than assuming an answer.
                .preferredColorScheme(.dark)
        }
    }
}
