import SwiftUI
import HoppaRules
import HoppaStore

// Ticket 0025 — "The Logbook on disk".
//
// The store is created once, here, and injected into the environment. There is one
// store and every screen needs it, so threading it through initialisers would be
// carrying without gain. Language is a sibling store on a sibling file.

@main
struct HoppaApp: App {
    @State private var store: LogbookStore
    @State private var languages: LanguageStore

    init() {
        BundledFonts.register()
        HoppaChrome.install()
        let url = HarnessSeed.prepare()
        _store = State(initialValue: LogbookStore(url: url))
        _languages = State(
            initialValue: LanguageStore(
                url: LanguageStore.sidecar(beside: url),
                preferredIdentifiers: Locale.preferredLanguages
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            HoppaShell()
                .environment(store)
                .environment(languages)
                .preferredColorScheme(.dark)
                .dynamicTypeSize(.large)
                .tint(Color.text)
        }
    }
}
