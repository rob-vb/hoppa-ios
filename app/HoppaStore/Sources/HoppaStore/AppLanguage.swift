import Foundation

/// The two voices Hoppa speaks. Not a Logbook field. Not an Action.
public enum AppLanguage: String, Codable, Sendable, Hashable, CaseIterable, Identifiable {
    case english = "en"
    case dutch = "nl"

    public var id: Self { self }

    /// Always "English" / "Nederlands". Recoverable after a wrong tap.
    public var nativeName: String {
        switch self {
        case .english: "English"
        case .dutch: "Nederlands"
        }
    }

    /// Month names and date field order for History / Past. Not for UI chrome.
    public var locale: Locale {
        switch self {
        case .english: Locale(identifier: "en_GB")
        case .dutch: Locale(identifier: "nl_NL")
        }
    }

    /// The phone's primary language. `nl` (including `nl-BE`) → Dutch. Anything else → English.
    public static func detected(from preferredIdentifiers: [String]) -> AppLanguage {
        guard let identifier = preferredIdentifiers.first else { return .english }
        let code = identifier.split(whereSeparator: { $0 == "-" || $0 == "_" }).first
        if code?.caseInsensitiveCompare("nl") == .orderedSame { return .dutch }
        return .english
    }
}
