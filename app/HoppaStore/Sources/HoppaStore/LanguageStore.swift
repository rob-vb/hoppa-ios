import Foundation
import Observation

/// The one writer for app language. Sibling of `LogbookStore`, different file.
///
/// Absence of `language.json` is never-chosen: this launch detects, and writes nothing.
/// `choose` is the only mutation.
@MainActor
@Observable
public final class LanguageStore {
    public let url: URL
    public private(set) var language: AppLanguage
    /// False means this launch's language came from detection and will be recomputed
    /// next launch if the file is still absent.
    public private(set) var isChosen: Bool

    public var phrasebook: Phrasebook { Phrasebook(language) }

    /// `preferredIdentifiers` is a boundary argument. The store does not reach for `Locale`.
    public init(url: URL, preferredIdentifiers: [String]) {
        self.url = url
        if let saved = Self.read(url) {
            self.language = saved
            self.isChosen = true
        } else {
            self.language = AppLanguage.detected(from: preferredIdentifiers)
            self.isChosen = false
        }
    }

    /// The only mutation. Idempotent: picking the current language rewrites the same bytes.
    public func choose(_ language: AppLanguage) {
        self.language = language
        self.isChosen = true
        persist()
    }

    public static func sidecar(beside logbookURL: URL) -> URL {
        logbookURL.deletingLastPathComponent().appendingPathComponent("language.json")
    }

    private func persist() {
        let file = LanguageFile(language: language)
        guard let data = try? Self.encoder.encode(file) else { return }
        try? data.write(to: url, options: [.atomic])
    }

    private static func read(_ url: URL) -> AppLanguage? {
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(LanguageFile.self, from: data)
        else { return nil }
        return file.language
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        return encoder
    }
}

private struct LanguageFile: Codable {
    var language: AppLanguage
}
