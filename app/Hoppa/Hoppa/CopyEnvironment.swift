import SwiftUI
import HoppaStore

private struct PhrasebookKey: EnvironmentKey {
    static let defaultValue = Phrasebook(.english)
}

extension EnvironmentValues {
    var copy: Phrasebook {
        get { self[PhrasebookKey.self] }
        set { self[PhrasebookKey.self] = newValue }
    }
}
