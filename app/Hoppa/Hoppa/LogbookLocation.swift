import Foundation
import HoppaRules

// Ticket 0025 wrote this beside `HoppaApp`; ticket 0032 moved it out, because `HoppaApp`
// imports SwiftUI and this does not. A file in the app target that imports no SwiftUI can
// be type-checked on the VPS against the built modules, and this one names the single path
// every byte of Rob's training goes through — so it is worth having on the checkable side.

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
