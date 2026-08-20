import UIKit
import CoreText

// Ticket 0018 — the bundled faces, lifted out of the smoke-test screen when
// ticket 0025 replaced it. Unchanged; it is still the only thing that registers
// Anton and IBM Plex Sans.

// MARK: - Bundled fonts

/// Registers the bundled faces with CoreText at launch.
///
/// This is deliberately runtime registration rather than an `UIAppFonts` entry
/// in the Info.plist: a modern Xcode project generates its Info.plist from build
/// settings, so there is no plist file to edit, and this route needs no step in
/// the Xcode UI at all. `UIAppFonts` remains the conventional alternative and
/// can replace this later.
enum BundledFonts {
    /// PostScript names — read from the font files themselves. They are not
    /// guessable from the filenames: IBM's medium weight is `IBMPlexSans-Medm`.
    static let display = "Anton-Regular"
    static let body = "IBMPlexSans"
    static let bodyMedium = "IBMPlexSans-Medm"

    private static let files = ["Anton-Regular", "IBMPlexSans-Regular", "IBMPlexSans-Medium"]

    static func register() {
        for file in files {
            guard let url = locate(file) else {
                print("[smoke] font file not in the bundle: \(file).ttf")
                continue
            }
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                let reason = error?.takeRetainedValue().localizedDescription ?? "unknown"
                print("[smoke] could not register \(file).ttf — \(reason)")
            }
        }
    }

    /// The Fonts folder may land flattened into the bundle root or kept as a
    /// subdirectory, depending on how Xcode added it. Look in both.
    private static func locate(_ file: String) -> URL? {
        Bundle.main.url(forResource: file, withExtension: "ttf")
            ?? Bundle.main.url(forResource: file, withExtension: "ttf", subdirectory: "Fonts")
    }

    /// True when CoreText can actually resolve the PostScript name, so a silent
    /// fallback to the system face cannot pass as a success.
    static func isAvailable(_ postScriptName: String) -> Bool {
        UIFont(name: postScriptName, size: 12) != nil
    }
}
